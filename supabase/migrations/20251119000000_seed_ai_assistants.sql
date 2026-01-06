-- Seed AI Assistants table with default MedX Health Assistant
-- This migration ensures the assistant referenced in the app exists

-- First, ensure the ai_assistants table exists
CREATE TABLE IF NOT EXISTS ai_assistants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assistant_name TEXT NOT NULL,
    assistant_type TEXT NOT NULL DEFAULT 'health',
    model_version TEXT NOT NULL DEFAULT 'amazon.nova-pro-v1:0',
    system_prompt TEXT,
    capabilities TEXT[],
    icon_url TEXT,
    description TEXT,
    response_time_avg_ms INTEGER,
    accuracy_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the default MedX Health Assistant
-- Using a specific UUID that matches what's expected in the app
INSERT INTO ai_assistants (
    id,
    assistant_name,
    assistant_type,
    model_version,
    system_prompt,
    capabilities,
    icon_url,
    description,
    response_time_avg_ms,
    accuracy_score
) VALUES (
    'f11201de-09d6-4876-ac62-fd8eb2e44692',
    'MedX Health Assistant',
    'health',
    'eu.amazon.nova-pro-v1:0',
    'You are MedX AI, a friendly and professional healthcare AI assistant for the MedZen health app. Your role is to:

1. Provide accurate health information and guidance
2. Help users understand their symptoms and when to seek medical attention
3. Offer general wellness advice and health tips
4. Answer questions about medications, treatments, and procedures
5. Support users in managing chronic conditions
6. Provide mental health support and coping strategies

IMPORTANT GUIDELINES:
- Always recommend consulting a healthcare professional for serious symptoms
- Never diagnose conditions - only provide information
- Be empathetic and supportive
- Use clear, simple language
- Respect patient privacy and confidentiality
- If unsure, recommend seeing a doctor
- Support multiple languages (detect and respond in user''s language)',
    ARRAY['health_information', 'symptom_guidance', 'wellness_advice', 'medication_info', 'chronic_care', 'mental_health', 'multilingual'],
    'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/Default_patient_pic/medzen_doctor.png',
    'MedX is your AI health companion, providing trusted health information and guidance. Available 24/7 to help you understand symptoms, medications, and wellness tips.',
    1500,
    0.92
) ON CONFLICT (id) DO UPDATE SET
    assistant_name = EXCLUDED.assistant_name,
    model_version = EXCLUDED.model_version,
    system_prompt = EXCLUDED.system_prompt,
    capabilities = EXCLUDED.capabilities,
    description = EXCLUDED.description,
    updated_at = NOW();

-- Create ai_conversations table if it doesn't exist
CREATE TABLE IF NOT EXISTS ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user_id TEXT, -- For compatibility with current implementation
    assistant_id UUID REFERENCES ai_assistants(id) DEFAULT 'f11201de-09d6-4876-ac62-fd8eb2e44692',
    title TEXT,
    status TEXT DEFAULT 'active',
    default_language TEXT DEFAULT 'en',
    total_tokens INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create ai_messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    model_version TEXT,
    confidence_score DECIMAL(3,2),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    language TEXT DEFAULT 'en'
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_conversations_patient_id ON ai_conversations(patient_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_status ON ai_conversations(status);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON ai_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_created_at ON ai_messages(created_at);

-- Enable RLS
ALTER TABLE ai_assistants ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (safe for re-runs)
DROP POLICY IF EXISTS "ai_assistants_select_all" ON ai_assistants;
DROP POLICY IF EXISTS "ai_conversations_select_own" ON ai_conversations;
DROP POLICY IF EXISTS "ai_conversations_insert_own" ON ai_conversations;
DROP POLICY IF EXISTS "ai_conversations_update_own" ON ai_conversations;
DROP POLICY IF EXISTS "ai_messages_select_own" ON ai_messages;
DROP POLICY IF EXISTS "ai_messages_insert_own" ON ai_messages;

-- RLS policies for ai_assistants (public read)
CREATE POLICY "ai_assistants_select_all" ON ai_assistants
    FOR SELECT USING (true);

-- RLS policies for ai_conversations (both user_id and patient_id are UUID)
CREATE POLICY "ai_conversations_select_own" ON ai_conversations
    FOR SELECT USING (
        patient_id = auth.uid() OR
        user_id = auth.uid()
    );

CREATE POLICY "ai_conversations_insert_own" ON ai_conversations
    FOR INSERT WITH CHECK (
        patient_id = auth.uid() OR
        user_id = auth.uid()
    );

CREATE POLICY "ai_conversations_update_own" ON ai_conversations
    FOR UPDATE USING (
        patient_id = auth.uid() OR
        user_id = auth.uid()
    );

-- RLS policies for ai_messages
CREATE POLICY "ai_messages_select_own" ON ai_messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM ai_conversations
            WHERE patient_id = auth.uid() OR user_id = auth.uid()
        )
    );

CREATE POLICY "ai_messages_insert_own" ON ai_messages
    FOR INSERT WITH CHECK (
        conversation_id IN (
            SELECT id FROM ai_conversations
            WHERE patient_id = auth.uid() OR user_id = auth.uid()
        )
    );

-- Grant service role full access for Lambda function
GRANT ALL ON ai_assistants TO service_role;
GRANT ALL ON ai_conversations TO service_role;
GRANT ALL ON ai_messages TO service_role;
