import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';

interface PatchOp {
  op: 'set' | 'append' | 'remove';
  path: string;
  value?: any;
}

interface PatchRequest {
  encounter_id: string;
  client_revision: number;
  ops: PatchOp[];
  device?: {
    platform: string;
    app_version: string;
  };
}

interface ErrorResponse {
  error: string;
  code: string;
  status: number;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED', status: 405 }),
      { status: 405, headers: { 'Content-Type': 'application/json' } }
    );
  }

  try {
    // Verify Firebase JWT
    const token = req.headers.get('x-firebase-token');
    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Missing Firebase token', code: 'MISSING_TOKEN', status: 401 }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const auth = await verifyFirebaseJWT(token);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid Firebase token', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const requestBody = await req.json() as PatchRequest;
    const { encounter_id, client_revision, ops } = requestBody;

    if (!encounter_id || ops === undefined) {
      return new Response(
        JSON.stringify({ error: 'Missing encounter_id or ops', code: 'MISSING_PARAMS', status: 400 }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase admin client
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    console.log(`[soap-draft-patch] Patching SOAP draft for encounter: ${encounter_id}`);
    console.log(`[soap-draft-patch] Client revision: ${client_revision}, ${ops.length} operations`);

    // 1. Fetch current draft and revision
    const { data: session, error: fetchError } = await supabaseAdmin
      .from('video_call_sessions')
      .select('soap_draft_json, server_revision, soap_status')
      .eq('id', encounter_id)
      .single();

    if (fetchError || !session) {
      console.error('[soap-draft-patch] Failed to fetch session:', fetchError);
      return new Response(
        JSON.stringify({ error: 'Session not found', code: 'SESSION_NOT_FOUND', status: 404 }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const serverRevision = session.server_revision || 0;

    // 2. Check for revision conflicts
    if (client_revision < serverRevision) {
      console.warn(`[soap-draft-patch] Conflict detected: client_revision (${client_revision}) < server_revision (${serverRevision})`);
      return new Response(
        JSON.stringify({
          ok: false,
          conflict: true,
          server_revision: serverRevision,
          latest_draft: session.soap_draft_json,
          message: 'Your version is outdated. Please reload the latest version.',
          status: 409,
        }),
        { status: 409, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 3. Deep clone the current draft
    let updatedDraft = JSON.parse(JSON.stringify(session.soap_draft_json || {}));

    // 4. Apply each patch operation
    console.log(`[soap-draft-patch] Applying ${ops.length} patch operations...`);
    let operationsApplied = 0;

    for (const op of ops) {
      try {
        if (op.op === 'set') {
          setJsonPath(updatedDraft, op.path, op.value);
          operationsApplied++;
          console.log(`[soap-draft-patch] ✓ SET ${op.path} = ${JSON.stringify(op.value).substring(0, 50)}`);
        } else if (op.op === 'append') {
          appendJsonPath(updatedDraft, op.path, op.value);
          operationsApplied++;
          console.log(`[soap-draft-patch] ✓ APPEND to ${op.path}`);
        } else if (op.op === 'remove') {
          removeJsonPath(updatedDraft, op.path);
          operationsApplied++;
          console.log(`[soap-draft-patch] ✓ REMOVE ${op.path}`);
        }
      } catch (e) {
        console.error(`[soap-draft-patch] Failed to apply operation ${op.op} on ${op.path}:`, e);
        // Continue with next operation instead of failing entire patch
      }
    }

    // 5. Update metadata timestamps
    if (!updatedDraft.meta) {
      updatedDraft.meta = {};
    }
    updatedDraft.meta.updated_at = new Date().toISOString();
    updatedDraft.meta.last_updated_by = 'clinician';

    // 6. Increment server revision
    const newServerRevision = serverRevision + 1;

    // 7. Determine new soap_status based on operations
    let newStatus = session.soap_status;
    let newEncounterStatus = session.encounter_status;
    if (session.soap_status === 'draft_ready') {
      newStatus = 'editing'; // Transition to editing when first change made
      newEncounterStatus = 'soap_editing'; // Also transition encounter to editing
    }

    // 8. Save updated draft with new revision
    console.log(`[soap-draft-patch] Saving draft with ${operationsApplied} applied operations, new revision: ${newServerRevision}`);
    const { error: updateError } = await supabaseAdmin
      .from('video_call_sessions')
      .update({
        soap_draft_json: updatedDraft,
        server_revision: newServerRevision,
        soap_status: newStatus,
        encounter_status: newEncounterStatus,
      })
      .eq('id', encounter_id);

    if (updateError) {
      console.error('[soap-draft-patch] Failed to update SOAP draft:', updateError);
      return new Response(
        JSON.stringify({
          error: 'Failed to save SOAP draft patch',
          code: 'UPDATE_FAILED',
          status: 500,
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[soap-draft-patch] ✅ SOAP draft patched successfully (${operationsApplied} ops, rev ${newServerRevision})`);

    return new Response(
      JSON.stringify({
        ok: true,
        server_revision: newServerRevision,
        updated_at: updatedDraft.meta.updated_at,
        conflict: false,
        operations_applied: operationsApplied,
        status: 200,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('[soap-draft-patch] Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        code: 'INTERNAL_ERROR',
        status: 500,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

// Helper Functions

/**
 * Set a value at a JSONPath (e.g., "$.tab3_cc.chief_complaint_patient_words")
 * Creates intermediate objects as needed
 */
function setJsonPath(obj: any, path: string, value: any) {
  const keys = path.replace(/^\$\./, '').split('.');
  let current = obj;

  // Navigate/create path to parent
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) {
      current[keys[i]] = {};
    }
    current = current[keys[i]];
  }

  // Set final value
  current[keys[keys.length - 1]] = value;
}

/**
 * Append a value to an array at a JSONPath
 * Creates array if it doesn't exist
 */
function appendJsonPath(obj: any, path: string, value: any) {
  const keys = path.replace(/^\$\./, '').split('.');
  let current = obj;

  // Navigate/create path to target
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (i === keys.length - 1) {
      // Last key - append to array
      if (!current[key]) {
        current[key] = [];
      }
      if (Array.isArray(current[key])) {
        current[key].push(value);
      }
    } else {
      // Intermediate key
      if (!current[key]) {
        current[key] = {};
      }
      current = current[key];
    }
  }
}

/**
 * Remove a value from an object or array at a JSONPath
 */
function removeJsonPath(obj: any, path: string) {
  const keys = path.replace(/^\$\./, '').split('.');
  let current = obj;

  // Navigate to parent
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) {
      return; // Path doesn't exist
    }
    current = current[keys[i]];
  }

  // Remove final key
  const lastKey = keys[keys.length - 1];
  if (Array.isArray(current)) {
    const index = parseInt(lastKey);
    if (!isNaN(index) && index >= 0 && index < current.length) {
      current.splice(index, 1);
    }
  } else if (typeof current === 'object' && lastKey in current) {
    delete current[lastKey];
  }
}
