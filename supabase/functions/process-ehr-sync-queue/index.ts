import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts'
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from '../_shared/rate-limiter.ts'
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

interface SyncQueueItem {
  id: string
  table_name: string
  record_id: string
  template_id: string
  sync_type: string
  sync_status: string
  retry_count: number
  data_snapshot: any
  ehr_id: string
}

/**
 * Check if clinical note has meaningful content for EHR sync
 * - Must have chief complaint, OR
 * - Must have 5+ populated SOAP fields
 */
function hasMeaningfulContent(note: any): boolean {
  // Has chief complaint
  if (note.section_1_chief_complaint) {
    return true
  }

  // Count populated SOAP fields (threshold: 5+ non-empty fields)
  let populatedCount = 0
  if (note.section_2_hpi) populatedCount++
  if (note.section_2_symptoms) populatedCount++
  if (note.section_2_medical_conditions) populatedCount++
  if (note.section_2_current_medications) populatedCount++
  if (note.section_3_physical_exam) populatedCount++
  if (note.section_3_vitals_temperature) populatedCount++
  if (note.section_3_vitals_systolic_bp) populatedCount++
  if (note.section_3_vitals_heart_rate) populatedCount++
  if (note.section_4_assessment_diagnoses) populatedCount++
  if (note.section_5_plan_treatments) populatedCount++
  if (note.section_5_plan_medications) populatedCount++

  return populatedCount >= 5
}

/**
 * Background worker function to process pending items in the EHRbase sync queue
 * This function:
 * 1. Fetches pending/failed items from ehrbase_sync_queue
 * 2. Validates each note has meaningful content before syncing
 * 3. Calls sync-to-ehrbase edge function for valid items
 * 4. Marks meaningless notes as skipped (no sync needed)
 * 5. Updates queue status based on results
 * 6. Retries failed items up to 5 times
 */
