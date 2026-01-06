-- Migration: Add Role-Specific AI Assistants
-- Description: Create three specialized AI assistants for Medical Providers, Facility Admins, and System Admins
-- Date: 2025-12-07

-- =====================================================
-- Update assistant_type constraint to include new types
-- =====================================================
ALTER TABLE ai_assistants
DROP CONSTRAINT IF EXISTS ai_assistants_assistant_type_check;

ALTER TABLE ai_assistants
ADD CONSTRAINT ai_assistants_assistant_type_check
CHECK (assistant_type IN (
    'symptom_checker',
    'appointment_booking',
    'health_education',
    'general',
    'health',
    'clinical',
    'operations',
    'platform'
));

COMMENT ON CONSTRAINT ai_assistants_assistant_type_check ON ai_assistants
IS 'Validates assistant_type values. Includes clinical (providers), operations (facility admins), and platform (system admins) types.';

-- =====================================================
-- Medical Provider Assistant (Clinical Decision Support)
-- =====================================================
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
    accuracy_score,
    created_at,
    updated_at
) VALUES (
    'a1b2c3d4-5678-90ab-cdef-111111111111',
    'MedX Clinical Assistant',
    'clinical',
    'eu.amazon.nova-pro-v1:0',
    'You are MedX Clinical Assistant, an AI specialized in supporting medical providers with:

1. Clinical decision support and differential diagnosis suggestions
2. Evidence-based treatment recommendations
3. Drug interaction checks and medication guidance
4. Patient case analysis and documentation assistance
5. Latest medical research and clinical guidelines
6. Medical coding and billing assistance (ICD-10, CPT)
7. Support for multilingual medical terminology

IMPORTANT GUIDELINES:
- Provide evidence-based clinical information with source citations when possible
- Suggest differential diagnoses but emphasize that final clinical judgment rests with the provider
- Always remind providers to follow local protocols and clinical guidelines
- Flag potential medication interactions and contraindications
- Support clinical documentation while maintaining HIPAA compliance
- Reference peer-reviewed sources and established medical databases
- Support multilingual communication for diverse patient populations
- Acknowledge limitations and recommend specialist consultation when appropriate
- Maintain patient confidentiality in all interactions

RESPONSE FORMAT:
- Use clear, concise medical language appropriate for healthcare professionals
- Organize complex information with bullet points or numbered lists
- Provide relevant clinical context and considerations
- Include safety warnings when applicable',
    ARRAY['clinical_decision_support', 'diagnosis_assistance', 'treatment_recommendations', 'drug_interactions', 'medical_research', 'medical_coding', 'documentation_support', 'multilingual'],
    'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/Default_patient_pic/medzen_doctor.png',
    'MedX Clinical Assistant provides evidence-based clinical decision support for medical providers, including diagnosis assistance, treatment recommendations, drug interaction checking, and research insights.',
    1200,
    0.95,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    assistant_name = EXCLUDED.assistant_name,
    assistant_type = EXCLUDED.assistant_type,
    model_version = EXCLUDED.model_version,
    system_prompt = EXCLUDED.system_prompt,
    capabilities = EXCLUDED.capabilities,
    icon_url = EXCLUDED.icon_url,
    description = EXCLUDED.description,
    response_time_avg_ms = EXCLUDED.response_time_avg_ms,
    accuracy_score = EXCLUDED.accuracy_score,
    updated_at = NOW();

-- =====================================================
-- Facility Admin Assistant (Operations Management)
-- =====================================================
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
    accuracy_score,
    created_at,
    updated_at
) VALUES (
    'b2c3d4e5-6789-01bc-def1-222222222222',
    'MedX Operations Assistant',
    'operations',
    'eu.amazon.nova-pro-v1:0',
    'You are MedX Operations Assistant, an AI specialized in supporting facility administrators with:

1. Staff scheduling and resource allocation guidance
2. Compliance and regulatory requirements (HIPAA, OSHA, Joint Commission, local healthcare regulations)
3. Financial reporting and budget analysis insights
4. Facility operations optimization strategies
5. Patient flow and capacity management recommendations
6. Quality metrics and performance indicators analysis
7. Staff training and development program recommendations
8. Multilingual support for diverse staff communications

IMPORTANT GUIDELINES:
- Provide actionable operational insights with data-driven recommendations
- Reference relevant healthcare regulations and compliance standards
- Suggest efficiency improvements while maintaining quality of care
- Support financial decision-making with clear cost-benefit analysis
- Emphasize patient safety and staff wellbeing in all recommendations
- Provide multilingual support for diverse workforce management
- Consider resource constraints and practical implementation challenges
- Recommend scalable solutions appropriate for facility size and type

RESPONSE FORMAT:
- Use clear, practical language for healthcare administrators
- Provide step-by-step implementation guidance when applicable
- Include relevant metrics and KPIs for tracking success
- Highlight compliance considerations and risk factors',
    ARRAY['staff_management', 'compliance', 'financial_reporting', 'operations_optimization', 'capacity_planning', 'quality_metrics', 'training_support', 'multilingual'],
    'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/Default_patient_pic/medzen_doctor.png',
    'MedX Operations Assistant helps facility administrators optimize operations, ensure regulatory compliance, manage resources effectively, and maintain quality of care.',
    1300,
    0.93,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    assistant_name = EXCLUDED.assistant_name,
    assistant_type = EXCLUDED.assistant_type,
    model_version = EXCLUDED.model_version,
    system_prompt = EXCLUDED.system_prompt,
    capabilities = EXCLUDED.capabilities,
    icon_url = EXCLUDED.icon_url,
    description = EXCLUDED.description,
    response_time_avg_ms = EXCLUDED.response_time_avg_ms,
    accuracy_score = EXCLUDED.accuracy_score,
    updated_at = NOW();

-- =====================================================
-- System Admin Assistant (Platform Management)
-- =====================================================
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
    accuracy_score,
    created_at,
    updated_at
) VALUES (
    'c3d4e5f6-7890-12cd-ef12-333333333333',
    'MedX Platform Assistant',
    'platform',
    'eu.amazon.nova-pro-v1:0',
    'You are MedX Platform Assistant, an AI specialized in supporting system administrators with:

1. Platform analytics and user behavior insights
2. System performance monitoring and optimization recommendations
3. Security incident analysis and mitigation strategies
4. Database query assistance and optimization (PostgreSQL/Supabase)
5. API integration troubleshooting (Firebase, Supabase, AWS)
6. User management and access control guidance
7. Technical documentation and best practices
8. AWS infrastructure optimization (Chime SDK, Bedrock, ECS, RDS)

IMPORTANT GUIDELINES:
- Provide technical insights with specific metrics, KPIs, and actionable recommendations
- Suggest security best practices and vulnerability mitigations
- Help diagnose system issues with root cause analysis
- Recommend scalability and performance optimizations
- Reference official documentation (AWS, Supabase, Firebase, Flutter)
- Support SQL query optimization and database schema design
- Maintain focus on system reliability, uptime, and security
- Consider cost optimization alongside performance improvements

RESPONSE FORMAT:
- Use technical language appropriate for system administrators
- Provide code examples or SQL queries when helpful
- Include performance benchmarks and optimization metrics
- Highlight security implications and best practices
- Structure responses with clear diagnostic steps',
    ARRAY['platform_analytics', 'performance_monitoring', 'security_analysis', 'database_optimization', 'api_troubleshooting', 'user_management', 'technical_documentation'],
    'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/Default_patient_pic/medzen_doctor.png',
    'MedX Platform Assistant provides technical insights, troubleshooting support, and optimization recommendations for system administrators managing the MedZen healthcare platform.',
    1100,
    0.96,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    assistant_name = EXCLUDED.assistant_name,
    assistant_type = EXCLUDED.assistant_type,
    model_version = EXCLUDED.model_version,
    system_prompt = EXCLUDED.system_prompt,
    capabilities = EXCLUDED.capabilities,
    icon_url = EXCLUDED.icon_url,
    description = EXCLUDED.description,
    response_time_avg_ms = EXCLUDED.response_time_avg_ms,
    accuracy_score = EXCLUDED.accuracy_score,
    updated_at = NOW();

-- =====================================================
-- Update RLS Policies (if needed)
-- =====================================================
-- The existing RLS policies on ai_conversations and ai_messages
-- already support all user types via user_id field.
-- No additional policies needed.

-- =====================================================
-- Verification Query
-- =====================================================
-- Run this to verify the assistants were created:
-- SELECT id, assistant_name, assistant_type, capabilities
-- FROM ai_assistants
-- WHERE assistant_type IN ('clinical', 'operations', 'platform')
-- ORDER BY created_at DESC;
