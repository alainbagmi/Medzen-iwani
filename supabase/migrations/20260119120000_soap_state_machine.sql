-- SOAP State Machine Schema Migration
-- Implements structured state tracking for encounters, transcriptions, and SOAP generation
-- Adds support for context snapshots, chunked transcription, and debounced autosave

-- Add state machine columns to video_call_sessions
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS encounter_status text DEFAULT 'scheduled' CHECK (encounter_status IN (
  'scheduled', 'precheck_open', 'ready_to_start', 'in_call', 'call_ending',
  'call_ended', 'soap_drafting', 'soap_ready', 'soap_editing',
  'soap_submitted', 'soap_signed', 'closed'
)),
ADD COLUMN IF NOT EXISTS transcription_status text DEFAULT 'disabled' CHECK (transcription_status IN (
  'disabled', 'starting', 'running', 'paused', 'stopping', 'completed', 'failed'
)),
ADD COLUMN IF NOT EXISTS soap_status text DEFAULT 'not_started' CHECK (soap_status IN (
  'not_started', 'drafting', 'draft_ready', 'editing', 'submitted', 'signed', 'failed'
)),
ADD COLUMN IF NOT EXISTS context_snapshot_id uuid,
ADD COLUMN IF NOT EXISTS soap_draft_json jsonb,
ADD COLUMN IF NOT EXISTS soap_final_json jsonb,
ADD COLUMN IF NOT EXISTS client_revision int DEFAULT 0,
ADD COLUMN IF NOT EXISTS server_revision int DEFAULT 0;

-- Create context_snapshots table for pre-call patient context
CREATE TABLE IF NOT EXISTS context_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  encounter_id uuid REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  snapshot_version int DEFAULT 1,
  patient_demographics jsonb NOT NULL,
  active_conditions jsonb,
  current_medications jsonb,
  allergies jsonb,
  recent_labs_vitals jsonb,
  recent_notes_summary text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(encounter_id)
);

-- Create call_transcript_chunks table for chunked transcript storage
CREATE TABLE IF NOT EXISTS call_transcript_chunks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  encounter_id uuid REFERENCES video_call_sessions(id) ON DELETE CASCADE NOT NULL,
  sequence int NOT NULL,
  start_ms bigint,
  end_ms bigint,
  speaker text,
  attendee_id uuid,
  text text NOT NULL,
  confidence float DEFAULT 1.0,
  language_code text DEFAULT 'en',
  created_at timestamptz DEFAULT now(),
  UNIQUE(encounter_id, sequence)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_context_snapshots_encounter
  ON context_snapshots(encounter_id);

CREATE INDEX IF NOT EXISTS idx_context_snapshots_created
  ON context_snapshots(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_transcript_chunks_encounter
  ON call_transcript_chunks(encounter_id, sequence);

CREATE INDEX IF NOT EXISTS idx_transcript_chunks_created
  ON call_transcript_chunks(encounter_id, created_at);

CREATE INDEX IF NOT EXISTS idx_video_sessions_encounter_status
  ON video_call_sessions(encounter_status);

CREATE INDEX IF NOT EXISTS idx_video_sessions_soap_status
  ON video_call_sessions(soap_status);

-- Enable RLS on new tables
ALTER TABLE context_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_transcript_chunks ENABLE ROW LEVEL SECURITY;

-- RLS Policy: context_snapshots - allow users to view snapshots for their own appointments/calls
CREATE POLICY context_snapshots_read ON context_snapshots
  FOR SELECT
  USING (
    encounter_id IN (
      SELECT id FROM video_call_sessions
      WHERE provider_id = auth.uid() OR patient_id = auth.uid()
    )
  );

CREATE POLICY context_snapshots_write ON context_snapshots
  FOR INSERT
  WITH CHECK (
    encounter_id IN (
      SELECT id FROM video_call_sessions
      WHERE provider_id = auth.uid()
    )
  );

-- RLS Policy: call_transcript_chunks - allow users to view/insert chunks for their calls
CREATE POLICY transcript_chunks_read ON call_transcript_chunks
  FOR SELECT
  USING (
    encounter_id IN (
      SELECT id FROM video_call_sessions
      WHERE provider_id = auth.uid() OR patient_id = auth.uid()
    )
  );

CREATE POLICY transcript_chunks_insert ON call_transcript_chunks
  FOR INSERT
  WITH CHECK (
    encounter_id IN (
      SELECT id FROM video_call_sessions
      WHERE provider_id = auth.uid() OR patient_id = auth.uid()
    )
  );

-- Grant permissions to edge functions (using service role)
GRANT SELECT, INSERT, UPDATE ON context_snapshots TO service_role;
GRANT SELECT, INSERT, UPDATE ON call_transcript_chunks TO service_role;
GRANT SELECT, UPDATE ON video_call_sessions TO service_role;

-- Add foreign key constraint for context_snapshot_id
ALTER TABLE video_call_sessions
ADD CONSTRAINT fk_context_snapshot
  FOREIGN KEY (context_snapshot_id)
  REFERENCES context_snapshots(id)
  ON DELETE SET NULL;
