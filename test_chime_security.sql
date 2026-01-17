-- Test script: Verify chime_messages security
-- Run this to verify the RPC function blocks unauthorized access

-- Step 1: Find a real appointment with messages
SELECT
    a.id as appointment_id,
    a.patient_id,
    mpp.user_id as provider_user_id,
    COUNT(cm.id) as message_count
FROM appointments a
LEFT JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
LEFT JOIN chime_messages cm ON cm.appointment_id = a.id
WHERE cm.id IS NOT NULL
GROUP BY a.id, a.patient_id, mpp.user_id
LIMIT 1;

-- Step 2: Test legitimate access (patient)
-- Replace UUIDs with values from Step 1
DO $$
DECLARE
    test_appointment_id UUID := 'YOUR-APPOINTMENT-ID-FROM-STEP-1';
    test_patient_id UUID := 'YOUR-PATIENT-ID-FROM-STEP-1';
    message_count INTEGER;
BEGIN
    -- Try to get messages as patient (should succeed)
    SELECT COUNT(*) INTO message_count
    FROM get_appointment_messages(test_appointment_id, test_patient_id);

    RAISE NOTICE '✅ Patient can access messages: % messages found', message_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Patient access failed: %', SQLERRM;
END $$;

-- Step 3: Test legitimate access (provider)
-- Replace UUIDs with values from Step 1
DO $$
DECLARE
    test_appointment_id UUID := 'YOUR-APPOINTMENT-ID-FROM-STEP-1';
    test_provider_id UUID := 'YOUR-PROVIDER-USER-ID-FROM-STEP-1';
    message_count INTEGER;
BEGIN
    -- Try to get messages as provider (should succeed)
    SELECT COUNT(*) INTO message_count
    FROM get_appointment_messages(test_appointment_id, test_provider_id);

    RAISE NOTICE '✅ Provider can access messages: % messages found', message_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Provider access failed: %', SQLERRM;
END $$;

-- Step 4: Test unauthorized access (random user)
-- Replace UUIDs with values from Step 1
DO $$
DECLARE
    test_appointment_id UUID := 'YOUR-APPOINTMENT-ID-FROM-STEP-1';
    fake_user_id UUID := gen_random_uuid(); -- Random UUID (not a participant)
    message_count INTEGER;
BEGIN
    -- Try to get messages as non-participant (should fail)
    SELECT COUNT(*) INTO message_count
    FROM get_appointment_messages(test_appointment_id, fake_user_id);

    RAISE NOTICE '❌ SECURITY BREACH: Unauthorized user accessed % messages', message_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '✅ Unauthorized access blocked correctly: %', SQLERRM;
END $$;

-- Step 5: Verify policies exist
SELECT
    policyname,
    cmd,
    roles::text[] as roles
FROM pg_policies
WHERE tablename = 'chime_messages'
ORDER BY policyname;

-- Expected results:
-- ✅ chime_messages_insert_validated | INSERT | {authenticated,anon}
-- ✅ chime_messages_select_participants | SELECT | {authenticated,anon}
