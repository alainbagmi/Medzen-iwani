-- Fix medical_practitioners_details_view to use the same providerid as medical_practitioners_view
-- The medical_practitioners_view uses medical_provider_profiles.id as providerid
-- The medical_practitioners_details_view was using medical_provider_profiles.user_id as providerid
-- This caused a mismatch where clicking a provider from the list couldn't find the detail

-- First, let's check what medical_practitioners_view uses and align details view to match

-- Drop and recreate medical_practitioners_details_view with correct providerid
DROP VIEW IF EXISTS medical_practitioners_details_view CASCADE;

CREATE VIEW medical_practitioners_details_view WITH (security_invoker = false) AS
SELECT
    u.profile_picture_url AS picture,
    u.full_name AS name,
    mp.primary_specialization AS specialization,
    mp.years_of_experience AS experience,
    mp.consultation_fee AS fees,
    COALESCE(avg_reviews.avg_rating, 0::numeric) AS rating,
    COALESCE(consults.total_consultations, 0::bigint) AS number_of_consultations,
    mp.id AS providerid,  -- Changed from mp.user_id to mp.id to match medical_practitioners_view
    up.bio
FROM medical_provider_profiles mp
JOIN users u ON u.id = mp.user_id
LEFT JOIN user_profiles up ON up.user_id = mp.user_id
LEFT JOIN (
    SELECT
        reviewed_entity_id,
        AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY reviewed_entity_id
) avg_reviews ON avg_reviews.reviewed_entity_id = mp.id  -- Also use mp.id here for consistency
LEFT JOIN (
    SELECT
        provider_id,
        COUNT(*) AS total_consultations
    FROM appointments
    GROUP BY provider_id
) consults ON consults.provider_id = mp.id  -- Also use mp.id here for consistency
WHERE mp.application_status = 'approved';  -- Only show approved providers

-- Grant permissions
GRANT SELECT ON medical_practitioners_details_view TO anon;
GRANT SELECT ON medical_practitioners_details_view TO authenticated;
GRANT SELECT ON medical_practitioners_details_view TO service_role;

COMMENT ON VIEW medical_practitioners_details_view IS 'Detailed view of approved medical practitioners for patient booking. Uses mp.id as providerid to match medical_practitioners_view.';
