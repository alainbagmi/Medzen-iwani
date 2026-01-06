# Medical Transcribe Implementation Plan

## Overview

Implement multi-language transcription for MedZen video calls with clinical note generation and OpenEHR upload capabilities.

**Target Languages:**
1. ✅ English (AWS Transcribe Medical)
2. ✅ French (AWS Transcribe Medical)
3. 🔄 Fulfulde (OpenAI Whisper)
4. 🔄 Pidgin English - Nigerian/Cameroonian (OpenAI Whisper)
5. 🔄 Central African Languages - Lingala, Sango, etc. (OpenAI Whisper)

## Hybrid Transcription Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Video Call Recording                          │
│                         (S3 Upload)                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  Language Detection   │
              │   (Auto or Manual)    │
              └───────────┬───────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ AWS Transcribe  │ │ AWS Transcribe  │ │ OpenAI Whisper  │
│    Medical      │ │   Standard      │ │      API        │
│  (English)      │ │   (French)      │ │ (African langs) │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ AWS Comprehend  │ │ AWS Comprehend  │ │ Bedrock Claude  │
│    Medical      │ │    Medical      │ │ Entity Extract  │
│ (Entity Extrac) │ │ (Entity Extrac) │ │ (African langs) │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
                             ▼
              ┌───────────────────────┐
              │  Unified Transcript   │
              │    + Medical Entities │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  AI Clinical Note     │
              │  (Bedrock Claude)     │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   OpenEHR/EHRbase     │
              │   Clinical Document   │
              └───────────────────────┘
```

### Language Router Decision Matrix

| Detected Language | Transcription Service | Entity Extraction |
|-------------------|----------------------|-------------------|
| English (en-*) | AWS Transcribe Medical | AWS Comprehend Medical |
| French (fr-*) | AWS Transcribe Standard | AWS Comprehend Medical |
| Fulfulde (ff) | OpenAI Whisper | Bedrock Claude |
| Pidgin English (pcm) | OpenAI Whisper | Bedrock Claude |
| Lingala (ln) | OpenAI Whisper | Bedrock Claude |
| Sango (sg) | OpenAI Whisper | Bedrock Claude |
| Other African | OpenAI Whisper | Bedrock Claude |

## Current State Analysis

### Already Implemented
1. **AWS Lambda Infrastructure** (`aws-deployment/cloudformation/chime-sdk-multi-region.yaml`)
   - `medzen-recording-handler` - Python Lambda that triggers transcription on S3 upload
   - `medzen-transcription-processor` - Node.js Lambda that processes transcripts and extracts medical entities
   - IAM roles with Transcribe, Transcribe Medical, and Comprehend Medical permissions

2. **S3 Buckets** (eu-west-1)
   - `medzen-meeting-recordings-558069890522` - Raw recordings
   - `medzen-meeting-transcripts-558069890522` - Transcript JSON files
   - `medzen-medical-data-558069890522` - Medical entity extraction results

3. **Edge Functions**
   - `chime-meeting-token` - Has `transcriptionEnabled` parameter in meeting creation
   - `chime-transcription-callback` - Webhook for transcription completion events
   - `chime-recording-callback` - Webhook for recording upload events

4. **Database Columns** (`video_call_sessions`)
   - `transcription_enabled`, `transcript_language`, `auto_language_detect`
   - `transcript_text`, `transcript_segments`, `medical_entities`
   - `recording_url`, `transcript_url`

### Gaps to Address
1. **Medical Transcribe vs Standard Transcribe** - Need to ensure Medical Transcribe is used for English consultations
2. **Provider Transcript UI** - No UI for providers to view/edit transcripts
3. **Clinical Note Generation** - No AI-assisted note generation from transcripts
4. **OpenEHR Integration** - No upload of clinical notes to EHRbase
5. **Real-time Live Captions** - Optional enhancement for live transcription during calls

---

## Implementation Steps

### Phase 0: Multi-Language Transcription Router

#### Step 0.1: Create Language Router Lambda
**File**: `aws-lambda/transcription-router/index.py`

```python
import boto3
import os
import json
import requests

# Language codes supported by each service
AWS_TRANSCRIBE_MEDICAL_LANGUAGES = ['en-US', 'en-GB', 'en-AU', 'en-IN']
AWS_TRANSCRIBE_STANDARD_LANGUAGES = ['fr-FR', 'fr-CA']
WHISPER_LANGUAGES = ['ff', 'pcm', 'ln', 'sg', 'wo', 'tw', 'bm', 'ha', 'yo', 'ig']

