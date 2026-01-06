-- Migration: Cleanup Deprecated Tables and Failed EHR Sync Records
-- Date: December 19, 2025
-- Purpose: Remove deprecated tables and clear failed EHR sync records per compliance audit
-- Reference: DATABASE_COMPLIANCE_REPORT.md

-- ============================================
-- SECTION 1: Clear Failed EHR Sync Records
-- ============================================
-- These 30 records failed due to missing OpenEHR template "RIPPLE - Clinical Notes.v1"
-- Keeping them serves no purpose and clutters the sync queue

DELETE FROM ehrbase_sync_queue
WHERE sync_status = 'failed';

-- Log the cleanup
DO $$
BEGIN
    RAISE NOTICE 'Cleared all failed EHR sync records from ehrbase_sync_queue';
END $$;

-- ============================================
-- SECTION 2: Drop Deprecated Tables
-- ============================================
-- These tables were marked as deprecated in migration 20251219141047
-- They have been replaced by newer implementations:
-- - z_chats, z_chat_messages, chat -> ai_conversations, ai_messages
-- - conversation -> conversations
-- - *_backup_* tables are temporary backups no longer needed

-- Drop in correct order to handle any dependencies

-- 2.1 Legacy chat tables (replaced by ai_conversations/ai_messages)
DROP TABLE IF EXISTS z_chat_messages CASCADE;
DROP TABLE IF EXISTS z_chats CASCADE;
DROP TABLE IF EXISTS chat CASCADE;

-- 2.2 Legacy conversation table (replaced by conversations)
DROP TABLE IF EXISTS conversation CASCADE;

-- 2.3 Temporary backup tables from Nov 14, 2025 migration
DROP TABLE IF EXISTS specialties_backup_20251114 CASCADE;
DROP TABLE IF EXISTS provider_profiles_backup_20251114 CASCADE;

-- ============================================
-- SECTION 3: Verification Queries
-- ============================================

-- Verify no more failed sync records
DO $$
DECLARE
    failed_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO failed_count
    FROM ehrbase_sync_queue
    WHERE sync_status = 'failed';

    IF failed_count > 0 THEN
        RAISE EXCEPTION 'Failed sync records still exist: %', failed_count;
    ELSE
        RAISE NOTICE 'SUCCESS: No failed sync records remain';
    END IF;
END $$;

-- Verify deprecated tables are dropped
DO $$
DECLARE
    remaining_tables TEXT[];
BEGIN
    SELECT ARRAY_AGG(tablename) INTO remaining_tables
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN (
        'z_chats', 'z_chat_messages', 'chat', 'conversation',
        'specialties_backup_20251114', 'provider_profiles_backup_20251114'
    );

    IF remaining_tables IS NOT NULL THEN
        RAISE EXCEPTION 'Deprecated tables still exist: %', remaining_tables;
    ELSE
        RAISE NOTICE 'SUCCESS: All deprecated tables have been dropped';
    END IF;
END $$;

-- ============================================
-- SECTION 4: Update Compliance Tracking
-- ============================================

-- Add comment to track when cleanup was performed
COMMENT ON TABLE ehrbase_sync_queue IS 'EHR sync queue - Failed records cleaned up on Dec 19, 2025';

-- Final summary
DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'DATABASE CLEANUP COMPLETED SUCCESSFULLY';
    RAISE NOTICE '===========================================';
    RAISE NOTICE '✓ Cleared all failed EHR sync records';
    RAISE NOTICE '✓ Dropped 6 deprecated tables:';
    RAISE NOTICE '  - z_chats';
    RAISE NOTICE '  - z_chat_messages';
    RAISE NOTICE '  - chat';
    RAISE NOTICE '  - conversation';
    RAISE NOTICE '  - specialties_backup_20251114';
    RAISE NOTICE '  - provider_profiles_backup_20251114';
    RAISE NOTICE '===========================================';
END $$;
