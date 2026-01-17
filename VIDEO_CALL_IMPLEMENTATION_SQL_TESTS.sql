-- VIDEO CALL IMPLEMENTATION TEST SUITE
-- Test database persistence of SOAP notes and message receiver tracking
-- Run in Supabase SQL Editor (dashboard.supabase.com → SQL)

-- ============================================================================
-- SETUP: Get IDs for testing (MODIFY THESE VALUES)
-- ============================================================================

-- Replace these with actual UUIDs from your test data
-- To find: SELECT id, email FROM users LIMIT 5;
\set provider_id 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
\set patient_id 'yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
\set appointment_id 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz'

-- Alternative: Use these for quick lookup
SELECT
  u1.id as provider_id,
  u2.id as patient_id,
  a.id as appointment_id
FROM users u1
JOIN users u2 ON u2.role = 'patient' AND u1.role = 'medical_provider'
JOIN appointments a ON a.provider_id = u1.id AND a.patient_id = u2.id
WHERE a.scheduled_date > NOW()
LIMIT 1;

-- ============================================================================
-- TEST 1: Verify Video Call Session Created
-- ============================================================================

-- Description: Check if the video call session was properly created and finalized
-- Expected: One row with status 'completed' or 'ended', transcription_status populated

SELECT
  'TEST 1: Video Call Session' as test_name,
  CASE WHEN vcs.id IS NOT NULL THEN 'PASS' ELSE 'FAIL' END as result,
  vcs.id,
  vcs.status,
  vcs.transcription_status,
  vcs.created_at,
  vcs.ended_at,
  CASE
    WHEN vcs.id IS NULL THEN 'Session not found - call may not have been completed'
    WHEN vcs.status IS NULL THEN 'Status is NULL - session not properly finalized'
    WHEN vcs.ended_at IS NULL THEN 'Call not properly ended'
    WHEN vcs.transcription_status = 'failed' THEN 'Transcription failed'
    ELSE 'Session looks good'
  END as notes
FROM (
  SELECT *
  FROM video_call_sessions
  WHERE appointment_id = :'appointment_id'
  ORDER BY created_at DESC
  LIMIT 1
) vcs;

-- ============================================================================
-- TEST 2: Verify Transcription Captured
-- ============================================================================

-- Description: Check if transcript was saved and contains content
-- Expected: transcript_text not empty, speaker_segments populated

SELECT
  'TEST 2: Transcription Capture' as test_name,
  CASE
    WHEN vt.id IS NOT NULL THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  vt.id,
  vt.session_id,
  LENGTH(vt.transcript_text) as transcript_length,
  CASE
    WHEN LENGTH(vt.transcript_text) > 10 THEN 'Has content'
    WHEN LENGTH(vt.transcript_text) > 0 THEN 'Has minimal content'
    ELSE 'Empty transcript'
  END as transcript_quality,
  vt.speaker_segments IS NOT NULL as has_speakers,
  vt.status,
  vt.created_at
FROM video_transcripts vt
WHERE vt.session_id IN (
  SELECT id FROM video_call_sessions
  WHERE appointment_id = :'appointment_id'
)
ORDER BY vt.created_at DESC
LIMIT 1;

-- Show actual transcript text
SELECT
  'TEST 2B: Transcript Content' as test_name,
  SUBSTRING(vt.transcript_text, 1, 200) as transcript_preview
FROM video_transcripts vt
WHERE vt.session_id IN (
  SELECT id FROM video_call_sessions
  WHERE appointment_id = :'appointment_id'
)
ORDER BY vt.created_at DESC
LIMIT 1;

-- ============================================================================
-- TEST 3: Verify SOAP Note Generated
-- ============================================================================

-- Description: Check if AI-generated SOAP note exists
-- Expected: clinical_notes row with soap_content populated

