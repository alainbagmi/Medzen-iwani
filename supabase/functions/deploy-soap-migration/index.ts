import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { corsHeaders } from '../_shared/cors.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

export default async (req: Request): Promise<Response> => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

  const migrationSQL = `
CREATE TABLE IF NOT EXISTS soap_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  call_transcript_id UUID REFERENCES call_transcripts(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'draft',
  chief_complaint TEXT,
  subjective JSONB,
  objective JSONB,
  assessment JSONB,
  plan JSONB,
  safety JSONB,
  ai_generated_at TIMESTAMPTZ,
  ai_model_used VARCHAR(255),
  ai_raw_json JSONB,
  ai_generation_prompt_version VARCHAR(50),
  requires_clinician_review BOOLEAN DEFAULT true,
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  submitted_at TIMESTAMPTZ
);

COMMENT ON TABLE soap_notes IS 'Stores AI-generated SOAP note drafts from video call transcripts, ready for clinician review and submission';

CREATE INDEX IF NOT EXISTS idx_soap_notes_session_id ON soap_notes(session_id);
CREATE INDEX IF NOT EXISTS idx_soap_notes_appointment_id ON soap_notes(appointment_id);
CREATE INDEX IF NOT EXISTS idx_soap_notes_status ON soap_notes(status);
CREATE INDEX IF NOT EXISTS idx_soap_notes_created_at ON soap_notes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_soap_notes_reviewed_by ON soap_notes(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_soap_notes_session_status ON soap_notes(session_id, status);
CREATE INDEX IF NOT EXISTS idx_soap_notes_appointment_status ON soap_notes(appointment_id, status);

ALTER TABLE soap_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "soap_notes_select_access" ON soap_notes;
DROP POLICY IF EXISTS "soap_notes_insert_access" ON soap_notes;
DROP POLICY IF EXISTS "soap_notes_update_access" ON soap_notes;

CREATE POLICY "soap_notes_select_access" ON soap_notes
FOR SELECT USING (
  auth.uid() IS NULL OR
  session_id IN (
    SELECT id FROM video_call_sessions
    WHERE provider_id = auth.uid() OR patient_id = auth.uid()
  )
);

CREATE POLICY "soap_notes_insert_access" ON soap_notes
FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "soap_notes_update_access" ON soap_notes
FOR UPDATE USING (
  auth.role() = 'service_role' OR
  (requires_clinician_review = true AND reviewed_by = auth.uid())
);

GRANT SELECT ON soap_notes TO anon;
GRANT SELECT ON soap_notes TO authenticated;
GRANT ALL ON soap_notes TO service_role;
  `;

  try {
    console.log('[Deploy SOAP Migration] Starting migration...');
    
    // Execute the SQL using Supabase's SQL execution capability
    const { error } = await supabase.rpc('exec_sql', { sql: migrationSQL });
    
    if (error) {
      console.error('[Deploy SOAP Migration] RPC error:', error);
      
      // If exec_sql doesn't exist, try a different approach - create the table directly
      // using individual Supabase operations
      console.log('[Deploy SOAP Migration] Falling back to direct table creation...');
      
      // Create the table using direct API
      const createTableSQL = `
        CREATE TABLE IF NOT EXISTS public.soap_notes (
          id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          session_id uuid NOT NULL,
          appointment_id uuid NOT NULL,
          call_transcript_id uuid,
          status varchar(50) DEFAULT 'draft',
          chief_complaint text,
          subjective jsonb,
          objective jsonb,
          assessment jsonb,
          plan jsonb,
          safety jsonb,
          ai_generated_at timestamptz,
          ai_model_used varchar(255),
          ai_raw_json jsonb,
          ai_generation_prompt_version varchar(50),
          requires_clinician_review boolean DEFAULT true,
          reviewed_by uuid,
          reviewed_at timestamptz,
          review_notes text,
          created_at timestamptz DEFAULT now(),
          updated_at timestamptz DEFAULT now(),
          submitted_at timestamptz,
          CONSTRAINT fk_session_id FOREIGN KEY (session_id) REFERENCES public.video_call_sessions(id) ON DELETE CASCADE,
          CONSTRAINT fk_appointment_id FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE,
          CONSTRAINT fk_call_transcript_id FOREIGN KEY (call_transcript_id) REFERENCES public.call_transcripts(id) ON DELETE SET NULL,
          CONSTRAINT fk_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL
        );
      `;
      
      // This would fail silently if table already exists, which is fine
      console.log('[Deploy SOAP Migration] Could not use RPC - table should be created via standard migration');
      
      return new Response(
        JSON.stringify({
          success: false,
          message: 'exec_sql RPC not available. Please deploy this migration via: npx supabase db push',
          details: {
            migration: 'supabase/migrations/20260115200000_create_soap_notes_table.sql',
            instruction: 'Run: npx supabase db push --password <your_db_password>',
            fallback: 'This function requires database password for CLI deployment'
          }
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }
    
    console.log('[Deploy SOAP Migration] Migration completed successfully');
    
    return new Response(
      JSON.stringify({
        success: true,
        message: 'SOAP notes table created successfully',
        timestamp: new Date().toISOString()
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  } catch (error) {
    console.error('[Deploy SOAP Migration] Error:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
};
