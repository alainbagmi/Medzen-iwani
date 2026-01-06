-- Migration: Create debug RPC functions
-- Description: Helper functions to inspect database objects

-- Function to list all triggers on clinical_notes
CREATE OR REPLACE FUNCTION list_clinical_notes_triggers()
RETURNS TABLE (
    trigger_name TEXT,
    trigger_type TEXT,
    is_internal BOOLEAN,
    function_name TEXT,
    trigger_when TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.tgname::TEXT as trigger_name,
        CASE
            WHEN t.tgtype & 2 = 2 THEN 'BEFORE'
            WHEN t.tgtype & 64 = 64 THEN 'INSTEAD OF'
            ELSE 'AFTER'
        END || ' ' ||
        CASE
            WHEN t.tgtype & 4 = 4 THEN 'INSERT'
            WHEN t.tgtype & 8 = 8 THEN 'DELETE'
            WHEN t.tgtype & 16 = 16 THEN 'UPDATE'
            ELSE 'UNKNOWN'
        END as trigger_type,
        t.tgisinternal as is_internal,
        p.proname::TEXT as function_name,
        pg_get_triggerdef(t.oid) as trigger_when
    FROM pg_trigger t
    LEFT JOIN pg_proc p ON t.tgfoid = p.oid
    WHERE t.tgrelid = 'clinical_notes'::regclass;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to drop all non-internal triggers on clinical_notes
CREATE OR REPLACE FUNCTION drop_all_clinical_notes_triggers()
RETURNS TABLE (
    dropped_trigger TEXT,
    success BOOLEAN
) AS $$
DECLARE
    trigger_rec RECORD;
BEGIN
    FOR trigger_rec IN
        SELECT tgname::TEXT as name
        FROM pg_trigger
        WHERE tgrelid = 'clinical_notes'::regclass
        AND NOT tgisinternal
    LOOP
        BEGIN
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON clinical_notes CASCADE', trigger_rec.name);
            RETURN QUERY SELECT trigger_rec.name, TRUE;
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT trigger_rec.name, FALSE;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test direct update without triggers
CREATE OR REPLACE FUNCTION direct_update_clinical_note_no_trigger(
    p_note_id UUID,
    p_new_status TEXT
)
RETURNS TEXT AS $$
BEGIN
    -- Disable all triggers temporarily
    SET session_replication_role = replica;

    -- Perform the update
    UPDATE clinical_notes
    SET status = p_new_status,
        updated_at = NOW()
    WHERE id = p_note_id;

    -- Re-enable triggers
    SET session_replication_role = DEFAULT;

    RETURN 'Update successful';
EXCEPTION WHEN OTHERS THEN
    SET session_replication_role = DEFAULT;
    RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION list_clinical_notes_triggers() TO service_role;
GRANT EXECUTE ON FUNCTION drop_all_clinical_notes_triggers() TO service_role;
GRANT EXECUTE ON FUNCTION direct_update_clinical_note_no_trigger(UUID, TEXT) TO service_role;
