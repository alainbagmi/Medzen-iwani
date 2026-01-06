-- Migration: Fix duplicate user_ids in user_profiles table
-- Problem: The user_profiles table was missing a UNIQUE constraint on user_id,
--          allowing multiple profile records for the same user (14 duplicates found).
--
-- Root cause: Users tapping submit button multiple times, network retries,
--             or app logic creating profiles without checking for existing ones.
--
-- Solution:
--   1. Delete duplicate rows, keeping only the most recent one per user (DONE via API on 2026-01-05)
--   2. Add a UNIQUE constraint to prevent future duplicates
--
-- Affected users (duplicates cleaned):
--   - 450b80a1-... (ZEH-NLO Estelle Marlene): 4 duplicates removed
--   - 517afa94-... (Sese Mudika): 6 duplicates removed
--   - 45ba4979-... (Peter Mbala): 1 duplicate removed
--   - ca9249c5-... (MAXWELL KAISA JR): 3 duplicates removed

-- Add a unique constraint on user_id to prevent future duplicates
-- This will fail if duplicates still exist (they were cleaned via API)
ALTER TABLE user_profiles
ADD CONSTRAINT user_profiles_user_id_unique UNIQUE (user_id);

-- Add a comment explaining the constraint
COMMENT ON CONSTRAINT user_profiles_user_id_unique ON user_profiles IS
    'Ensures each user can only have one profile record. Added 2026-01-05 to fix duplicate user_id issue.';
