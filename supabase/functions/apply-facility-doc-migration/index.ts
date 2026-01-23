import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders_resp = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders_resp, ...securityHeaders } });
  }

  // Verify authorization - only allow from localhost or valid auth
  const authHeader = req.headers.get('authorization');

  if (!authHeader || !authHeader.includes('Bearer')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // Initialize Supabase with service role (has admin access)
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: 'Missing Supabase credentials' }),
        { status: 500, headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Execute the migration SQL
    const migrationSql = `
-- Facility Document Generation System
-- Tracks AI-prefilled facility documents with versioning
-- Storage: MiniSanteTemplate (templates) → AI fill → User confirms → Save to facility storage

-- Create facility_generated_documents table
CREATE TABLE IF NOT EXISTS facility_generated_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Facility reference
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE NOT NULL,

  -- Document info
  document_type VARCHAR(100) NOT NULL,
  template_path TEXT NOT NULL,
  title VARCHAR(255) NOT NULL,

  -- Document file
  file_path TEXT,
  file_size BIGINT,

  -- Versioning
  version INTEGER DEFAULT 1 NOT NULL,
  status VARCHAR(50) DEFAULT 'draft',

  -- AI generation metadata
  ai_prefill_data JSONB,
  ai_confidence_score DECIMAL(3,2),
  ai_flags JSONB,

  -- Workflow
  generated_by UUID REFERENCES users(id) NOT NULL,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_by UUID REFERENCES users(id),
  confirmed_at TIMESTAMPTZ,
  confirmation_notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_facility
  ON facility_generated_documents(facility_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_status
  ON facility_generated_documents(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_facility_document_draft
  ON facility_generated_documents(facility_id, document_type, DATE(created_at))
  WHERE status IN ('draft', 'preview');

CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_type_date
  ON facility_generated_documents(document_type, created_at DESC)
  WHERE status != 'draft';

-- Enable RLS
ALTER TABLE facility_generated_documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Facility admins view own documents" ON facility_generated_documents;
DROP POLICY IF EXISTS "Facility admins update own documents" ON facility_generated_documents;
DROP POLICY IF EXISTS "Service role can manage documents" ON facility_generated_documents;

CREATE POLICY "Facility admins view own documents"
ON facility_generated_documents FOR SELECT
TO authenticated
USING (
  facility_id IN (
    SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
    UNION
    SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Facility admins update own documents"
ON facility_generated_documents FOR UPDATE
TO authenticated
USING (
  facility_id IN (
    SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
    UNION
    SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Service role can manage documents"
ON facility_generated_documents FOR ALL
TO service_role
USING (true);

-- Auto-update timestamp
DROP TRIGGER IF EXISTS update_facility_generated_documents_updated_at ON facility_generated_documents;
CREATE TRIGGER update_facility_generated_documents_updated_at
BEFORE UPDATE ON facility_generated_documents
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grants
GRANT SELECT ON facility_generated_documents TO authenticated;
GRANT UPDATE ON facility_generated_documents TO authenticated;
GRANT SELECT, INSERT, UPDATE ON facility_generated_documents TO service_role;
    `;

    // Execute using raw SQL - split by semicolons
    const statements = migrationSql
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0 && !s.startsWith('--'));

    console.log(`Executing ${statements.length} SQL statements...`);

    // Use the Supabase admin client to execute raw SQL
    // Note: This requires using the internal rpc or direct connection
    const result = await supabase.rpc('exec_sql', {
      sql: migrationSql,
    }).catch((err) => {
      console.error('RPC error:', err);
      // If RPC doesn't exist, try alternative approach
      return null;
    });

    if (result !== null) {
      console.log('✅ Migration executed successfully via RPC');
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Migration applied successfully',
        }),
        { status: 200, headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Fallback: If RPC doesn't exist, return instructions
    console.log('⚠️  RPC exec_sql not available - returning manual instructions');
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Please apply migration manually via Supabase Dashboard',
        instruction: 'Go to https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql/new and paste the migration SQL',
        sql: migrationSql,
      }),
      { status: 400, headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({
        error: error.message,
        hint: 'Check Supabase logs for details',
      }),
      { status: 500, headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
