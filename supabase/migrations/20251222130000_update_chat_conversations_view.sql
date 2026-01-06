-- Update chat_conversations view with DISTINCT ON and provider_role
DROP VIEW IF EXISTS chat_conversations;
CREATE VIEW chat_conversations AS
SELECT DISTINCT ON (cm.appointment_id)
    cm.appointment_id,
    a.scheduled_start as appointment_date,
    a.status as appointment_status,

    -- Patient info (shown to Provider)
    a.patient_id,
    CONCAT(pu.first_name, ' ', pu.last_name) as patient_name,
    pu.avatar_url as patient_photo,

    -- Provider info (shown to Patient)
    a.provider_id,
    CONCAT(pru.first_name, ' ', pru.last_name) as provider_name,
    pru.avatar_url as provider_photo,
    mp.professional_role as provider_role,

    -- Message stats
    (SELECT COUNT(*) FROM chime_messages WHERE appointment_id = cm.appointment_id) as total_messages,
    (SELECT MAX(created_at) FROM chime_messages WHERE appointment_id = cm.appointment_id) as last_message_at,
    (SELECT message_content FROM chime_messages
     WHERE appointment_id = cm.appointment_id
     ORDER BY created_at DESC LIMIT 1) as last_message_preview

FROM chime_messages cm
JOIN appointments a ON a.id = cm.appointment_id
JOIN users pu ON pu.id = a.patient_id
JOIN users pru ON pru.id = a.provider_id
LEFT JOIN medical_provider_profiles mp ON mp.user_id = a.provider_id
ORDER BY cm.appointment_id, cm.created_at DESC;