# Fulfulde ISO codes: ff, fub, fuc, fue, fuf, fuh, fuq, fuv
FULFULDE_VARIANTS = ['ff', 'fub', 'fuc', 'fue', 'fuf', 'fuh', 'fuq', 'fuv', 'ful']

def detect_language(audio_s3_uri):
    """Auto-detect language using Whisper's language detection"""
    # Download first 30 seconds for detection
    # Call OpenAI Whisper with detect_language=True
    pass

def route_transcription(event, context):
    """Route transcription to appropriate service based on language"""

    s3_uri = event['s3_uri']
    language_code = event.get('language_code', 'auto')
    appointment_id = event['appointment_id']

    # Auto-detect if not specified
    if language_code == 'auto':
        language_code = detect_language(s3_uri)

    # Route based on language
    if language_code.startswith('en'):
        return transcribe_with_aws_medical(s3_uri, language_code, appointment_id)
    elif language_code.startswith('fr'):
        return transcribe_with_aws_standard(s3_uri, language_code, appointment_id)
    elif language_code in FULFULDE_VARIANTS or language_code in WHISPER_LANGUAGES:
        return transcribe_with_whisper(s3_uri, language_code, appointment_id)
    else:
        # Default to Whisper for unknown African languages
        return transcribe_with_whisper(s3_uri, language_code, appointment_id)

def transcribe_with_aws_medical(s3_uri, language_code, appointment_id):
    """Use AWS Transcribe Medical for English"""
    transcribe = boto3.client('transcribe', region_name='eu-central-1')

    job_name = f"medzen-medical-{appointment_id}"

    transcribe.start_medical_transcription_job(
        MedicalTranscriptionJobName=job_name,
        LanguageCode=language_code,
        MediaFormat='mp4',
        Media={'MediaFileUri': s3_uri},
        OutputBucketName=os.environ['TRANSCRIPTS_BUCKET'],
        Specialty='PRIMARYCARE',
        Type='CONVERSATION',
        Settings={
            'ShowSpeakerLabels': True,
            'MaxSpeakerLabels': 2,
            'VocabularyName': 'medzen-medical-vocabulary'
        }
    )

    return {'service': 'aws_transcribe_medical', 'job_name': job_name}

def transcribe_with_aws_standard(s3_uri, language_code, appointment_id):
    """Use AWS Transcribe Standard for French"""
    transcribe = boto3.client('transcribe', region_name='eu-central-1')

    job_name = f"medzen-standard-{appointment_id}"

    transcribe.start_transcription_job(
        TranscriptionJobName=job_name,
        LanguageCode=language_code,
        MediaFormat='mp4',
        Media={'MediaFileUri': s3_uri},
        OutputBucketName=os.environ['TRANSCRIPTS_BUCKET'],
        Settings={
            'ShowSpeakerLabels': True,
            'MaxSpeakerLabels': 2
        }
    )

    return {'service': 'aws_transcribe_standard', 'job_name': job_name}

def transcribe_with_whisper(s3_uri, language_code, appointment_id):
    """Use OpenAI Whisper API for African languages"""
    import openai

    # Download audio from S3
    s3 = boto3.client('s3')
    bucket, key = parse_s3_uri(s3_uri)
    local_path = f"/tmp/{appointment_id}.mp4"
    s3.download_file(bucket, key, local_path)

    # Call OpenAI Whisper API
    openai.api_key = os.environ['OPENAI_API_KEY']

    with open(local_path, 'rb') as audio_file:
        transcript = openai.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file,
            language=language_code if language_code != 'auto' else None,
            response_format="verbose_json",
            timestamp_granularities=["segment", "word"]
        )

    # Upload transcript to S3
    transcript_key = f"whisper/{appointment_id}/transcript.json"
    s3.put_object(
        Bucket=os.environ['TRANSCRIPTS_BUCKET'],
        Key=transcript_key,
        Body=json.dumps(transcript.model_dump())
    )

    # Extract medical entities using Bedrock Claude
    entities = extract_entities_with_bedrock(transcript.text, language_code)

    return {
        'service': 'openai_whisper',
        'transcript': transcript.text,
        'segments': transcript.segments,
        'language': transcript.language,
        'medical_entities': entities
    }

