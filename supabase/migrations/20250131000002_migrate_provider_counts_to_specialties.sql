-- =====================================================
-- Migrate Provider Counts to Specialties Table
-- =====================================================
-- Removes the v_specialty_provider_counts view and adds count columns
-- directly to the specialties table for better performance.
-- Includes triggers to automatically maintain counts.
--
-- Created: 2025-01-31
-- Purpose: Denormalize provider counts into specialties table
-- =====================================================

-- =====================================================
-- 1. ADD COUNT COLUMNS TO SPECIALTIES TABLE
-- =====================================================

ALTER TABLE specialties
ADD COLUMN IF NOT EXISTS primary_count INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN IF NOT EXISTS secondary_count INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN IF NOT EXISTS total_provider_count INTEGER DEFAULT 0 NOT NULL;

COMMENT ON COLUMN specialties.primary_count IS
'Number of providers who have this as their primary specialty';

COMMENT ON COLUMN specialties.secondary_count IS
'Number of providers who have this as a secondary specialty/subspecialty';

COMMENT ON COLUMN specialties.total_provider_count IS
'Total unique providers associated with this specialty (primary or secondary)';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_specialties_primary_count
ON specialties(primary_count DESC)
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_specialties_total_provider_count
ON specialties(total_provider_count DESC)
WHERE is_active = true;

-- =====================================================
-- 2. POPULATE INITIAL COUNT DATA
-- =====================================================

-- Calculate and populate provider counts from existing data
UPDATE specialties s
SET
  primary_count = COALESCE((
    SELECT COUNT(DISTINCT mpp.id)
    FROM medical_provider_profiles mpp
    WHERE mpp.primary_specialty_id = s.id::text
      AND mpp.application_status = 'approved'
  ), 0),

  secondary_count = COALESCE((
    SELECT COUNT(DISTINCT ps.provider_id)
    FROM provider_specialties ps
    WHERE ps.specialty_id = s.id::text
      AND ps.is_active = true
  ), 0);

-- Calculate total_provider_count (unique providers with this specialty)
UPDATE specialties s
SET total_provider_count = (
  SELECT COUNT(DISTINCT provider_id) FROM (
    -- Primary specialty providers
    SELECT mpp.id::text as provider_id
    FROM medical_provider_profiles mpp
    WHERE mpp.primary_specialty_id = s.id::text
      AND mpp.application_status = 'approved'

    UNION

    -- Secondary specialty providers
    SELECT ps.provider_id
    FROM provider_specialties ps
    WHERE ps.specialty_id = s.id::text
      AND ps.is_active = true
  ) AS all_providers
);

-- =====================================================
-- 3. CREATE FUNCTION TO RECALCULATE SPECIALTY COUNTS
-- =====================================================

