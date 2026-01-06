-- Fix: specialties column is actually jsonb[] (array of jsonb)

-- Must drop first because we're changing return type
DROP FUNCTION IF EXISTS get_nearby_facilities(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER);
DROP FUNCTION IF EXISTS get_nearby_facilities_for_user(UUID, DOUBLE PRECISION, INTEGER);

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
  consultation_fee NUMERIC(10,2),
  emergency_services BOOLEAN,
  specialties JSONB[],
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
    f.specialties,
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

-- Also update the get_nearby_facilities_for_user function
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
  consultation_fee NUMERIC(10,2),
  emergency_services BOOLEAN,
  specialties JSONB[],
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_nearby_facilities TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_facilities_for_user TO authenticated;
