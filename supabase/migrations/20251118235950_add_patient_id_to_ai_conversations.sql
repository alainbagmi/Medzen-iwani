-- Migration: Add patient_id column to ai_conversations table
-- Purpose: Fixes column not found error in 20251119000000_seed_ai_assistants.sql
-- The seed migration expects patient_id for patient-specific conversations
-- while user_id remains for general user reference
-- Date: 2025-11-27

-- Add patient_id column if it doesn't exist
-- This allows the seed migration to create indexes and RLS policies
ALTER TABLE ai_conversations
ADD COLUMN IF NOT EXISTS patient_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Add comment explaining the column
COMMENT ON COLUMN ai_conversations.patient_id IS 'References the patient user for medical conversations. May be NULL for non-patient conversations.';
