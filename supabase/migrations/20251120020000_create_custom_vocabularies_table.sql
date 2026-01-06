-- Migration: Create custom_vocabularies table
-- Purpose: Manage AWS Transcribe custom vocabularies for medical terms and regional languages
-- Created: 2025-11-20

-- Create custom_vocabularies table
CREATE TABLE IF NOT EXISTS custom_vocabularies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Vocabulary identification
  name VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Language configuration
  language_code VARCHAR(10) NOT NULL, -- e.g., en-US, pcm (Pidgin), camfrang (Camfranglais)
  language_name VARCHAR(100) NOT NULL,

  -- Vocabulary content
  phrases JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Format: [{phrase: "BP", sounds_like: "", ipa: "", display_as: "blood pressure"}]

  -- AWS Transcribe integration
  aws_vocabulary_name VARCHAR(255), -- AWS-generated name (max 200 chars)
  vocabulary_status VARCHAR(20) DEFAULT 'pending', -- pending, processing, ready, failed
  aws_vocabulary_arn VARCHAR(500),
  last_modified_by_aws TIMESTAMPTZ,
  failure_reason TEXT,

  -- Metadata
  vocabulary_type VARCHAR(50) DEFAULT 'medical', -- medical, general, regional, mixed
  specialty VARCHAR(100), -- e.g., cardiology, pediatrics, general_practice
  region VARCHAR(100), -- e.g., West Africa, East Africa, Southern Africa

  -- Usage tracking
  times_used INT DEFAULT 0,
  last_used_at TIMESTAMPTZ,

  -- Versioning
  version INT DEFAULT 1,
  parent_vocabulary_id UUID REFERENCES custom_vocabularies(id) ON DELETE SET NULL,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Add comments for documentation
COMMENT ON TABLE custom_vocabularies IS 'AWS Transcribe custom vocabularies for medical terms and regional language support';
COMMENT ON COLUMN custom_vocabularies.name IS 'Internal unique name (slug format, e.g., pidgin-medical-terms-v1)';
COMMENT ON COLUMN custom_vocabularies.display_name IS 'User-friendly display name (e.g., "Pidgin English Medical Terms")';
COMMENT ON COLUMN custom_vocabularies.language_code IS 'Language code matching AWS Transcribe or custom codes (pcm, camfrang)';
COMMENT ON COLUMN custom_vocabularies.phrases IS 'Array of vocabulary phrases with pronunciation guidance: [{phrase, sounds_like, ipa, display_as}]';
COMMENT ON COLUMN custom_vocabularies.aws_vocabulary_name IS 'Name registered with AWS Transcribe (auto-generated, max 200 chars)';
COMMENT ON COLUMN custom_vocabularies.vocabulary_status IS 'AWS processing status: pending, processing, ready, failed';
COMMENT ON COLUMN custom_vocabularies.vocabulary_type IS 'Category: medical, general, regional, mixed';
COMMENT ON COLUMN custom_vocabularies.specialty IS 'Medical specialty if applicable (cardiology, pediatrics, etc.)';
COMMENT ON COLUMN custom_vocabularies.region IS 'Geographic region for regional languages (West Africa, East Africa, etc.)';
COMMENT ON COLUMN custom_vocabularies.times_used IS 'Usage counter for analytics';
COMMENT ON COLUMN custom_vocabularies.parent_vocabulary_id IS 'Parent vocabulary for versioning (null for base version)';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_custom_vocabularies_language_code
ON custom_vocabularies(language_code);

CREATE INDEX IF NOT EXISTS idx_custom_vocabularies_status
ON custom_vocabularies(vocabulary_status);

CREATE INDEX IF NOT EXISTS idx_custom_vocabularies_type
ON custom_vocabularies(vocabulary_type);

CREATE INDEX IF NOT EXISTS idx_custom_vocabularies_aws_name
ON custom_vocabularies(aws_vocabulary_name);

-- Create index for JSONB phrases
CREATE INDEX IF NOT EXISTS idx_custom_vocabularies_phrases
ON custom_vocabularies USING GIN(phrases);

-- Create index for usage tracking
CREATE INDEX IF NOT EXISTS idx_custom_vocabularies_last_used
ON custom_vocabularies(last_used_at DESC);

