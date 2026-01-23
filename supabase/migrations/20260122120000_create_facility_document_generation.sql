-- Facility Document Generation System
-- Tracks AI-prefilled facility documents with versioning
-- Storage: MiniSanteTemplate (templates) → AI fill → User confirms → Save to facility storage

-- Create facility_generated_documents table
CREATE TABLE IF NOT EXISTS facility_generated_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Facility reference
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE NOT NULL,

  -- Document info
  document_type VARCHAR(100) NOT NULL, -- 'rma_ii_report', 'staff_roster', etc.
  template_path TEXT NOT NULL, -- Path in MiniSanteTemplate bucket (e.g., 'RMA II 31 01 2024 ANGLAIS.pdf')
  title VARCHAR(255) NOT NULL, -- Display title

  -- Document file (user-confirmed, ready for download/print)
  file_path TEXT, -- Path in user's storage (set after user confirms)
  file_size BIGINT,

  -- Versioning
  version INTEGER DEFAULT 1 NOT NULL,
  status VARCHAR(50) DEFAULT 'draft', -- draft/preview/confirmed/saved

  -- AI generation metadata
  ai_prefill_data JSONB, -- Data that AI used to prefill (facility data snapshot)
  ai_confidence_score DECIMAL(3,2), -- 0.0 to 1.0
  ai_flags JSONB, -- Missing or low-confidence fields

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
CREATE INDEX idx_facility_generated_documents_facility
  ON facility_generated_documents(facility_id, created_at DESC);

CREATE INDEX idx_facility_generated_documents_status
  ON facility_generated_documents(status);

-- Index for draft document lookup (uniqueness enforced by application logic)
CREATE INDEX idx_facility_document_draft_lookup
  ON facility_generated_documents(facility_id, document_type)
  WHERE status IN ('draft', 'preview');

-- RLS: Facility admins can view their facility's documents
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

-- RLS: Facility admins can update (confirm/save) their facility's documents
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

-- RLS: Service role can insert and update (for edge functions)
CREATE POLICY "Service role can manage documents"
ON facility_generated_documents FOR ALL
TO service_role
USING (true);

-- Auto-update timestamp
CREATE TRIGGER update_facility_generated_documents_updated_at
BEFORE UPDATE ON facility_generated_documents
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant table access
GRANT SELECT ON facility_generated_documents TO authenticated;
GRANT UPDATE ON facility_generated_documents TO authenticated;
GRANT SELECT, INSERT, UPDATE ON facility_generated_documents TO service_role;

-- Create index for improved query performance
CREATE INDEX idx_facility_generated_documents_type_date
  ON facility_generated_documents(document_type, created_at DESC)
  WHERE status != 'draft';
