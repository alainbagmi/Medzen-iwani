-- Migration: Create RPC function to update clinical note status
-- Description: Bypasses PostgREST to test if issue is in triggers or RPC layer

-- Create a simple RPC function to update status
CREATE OR REPLACE FUNCTION update_clinical_note_status(
    p_note_id UUID,
    p_new_status TEXT
)
RETURNS TABLE (
    note_id UUID,
    old_status TEXT,
    new_status TEXT,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_old_status TEXT;
BEGIN
    -- Get current status
    SELECT status INTO v_old_status
    FROM clinical_notes
    WHERE id = p_note_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT
            p_note_id,
            NULL::TEXT,
            p_new_status,
            FALSE,
            'Note not found'::TEXT;
        RETURN;
    END IF;

    -- Perform the update
    BEGIN
        UPDATE clinical_notes
        SET status = p_new_status,
            updated_at = NOW()
        WHERE id = p_note_id;

        RETURN QUERY SELECT
            p_note_id,
            v_old_status,
            p_new_status,
            TRUE,
            NULL::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            p_note_id,
            v_old_status,
            p_new_status,
            FALSE,
            SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to service role
GRANT EXECUTE ON FUNCTION update_clinical_note_status(UUID, TEXT) TO service_role;
