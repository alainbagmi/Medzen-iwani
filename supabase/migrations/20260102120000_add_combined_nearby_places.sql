-- =====================================================
-- Migration: Add combined nearby_places function
-- Returns both facilities AND medical providers with distance
-- =====================================================

-- =====================================================
-- STEP 1: Add location columns to medical_provider_profiles (optional)
-- Providers can have their own location OR inherit from their facility
-- =====================================================

ALTER TABLE medical_provider_profiles
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS geog GEOGRAPHY(POINT, 4326),
ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

COMMENT ON COLUMN medical_provider_profiles.latitude IS 'Provider latitude (optional - falls back to facility location)';
COMMENT ON COLUMN medical_provider_profiles.longitude IS 'Provider longitude (optional - falls back to facility location)';
COMMENT ON COLUMN medical_provider_profiles.geog IS 'PostGIS geography point for distance calculations';

-- Trigger for medical_provider_profiles location updates
DROP TRIGGER IF EXISTS provider_profiles_update_geog ON medical_provider_profiles;
CREATE TRIGGER provider_profiles_update_geog
  BEFORE INSERT OR UPDATE OF latitude, longitude ON medical_provider_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_geography_point();

-- Create spatial index
CREATE INDEX IF NOT EXISTS idx_provider_profiles_geog
  ON medical_provider_profiles USING GIST (geog);

-- =====================================================
-- STEP 2: Create the combined nearby_places function
-- Returns both facilities and providers in a single query
-- =====================================================

CREATE OR REPLACE FUNCTION nearby_places(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m INTEGER DEFAULT 50000,  -- Default 50km in meters
  p_types TEXT[] DEFAULT NULL,        -- Filter: 'facility', 'provider', facility_type, specialty
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  place_kind TEXT,           -- 'facility' or 'provider'
  id UUID,
  name TEXT,
  subtype TEXT,              -- facility_type or provider specialty
  image_url TEXT,
  phone_number TEXT,
  address TEXT,
  city TEXT,
  country TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  distance_m DOUBLE PRECISION,
  distance_km DOUBLE PRECISION,
  consultation_fee DOUBLE PRECISION,
  is_available BOOLEAN,
  rating DOUBLE PRECISION,
  metadata JSONB              -- Additional type-specific data
) AS $$
DECLARE
  v_user_point geography;
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RAISE EXCEPTION 'Location coordinates are required (p_lat, p_lng)';
  END IF;

  -- Create user's location point
  v_user_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;

  RETURN QUERY
  WITH all_places AS (
    -- FACILITIES
    SELECT
      'facility'::TEXT as place_kind,
      f.id,
      f.facility_name as name,
      f.facility_type::TEXT as subtype,
      f.image_url,
      f.phone_number,
      f.address,
      f.city,
      f.country,
      f.latitude as lat,
      f.longitude as lng,
      ST_Distance(f.geog, v_user_point) as distance_m,
      f.consultation_fee,
      f.is_active as is_available,
      NULL::DOUBLE PRECISION as rating,
      jsonb_build_object(
        'facility_code', f.facility_code,
        'facility_type', f.facility_type,
        'emergency_services', f.emergency_services,
        'specialties', f.specialties,
        'departments', f."Departments",
        'website', f.website,
        'email', f.email
      ) as metadata
    FROM facilities f
    WHERE f.is_active = true
      AND f.geog IS NOT NULL
      AND ST_DWithin(f.geog, v_user_point, p_radius_m)
      AND (
        p_types IS NULL
        OR 'facility' = ANY(p_types)
        OR f.facility_type::TEXT = ANY(p_types)
      )

    UNION ALL

    -- MEDICAL PROVIDERS
    SELECT
      'provider'::TEXT as place_kind,
      mp.id,
      COALESCE(u.first_name || ' ' || u.last_name, u.email) as name,
      COALESCE(mp.primary_specialization, mp.professional_role)::TEXT as subtype,
      COALESCE(mp.avatar_url, u.photo_url) as image_url,
      u.phone_number,
      fac.address,
      fac.city,
      fac.country,
      -- Use provider location if set, otherwise facility location
      COALESCE(mp.latitude, fac.latitude) as lat,
      COALESCE(mp.longitude, fac.longitude) as lng,
      ST_Distance(
        COALESCE(mp.geog, fac.geog),
        v_user_point
      ) as distance_m,
      mp.consultation_fee,
      (mp.availability_status = 'available' AND mp.accepts_new_patients) as is_available,
      mp.patient_satisfaction_avg as rating,
      jsonb_build_object(
        'provider_number', mp.provider_number,
        'professional_role', mp.professional_role,
        'specialization', mp.primary_specialization,
        'is_specialist', mp.is_specialist,
        'years_experience', mp.years_of_experience,
        'languages_spoken', mp.languages_spoken,
        'video_enabled', mp.video_consultation_enabled,
        'telemedicine_enabled', mp.telemedicine_setup_complete,
        'facility_id', mp.facility_id,
        'facility_name', fac.facility_name
      ) as metadata
    FROM medical_provider_profiles mp
    JOIN users u ON u.id = mp.user_id
    LEFT JOIN facilities fac ON fac.id = mp.facility_id
    WHERE mp.application_status = 'approved'
      AND (mp.geog IS NOT NULL OR fac.geog IS NOT NULL)
      AND ST_DWithin(
        COALESCE(mp.geog, fac.geog),
        v_user_point,
        p_radius_m
      )
      AND (
        p_types IS NULL
        OR 'provider' = ANY(p_types)
        OR mp.primary_specialization::TEXT = ANY(p_types)
        OR mp.professional_role::TEXT = ANY(p_types)
      )
  )
  SELECT
    ap.place_kind,
    ap.id,
    ap.name,
    ap.subtype,
    ap.image_url,
    ap.phone_number,
    ap.address,
    ap.city,
    ap.country,
    ap.lat,
    ap.lng,
    ROUND(ap.distance_m::numeric, 2)::double precision as distance_m,
    ROUND((ap.distance_m / 1000.0)::numeric, 2)::double precision as distance_km,
    ap.consultation_fee,
    ap.is_available,
    ap.rating,
    ap.metadata
  FROM all_places ap
  ORDER BY ap.distance_m ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- STEP 3: Create helper function to get nearby providers only