def extract_entities_with_bedrock(transcript_text, language_code):
    """Extract medical entities from transcript using Bedrock Claude"""
    bedrock = boto3.client('bedrock-runtime', region_name='eu-central-1')

    # Language-specific prompt
    language_name = {
        'ff': 'Fulfulde',
        'pcm': 'Nigerian Pidgin English',
        'ln': 'Lingala',
        'sg': 'Sango',
        'fr': 'French'
    }.get(language_code, 'the detected language')

    prompt = f"""You are a medical entity extraction specialist fluent in {language_name} and medical terminology.

Extract all medical entities from this consultation transcript. The transcript is in {language_name}.

TRANSCRIPT:
{transcript_text}

Extract and return a JSON array with these entity types:
- SYMPTOMS: Patient symptoms and complaints
- DIAGNOSIS: Medical diagnoses mentioned
- MEDICATIONS: Drug names, dosages
- PROCEDURES: Medical procedures discussed
- ANATOMY: Body parts mentioned
- VITALS: Vital signs (BP, temp, etc.)

For each entity, include:
- text: Original text in {language_name}
- text_en: English translation
- type: Entity type from above
- icd10_code: Suggested ICD-10 code if applicable
- confidence: Confidence score 0-1

Return only valid JSON array."""

    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-5-sonnet-20241022-v2:0',
        contentType='application/json',
        accept='application/json',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 4096,
            'messages': [{'role': 'user', 'content': prompt}]
        })
    )

    response_body = json.loads(response['body'].read())
    entities_text = response_body['content'][0]['text']

    # Parse JSON from response
    try:
        return json.loads(entities_text)
    except:
        return []
```

#### Step 0.2: Add Language Selection to Video Call UI
**Update**: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

Add language selection dropdown before call starts:
```dart
// Language options for transcription
final List<Map<String, String>> transcriptionLanguages = [
  {'code': 'auto', 'name': 'Auto-Detect'},
  {'code': 'en-US', 'name': 'English (US)'},
  {'code': 'en-GB', 'name': 'English (UK)'},
  {'code': 'fr-FR', 'name': 'French (France)'},
  {'code': 'fr-CA', 'name': 'French (Canada)'},
  {'code': 'ff', 'name': 'Fulfulde / Pulaar'},
  {'code': 'pcm', 'name': 'Pidgin English (Nigeria/Cameroon)'},
  {'code': 'ln', 'name': 'Lingala'},
  {'code': 'sg', 'name': 'Sango'},
  {'code': 'sw', 'name': 'Swahili'},
  {'code': 'ha', 'name': 'Hausa'},
  {'code': 'yo', 'name': 'Yoruba'},
  {'code': 'ig', 'name': 'Igbo'},
];
```

#### Step 0.3: Store OpenAI API Key Securely
**Edge Function Secret**: Add to Supabase secrets

```bash
npx supabase secrets set OPENAI_API_KEY=sk-...
```

---

### Phase 1: Verify and Enhance AWS Transcribe Medical

#### Step 1.1: Update Recording Handler Lambda
**File**: Create `aws-lambda/chime-recording-handler/index.py`

The current inline Lambda needs to explicitly use Medical Transcribe for English:

```python
# Key changes:
# 1. Use StartMedicalTranscriptionJob for en-* languages
# 2. Fall back to StartTranscriptionJob for other languages
# 3. Configure specialty (PRIMARYCARE is most appropriate)
# 4. Enable medical entity identification
```

**Actions**:
1. Extract inline Lambda to `aws-lambda/chime-recording-handler/`
2. Add logic to choose Medical vs Standard Transcribe based on language
3. Configure HIPAA-compliant settings (OutputEncryptionKMSKeyId)
4. Add custom vocabulary support for medical terms

#### Step 1.2: Update Transcription Processor Lambda
**File**: `aws-deployment/cloudformation/chime-sdk-multi-region.yaml` (inline code)

Enhance to:
1. Parse Medical Transcribe output format (different from standard)
2. Extract medical entities with confidence scores
3. Store structured data in Supabase `video_call_sessions`
4. Trigger clinical note generation via Bedrock

---

### Phase 2: Provider Transcript Viewer UI

#### Step 2.1: Create Transcript Viewer Page in FlutterFlow
**Location**: FlutterFlow project (via MCP or manual)

**Page**: `ProviderTranscriptViewer`
- **URL Parameter**: `appointmentId` (UUID)
- **Data Source**: Supabase query on `video_call_sessions`

**UI Components**:
```
┌────────────────────────────────────────────────┐
│ Consultation Transcript                        │
│ Patient: [Name]  │  Date: [Date]  │  [Status]  │
├────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐│
│ │ Transcript                                  ││
│ │ ──────────────────────────────────────────  ││
│ │ [00:00:15] Dr. Smith: How are you feeling?  ││
│ │ [00:00:22] Patient: I've had a headache...  ││
│ │ ...                                         ││
│ └─────────────────────────────────────────────┘│
├────────────────────────────────────────────────┤
│ Medical Entities Detected                      │
│ ┌──────────────┬─────────┬───────────────────┐ │
│ │ Entity       │ Type    │ ICD-10            │ │
│ ├──────────────┼─────────┼───────────────────┤ │
│ │ Headache     │ Symptom │ R51.9             │ │
│ │ Ibuprofen    │ Medication │ -              │ │
│ └──────────────┴─────────┴───────────────────┘ │
├────────────────────────────────────────────────┤
│ [Generate Clinical Note]  [Export PDF]  [Save] │
└────────────────────────────────────────────────┘
```

#### Step 2.2: Create Custom Action for Transcript Fetch
**File**: `lib/custom_code/actions/get_consultation_transcript.dart`

```dart
Future<Map<String, dynamic>?> getConsultationTranscript(
  String appointmentId,
) async {
  final response = await SupaFlow.client
      .from('video_call_sessions')
      .select('''
        id,
        transcript_text,
        transcript_segments,
        medical_entities,
        transcript_language,
        recording_url,
        transcript_url,
        transcription_completed_at,
        appointments!inner(
          id,
          patient_id,
          provider_id,
          scheduled_start,
          chief_complaint,
          users!appointments_patient_id_fkey(first_name, last_name)
        )
      ''')
      .eq('appointment_id', appointmentId)
      .maybeSingle();

  return response;
}
```

---

### Phase 3: AI Clinical Note Generation

#### Step 3.1: Create Bedrock Note Generation Edge Function
**File**: `supabase/functions/generate-clinical-note/index.ts`

```typescript
// Use AWS Bedrock Claude to generate SOAP/clinical note from transcript
// Input: session_id, transcript_text, medical_entities, provider_preferences
// Output: structured clinical note (SOAP format by default)