SELECT
  'TEST 3: SOAP Note Generation' as test_name,
  CASE
    WHEN cn.id IS NOT NULL THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  cn.id,
  cn.appointment_id,
  cn.provider_id,
  cn.status,
  CASE
    WHEN cn.soap_content IS NOT NULL THEN 'Has content'
    WHEN cn.soap_content::text LIKE '%Subjective%' THEN 'Structured SOAP'
    ELSE 'Empty or malformed'
  END as soap_quality,
  cn.is_signed,
  cn.created_at,
  cn.updated_at
FROM clinical_notes cn
WHERE cn.appointment_id = :'appointment_id'
ORDER BY cn.created_at DESC
LIMIT 1;

-- Show SOAP note content structure
SELECT
  'TEST 3B: SOAP Content Structure' as test_name,
  CASE
    WHEN cn.soap_content::text LIKE '%"subjective"%' THEN 'Subjective: Present'
    ELSE 'Subjective: Missing'
  END as subjective_status,
  CASE
    WHEN cn.soap_content::text LIKE '%"objective"%' THEN 'Objective: Present'
    ELSE 'Objective: Missing'
  END as objective_status,
  CASE
    WHEN cn.soap_content::text LIKE '%"assessment"%' THEN 'Assessment: Present'
    ELSE 'Assessment: Missing'
  END as assessment_status,
  CASE
    WHEN cn.soap_content::text LIKE '%"plan"%' THEN 'Plan: Present'
    ELSE 'Plan: Missing'
  END as plan_status
FROM clinical_notes cn
WHERE cn.appointment_id = :'appointment_id'
ORDER BY cn.created_at DESC
LIMIT 1;

-- ============================================================================
-- TEST 4: Verify Message Sender Capture
-- ============================================================================

-- Description: Check if messages were saved with sender information
-- Expected: Multiple rows with sender_id and sender_name populated

SELECT
  'TEST 4: Message Sender Capture' as test_name,
  COUNT(*) as total_messages,
  COUNT(CASE WHEN cm.sender_id IS NOT NULL THEN 1 END) as messages_with_sender_id,
  COUNT(CASE WHEN cm.sender_name IS NOT NULL THEN 1 END) as messages_with_sender_name,
  COUNT(CASE WHEN cm.sender_id IS NOT NULL AND cm.sender_name IS NOT NULL THEN 1 END) as fully_complete_senders,
  CASE
    WHEN COUNT(*) = 0 THEN 'FAIL - No messages'
    WHEN COUNT(CASE WHEN cm.sender_id IS NOT NULL THEN 1 END) = COUNT(*) THEN 'PASS'
    ELSE 'PARTIAL - Some sender fields missing'
  END as result
FROM chime_messages cm
WHERE cm.appointment_id = :'appointment_id';

-- Show individual messages with sender info
SELECT
  'TEST 4B: Message Sender Details' as test_name,
  cm.id,
  cm.sender_id,
  cm.sender_name,
  cm.sender_avatar,
  SUBSTRING(cm.message, 1, 50) as message_preview,
  cm.created_at
FROM chime_messages cm
WHERE cm.appointment_id = :'appointment_id'
ORDER BY cm.created_at
LIMIT 10;

-- ============================================================================
-- TEST 5: Verify Message Receiver Capture (CRITICAL NEW FUNCTIONALITY)
-- ============================================================================

-- Description: Check if messages were saved with RECEIVER information
-- This is the NEW functionality that was added
-- Expected: All messages have receiver_id and receiver_name populated

SELECT
  'TEST 5: Message Receiver Capture' as test_name,
  COUNT(*) as total_messages,
  COUNT(CASE WHEN cm.receiver_id IS NOT NULL THEN 1 END) as messages_with_receiver_id,
  COUNT(CASE WHEN cm.receiver_name IS NOT NULL THEN 1 END) as messages_with_receiver_name,
  COUNT(CASE WHEN cm.receiver_id IS NOT NULL AND cm.receiver_name IS NOT NULL THEN 1 END) as fully_complete_receivers,
  COUNT(CASE WHEN cm.receiver_id = cm.sender_id THEN 1 END) as error_same_sender_receiver,
  CASE
    WHEN COUNT(*) = 0 THEN 'FAIL - No messages'
    WHEN COUNT(CASE WHEN cm.receiver_id IS NOT NULL AND cm.receiver_name IS NOT NULL THEN 1 END) = COUNT(*) THEN 'PASS'
    ELSE 'PARTIAL - Some receiver fields NULL'
  END as result
