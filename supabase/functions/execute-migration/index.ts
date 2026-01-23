import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  const sql = `
    CREATE TABLE IF NOT EXISTS facility_generated_documents (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE NOT NULL,
      document_type VARCHAR(100) NOT NULL,
      template_path TEXT NOT NULL,
      title VARCHAR(255) NOT NULL,
      file_path TEXT,
      file_size BIGINT,
      version INTEGER DEFAULT 1 NOT NULL,
      status VARCHAR(50) DEFAULT 'draft',
      ai_prefill_data JSONB,
      ai_confidence_score DECIMAL(3,2),
      ai_flags JSONB,
      generated_by UUID REFERENCES users(id) NOT NULL,
      generated_at TIMESTAMPTZ DEFAULT NOW(),
      confirmed_by UUID REFERENCES users(id),
      confirmed_at TIMESTAMPTZ,
      confirmation_notes TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_facility ON facility_generated_documents(facility_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_status ON facility_generated_documents(status);
    CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_type_date ON facility_generated_documents(document_type, created_at DESC) WHERE status != 'draft';
    CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_facility_document_draft ON facility_generated_documents(facility_id, document_type, DATE(created_at)) WHERE status IN ('draft', 'preview');

    ALTER TABLE facility_generated_documents ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Facility admins view own documents" ON facility_generated_documents;
    DROP POLICY IF EXISTS "Facility admins update own documents" ON facility_generated_documents;
    DROP POLICY IF EXISTS "Service role can manage documents" ON facility_generated_documents;

    CREATE POLICY "Facility admins view own documents" ON facility_generated_documents FOR SELECT TO authenticated USING (
      facility_id IN (
        SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
        UNION
        SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
      )
    );

    CREATE POLICY "Facility admins update own documents" ON facility_generated_documents FOR UPDATE TO authenticated USING (
      facility_id IN (
        SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
        UNION
        SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
      )
    );

    CREATE POLICY "Service role can manage documents" ON facility_generated_documents FOR ALL TO service_role USING (true);

    DROP TRIGGER IF EXISTS update_facility_generated_documents_updated_at ON facility_generated_documents;
    CREATE TRIGGER update_facility_generated_documents_updated_at BEFORE UPDATE ON facility_generated_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    GRANT SELECT ON facility_generated_documents TO authenticated;
    GRANT UPDATE ON facility_generated_documents TO authenticated;
    GRANT SELECT, INSERT, UPDATE ON facility_generated_documents TO service_role;
  `;

  try {
    const { error } = await supabase.rpc('execute_sql', { sql_text: sql });

    if (error) {
      console.error('Migration error:', error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } });
    }

    return new Response(JSON.stringify({ success: true, message: 'Migration applied' }), { status: 200, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } });
  } catch (err) {
    console.error('Exception:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } });
  }
});
