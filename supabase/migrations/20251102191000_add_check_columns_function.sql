-- Create a function to check what columns exist in ehrbase_sync_queue
CREATE OR REPLACE FUNCTION check_ehrbase_sync_queue_columns()
RETURNS TABLE (
  column_name TEXT,
  data_type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.column_name::TEXT,
    c.data_type::TEXT
  FROM information_schema.columns c
  WHERE c.table_name = 'ehrbase_sync_queue'
  AND c.table_schema = 'public'
  ORDER BY c.ordinal_position;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution to authenticated and service_role
GRANT EXECUTE ON FUNCTION check_ehrbase_sync_queue_columns() TO authenticated, service_role, anon;