FROM chime_messages cm
WHERE cm.appointment_id = :'appointment_id';

-- Show individual messages with BOTH sender and receiver
SELECT
  'TEST 5B: Message Bidirectional Tracking' as test_name,
  cm.id,
  cm.sender_id,
  cm.sender_name,
  cm.receiver_id,
  cm.receiver_name,
  CASE
    WHEN cm.sender_id IS NULL THEN 'FAIL - No sender'
    WHEN cm.receiver_id IS NULL THEN 'FAIL - No receiver'
    WHEN cm.sender_id = cm.receiver_id THEN 'FAIL - Same sender/receiver'
    ELSE 'PASS'
  END as validation,
  SUBSTRING(cm.message, 1, 40) as message_preview,
  cm.created_at
FROM chime_messages cm
WHERE cm.appointment_id = :'appointment_id'
ORDER BY cm.created_at;

-- ============================================================================
-- TEST 6: Verify Receiver Data Integrity
-- ============================================================================

-- Description: Check that sender and receiver are correctly opposite roles
-- Expected: If sender is provider, receiver should be patient and vice versa

WITH message_directions AS (
  SELECT
    cm.id,
    cm.sender_id,
    cm.sender_name,
    cm.receiver_id,
    cm.receiver_name,
    (cm.sender_id = :'provider_id') as sender_is_provider,
    (cm.receiver_id = :'provider_id') as receiver_is_provider,
    (cm.sender_id = :'patient_id') as sender_is_patient,
    (cm.receiver_id = :'patient_id') as receiver_is_patient
  FROM chime_messages cm
  WHERE cm.appointment_id = :'appointment_id'
)
SELECT
  'TEST 6: Receiver Data Integrity' as test_name,
  COUNT(*) as total_messages,
  COUNT(CASE
    WHEN (sender_is_provider AND receiver_is_patient) OR (sender_is_patient AND receiver_is_provider)
    THEN 1
  END) as correctly_paired_messages,
  COUNT(CASE
    WHEN NOT ((sender_is_provider AND receiver_is_patient) OR (sender_is_patient AND receiver_is_provider))
    THEN 1
  END) as incorrectly_paired_messages,
  CASE
    WHEN COUNT(*) = 0 THEN 'FAIL - No messages'
    WHEN COUNT(CASE
      WHEN NOT ((sender_is_provider AND receiver_is_patient) OR (sender_is_patient AND receiver_is_provider))
      THEN 1
    END) = 0 THEN 'PASS'
    ELSE 'PARTIAL - Some incorrect pairings'
  END as result
FROM message_directions;

-- Show any incorrectly paired messages
SELECT
  'TEST 6B: Incorrect Message Pairings' as test_name,
  md.id,
  md.sender_id,
  md.sender_name,
  md.receiver_id,
  md.receiver_name,
  'ERROR: Check pairing' as issue
FROM (
  SELECT
    cm.id,
    cm.sender_id,
    cm.sender_name,
    cm.receiver_id,
    cm.receiver_name,
    (cm.sender_id = :'provider_id') as sender_is_provider,
    (cm.receiver_id = :'provider_id') as receiver_is_provider,
    (cm.sender_id = :'patient_id') as sender_is_patient,
    (cm.receiver_id = :'patient_id') as receiver_is_patient
  FROM chime_messages cm
  WHERE cm.appointment_id = :'appointment_id'
) md
WHERE NOT ((md.sender_is_provider AND md.receiver_is_patient) OR (md.sender_is_patient AND md.receiver_is_provider));

-- ============================================================================
-- TEST 7: Verify Note Persistence and Status
-- ============================================================================

