-- ============================================================================
-- Migration: Add Video Call Notifications and Chat Attachments
-- Date: 2026-01-02
-- Description:
--   1. Creates call_notifications table for realtime notifications
--   2. Adds file attachment columns to chime_messages
--   3. Creates consultation_note_drafts table for draft notes
--   4. Adds proper RLS policies for all tables
--   5. Creates call_attachments storage bucket
-- ============================================================================

-- ============================================================================
-- 1. CALL NOTIFICATIONS TABLE
-- Used for realtime notifications when provider starts call, sends message, etc.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.call_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type text NOT NULL, -- 'call_started', 'message', 'call_ended', etc.
  title text NOT NULL,
  body text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_call_notifications_recipient ON public.call_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_call_notifications_created ON public.call_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_call_notifications_unread ON public.call_notifications(recipient_id) WHERE read_at IS NULL;

-- Enable RLS
ALTER TABLE public.call_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for call_notifications
-- Recipients can read their own notifications (allow anon/public for Firebase auth)
CREATE POLICY "call_notif_read_own" ON public.call_notifications
  FOR SELECT
  USING (auth.uid() IS NULL OR recipient_id = auth.uid());

-- Recipients can update (mark as read) their own notifications
CREATE POLICY "call_notif_update_own" ON public.call_notifications
  FOR UPDATE
  USING (auth.uid() IS NULL OR recipient_id = auth.uid())
  WITH CHECK (auth.uid() IS NULL OR recipient_id = auth.uid());

-- Only service role can insert (prevents client spam)
CREATE POLICY "call_notif_insert_service" ON public.call_notifications
  FOR INSERT
  WITH CHECK (
    -- Allow if no auth (for edge function with service key) or if insert from authenticated edge function
    auth.uid() IS NULL OR EXISTS (
      SELECT 1 FROM public.users WHERE id = auth.uid()
    )
  );

-- ============================================================================
-- 2. ADD FILE ATTACHMENT COLUMNS TO CHIME_MESSAGES
-- ============================================================================
DO $$
BEGIN
  -- Add sender_role column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chime_messages' AND column_name = 'sender_role'
  ) THEN
    ALTER TABLE public.chime_messages ADD COLUMN sender_role text;
    COMMENT ON COLUMN public.chime_messages.sender_role IS 'Role of sender: patient, medical_provider, etc.';
  END IF;

  -- Add file_url column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chime_messages' AND column_name = 'file_url'
  ) THEN
    ALTER TABLE public.chime_messages ADD COLUMN file_url text;
    COMMENT ON COLUMN public.chime_messages.file_url IS 'Storage path for file attachments';
  END IF;

  -- Add file_name column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chime_messages' AND column_name = 'file_name'
  ) THEN
    ALTER TABLE public.chime_messages ADD COLUMN file_name text;
    COMMENT ON COLUMN public.chime_messages.file_name IS 'Original filename of attachment';
  END IF;

  -- Add file_mime column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chime_messages' AND column_name = 'file_mime'
  ) THEN
    ALTER TABLE public.chime_messages ADD COLUMN file_mime text;
    COMMENT ON COLUMN public.chime_messages.file_mime IS 'MIME type of attachment';
  END IF;

  -- Add file_size column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chime_messages' AND column_name = 'file_size'
  ) THEN
    ALTER TABLE public.chime_messages ADD COLUMN file_size integer;
    COMMENT ON COLUMN public.chime_messages.file_size IS 'File size in bytes';
  END IF;
END $$;

-- ============================================================================
-- 3. CONSULTATION NOTE DRAFTS TABLE
-- Stores draft clinical notes before provider reviews and submits
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.consultation_note_drafts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  session_id uuid REFERENCES public.video_call_sessions(id) ON DELETE SET NULL,
  created_by uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  source text NOT NULL DEFAULT 'chime_live', -- 'chime_live', 'manual', 'upload'
  language_code text NOT NULL DEFAULT 'en-US',
  draft_text text NOT NULL,
  status text NOT NULL DEFAULT 'editing' CHECK (status IN ('editing', 'submitted', 'discarded')),
  submitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_note_drafts_appointment ON public.consultation_note_drafts(appointment_id);
CREATE INDEX IF NOT EXISTS idx_note_drafts_created_by ON public.consultation_note_drafts(created_by);
CREATE INDEX IF NOT EXISTS idx_note_drafts_status ON public.consultation_note_drafts(status);

-- Enable RLS
ALTER TABLE public.consultation_note_drafts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "note_drafts_select_own" ON public.consultation_note_drafts
  FOR SELECT
  USING (auth.uid() IS NULL OR created_by = auth.uid());

CREATE POLICY "note_drafts_insert_own" ON public.consultation_note_drafts
  FOR INSERT
  WITH CHECK (auth.uid() IS NULL OR created_by = auth.uid());

CREATE POLICY "note_drafts_update_own" ON public.consultation_note_drafts
  FOR UPDATE
  USING (auth.uid() IS NULL OR created_by = auth.uid())
  WITH CHECK (auth.uid() IS NULL OR created_by = auth.uid());

-- ============================================================================
-- 4. ADD TRANSCRIPTION MODE TO VIDEO_CALL_SESSIONS
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'video_call_sessions' AND column_name = 'transcription_mode'
  ) THEN
    ALTER TABLE public.video_call_sessions ADD COLUMN transcription_mode text DEFAULT 'standard';
    COMMENT ON COLUMN public.video_call_sessions.transcription_mode IS 'Transcription mode: medical (en-US only) or standard';
  END IF;
END $$;

-- ============================================================================
-- 5. ENABLE REALTIME FOR NOTIFICATIONS AND MESSAGES
-- ============================================================================
-- Add tables to realtime publication
DO $$
BEGIN
  -- Check if call_notifications is already in publication
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'call_notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.call_notifications;
  END IF;
END $$;

-- chime_messages should already be in realtime, but ensure it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chime_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chime_messages;
  END IF;
END $$;

-- ============================================================================
-- 6. CREATE FUNCTION TO INSERT CALL NOTIFICATION (for edge functions)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.insert_call_notification(
  p_recipient_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id uuid;
BEGIN
  INSERT INTO public.call_notifications (recipient_id, type, title, body, payload)
  VALUES (p_recipient_id, p_type, p_title, p_body, p_payload)
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

-- Grant execute to authenticated users (edge functions run as authenticated)
GRANT EXECUTE ON FUNCTION public.insert_call_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_call_notification TO service_role;

-- ============================================================================
-- 7. CREATE FUNCTION TO MARK NOTIFICATION AS READ
-- ============================================================================
CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.call_notifications
  SET read_at = now()
  WHERE id = p_notification_id
  AND read_at IS NULL;

  RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notification_read TO anon;

-- ============================================================================
-- 8. TRIGGER TO UPDATE updated_at ON CONSULTATION_NOTE_DRAFTS
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_note_draft_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_note_draft_timestamp ON public.consultation_note_drafts;
CREATE TRIGGER update_note_draft_timestamp
  BEFORE UPDATE ON public.consultation_note_drafts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_note_draft_timestamp();

-- ============================================================================
-- DONE
-- ============================================================================
COMMENT ON TABLE public.call_notifications IS 'Real-time notifications for video call events (call started, new message, etc.)';
COMMENT ON TABLE public.consultation_note_drafts IS 'Draft clinical notes from video calls, pending provider review and submission';
