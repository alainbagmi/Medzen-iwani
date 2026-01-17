SELECT 
  id, 
  appointment_id, 
  provider_id, 
  patient_id,
  status, 
  meeting_id,
  created_at,
  ended_at
FROM video_call_sessions 
ORDER BY created_at DESC 
LIMIT 5;
