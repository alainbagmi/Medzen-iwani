-- Migration: Create Amazon Chime Messaging tables
-- These tables support HIPAA-compliant messaging for telehealth consultations
-- Used by the chime-messaging Supabase edge function

-- ============================================================================
-- Table: chime_messaging_channels
-- Stores Chime SDK messaging channel information for provider-patient communication
-- ============================================================================
CREATE TABLE IF NOT EXISTS chime_messaging_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Channel identification
    channel_arn TEXT NOT NULL UNIQUE,
    channel_name VARCHAR(255) NOT NULL,

    -- Participants
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,

    -- Channel metadata
    channel_mode VARCHAR(50) DEFAULT 'RESTRICTED',
    privacy VARCHAR(50) DEFAULT 'PRIVATE',

    -- Status
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ,

    -- Constraints
    CONSTRAINT unique_channel_participants UNIQUE (provider_id, patient_id, appointment_id)
);

-- Indexes for chime_messaging_channels
CREATE INDEX IF NOT EXISTS idx_chime_channels_provider ON chime_messaging_channels(provider_id);
CREATE INDEX IF NOT EXISTS idx_chime_channels_patient ON chime_messaging_channels(patient_id);
CREATE INDEX IF NOT EXISTS idx_chime_channels_appointment ON chime_messaging_channels(appointment_id);
CREATE INDEX IF NOT EXISTS idx_chime_channels_status ON chime_messaging_channels(status);
CREATE INDEX IF NOT EXISTS idx_chime_channels_arn ON chime_messaging_channels(channel_arn);

-- Enable RLS
ALTER TABLE chime_messaging_channels ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chime_messaging_channels
-- Users can only see channels they are part of
CREATE POLICY "Users can view own channels" ON chime_messaging_channels
    FOR SELECT USING (
        auth.uid() = provider_id OR auth.uid() = patient_id
    );

-- Only authenticated users can create channels (through edge function)
CREATE POLICY "Authenticated users can create channels" ON chime_messaging_channels
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated'
    );

-- Users can update their own channels
CREATE POLICY "Users can update own channels" ON chime_messaging_channels
    FOR UPDATE USING (
        auth.uid() = provider_id OR auth.uid() = patient_id
    );

-- ============================================================================
-- Table: chime_message_audit
-- HIPAA-compliant audit log for all messaging activities
-- ============================================================================
CREATE TABLE IF NOT EXISTS chime_message_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference to channel
    channel_id UUID NOT NULL REFERENCES chime_messaging_channels(id) ON DELETE CASCADE,
    channel_arn TEXT NOT NULL,

    -- Message identification
    message_id VARCHAR(255),

    -- Actor information
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_role VARCHAR(50) NOT NULL CHECK (user_role IN ('provider', 'patient', 'system')),

    -- Action details
    action_type VARCHAR(100) NOT NULL CHECK (action_type IN (
        'channel_created',
        'channel_archived',
        'channel_deleted',
        'message_sent',
        'message_read',
        'message_deleted',
        'member_added',
        'member_removed',
        'typing_indicator'
    )),

    -- Audit metadata (no PHI stored here, just metadata)
    metadata JSONB DEFAULT '{}',

    -- Network/client information for audit trail
    ip_address INET,
    user_agent TEXT,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for chime_message_audit
CREATE INDEX IF NOT EXISTS idx_chime_audit_channel ON chime_message_audit(channel_id);
CREATE INDEX IF NOT EXISTS idx_chime_audit_user ON chime_message_audit(user_id);
CREATE INDEX IF NOT EXISTS idx_chime_audit_action ON chime_message_audit(action_type);
CREATE INDEX IF NOT EXISTS idx_chime_audit_created ON chime_message_audit(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chime_audit_channel_arn ON chime_message_audit(channel_arn);

-- Enable RLS
ALTER TABLE chime_message_audit ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chime_message_audit
-- Users can view audit logs for channels they're part of
CREATE POLICY "Users can view audit for own channels" ON chime_message_audit
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chime_messaging_channels c
            WHERE c.id = chime_message_audit.channel_id
            AND (c.provider_id = auth.uid() OR c.patient_id = auth.uid())
        )
    );

-- Only system/edge functions can insert audit logs
CREATE POLICY "System can insert audit logs" ON chime_message_audit
    FOR INSERT WITH CHECK (
        auth.role() = 'service_role' OR auth.role() = 'authenticated'
    );

-- ============================================================================
-- Trigger: Update updated_at on chime_messaging_channels
-- ============================================================================
CREATE OR REPLACE FUNCTION update_chime_channel_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chime_channel_timestamp
    BEFORE UPDATE ON chime_messaging_channels
    FOR EACH ROW
    EXECUTE FUNCTION update_chime_channel_updated_at();

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON TABLE chime_messaging_channels IS 'Amazon Chime SDK messaging channels for HIPAA-compliant telehealth communication';
COMMENT ON TABLE chime_message_audit IS 'HIPAA-compliant audit log for all Chime messaging activities';

COMMENT ON COLUMN chime_messaging_channels.channel_arn IS 'Amazon Chime channel ARN';
COMMENT ON COLUMN chime_messaging_channels.channel_mode IS 'Channel mode: RESTRICTED (only admins send) or UNRESTRICTED (all members)';
COMMENT ON COLUMN chime_messaging_channels.privacy IS 'Channel privacy: PRIVATE or PUBLIC';

COMMENT ON COLUMN chime_message_audit.metadata IS 'Non-PHI metadata about the action (timestamps, counts, etc.)';
COMMENT ON COLUMN chime_message_audit.ip_address IS 'Client IP for audit trail compliance';
COMMENT ON COLUMN chime_message_audit.user_agent IS 'Client user agent for audit trail compliance';