interface ClinicalNote {
  subjective: string;      // Chief complaint, HPI, symptoms
  objective: string;       // Vitals, physical exam findings
  assessment: string;      // Diagnosis, differential diagnosis
  plan: string;            // Treatment plan, prescriptions, follow-up
  icd10_codes: string[];   // Suggested ICD-10 codes
  cpt_codes: string[];     // Suggested CPT codes
}
```

**Prompt Engineering**:
```
You are a medical scribe assistant. Generate a clinical note from this consultation transcript.

Patient: {patient_name}
Date: {date}
Provider: {provider_name}

TRANSCRIPT:
{transcript_text}

DETECTED MEDICAL ENTITIES:
{medical_entities}

Generate a SOAP note with:
- Subjective: Chief complaint and history from patient's own words
- Objective: Any vitals or exam findings mentioned
- Assessment: Likely diagnoses based on discussion
- Plan: Treatment discussed, medications, follow-up

Include relevant ICD-10 and CPT codes.
```

#### Step 3.2: Create Clinical Note Editor Component
**Location**: FlutterFlow custom widget

The provider should be able to:
1. View AI-generated note
2. Edit any section
3. Accept/reject suggested ICD-10 codes
4. Sign and finalize the note

---

### Phase 4: OpenEHR Clinical Notes Upload

#### Step 4.1: Create Clinical Notes Archetype
**File**: `ehrbase-templates/medzen.clinical.notes.v1.opt`

OpenEHR archetype for clinical consultation notes:
```
COMPOSITION (openEHR-EHR-COMPOSITION.encounter.v1)
├── SECTION (openEHR-EHR-SECTION.soap_headings.v1)
│   ├── EVALUATION (Subjective)
│   ├── OBSERVATION (Objective)
│   ├── EVALUATION (Assessment)
│   └── INSTRUCTION (Plan)
├── CLUSTER (Problem/Diagnosis - ICD-10 coded)
└── CLUSTER (Procedure - CPT coded)
```

#### Step 4.2: Update EHRbase Sync Edge Function
**File**: `supabase/functions/sync-to-ehrbase/index.ts`

Add new sync type: `clinical_note`

```typescript
case 'clinical_note':
  await syncClinicalNote(record.record_id, record.data_snapshot);
  break;