CREATE OR REPLACE FUNCTION recalculate_specialty_counts(specialty_id_param TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE specialties s
  SET
    primary_count = COALESCE((
      SELECT COUNT(DISTINCT mpp.id)
      FROM medical_provider_profiles mpp
      WHERE mpp.primary_specialty_id = specialty_id_param
        AND mpp.application_status = 'approved'
    ), 0),

    secondary_count = COALESCE((
      SELECT COUNT(DISTINCT ps.provider_id)
      FROM provider_specialties ps
      WHERE ps.specialty_id = specialty_id_param
        AND ps.is_active = true
    ), 0),

    total_provider_count = (
      SELECT COUNT(DISTINCT provider_id) FROM (
        SELECT mpp.id::text as provider_id
        FROM medical_provider_profiles mpp
        WHERE mpp.primary_specialty_id = specialty_id_param
          AND mpp.application_status = 'approved'

        UNION

        SELECT ps.provider_id
        FROM provider_specialties ps
        WHERE ps.specialty_id = specialty_id_param
          AND ps.is_active = true
      ) AS all_providers
    ),

    updated_at = NOW()
  WHERE s.id::text = specialty_id_param;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION recalculate_specialty_counts(TEXT) IS
'Recalculates and updates provider counts for a specific specialty';

-- =====================================================
-- 4. CREATE TRIGGERS FOR AUTOMATIC COUNT UPDATES
-- =====================================================

-- Trigger function for medical_provider_profiles changes
CREATE OR REPLACE FUNCTION update_specialty_counts_on_provider_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    IF NEW.primary_specialty_id IS NOT NULL AND NEW.application_status = 'approved' THEN
      PERFORM recalculate_specialty_counts(NEW.primary_specialty_id);
    END IF;
    RETURN NEW;
  END IF;

  -- Handle UPDATE
  IF TG_OP = 'UPDATE' THEN
    -- Primary specialty changed
    IF NEW.primary_specialty_id IS DISTINCT FROM OLD.primary_specialty_id THEN
      -- Recalculate old specialty if it exists
      IF OLD.primary_specialty_id IS NOT NULL THEN
        PERFORM recalculate_specialty_counts(OLD.primary_specialty_id);
      END IF;
      -- Recalculate new specialty if it exists
      IF NEW.primary_specialty_id IS NOT NULL THEN
        PERFORM recalculate_specialty_counts(NEW.primary_specialty_id);
      END IF;
    END IF;

    -- Application status changed (affects whether provider is counted)
    IF NEW.application_status IS DISTINCT FROM OLD.application_status THEN
      IF NEW.primary_specialty_id IS NOT NULL THEN
        PERFORM recalculate_specialty_counts(NEW.primary_specialty_id);
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  -- Handle DELETE
  IF TG_OP = 'DELETE' THEN
    IF OLD.primary_specialty_id IS NOT NULL THEN
      PERFORM recalculate_specialty_counts(OLD.primary_specialty_id);
    END IF;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on medical_provider_profiles
DROP TRIGGER IF EXISTS trigger_update_specialty_counts_provider ON medical_provider_profiles;

CREATE TRIGGER trigger_update_specialty_counts_provider
  AFTER INSERT OR UPDATE OR DELETE ON medical_provider_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_specialty_counts_on_provider_change();

COMMENT ON FUNCTION update_specialty_counts_on_provider_change() IS
'Automatically updates specialty provider counts when provider primary specialty changes';

-- Trigger function for provider_specialties changes
CREATE OR REPLACE FUNCTION update_specialty_counts_on_secondary_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    IF NEW.specialty_id IS NOT NULL AND NEW.is_active = true THEN
      PERFORM recalculate_specialty_counts(NEW.specialty_id);
    END IF;
    RETURN NEW;
  END IF;

  -- Handle UPDATE
  IF TG_OP = 'UPDATE' THEN
    -- Specialty changed
    IF NEW.specialty_id IS DISTINCT FROM OLD.specialty_id THEN
      IF OLD.specialty_id IS NOT NULL THEN
        PERFORM recalculate_specialty_counts(OLD.specialty_id);
      END IF;
      IF NEW.specialty_id IS NOT NULL THEN
        PERFORM recalculate_specialty_counts(NEW.specialty_id);
      END IF;
    END IF;

    -- Active status changed
    IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      IF NEW.specialty_id IS NOT NULL THEN
        PERFORM recalculate_specialty_counts(NEW.specialty_id);
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  -- Handle DELETE
  IF TG_OP = 'DELETE' THEN
    IF OLD.specialty_id IS NOT NULL THEN
      PERFORM recalculate_specialty_counts(OLD.specialty_id);
    END IF;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on provider_specialties
DROP TRIGGER IF EXISTS trigger_update_specialty_counts_secondary ON provider_specialties;

CREATE TRIGGER trigger_update_specialty_counts_secondary
  AFTER INSERT OR UPDATE OR DELETE ON provider_specialties
  FOR EACH ROW
  EXECUTE FUNCTION update_specialty_counts_on_secondary_change();

COMMENT ON FUNCTION update_specialty_counts_on_secondary_change() IS
'Automatically updates specialty provider counts when secondary specialties change';

-- =====================================================
-- 5. DROP THE OLD VIEW
-- =====================================================

DROP VIEW IF EXISTS v_specialty_provider_counts;

-- =====================================================
-- 6. CREATE REPLACEMENT VIEW (OPTIONAL - FOR BACKWARD COMPATIBILITY)
-- =====================================================

-- Create a simple view that reads from the denormalized columns
-- This maintains backward compatibility with existing queries
CREATE OR REPLACE VIEW v_specialty_provider_counts AS
SELECT
  id as specialty_id,
  specialty_code,
  specialty_name,
  primary_count,
  secondary_count,
  total_provider_count
FROM specialties
WHERE is_active = true
ORDER BY total_provider_count DESC, specialty_name;

COMMENT ON VIEW v_specialty_provider_counts IS
'Simple view exposing specialty provider counts (now stored directly in specialties table)';

-- =====================================================
-- 7. GRANT PERMISSIONS
-- =====================================================

-- Grant SELECT permissions on updated table
GRANT SELECT ON specialties TO postgres;
GRANT SELECT ON specialties TO authenticated;
GRANT SELECT ON v_specialty_provider_counts TO postgres;
GRANT SELECT ON v_specialty_provider_counts TO authenticated;

-- =====================================================
-- 8. VERIFICATION QUERIES
-- =====================================================

-- Verify counts are populated
-- SELECT specialty_code, specialty_name, primary_count, secondary_count, total_provider_count
-- FROM specialties
-- WHERE total_provider_count > 0
-- ORDER BY total_provider_count DESC
-- LIMIT 10;

-- Compare old view logic with new table columns
-- SELECT
--   s.specialty_code,
--   s.primary_count as table_primary,
--   s.secondary_count as table_secondary,
--   s.total_provider_count as table_total
-- FROM specialties s
-- WHERE s.is_active = true
-- ORDER BY s.total_provider_count DESC;

-- =====================================================
-- 9. TABLE RELATIONSHIP MAPPING
-- =====================================================

COMMENT ON TABLE specialties IS
'Master list of medical specialties with denormalized provider counts for performance.

RELATIONSHIPS:
- Referenced by: medical_provider_profiles.primary_specialty_id (one-to-many)
- Referenced by: provider_specialties.specialty_id (many-to-many via junction table)
- Self-referential: parent_specialty_id references specialties.id (hierarchical structure)

COUNT COLUMNS (auto-maintained by triggers):
- primary_count: Count of approved providers with this as primary specialty
- secondary_count: Count of active secondary/subspecialty assignments
- total_provider_count: Total unique providers (primary + secondary)';

COMMENT ON TABLE provider_specialties IS
'Many-to-many junction table between providers and specialties.

RELATIONSHIPS:
- provider_id → medical_provider_profiles.id (many-to-one)
- specialty_id → specialties.id (many-to-one)

TRIGGER BEHAVIOR:
- Changes to this table automatically update specialties.secondary_count and specialties.total_provider_count';

COMMENT ON TABLE medical_provider_profiles IS
'Provider profile information including primary specialty.

RELATIONSHIPS:
- user_id → users.id (one-to-one)
- primary_specialty_id → specialties.id (many-to-one)
- facility_id → facilities.id (many-to-one)
- Secondary specialties via provider_specialties junction table

TRIGGER BEHAVIOR:
- Changes to primary_specialty_id or application_status automatically update specialties.primary_count and specialties.total_provider_count';

-- =====================================================
-- END OF MIGRATION
-- =====================================================

-- Changes applied:
-- 1. Added primary_count, secondary_count, total_provider_count columns to specialties
-- 2. Populated counts from existing data
-- 3. Created recalculate_specialty_counts() function
-- 4. Created triggers to auto-maintain counts on:
--    - medical_provider_profiles changes
--    - provider_specialties changes
-- 5. Dropped old computed view
-- 6. Created new simple view for backward compatibility
-- 7. Added comprehensive relationship documentation
--
-- Performance benefit:
-- - Counts now stored directly in specialties table (no JOINs at query time)
-- - Triggers ensure counts stay synchronized automatically
-- - Indexes on count columns for efficient sorting/filtering
