-- Migration: Enable Realtime for Call Notifications and Chat
-- Created: 2026-01-02
-- Purpose: Enable Supabase Realtime replication for video call notifications and chat messages

-- ============================================================================
-- PART 1: Enable Realtime Replication
-- ============================================================================

-- Enable realtime for call_notifications table (if it exists)
DO $$
BEGIN
    -- Check if call_notifications exists before adding to publication
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'call_notifications' AND table_schema = 'public') THEN
        -- Add to realtime publication
        ALTER PUBLICATION supabase_realtime ADD TABLE public.call_notifications;
        RAISE NOTICE 'Added call_notifications to supabase_realtime publication';
    ELSE
        RAISE NOTICE 'call_notifications table does not exist, skipping';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'call_notifications already in publication';
END $$;

-- Enable realtime for chime_messages table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chime_messages' AND table_schema = 'public') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chime_messages;
        RAISE NOTICE 'Added chime_messages to supabase_realtime publication';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'chime_messages already in publication';
END $$;

-- Enable realtime for consultation_note_drafts if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consultation_note_drafts' AND table_schema = 'public') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.consultation_note_drafts;
        RAISE NOTICE 'Added consultation_note_drafts to supabase_realtime publication';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'consultation_note_drafts already in publication';
END $$;

-- ============================================================================
-- PART 2: Create call_notifications table if not exists
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.call_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL DEFAULT 'call_started',
    title VARCHAR(255),
    body TEXT,
    payload JSONB DEFAULT '{}'::jsonb,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_call_notifications_recipient
ON public.call_notifications(recipient_id);

CREATE INDEX IF NOT EXISTS idx_call_notifications_unread
ON public.call_notifications(recipient_id)
WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_call_notifications_created
ON public.call_notifications(created_at DESC);

-- Enable RLS on call_notifications
ALTER TABLE public.call_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for call_notifications
-- Users can view their own notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.call_notifications;
CREATE POLICY "Users can view own notifications"
ON public.call_notifications FOR SELECT
USING (
    auth.uid() IS NULL  -- Allow Firebase auth pattern
    OR recipient_id = auth.uid()
);

-- System can insert notifications
DROP POLICY IF EXISTS "System can insert notifications" ON public.call_notifications;
CREATE POLICY "System can insert notifications"
ON public.call_notifications FOR INSERT
WITH CHECK (true);

-- Users can update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update own notifications" ON public.call_notifications;
CREATE POLICY "Users can update own notifications"
ON public.call_notifications FOR UPDATE
USING (
    auth.uid() IS NULL
    OR recipient_id = auth.uid()
);

-- ============================================================================
-- PART 3: Add session_id to consultation_note_drafts if table exists
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consultation_note_drafts' AND table_schema = 'public') THEN
        -- Check if session_id column exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                      WHERE table_name = 'consultation_note_drafts'
                      AND column_name = 'session_id'
                      AND table_schema = 'public') THEN
            ALTER TABLE public.consultation_note_drafts
            ADD COLUMN session_id UUID REFERENCES public.video_call_sessions(id);
            RAISE NOTICE 'Added session_id column to consultation_note_drafts';
        END IF;
    END IF;
END $$;

-- ============================================================================
-- PART 4: Ensure chime_messages has file attachment columns
-- ============================================================================

DO $$
BEGIN
    -- Add file_url column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_name = 'chime_messages'
                  AND column_name = 'file_url'
                  AND table_schema = 'public') THEN
        ALTER TABLE public.chime_messages ADD COLUMN file_url TEXT;
        RAISE NOTICE 'Added file_url column to chime_messages';
    END IF;

    -- Add file_name column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_name = 'chime_messages'
                  AND column_name = 'file_name'
                  AND table_schema = 'public') THEN
        ALTER TABLE public.chime_messages ADD COLUMN file_name VARCHAR(255);
        RAISE NOTICE 'Added file_name column to chime_messages';
    END IF;

    -- Add file_type column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_name = 'chime_messages'
                  AND column_name = 'file_type'
                  AND table_schema = 'public') THEN
        ALTER TABLE public.chime_messages ADD COLUMN file_type VARCHAR(100);
        RAISE NOTICE 'Added file_type column to chime_messages';
    END IF;
END $$;

-- ============================================================================
-- PART 5: Create call_attachments storage bucket (if it doesn't exist)
-- Note: This needs to be done via Supabase dashboard or CLI, but we document it here
-- ============================================================================

-- The call_attachments bucket should be created with the following settings:
-- - Public: false (requires signed URLs)
-- - Allowed MIME types: image/*, application/pdf, application/msword,
--   application/vnd.openxmlformats-officedocument.wordprocessingml.document, text/plain
-- - Max file size: 10MB

-- RLS for storage.objects (if managing via SQL)
-- These policies should be applied in the Supabase dashboard

-- ============================================================================
-- PART 6: Add trigger to update updated_at on call_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION update_notification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_notification_updated_at ON public.call_notifications;
CREATE TRIGGER trigger_update_notification_updated_at
    BEFORE UPDATE ON public.call_notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_notification_updated_at();

-- ============================================================================
-- PART 7: Grant permissions
-- ============================================================================

GRANT ALL ON public.call_notifications TO authenticated;
GRANT ALL ON public.call_notifications TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.call_notifications TO anon;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Migration 20260102100000_enable_realtime_for_notifications completed successfully';
END $$;