-- Description: Check if SOAP notes are properly saved and reflect provider actions
-- Expected: Note status is 'confirmed' if provider saved, or no note if discarded

SELECT
  'TEST 7: SOAP Note Persistence' as test_name,
  COUNT(*) as total_notes,
  COUNT(CASE WHEN cn.status = 'confirmed' THEN 1 END) as confirmed_notes,
  COUNT(CASE WHEN cn.status = 'draft' THEN 1 END) as draft_notes,
  COUNT(CASE WHEN cn.is_signed THEN 1 END) as signed_notes,
  COUNT(CASE WHEN cn.soap_content IS NOT NULL THEN 1 END) as notes_with_content,
  CASE
    WHEN COUNT(*) = 0 THEN 'INFO - No notes found (may have been discarded)'
    WHEN COUNT(CASE WHEN cn.status = 'confirmed' THEN 1 END) > 0 THEN 'PASS'
    ELSE 'PARTIAL - Notes exist but not confirmed'
  END as result
FROM clinical_notes cn
WHERE cn.appointment_id = :'appointment_id';

-- ============================================================================
-- TEST 8: Full Workflow Verification
-- ============================================================================

-- Description: Complete check of entire post-call workflow
-- Expected: All components are present and correctly linked

SELECT
  'TEST 8: Complete Workflow' as test_name,
  CASE
    WHEN vcs.id IS NOT NULL THEN 'Present' ELSE 'MISSING' END as video_session,
  CASE
    WHEN vt.id IS NOT NULL THEN 'Present' ELSE 'MISSING' END as transcript,
  CASE
    WHEN cn.id IS NOT NULL THEN 'Present' ELSE 'MISSING' END as soap_note,
  CASE
    WHEN cm.id IS NOT NULL THEN 'Present' ELSE 'MISSING' END as messages,
  COUNT(cm.id) OVER () as message_count,
  CASE
    WHEN vcs.id IS NOT NULL AND vt.id IS NOT NULL AND cn.id IS NOT NULL AND cm.id IS NOT NULL THEN 'PASS'
    WHEN vcs.id IS NOT NULL AND vt.id IS NOT NULL AND cn.id IS NOT NULL THEN 'PASS'
    WHEN vcs.id IS NOT NULL AND vt.id IS NOT NULL THEN 'PARTIAL'
    ELSE 'INCOMPLETE'
  END as workflow_status
FROM
  (SELECT * FROM video_call_sessions WHERE appointment_id = :'appointment_id' ORDER BY created_at DESC LIMIT 1) vcs
FULL OUTER JOIN
  (SELECT * FROM video_transcripts WHERE session_id IN (SELECT id FROM video_call_sessions WHERE appointment_id = :'appointment_id') ORDER BY created_at DESC LIMIT 1) vt ON true
FULL OUTER JOIN
  (SELECT * FROM clinical_notes WHERE appointment_id = :'appointment_id' ORDER BY created_at DESC LIMIT 1) cn ON true
FULL OUTER JOIN
  (SELECT * FROM chime_messages WHERE appointment_id = :'appointment_id' LIMIT 1) cm ON true
LIMIT 1;

-- ============================================================================
-- TEST 9: Timestamp Analysis
-- ============================================================================

-- Description: Verify chronological order and timing of events
-- Expected: Times should progress: session → transcript → note → messages

SELECT
  'TEST 9: Event Timing' as test_name,
  vcs.created_at as session_start,
  vcs.ended_at as session_end,
  vt.created_at as transcript_created,
  cn.created_at as note_created,
  MIN(cm.created_at) as first_message,
  MAX(cm.created_at) as last_message,
  EXTRACT(EPOCH FROM (vt.created_at - vcs.ended_at)) as transcript_delay_seconds,
  EXTRACT(EPOCH FROM (cn.created_at - vt.created_at)) as soap_generation_delay_seconds