-- Create function to increment usage counter
CREATE OR REPLACE FUNCTION increment_vocabulary_usage(vocab_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE custom_vocabularies
  SET
    times_used = times_used + 1,
    last_used_at = NOW()
  WHERE id = vocab_id;
END;
$$;

COMMENT ON FUNCTION increment_vocabulary_usage IS 'Increment usage counter when vocabulary is used in transcription';

-- Create function to get vocabulary by language
CREATE OR REPLACE FUNCTION get_vocabulary_for_language(p_language_code VARCHAR)
RETURNS custom_vocabularies
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  vocab custom_vocabularies;
BEGIN
  -- Get the most recently used ready vocabulary for the language
  SELECT * INTO vocab
  FROM custom_vocabularies
  WHERE language_code = p_language_code
    AND vocabulary_status = 'ready'
  ORDER BY times_used DESC, last_used_at DESC NULLS LAST, created_at DESC
  LIMIT 1;

  RETURN vocab;
END;
$$;

COMMENT ON FUNCTION get_vocabulary_for_language IS 'Get the best available vocabulary for a given language code';

-- Create function to format phrases for AWS Transcribe
CREATE OR REPLACE FUNCTION format_vocabulary_for_aws(vocab_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  vocab_text TEXT;
BEGIN
  -- Format phrases as tab-separated values: Phrase [TAB] IPA [TAB] SoundsLike [TAB] DisplayAs
  SELECT string_agg(
    CONCAT_WS(E'\t',
      phrase_data->>'phrase',
      COALESCE(phrase_data->>'ipa', ''),
      COALESCE(phrase_data->>'sounds_like', ''),
      COALESCE(phrase_data->>'display_as', '')
    ),
    E'\n'
  )
  INTO vocab_text
  FROM custom_vocabularies,
       jsonb_array_elements(phrases) as phrase_data
  WHERE id = vocab_id;

  -- Add header
  vocab_text := E'Phrase\tIPA\tSoundsLike\tDisplayAs\n' || vocab_text;

  RETURN vocab_text;
END;
$$;

COMMENT ON FUNCTION format_vocabulary_for_aws IS 'Format vocabulary phrases as AWS Transcribe-compatible TSV text';

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_custom_vocabularies_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER custom_vocabularies_updated_at
BEFORE UPDATE ON custom_vocabularies
FOR EACH ROW
EXECUTE FUNCTION update_custom_vocabularies_updated_at();

-- Create trigger to validate phrases JSONB structure
CREATE OR REPLACE FUNCTION validate_vocabulary_phrases()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  phrase_elem JSONB;
BEGIN
  -- Validate each phrase has required 'phrase' field
  FOR phrase_elem IN SELECT * FROM jsonb_array_elements(NEW.phrases)
  LOOP
    IF NOT (phrase_elem ? 'phrase') THEN
      RAISE EXCEPTION 'Each phrase must have a "phrase" field';
    END IF;

    -- Validate phrase length (AWS Transcribe limits)
    IF length(phrase_elem->>'phrase') > 256 THEN
      RAISE EXCEPTION 'Phrase length cannot exceed 256 characters';
    END IF;
  END LOOP;

  -- Validate total phrase count (AWS limit is 50,000)
  IF jsonb_array_length(NEW.phrases) > 50000 THEN
    RAISE EXCEPTION 'Vocabulary cannot contain more than 50,000 phrases';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_custom_vocabulary_phrases
BEFORE INSERT OR UPDATE OF phrases ON custom_vocabularies
FOR EACH ROW
EXECUTE FUNCTION validate_vocabulary_phrases();

COMMENT ON TRIGGER validate_custom_vocabulary_phrases ON custom_vocabularies IS 'Validate vocabulary phrases meet AWS Transcribe requirements';

-- Enable RLS
ALTER TABLE custom_vocabularies ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- All authenticated users can view ready vocabularies
CREATE POLICY "Authenticated users can view ready vocabularies"
ON custom_vocabularies
FOR SELECT
TO authenticated
USING (vocabulary_status = 'ready');

-- System admins can manage all vocabularies
CREATE POLICY "System admins can manage vocabularies"
ON custom_vocabularies
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = auth.uid()
  )
);

