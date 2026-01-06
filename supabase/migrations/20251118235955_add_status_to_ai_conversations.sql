-- Migration: Add status column to ai_conversations table
-- Purpose: Fixes column not found error in 20251119000000_seed_ai_assistants.sql
-- The seed migration expects status for conversation state tracking
-- Note: Existing table has is_active (boolean), this adds status (text) for more granular states
-- Date: 2025-11-27

-- Add status column if it doesn't exist
ALTER TABLE ai_conversations
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Add comment explaining the column
COMMENT ON COLUMN ai_conversations.status IS 'Conversation status: active, archived, completed. Complements is_active boolean for more granular state management.';