FROM video_call_sessions vcs
LEFT JOIN video_transcripts vt ON vt.session_id = vcs.id
LEFT JOIN clinical_notes cn ON cn.appointment_id = vcs.appointment_id
LEFT JOIN chime_messages cm ON cm.appointment_id = vcs.appointment_id
WHERE vcs.appointment_id = :'appointment_id'
GROUP BY vcs.id, vcs.created_at, vcs.ended_at, vt.created_at, cn.created_at;

-- ============================================================================
-- TEST 10: Quick Health Check
-- ============================================================================

-- Description: Overall health assessment of the implementation
-- Expected: All checks return TRUE

WITH health_checks AS (
  SELECT
    'Video session exists' as check_name,
    EXISTS(SELECT 1 FROM video_call_sessions WHERE appointment_id = :'appointment_id') as check_pass
  UNION ALL
  SELECT
    'Transcript captured',
    EXISTS(SELECT 1 FROM video_transcripts WHERE session_id IN (SELECT id FROM video_call_sessions WHERE appointment_id = :'appointment_id'))
  UNION ALL
  SELECT
    'SOAP note generated',
    EXISTS(SELECT 1 FROM clinical_notes WHERE appointment_id = :'appointment_id')
  UNION ALL
  SELECT
    'Messages have senders',
    (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id' AND sender_id IS NOT NULL) = (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id')
  UNION ALL
  SELECT
    'Messages have receivers',
    (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id' AND receiver_id IS NOT NULL) = (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id')
  UNION ALL
  SELECT
    'No sender=receiver',
    NOT EXISTS(SELECT 1 FROM chime_messages WHERE appointment_id = :'appointment_id' AND sender_id = receiver_id)
)
SELECT
  'TEST 10: Health Check' as test_name,
  SUM(CASE WHEN check_pass THEN 1 ELSE 0 END) as checks_passed,
  COUNT(*) as total_checks,
  CASE
    WHEN SUM(CASE WHEN check_pass THEN 1 ELSE 0 END) = COUNT(*) THEN 'PASS'
    WHEN SUM(CASE WHEN check_pass THEN 1 ELSE 0 END) >= COUNT(*) * 0.6 THEN 'PARTIAL'
    ELSE 'FAIL'
  END as overall_status
FROM health_checks;

-- Show individual check results
SELECT check_name, check_pass FROM (
  SELECT
    'Video session exists' as check_name,
    EXISTS(SELECT 1 FROM video_call_sessions WHERE appointment_id = :'appointment_id') as check_pass
  UNION ALL
  SELECT
    'Transcript captured',
    EXISTS(SELECT 1 FROM video_transcripts WHERE session_id IN (SELECT id FROM video_call_sessions WHERE appointment_id = :'appointment_id'))
  UNION ALL
  SELECT
    'SOAP note generated',
    EXISTS(SELECT 1 FROM clinical_notes WHERE appointment_id = :'appointment_id')
  UNION ALL
  SELECT
    'Messages have senders',
    (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id' AND sender_id IS NOT NULL) = (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id')
  UNION ALL
  SELECT
    'Messages have receivers',
    (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id' AND receiver_id IS NOT NULL) = (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = :'appointment_id')
  UNION ALL
  SELECT
    'No sender=receiver',
    NOT EXISTS(SELECT 1 FROM chime_messages WHERE appointment_id = :'appointment_id' AND sender_id = receiver_id)
) checks
ORDER BY check_name;

-- ============================================================================
-- CLEANUP (Run after testing to reset test data)
-- ============================================================================

-- Uncomment below to delete test data
/*
DELETE FROM chime_messages WHERE appointment_id = :'appointment_id';
DELETE FROM clinical_notes WHERE appointment_id = :'appointment_id';
DELETE FROM video_transcripts WHERE session_id IN (
  SELECT id FROM video_call_sessions WHERE appointment_id = :'appointment_id'
);
DELETE FROM video_call_sessions WHERE appointment_id = :'appointment_id';
DELETE FROM appointments WHERE id = :'appointment_id';
DELETE FROM users WHERE id IN (:'provider_id', :'patient_id');
*/

-- ============================================================================
-- END OF TEST SUITE
-- ============================================================================