-- Service role has full access
CREATE POLICY "Service role has full access to vocabularies"
ON custom_vocabularies
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT SELECT ON custom_vocabularies TO authenticated;
GRANT ALL ON custom_vocabularies TO service_role;
GRANT EXECUTE ON FUNCTION increment_vocabulary_usage TO authenticated;
GRANT EXECUTE ON FUNCTION get_vocabulary_for_language TO authenticated;
GRANT EXECUTE ON FUNCTION format_vocabulary_for_aws TO service_role;

-- Seed default vocabularies
INSERT INTO custom_vocabularies (
  name,
  display_name,
  description,
  language_code,
  language_name,
  vocabulary_type,
  region,
  phrases,
  vocabulary_status
) VALUES
(
  'medical-abbreviations-english',
  'Medical Abbreviations (English)',
  'Common medical abbreviations and acronyms used in healthcare',
  'en-US',
  'English (United States)',
  'medical',
  'Global',
  '[
    {"phrase": "BP", "display_as": "blood pressure"},
    {"phrase": "HR", "display_as": "heart rate"},
    {"phrase": "IV", "display_as": "intravenous"},
    {"phrase": "IM", "display_as": "intramuscular"},
    {"phrase": "PO", "display_as": "by mouth"},
    {"phrase": "PRN", "display_as": "as needed"},
    {"phrase": "BID", "display_as": "twice daily"},
    {"phrase": "TID", "display_as": "three times daily"},
    {"phrase": "QID", "display_as": "four times daily"},
    {"phrase": "NPO", "display_as": "nothing by mouth"},
    {"phrase": "CBC", "display_as": "complete blood count"},
    {"phrase": "ECG", "display_as": "electrocardiogram"},
    {"phrase": "EKG", "display_as": "electrocardiogram"},
    {"phrase": "MRI", "display_as": "magnetic resonance imaging"},
    {"phrase": "CT", "display_as": "computed tomography"},
    {"phrase": "ICU", "display_as": "intensive care unit"},
    {"phrase": "ER", "display_as": "emergency room"},
    {"phrase": "OR", "display_as": "operating room"}
  ]'::jsonb,
  'ready'
),
(
  'pidgin-medical-basic',
  'Nigerian Pidgin Medical Terms (Basic)',
  'Common medical terms in Nigerian Pidgin English',
  'pcm',
  'Nigerian Pidgin',
  'regional',
  'West Africa',
  '[
    {"phrase": "wahala", "sounds_like": "wa-ha-la", "display_as": "problem"},
    {"phrase": "belle", "sounds_like": "bel-lay", "display_as": "stomach"},
    {"phrase": "head dey pain me", "display_as": "I have a headache"},
    {"phrase": "body dey hot", "display_as": "fever"},
    {"phrase": "dash", "display_as": "give"},
    {"phrase": "carry", "display_as": "take"},
    {"phrase": "chop", "display_as": "eat"},
    {"phrase": "drink", "display_as": "take medication"},
    {"phrase": "doctor", "sounds_like": "dok-ta", "display_as": "doctor"},
    {"phrase": "hospital", "sounds_like": "hos-pi-tal", "display_as": "hospital"}
  ]'::jsonb,
  'ready'
),
(
  'camfranglais-medical-basic',
  'Camfranglais Medical Terms (Basic)',
  'Medical terms in Camfranglais (Cameroon French-English creole)',
  'camfrang',
  'Camfranglais',
  'regional',
  'Central Africa',
  '[
    {"phrase": "le dos", "sounds_like": "luh doh", "display_as": "back pain"},
    {"phrase": "la tête", "sounds_like": "la tet", "display_as": "head"},
    {"phrase": "mal au ventre", "display_as": "stomach ache"},
    {"phrase": "fever-là", "display_as": "fever"},
    {"phrase": "hospital-là", "display_as": "hospital"},
    {"phrase": "docteur-là", "display_as": "doctor"},
    {"phrase": "medicament", "sounds_like": "med-i-ca-mon", "display_as": "medication"}
  ]'::jsonb,
  'ready'
)
ON CONFLICT (name) DO NOTHING;
