import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts'
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from '../_shared/rate-limiter.ts'

serve(async (req) => {
  const origin = req.headers.get('origin')
  const corsHeaders = getCorsHeaders(origin)

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders, ...securityHeaders } })
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Create Supabase client with user's auth token
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Rate limiting check (HIPAA: Prevents DDoS and abuse)
    const rateLimitConfig = getRateLimitConfig('upload-profile-picture', user.id)
    const rateLimit = await checkRateLimit(rateLimitConfig)
    if (!rateLimit.allowed) {
      console.warn(`🚫 Rate limit exceeded for user ${user.id}`)
      return createRateLimitErrorResponse(rateLimit)
    }

    // Get user's firebase_uid from Supabase users table
    const { data: userData, error: userDataError } = await supabaseClient
      .from('users')
      .select('firebase_uid')
      .eq('id', user.id)
      .single()

    if (userDataError || !userData?.firebase_uid) {
      throw new Error('User not found or missing firebase_uid')
    }

    const firebaseUid = userData.firebase_uid

    // Parse the multipart form data
    const formData = await req.formData()
    const file = formData.get('file') as File

    if (!file) {
      throw new Error('No file provided')
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      throw new Error(`Invalid file type. Allowed: ${allowedTypes.join(', ')}`)
    }

    // Validate file size (5MB max)
    const maxSize = 5 * 1024 * 1024 // 5MB
    if (file.size > maxSize) {
      throw new Error('File size exceeds 5MB limit')
    }

    // Use service role for cleanup operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Step 1: Delete ALL existing profile pictures for this user (any role)
    // Use a simple path structure: pics/{firebase_uid}/ (works for all roles)
    const userFolder = `pics/${firebaseUid}`
    const { data: existingFiles, error: listError } = await supabaseAdmin
      .storage
      .from('profile_pictures')
      .list(userFolder, {
        limit: 100,
        sortBy: { column: 'created_at', order: 'desc' },
      })

    if (listError) {
      console.error('Error listing existing files:', listError)
    } else if (existingFiles && existingFiles.length > 0) {
      // Delete all existing files for this user
      const filesToDelete = existingFiles
        .filter(f => f.name && f.name !== '.emptyFolderPlaceholder')
        .map(f => `${userFolder}/${f.name}`)

      if (filesToDelete.length > 0) {
        const { error: deleteError } = await supabaseAdmin
          .storage
          .from('profile_pictures')
          .remove(filesToDelete)

        if (deleteError) {
          console.error('Error deleting old files:', deleteError)
        } else {
          console.log(`Deleted ${filesToDelete.length} old profile picture(s) for user ${firebaseUid}`)
        }
      }
    }

    // Step 2: Upload the new profile picture
    const timestamp = Date.now()
    const extension = file.name.split('.').pop() || 'jpeg'
    const fileName = `${userFolder}/${timestamp}.${extension}`
    const fileBuffer = await file.arrayBuffer()

    const { data: uploadData, error: uploadError } = await supabaseClient
      .storage
      .from('profile_pictures')
      .upload(fileName, fileBuffer, {
        contentType: file.type,
        upsert: false,
      })

    if (uploadError) {
      throw uploadError
    }

    // Step 3: Get the public URL
    const { data: urlData } = supabaseClient
      .storage
      .from('profile_pictures')
      .getPublicUrl(fileName)

    // Step 4: Update the users table with the new avatar_url
    const { error: updateError } = await supabaseClient
      .from('users')
      .update({ avatar_url: urlData.publicUrl })
      .eq('id', user.id)

    if (updateError) {
      console.error('Error updating avatar_url in users table:', updateError)
      // Don't throw - the upload succeeded even if DB update failed
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Profile picture uploaded successfully',
        data: {
          path: fileName,
          publicUrl: urlData.publicUrl,
          deletedOldFiles: existingFiles?.length || 0,
          firebase_uid: firebaseUid,
        },
      }),
      {
        headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
