-- Enable PostGIS extension for geospatial queries
-- This migration adds location tracking for users and facilities to enable distance calculations

-- =====================================================
-- STEP 1: Enable PostGIS Extension
-- =====================================================
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- =====================================================
-- STEP 2: Add location columns to users table
-- =====================================================

-- Add latitude and longitude columns
ALTER TABLE users
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

-- Add geography point column for efficient spatial queries
ALTER TABLE users
ADD COLUMN IF NOT EXISTS geog GEOGRAPHY(POINT, 4326);

-- Add comment for documentation
COMMENT ON COLUMN users.latitude IS 'User latitude from Google Location';
COMMENT ON COLUMN users.longitude IS 'User longitude from Google Location';
COMMENT ON COLUMN users.geog IS 'PostGIS geography point for distance calculations';
COMMENT ON COLUMN users.location_updated_at IS 'When the location was last updated';

-- =====================================================
-- STEP 3: Add location columns to facilities table
-- =====================================================

-- Add latitude and longitude columns (facilities already has a 'location' text column)
ALTER TABLE facilities
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Add geography point column for efficient spatial queries
ALTER TABLE facilities
ADD COLUMN IF NOT EXISTS geog GEOGRAPHY(POINT, 4326);

-- Add comment for documentation
COMMENT ON COLUMN facilities.latitude IS 'Facility latitude from Google Location';
COMMENT ON COLUMN facilities.longitude IS 'Facility longitude from Google Location';
COMMENT ON COLUMN facilities.geog IS 'PostGIS geography point for distance calculations';

-- =====================================================
-- STEP 4: Create trigger to auto-update geography point when lat/lng changes
-- =====================================================

-- Function to update geography point from lat/lng
CREATE OR REPLACE FUNCTION update_geography_point()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.geog := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  ELSE
    NEW.geog := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users table
DROP TRIGGER IF EXISTS users_update_geog ON users;
CREATE TRIGGER users_update_geog
  BEFORE INSERT OR UPDATE OF latitude, longitude ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_geography_point();

-- Trigger for facilities table
DROP TRIGGER IF EXISTS facilities_update_geog ON facilities;
CREATE TRIGGER facilities_update_geog
  BEFORE INSERT OR UPDATE OF latitude, longitude ON facilities
  FOR EACH ROW
  EXECUTE FUNCTION update_geography_point();

-- =====================================================
-- STEP 5: Create spatial indexes for efficient distance queries
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_users_geog ON users USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_facilities_geog ON facilities USING GIST (geog);

-- Also create indexes on lat/lng for simple queries
CREATE INDEX IF NOT EXISTS idx_users_lat_lng ON users (latitude, longitude) WHERE latitude IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_facilities_lat_lng ON facilities (latitude, longitude) WHERE latitude IS NOT NULL;

-- =====================================================
-- STEP 6: Create distance calculation functions
-- =====================================================

