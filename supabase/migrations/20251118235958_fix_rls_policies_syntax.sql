-- Migration: Fix RLS policy creation syntax
-- Purpose: PostgreSQL doesn't support IF NOT EXISTS for policies before v15
-- Fixes: Syntax error blocking 20251119000000_seed_ai_assistants.sql
-- Date: 2025-11-27

-- Drop existing policies if they exist (safe approach)
DROP POLICY IF EXISTS "ai_assistants_select_all" ON ai_assistants;
DROP POLICY IF EXISTS "ai_conversations_select_own" ON ai_conversations;
DROP POLICY IF EXISTS "ai_conversations_insert_own" ON ai_conversations;
DROP POLICY IF EXISTS "ai_conversations_update_own" ON ai_conversations;
DROP POLICY IF EXISTS "ai_messages_select_own" ON ai_messages;
DROP POLICY IF EXISTS "ai_messages_insert_own" ON ai_messages;
DROP POLICY IF EXISTS "ai_messages_update_own" ON ai_messages;

-- Ensure RLS is enabled
ALTER TABLE ai_assistants ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- Create policies for ai_assistants (public read)
CREATE POLICY "ai_assistants_select_all" ON ai_assistants
    FOR SELECT USING (true);

-- Create policies for ai_conversations (UUID comparisons without text casting)
CREATE POLICY "ai_conversations_select_own" ON ai_conversations
    FOR SELECT USING (
        user_id = auth.uid() OR
        patient_id = auth.uid()
    );

CREATE POLICY "ai_conversations_insert_own" ON ai_conversations
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR
        patient_id = auth.uid()
    );

CREATE POLICY "ai_conversations_update_own" ON ai_conversations
    FOR UPDATE USING (
        user_id = auth.uid() OR
        patient_id = auth.uid()
    );

-- Create policies for ai_messages
CREATE POLICY "ai_messages_select_own" ON ai_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND (
                ai_conversations.user_id = auth.uid() OR
                ai_conversations.patient_id = auth.uid()
            )
        )
    );

CREATE POLICY "ai_messages_insert_own" ON ai_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND (
                ai_conversations.user_id = auth.uid() OR
                ai_conversations.patient_id = auth.uid()
            )
        )
    );

CREATE POLICY "ai_messages_update_own" ON ai_messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND (
                ai_conversations.user_id = auth.uid() OR
                ai_conversations.patient_id = auth.uid()
            )
        )
    );

-- Add comments for documentation
COMMENT ON POLICY "ai_assistants_select_all" ON ai_assistants IS 'Allow all users to read AI assistant configurations';
COMMENT ON POLICY "ai_conversations_select_own" ON ai_conversations IS 'Users can only view their own conversations';
COMMENT ON POLICY "ai_conversations_insert_own" ON ai_conversations IS 'Users can only create conversations for themselves';
COMMENT ON POLICY "ai_conversations_update_own" ON ai_conversations IS 'Users can only update their own conversations';
COMMENT ON POLICY "ai_messages_select_own" ON ai_messages IS 'Users can only view messages in their conversations';
COMMENT ON POLICY "ai_messages_insert_own" ON ai_messages IS 'Users can only add messages to their conversations';
COMMENT ON POLICY "ai_messages_update_own" ON ai_messages IS 'Users can only update messages in their conversations';
