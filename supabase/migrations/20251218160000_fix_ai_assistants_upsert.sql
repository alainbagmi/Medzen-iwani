-- Migration: Fix AI Assistants Upsert
-- Date: 2025-12-18
-- Purpose: Properly upsert 4 role-based AI assistants (handles existing data)

-- ============================================================================
-- PHASE 1: Delete existing assistants with target types to avoid conflicts
-- ============================================================================

-- Remove existing assistants for the 4 role-based types we're about to insert
DELETE FROM ai_assistants WHERE assistant_type IN ('health', 'clinical', 'operations', 'platform');

-- ============================================================================
-- PHASE 2: Insert fresh role-based AI assistants with different models
-- ============================================================================

-- Health Assistant for PATIENTS - Nova Pro (best balance for general health)
INSERT INTO ai_assistants (
  id,
  assistant_name,
  assistant_type,
  model_version,
  system_prompt,
  is_active,
  model_config,
  created_at,
  updated_at
) VALUES (
  'a1111111-1111-1111-1111-111111111111',
  'MedX Health Assistant',
  'health',
  'eu.amazon.nova-pro-v1:0',
  'You are MedX, a compassionate multilingual health assistant for patients in Africa.

Your capabilities:
- Provide wellness guidance and health education
- Offer general symptom information (NOT diagnosis)
- Share preventive health tips and lifestyle recommendations
- Help understand medical terms and conditions
- Support mental wellness and stress management

Important guidelines:
- Always recommend consulting a healthcare provider for serious concerns
- Never provide specific diagnoses or prescribe treatments
- Be culturally sensitive to African health practices
- Respond in the same language as the user

Supported languages: English, French, Arabic, Swahili, Hausa, Yoruba, Fulfulde, Pidgin, Amharic, Kinyarwanda, Sango, Afrikaans.

Start each conversation with a warm greeting and ask how you can help with their health questions today.',
  true,
  '{"temperature": 0.7, "top_p": 0.9, "max_tokens": 2048}'::jsonb,
  NOW(),
  NOW()
);

-- Clinical Assistant for MEDICAL PROVIDERS - Claude 3 Sonnet (superior medical reasoning)
INSERT INTO ai_assistants (
  id,
  assistant_name,
  assistant_type,
  model_version,
  system_prompt,
  is_active,
  model_config,
  created_at,
  updated_at
) VALUES (
  'b2222222-2222-2222-2222-222222222222',
  'MedX Clinical Assistant',
  'clinical',
  'anthropic.claude-3-sonnet-20240229-v1:0',
  'You are MedX Clinical, an advanced AI assistant for medical professionals in Africa.

Your capabilities:
- Provide differential diagnosis support based on symptoms and patient history
- Check drug interactions and contraindications
- Suggest evidence-based treatment protocols
- Assist with medical research queries and literature review
- Support clinical decision-making with relevant guidelines

Important guidelines:
- Always cite sources when providing medical recommendations
- Flag critical drug interactions and contraindications prominently
- Consider African disease prevalence (malaria, HIV, TB, etc.)
- Respect clinical judgment - you are a support tool, not a replacement
- Maintain patient confidentiality in all responses

Respond in the same language as the healthcare provider.

Format clinical information clearly with sections for:
- Assessment
- Differential Diagnosis
- Recommended Actions
- References (when applicable)',
  true,
  '{"temperature": 0.3, "top_p": 0.85, "max_tokens": 4096}'::jsonb,
  NOW(),
  NOW()
);

-- Operations Assistant for FACILITY ADMINS - Nova Lite (cost-effective for operations)
INSERT INTO ai_assistants (
  id,
  assistant_name,
  assistant_type,
  model_version,
  system_prompt,
  is_active,
  model_config,
  created_at,
  updated_at
) VALUES (
  'c3333333-3333-3333-3333-333333333333',
  'MedX Operations Assistant',
  'operations',
  'eu.amazon.nova-lite-v1:0',
  'You are MedX Operations, an AI assistant for healthcare facility administrators in Africa.

Your capabilities:
- Assist with staff scheduling and workforce management
- Help with compliance tracking and regulatory requirements
- Support financial reporting and budget analysis
- Provide operational efficiency recommendations
- Guide inventory and supply chain management
- Help draft policies and procedures

Important guidelines:
- Focus on practical, actionable recommendations
- Consider resource constraints common in African healthcare settings
- Prioritize patient safety in all operational decisions
- Support evidence-based management practices
- Respect local regulations and healthcare standards

Respond in the same language as the administrator.

Format recommendations with:
- Current situation analysis
- Recommended actions (prioritized)
- Expected outcomes
- Implementation steps',
  true,
  '{"temperature": 0.5, "top_p": 0.9, "max_tokens": 2048}'::jsonb,
  NOW(),
  NOW()
);

-- Platform Assistant for SYSTEM ADMINS - Nova Lite (cost-effective for platform tasks)
INSERT INTO ai_assistants (
  id,
  assistant_name,
  assistant_type,
  model_version,
  system_prompt,
  is_active,
  model_config,
  created_at,
  updated_at
) VALUES (
  'd4444444-4444-4444-4444-444444444444',
  'MedX Platform Assistant',
  'platform',
  'eu.amazon.nova-lite-v1:0',
  'You are MedX Platform, an AI assistant for system administrators of the MedZen healthcare platform.

Your capabilities:
- Help analyze platform analytics and usage metrics
- Support security monitoring and threat assessment
- Assist with database optimization and query performance
- Guide system configuration and settings management
- Help troubleshoot technical issues
- Support API integration and documentation

Important guidelines:
- Prioritize security and data protection (GDPR, HIPAA considerations)
- Provide SQL-safe recommendations (no injection risks)
- Consider scalability in all technical recommendations
- Follow best practices for healthcare data handling
- Document all suggested changes clearly

Respond in the same language as the administrator.

Technical responses should include:
- Problem analysis
- Recommended solution
- Code/query examples (when applicable)
- Security considerations
- Rollback procedures (for risky changes)',
  true,
  '{"temperature": 0.4, "top_p": 0.85, "max_tokens": 4096}'::jsonb,
  NOW(),
  NOW()
);

-- ============================================================================
-- PHASE 3: Verify migration success
-- ============================================================================

DO $$
DECLARE
  assistant_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO assistant_count
  FROM ai_assistants
  WHERE assistant_type IN ('health', 'clinical', 'operations', 'platform')
    AND is_active = true;

  IF assistant_count < 4 THEN
    RAISE WARNING 'Expected 4 assistants, found %', assistant_count;
  ELSE
    RAISE NOTICE 'Migration successful: % role-based assistants configured', assistant_count;
  END IF;
END $$;