async function syncClinicalNote(noteId: string, data: ClinicalNoteData) {
  // 1. Get or create EHR for patient
  const ehrId = await getOrCreateEhr(data.patient_id);

  // 2. Build composition from template
  const composition = buildClinicalNotesComposition(data);

  // 3. POST to EHRbase
  const response = await fetch(
    `${EHRBASE_URL}/ehr/${ehrId}/composition`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${btoa(EHRBASE_CREDENTIALS)}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify(composition)
    }
  );

  // 4. Update Supabase with composition UID
  await supabase
    .from('clinical_notes')
    .update({ ehrbase_composition_uid: response.compositionUid })
    .eq('id', noteId);
}
```

#### Step 4.3: Create Clinical Notes Database Table
**Migration**: `supabase/migrations/YYYYMMDDHHMMSS_create_clinical_notes_table.sql`

```sql
CREATE TABLE IF NOT EXISTS clinical_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES appointments(id) NOT NULL,
  session_id UUID REFERENCES video_call_sessions(id),
  provider_id UUID REFERENCES users(id) NOT NULL,
  patient_id UUID REFERENCES users(id) NOT NULL,

  -- SOAP Note Content
  subjective TEXT,
  objective TEXT,
  assessment TEXT,
  plan TEXT,

  -- Coding
  icd10_codes JSONB DEFAULT '[]'::jsonb,
  cpt_codes JSONB DEFAULT '[]'::jsonb,

  -- Metadata
  note_type VARCHAR(50) DEFAULT 'soap',  -- soap, progress, procedure, etc.
  status VARCHAR(20) DEFAULT 'draft',     -- draft, signed, amended
  signed_at TIMESTAMPTZ,
  signed_by UUID REFERENCES users(id),

  -- AI Generation
  ai_generated BOOLEAN DEFAULT false,
  ai_model VARCHAR(100),
  original_transcript_id UUID,

  -- OpenEHR Integration
  ehrbase_composition_uid VARCHAR(255),
  ehrbase_synced_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_clinical_notes_appointment ON clinical_notes(appointment_id);
CREATE INDEX idx_clinical_notes_provider ON clinical_notes(provider_id);
CREATE INDEX idx_clinical_notes_patient ON clinical_notes(patient_id);
CREATE INDEX idx_clinical_notes_status ON clinical_notes(status);

-- RLS Policies
ALTER TABLE clinical_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can manage their own notes"
  ON clinical_notes FOR ALL
  USING (auth.uid() IS NULL OR provider_id = auth.uid());

CREATE POLICY "Patients can view their notes"
  ON clinical_notes FOR SELECT
  USING (auth.uid() IS NULL OR patient_id = auth.uid());
```

---

### Phase 5: Real-time Live Captions (Optional Enhancement)

#### Step 5.1: Enable Live Transcription in Chime SDK
**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

Add to embedded JavaScript:
```javascript
// In meeting session setup
if (meetingConfig.enableLiveTranscription) {
  const transcriptionConfig = {
    engineTranscribeMedicalSettings: {
      languageCode: 'en-US',
      specialty: 'PRIMARYCARE',
      type: 'CONVERSATION'
    }
  };

  await meetingSession.audioVideo.startLiveTranscription(
    transcriptionConfig.engineTranscribeMedicalSettings
  );

  // Subscribe to transcription events
  meetingSession.audioVideo.transcriptionController
    .subscribeToTranscriptEvent(handleTranscriptEvent);
}

function handleTranscriptEvent(transcript) {
  // Display live captions
  updateCaptionsUI(transcript.results);

  // Store segments to Supabase (debounced)
  storeTranscriptSegment(transcript);
}
```

#### Step 5.2: Add Captions UI Component
**Location**: Within `ChimeMeetingEnhanced` widget

```html
<div id="captions-container" class="captions-overlay">
  <div id="caption-text"></div>
</div>

<style>
.captions-overlay {
  position: absolute;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0,0,0,0.7);
  color: white;
  padding: 8px 16px;
  border-radius: 8px;
  max-width: 80%;
  text-align: center;
}
</style>
```

---

## Database Schema Changes

```sql
-- Migration: YYYYMMDDHHMMSS_add_transcription_enhancements.sql

-- Add columns to video_call_sessions if not exists
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS medical_transcription_used BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS transcription_specialty VARCHAR(50) DEFAULT 'PRIMARYCARE',
ADD COLUMN IF NOT EXISTS transcription_confidence NUMERIC(5,4),
ADD COLUMN IF NOT EXISTS entities_extraction_completed_at TIMESTAMPTZ;

