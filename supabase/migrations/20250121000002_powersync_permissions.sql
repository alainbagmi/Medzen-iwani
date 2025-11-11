-- PowerSync Permissions Setup
-- Configures Supabase database for PowerSync connection

-- =====================================================
-- 1. Enable Replication for PowerSync Tables
-- =====================================================

-- Enable replication publication (if not already enabled)
-- PowerSync uses logical replication to detect changes

-- Note: Run this only if you haven't already enabled replication
-- ALTER SYSTEM SET wal_level = logical;
-- You may need to restart PostgreSQL after this

-- Create publication for PowerSync (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'powersync'
  ) THEN
    CREATE PUBLICATION powersync FOR ALL TABLES;
  END IF;
END
$$;

-- =====================================================
-- 2. Grant PowerSync User Permissions
-- =====================================================

-- Grant necessary permissions to postgres user (used by PowerSync)
GRANT USAGE ON SCHEMA public TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Grant permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON SEQUENCES TO postgres;

-- =====================================================
-- 3. Configure Row Level Security for PowerSync
-- =====================================================

-- Enable RLS on all medical data tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE electronic_health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE vital_signs ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE immunizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE ehrbase_sync_queue ENABLE ROW LEVEL SECURITY;

-- Create policies to allow PowerSync postgres user to read all data
-- PowerSync handles user-level filtering via sync rules
-- These policies allow PowerSync to access data, while client apps use different policies

-- Drop existing PowerSync policies if they exist
DROP POLICY IF EXISTS "powersync_read_all" ON users;
DROP POLICY IF EXISTS "powersync_read_all" ON electronic_health_records;
DROP POLICY IF EXISTS "powersync_read_all" ON vital_signs;
DROP POLICY IF EXISTS "powersync_read_all" ON lab_results;
DROP POLICY IF EXISTS "powersync_read_all" ON prescriptions;
DROP POLICY IF EXISTS "powersync_read_all" ON immunizations;
DROP POLICY IF EXISTS "powersync_read_all" ON medical_records;
DROP POLICY IF EXISTS "powersync_read_all" ON ehrbase_sync_queue;

-- Create new policies for PowerSync
CREATE POLICY "powersync_read_all" ON users
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON electronic_health_records
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON vital_signs
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON lab_results
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON prescriptions
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON immunizations
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON medical_records
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON ehrbase_sync_queue
  FOR SELECT
  TO postgres
  USING (true);

-- =====================================================
-- 4. Create Helper View for PowerSync Monitoring
-- =====================================================

CREATE OR REPLACE VIEW v_powersync_replication_status AS
SELECT
  slot_name,
  plugin,
  slot_type,
  active,
  active_pid,
  restart_lsn,
  confirmed_flush_lsn
FROM pg_replication_slots
WHERE slot_name LIKE 'powersync%';

COMMENT ON VIEW v_powersync_replication_status IS 'Monitor PowerSync replication slot status';

-- Grant access to view
GRANT SELECT ON v_powersync_replication_status TO postgres;

-- =====================================================
-- 5. Create Function to Check PowerSync Health
-- =====================================================

CREATE OR REPLACE FUNCTION check_powersync_health()
RETURNS TABLE(
  check_name TEXT,
  status TEXT,
  details TEXT
) AS $$
BEGIN
  -- Check if replication is enabled
  RETURN QUERY
  SELECT
    'Replication Enabled'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'powersync')
      THEN 'OK'::TEXT
      ELSE 'ERROR'::TEXT
    END,
    'Publication exists for PowerSync'::TEXT;

  -- Check active replication slots
  RETURN QUERY
  SELECT
    'Active Replication Slots'::TEXT,
    CASE WHEN COUNT(*) > 0 THEN 'OK'::TEXT ELSE 'WARNING'::TEXT END,
    COUNT(*)::TEXT || ' active slot(s)'::TEXT
  FROM pg_replication_slots
  WHERE slot_name LIKE 'powersync%' AND active = true;

  -- Check table permissions
  RETURN QUERY
  SELECT
    'Table Permissions'::TEXT,
    'OK'::TEXT,
    COUNT(DISTINCT tablename)::TEXT || ' tables accessible'::TEXT
  FROM pg_tables
  WHERE schemaname = 'public'
    AND has_table_privilege('postgres', schemaname || '.' || tablename, 'SELECT');

  RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_powersync_health() IS 'Check PowerSync connection health and configuration';

-- =====================================================
-- 6. Comments for Documentation
-- =====================================================

COMMENT ON PUBLICATION powersync IS 'PowerSync logical replication publication - DO NOT DELETE';
