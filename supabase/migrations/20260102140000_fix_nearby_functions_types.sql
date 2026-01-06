-- =====================================================
-- Migration: Fix nearby functions type mismatches
-- =====================================================

-- =====================================================
-- STEP 1: Add blood_type column to patient_profiles if not exists
-- =====================================================

ALTER TABLE patient_profiles
ADD COLUMN IF NOT EXISTS blood_type TEXT;

COMMENT ON COLUMN patient_profiles.blood_type IS 'Blood type (A+, A-, B+, B-, AB+, AB-, O+, O-)';

-- =====================================================
-- STEP 2: Fix the combined nearby_places function (cast numeric to double)
-- =====================================================

DROP FUNCTION IF EXISTS nearby_places(DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, TEXT[], INTEGER);

CREATE OR REPLACE FUNCTION nearby_places(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m INTEGER DEFAULT 50000,
  p_types TEXT[] DEFAULT NULL,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  place_kind TEXT,
  id UUID,
  name TEXT,
  subtype TEXT,
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
  metadata JSONB
) AS $$
DECLARE
  v_user_point geography;
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RAISE EXCEPTION 'Location coordinates are required (p_lat, p_lng)';
  END IF;

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
      f.consultation_fee::DOUBLE PRECISION as consultation_fee,
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
      COALESCE(mp.avatar_url, u.profile_picture_url) as image_url,
      u.phone_number,
      fac.address,
      fac.city,
      fac.country,
      COALESCE(mp.latitude, fac.latitude) as lat,
      COALESCE(mp.longitude, fac.longitude) as lng,
      ST_Distance(
        COALESCE(mp.geog, fac.geog),
        v_user_point
      ) as distance_m,
      mp.consultation_fee::DOUBLE PRECISION as consultation_fee,
      (mp.availability_status = 'available' AND mp.accepts_new_patients) as is_available,
      mp.patient_satisfaction_avg::DOUBLE PRECISION as rating,
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
-- STEP 3: Fix the get_nearby_providers function
-- =====================================================

DROP FUNCTION IF EXISTS get_nearby_providers(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER);

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
    COALESCE(mp.avatar_url, u.profile_picture_url) as avatar_url,
    u.phone_number,
    mp.facility_id,
    fac.facility_name,
    fac.address,
    fac.city,
    fac.country,
    mp.consultation_fee::DOUBLE PRECISION as consultation_fee,
    (mp.availability_status = 'available' AND mp.accepts_new_patients) as is_available,
    mp.video_consultation_enabled as video_enabled,
    mp.patient_satisfaction_avg::DOUBLE PRECISION as rating,
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
-- STEP 4: Fix get_nearby_blood_donors function
-- =====================================================

DROP FUNCTION IF EXISTS get_nearby_blood_donors(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER);

CREATE OR REPLACE FUNCTION get_nearby_blood_donors(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50,
  result_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  patient_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  phone_number TEXT,
  country TEXT,
  blood_type TEXT,
  is_blood_donor BOOLEAN,
  blood_donor_status TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION,
  last_seen_at TIMESTAMPTZ
) AS $$
DECLARE
  v_user_point geography;
BEGIN
  IF user_lat IS NULL OR user_lng IS NULL THEN
    RAISE EXCEPTION 'Location is required';
  END IF;

  v_user_point := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;

  RETURN QUERY
  SELECT
    u.id as patient_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) as full_name,
    u.profile_picture_url as avatar_url,
    u.phone_number,
    u.country,
    pp.blood_type,
    COALESCE(pp.is_blood_donor, u.blood_donation) as is_blood_donor,
    pp.blood_donor_status,
    u.latitude,
    u.longitude,
    ROUND((ST_Distance(u.geog, v_user_point) / 1000.0)::numeric, 2)::double precision as distance_km,
    u.last_seen_at
  FROM users u
  LEFT JOIN patient_profiles pp ON pp.user_id = u.id
  WHERE (u.blood_donation = true OR pp.is_blood_donor = true)
    AND u.is_active = true
    AND u.geog IS NOT NULL
    AND ST_DWithin(u.geog, v_user_point, max_distance_km * 1000)
  ORDER BY distance_km ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =====================================================
-- STEP 5: Fix get_nearby_patients function
-- =====================================================

DROP FUNCTION IF EXISTS get_nearby_patients(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, BOOLEAN, INTEGER);

CREATE OR REPLACE FUNCTION get_nearby_patients(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50,
  blood_donors_only BOOLEAN DEFAULT false,
  result_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  patient_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  phone_number TEXT,
  country TEXT,
  is_blood_donor BOOLEAN,
  blood_type TEXT,
  blood_donor_status TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION,
  last_seen_at TIMESTAMPTZ
) AS $$
DECLARE
  v_user_point geography;
BEGIN
  IF user_lat IS NULL OR user_lng IS NULL THEN
    RAISE EXCEPTION 'Location is required';
  END IF;

  v_user_point := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;

  RETURN QUERY
  SELECT
    u.id as patient_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) as full_name,
    u.profile_picture_url as avatar_url,
    u.phone_number,
    u.country,
    COALESCE(pp.is_blood_donor, u.blood_donation, false) as is_blood_donor,
    pp.blood_type,
    pp.blood_donor_status,
    u.latitude,
    u.longitude,
    ROUND((ST_Distance(u.geog, v_user_point) / 1000.0)::numeric, 2)::double precision as distance_km,
    u.last_seen_at
  FROM users u
  LEFT JOIN patient_profiles pp ON pp.user_id = u.id
  WHERE u.is_active = true
    AND u.geog IS NOT NULL
    AND ST_DWithin(u.geog, v_user_point, max_distance_km * 1000)
    AND (NOT blood_donors_only OR u.blood_donation = true OR pp.is_blood_donor = true)
  ORDER BY distance_km ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =====================================================
-- STEP 6: Grant permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION nearby_places TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_providers TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_blood_donors TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_patients TO authenticated;

-- =====================================================
-- Done!
-- =====================================================