-- Create index for transcript searches
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcription
ON video_call_sessions(transcription_enabled, transcription_completed_at)
WHERE transcription_enabled = true;
```

---

## File Changes Summary

### New Files
| File | Purpose |
|------|---------|
| `supabase/functions/generate-clinical-note/index.ts` | AI note generation via Bedrock |
| `lib/custom_code/actions/get_consultation_transcript.dart` | Fetch transcript data |
| `lib/custom_code/actions/save_clinical_note.dart` | Save/update clinical notes |
| `supabase/migrations/YYYYMMDDHHMMSS_create_clinical_notes_table.sql` | Clinical notes table |
| `ehrbase-templates/medzen.clinical.notes.v1.opt` | OpenEHR composition template |

### Modified Files
| File | Changes |
|------|---------|
| `aws-deployment/cloudformation/chime-sdk-multi-region.yaml` | Update Lambda code for Medical Transcribe |
| `supabase/functions/sync-to-ehrbase/index.ts` | Add clinical note sync type |
| `lib/custom_code/widgets/chime_meeting_enhanced.dart` | Optional live captions support |
| `supabase/functions/chime-meeting-token/index.ts` | Pass Medical Transcribe config |

### FlutterFlow Pages (via MCP or manual)
| Page | Purpose |
|------|---------|
| `ProviderTranscriptViewer` | View/edit transcript and entities |
| `ClinicalNoteEditor` | Edit and sign clinical notes |

---

## Testing Plan

### Unit Tests
1. Medical Transcribe job creation with correct parameters
2. Transcript parsing for both Medical and Standard formats
3. Clinical note generation prompt accuracy
4. OpenEHR composition structure validation

### Integration Tests
1. End-to-end: Recording upload → Transcription → Entity extraction
2. Clinical note generation from transcript
3. OpenEHR sync with EHRbase
4. Provider UI viewing and editing flow

### Manual Testing
1. Conduct test video call with transcription enabled
2. Verify Medical Transcribe used for English
3. Generate clinical note from transcript
4. Sign and sync to EHRbase
5. Verify composition in EHRbase

---

## Cost Estimates

### Transcription Services by Language

| Service | Languages | Pricing | Estimated Monthly |
|---------|-----------|---------|-------------------|
| AWS Transcribe Medical | English | $0.075/min | ~$100-200 (1500-3000 mins) |
| AWS Transcribe Standard | French | $0.024/min | ~$25-50 (1000-2000 mins) |
| **OpenAI Whisper API** | Fulfulde, Pidgin, African | $0.006/min | ~$30-60 (500-1000 mins) |

### Supporting Services

| Service | Purpose | Pricing | Estimated Monthly |
|---------|---------|---------|-------------------|
| AWS Comprehend Medical | Entity extraction (EN/FR) | $0.01/100 chars | ~$50-100 |
| AWS Bedrock (Claude) | Entity extraction (African) | $0.003/1K tokens | ~$30-60 |
| AWS Bedrock (Claude) | Clinical note generation | $0.003/1K tokens | ~$20-40 |
| S3 Storage | Recordings & transcripts | $0.023/GB | ~$10-20 |

### Total Cost Summary

| Scenario | Monthly Estimate |
|----------|------------------|
| Low usage (500 calls/month) | **~$265/month** |
| Medium usage (1500 calls/month) | **~$530/month** |
| High usage (3000 calls/month) | **~$1,060/month** |

### Notes on Whisper API Costs
- OpenAI Whisper is **12x cheaper** than AWS Transcribe Medical ($0.006 vs $0.075/min)
- Whisper supports 97+ languages including experimental African language support
- For Fulfulde/Pidgin accuracy improvements, consider fine-tuning a local Whisper model

---

## Rollback Plan

1. **Disable Medical Transcribe**: Set `useMedicalTranscription: false` in chime-meeting-token
2. **Disable Note Generation**: Remove generate-clinical-note function call
3. **Disable EHRbase Sync**: Comment out clinical_note case in sync-to-ehrbase

---

## Success Criteria

- [ ] Medical Transcribe used for all English consultations
- [ ] Transcripts available within 5 minutes of call end
- [ ] Medical entities extracted with ICD-10 codes
- [ ] Providers can view/edit transcripts
- [ ] AI clinical notes generated with 90%+ usable content
- [ ] Clinical notes sync to EHRbase successfully
- [ ] HIPAA compliance maintained (encryption, audit logs)