-- =====================================================

CREATE OR REPLACE FUNCTION get_nearby_providers(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  provider_id UUID,
  user_id UUID,
  provider_number TEXT,
  full_name TEXT,
  professional_role TEXT,
  primary_specialization TEXT,
  avatar_url TEXT,
  phone_number TEXT,
  facility_id UUID,
  facility_name TEXT,
  address TEXT,
  city TEXT,
  country TEXT,
  consultation_fee DOUBLE PRECISION,
  is_available BOOLEAN,
  video_enabled BOOLEAN,
  rating DOUBLE PRECISION,
  years_experience INTEGER,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION
) AS $$
DECLARE
  v_user_point geography;
BEGIN
  IF user_lat IS NULL OR user_lng IS NULL THEN
    RAISE EXCEPTION 'User location is required';
  END IF;

  v_user_point := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;

  RETURN QUERY
  SELECT
    mp.id as provider_id,
    mp.user_id,
    mp.provider_number,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) as full_name,
    mp.professional_role,
    mp.primary_specialization,
    COALESCE(mp.avatar_url, u.photo_url) as avatar_url,
    u.phone_number,
    mp.facility_id,
    fac.facility_name,
    fac.address,
    fac.city,
    fac.country,
    mp.consultation_fee,
    (mp.availability_status = 'available' AND mp.accepts_new_patients) as is_available,
    mp.video_consultation_enabled as video_enabled,
    mp.patient_satisfaction_avg as rating,
    mp.years_of_experience as years_experience,
    COALESCE(mp.latitude, fac.latitude) as latitude,
    COALESCE(mp.longitude, fac.longitude) as longitude,
    ROUND((ST_Distance(
      COALESCE(mp.geog, fac.geog),
      v_user_point
    ) / 1000.0)::numeric, 2)::double precision as distance_km
  FROM medical_provider_profiles mp
  JOIN users u ON u.id = mp.user_id
  LEFT JOIN facilities fac ON fac.id = mp.facility_id
  WHERE mp.application_status = 'approved'
    AND (mp.geog IS NOT NULL OR fac.geog IS NOT NULL)
    AND ST_DWithin(
      COALESCE(mp.geog, fac.geog),
      v_user_point,
      max_distance_km * 1000
    )
  ORDER BY distance_km ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- STEP 4: Create function to update provider location
-- =====================================================

CREATE OR REPLACE FUNCTION update_provider_location(
  p_provider_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE medical_provider_profiles
  SET
    latitude = p_latitude,
    longitude = p_longitude,
    location_updated_at = NOW(),
    updated_at = NOW()
  WHERE id = p_provider_id;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 5: Create view for combined search results
-- =====================================================

CREATE OR REPLACE VIEW nearby_search_options AS
SELECT DISTINCT
  'facility_type' as option_type,
  facility_type as option_value,
  COUNT(*) as count
FROM facilities
WHERE is_active = true AND geog IS NOT NULL
GROUP BY facility_type

UNION ALL

SELECT DISTINCT
  'provider_specialty' as option_type,
  primary_specialization as option_value,
  COUNT(*) as count
FROM medical_provider_profiles
WHERE application_status = 'approved'
  AND primary_specialization IS NOT NULL
  AND primary_specialization != ''
GROUP BY primary_specialization

UNION ALL

SELECT DISTINCT
  'provider_role' as option_type,
  professional_role as option_value,
  COUNT(*) as count
FROM medical_provider_profiles
WHERE application_status = 'approved'
GROUP BY professional_role;

-- =====================================================
-- STEP 6: Grant permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION nearby_places TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_providers TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_provider_location TO authenticated;
GRANT SELECT ON nearby_search_options TO authenticated, anon;

-- =====================================================
-- Done! Combined nearby_places function is ready
-- =====================================================