async function processSyncQueue(req: Request): Promise<Response> {
  const origin = req.headers.get('origin')
  const corsHeaders_dynamic = getCorsHeaders(origin)

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders_dynamic, ...securityHeaders } })
  }

  try {
    // Verify Firebase JWT
    const token = req.headers.get('x-firebase-token')
    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Missing Firebase token', code: 'MISSING_TOKEN', status: 401 }),
        { status: 401, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const auth = await verifyFirebaseJWT(token)
    if (!auth.valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid Firebase token', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
        { status: 401, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Rate limiting check
    const rateLimitConfig = getRateLimitConfig('process-ehr-sync-queue', auth.user_id || auth.sub || '')
    const rateLimit = await checkRateLimit(rateLimitConfig)
    if (!rateLimit.allowed) {
      return createRateLimitErrorResponse(rateLimit)
    }

    // Create Supabase client
    const supabase = createClient(supabaseUrl!, supabaseServiceRoleKey!)

    // Fetch pending and failed items (with retry logic)
    const { data: queueItems, error: fetchError } = await supabase
      .from('ehrbase_sync_queue')
      .select('*')
      .in('sync_status', ['pending', 'failed'])
      .lt('retry_count', 5)  // Only items with < 5 retries
      .order('created_at', { ascending: true })
      .limit(10)  // Process max 10 items per run

    if (fetchError) {
      console.error('Error fetching sync queue items:', fetchError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch sync queue items',
          details: fetchError.message
        }),
        { status: 500, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!queueItems || queueItems.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No pending items in sync queue',
          itemsProcessed: 0
        }),
        { status: 200, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[Queue Worker] Processing ${queueItems.length} items from EHRbase sync queue`)

    let successCount = 0
    let failureCount = 0
    const results: any[] = []

    // Process each item
    for (const item of queueItems) {
      try {
        console.log(`[Queue Worker] Processing queue item: ${item.id} (table: ${item.table_name}, record: ${item.record_id})`)

        // Fetch associated clinical note to validate content
        let clinicalNote: any = null
        if (item.table_name === 'clinical_notes' || item.table_name === 'soap_notes') {
          const { data: noteData } = await supabase
            .from(item.table_name)
            .select('*')
            .eq('id', item.record_id)
            .maybeSingle()

          clinicalNote = noteData
        }

        // Validate content before syncing
        if (clinicalNote && !hasMeaningfulContent(clinicalNote)) {
          console.log(`⏭️  Skipping queue item ${item.id}: Note lacks meaningful content (no chief complaint + <5 SOAP fields)`)

          // Mark as skipped (not an error, just not needed)
          await supabase
            .from('ehrbase_sync_queue')
            .update({
              sync_status: 'skipped',
              processed_at: new Date().toISOString(),
              error_message: 'Note lacks meaningful clinical content (no chief complaint and <5 populated SOAP fields)'
            })
            .eq('id', item.id)

          successCount++ // Count as successfully processed (even though not synced)
          results.push({
            queueId: item.id,
            recordId: item.record_id,
            status: 'skipped',
            message: 'Note lacked meaningful content; sync not needed'
          })

          continue // Skip to next item
        }

        // Mark as processing
        await supabase
          .from('ehrbase_sync_queue')
          .update({ sync_status: 'processing' })
          .eq('id', item.id)

        // Call sync-to-ehrbase edge function
        const syncResponse = await fetch(`${supabaseUrl}/functions/v1/sync-to-ehrbase`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${supabaseServiceRoleKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            queueId: item.id,
            ...item
          })
        })

        const syncResult = await syncResponse.json()

        if (syncResponse.ok && syncResult.success) {
          // Update queue item as completed
          await supabase
            .from('ehrbase_sync_queue')
            .update({
              sync_status: 'completed',
              processed_at: new Date().toISOString(),
              error_message: null
            })
            .eq('id', item.id)

          // Update source table with EHR sync status if it exists
          try {
            if (item.table_name === 'soap_notes') {
              await supabase
                .from('soap_notes')
                .update({
                  ehr_sync_status: 'completed',
                  synced_at: new Date().toISOString()
                })
                .eq('id', item.record_id)
            } else if (item.table_name === 'clinical_notes') {
              await supabase
                .from('clinical_notes')
                .update({
                  ehr_sync_status: 'completed',
                  synced_at: new Date().toISOString()
                })
                .eq('id', item.record_id)
            }
          } catch (e) {
            console.error(`⚠️  Failed to update ${item.table_name}:`, e)
          }

          successCount++
          results.push({
            queueId: item.id,
            recordId: item.record_id,
            status: 'completed',
            message: 'Successfully synced to EHRbase'
          })

          console.log(`✅ Queue item ${item.id} completed`)
        } else {
          // Increment retry count and mark as failed
          const newRetryCount = (item.retry_count || 0) + 1
          const shouldRetry = newRetryCount < 5

          await supabase
            .from('ehrbase_sync_queue')
            .update({
              sync_status: shouldRetry ? 'failed' : 'error',
              retry_count: newRetryCount,
              error_message: syncResult.error || 'Unknown error',
              processed_at: new Date().toISOString()
            })
            .eq('id', item.id)

          // Update source table with error status if it exists
          try {
            if (item.table_name === 'soap_notes') {
              await supabase
                .from('soap_notes')
                .update({
                  ehr_sync_status: shouldRetry ? 'pending' : 'failed',
                  ehr_sync_error: syncResult.error || 'Unknown error'
                })
                .eq('id', item.record_id)
            } else if (item.table_name === 'clinical_notes') {
              await supabase
                .from('clinical_notes')
                .update({
                  ehr_sync_status: shouldRetry ? 'pending' : 'failed',
                  ehr_sync_error: syncResult.error || 'Unknown error'
                })
                .eq('id', item.record_id)
            }
          } catch (e) {
            console.error(`⚠️  Failed to update ${item.table_name}:`, e)
          }

          failureCount++
          results.push({
            queueId: item.id,
            recordId: item.record_id,
            status: shouldRetry ? 'retry' : 'error',
            message: syncResult.error || 'Sync failed',
            retryCount: newRetryCount
          })

          console.log(`❌ Queue item ${item.id} failed (retry ${newRetryCount}/5)`)
        }
      } catch (itemError) {
        console.error(`Error processing queue item ${item.id}:`, itemError)
        failureCount++

        // Update queue item with error
        try {
          const newRetryCount = (item.retry_count || 0) + 1
          await supabase
            .from('ehrbase_sync_queue')
            .update({
              sync_status: newRetryCount < 5 ? 'failed' : 'error',
              retry_count: newRetryCount,
              error_message: `Processing error: ${itemError instanceof Error ? itemError.message : String(itemError)}`,
              processed_at: new Date().toISOString()
            })
            .eq('id', item.id)
        } catch (updateError) {
          console.error('Failed to update queue item error:', updateError)
        }

        results.push({
          queueId: item.id,
          recordId: item.record_id,
          status: 'error',
          message: itemError instanceof Error ? itemError.message : String(itemError)
        })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Sync queue processing completed',
        itemsProcessed: queueItems.length,
        successCount,
        failureCount,
        results
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Unexpected error in process-ehr-sync-queue:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Unexpected error processing sync queue',
        details: error instanceof Error ? error.message : String(error)
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
}

serve(processSyncQueue)