-- Function to get distance between two points in meters
CREATE OR REPLACE FUNCTION get_distance_meters(
  lat1 DOUBLE PRECISION,
  lng1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lng2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
BEGIN
  IF lat1 IS NULL OR lng1 IS NULL OR lat2 IS NULL OR lng2 IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN ST_Distance(
    ST_SetSRID(ST_MakePoint(lng1, lat1), 4326)::geography,
    ST_SetSRID(ST_MakePoint(lng2, lat2), 4326)::geography
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get distance in kilometers
CREATE OR REPLACE FUNCTION get_distance_km(
  lat1 DOUBLE PRECISION,
  lng1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lng2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
BEGIN
  RETURN get_distance_meters(lat1, lng1, lat2, lng2) / 1000.0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- STEP 7: Create function to get nearby facilities for a user
-- =====================================================

CREATE OR REPLACE FUNCTION get_nearby_facilities(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  facility_id UUID,
  facility_code TEXT,
  facility_name TEXT,
  facility_type TEXT,
  address TEXT,
  city TEXT,
  country TEXT,
  phone_number TEXT,
  email TEXT,
  website TEXT,
  image_url TEXT,
  consultation_fee DOUBLE PRECISION,
  emergency_services BOOLEAN,
  specialties JSONB,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  IF user_lat IS NULL OR user_lng IS NULL THEN
    RAISE EXCEPTION 'User location is required';
  END IF;

  RETURN QUERY
  SELECT
    f.id AS facility_id,
    f.facility_code,
    f.facility_name,
    f.facility_type,
    f.address,
    f.city,
    f.country,
    f.phone_number,
    f.email,
    f.website,
    f.image_url,
    f.consultation_fee,
    f.emergency_services,
    f.specialties::jsonb,
    f.latitude,
    f.longitude,
    ROUND((ST_Distance(
      f.geog,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) / 1000.0)::numeric, 2)::double precision AS distance_km
  FROM facilities f
  WHERE f.is_active = true
    AND f.geog IS NOT NULL
    AND ST_DWithin(
      f.geog,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      max_distance_km * 1000  -- Convert km to meters
    )
  ORDER BY distance_km ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- STEP 8: Create function to get nearby facilities for a specific user by ID
-- =====================================================

CREATE OR REPLACE FUNCTION get_nearby_facilities_for_user(
  p_user_id UUID,
  max_distance_km DOUBLE PRECISION DEFAULT 50,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  facility_id UUID,
  facility_code TEXT,
  facility_name TEXT,
  facility_type TEXT,
  address TEXT,
  city TEXT,
  country TEXT,
  phone_number TEXT,
  email TEXT,
  website TEXT,
  image_url TEXT,
  consultation_fee DOUBLE PRECISION,
  emergency_services BOOLEAN,
  specialties JSONB,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION
) AS $$
DECLARE
  v_user_lat DOUBLE PRECISION;
  v_user_lng DOUBLE PRECISION;
BEGIN
  -- Get user's location
  SELECT u.latitude, u.longitude INTO v_user_lat, v_user_lng
  FROM users u
  WHERE u.id = p_user_id;

  IF v_user_lat IS NULL OR v_user_lng IS NULL THEN
    RAISE EXCEPTION 'User location not set for user %', p_user_id;
  END IF;

  RETURN QUERY
  SELECT * FROM get_nearby_facilities(v_user_lat, v_user_lng, max_distance_km, result_limit);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =====================================================
-- STEP 9: Create view for facilities with distance placeholder
-- =====================================================

-- This view shows all active facilities with their locations
CREATE OR REPLACE VIEW facilities_with_location AS
SELECT
  f.id,
  f.facility_code,
  f.facility_name,
  f.facility_type,
  f.address,
  f.city,
  f.state,
  f.country,
  f.postal_code,
  f.phone_number,
  f.email,
  f.website,
  f.image_url,
  f.consultation_fee,
  f.emergency_services,
  f.specialties,
  f.certifications,
  f.bed_capacity,
  f.operating_hours,
  f."Description" as description,
  f."Departments" as departments,
  f.latitude,
  f.longitude,
  f.application_status,
  f.is_active,
  f.created_at,
  f.updated_at,
  CASE
    WHEN f.latitude IS NOT NULL AND f.longitude IS NOT NULL THEN true
    ELSE false
  END as has_location
FROM facilities f
WHERE f.is_active = true;

-- =====================================================
-- STEP 10: Create function to update user location
-- =====================================================

CREATE OR REPLACE FUNCTION update_user_location(
  p_user_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE users
  SET
    latitude = p_latitude,
    longitude = p_longitude,
    location_updated_at = NOW(),
    updated_at = NOW()
  WHERE id = p_user_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 11: Create function to update facility location
-- =====================================================

CREATE OR REPLACE FUNCTION update_facility_location(
  p_facility_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE facilities
  SET
    latitude = p_latitude,
    longitude = p_longitude,
    updated_at = NOW()
  WHERE id = p_facility_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 12: Grant permissions
-- =====================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_distance_meters TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_distance_km TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_facilities TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_facilities_for_user TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_location TO authenticated;
GRANT EXECUTE ON FUNCTION update_facility_location TO authenticated;

-- Grant select on view
GRANT SELECT ON facilities_with_location TO authenticated, anon;

-- =====================================================
-- Done! PostGIS location support is now enabled
-- =====================================================
