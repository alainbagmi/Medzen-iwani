# DynamoDB to Supabase Migration Data Mapping

## Overview
This document describes the data transformation from three legacy DynamoDB tables to their corresponding Supabase PostgreSQL tables.

---

## Table 1: medzen-video-sessions → video_call_sessions

### DynamoDB Schema
```
PK: id (String)
Attributes:
  - id: UUID
  - appointmentId: String
  - providerId: String
  - patientId: String
  - status: String (INITIATED | ACTIVE | COMPLETED | FAILED)
  - startTime: Number (timestamp)
  - endTime: Number (timestamp)
  - joinUrl: String
  - meetingId: String
  - mediaRegion: String
  - transcriptionEnabled: Boolean
  - transcriptId: String
  - transcriptLanguage: String
  - soapNoteId: String
  - finalizationStatus: String
  - createdAt: Number (timestamp)
  - updatedAt: Number (timestamp)
```

### Supabase Schema
```sql
CREATE TABLE video_call_sessions (
  id UUID PRIMARY KEY,
  appointment_id UUID NOT NULL,
  provider_id UUID NOT NULL,
  patient_id UUID NOT NULL,
  status TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  join_url TEXT,
  meeting_id TEXT,
  media_region TEXT,
  transcription_enabled BOOLEAN DEFAULT false,
  transcript_id UUID,
  transcript_language TEXT,
  soap_note_id UUID,
  finalization_status TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Data Transformation Rules

| DynamoDB Field | Supabase Column | Transformation |
|---|---|---|
| id | id | Direct UUID (no change) |
| appointmentId | appointment_id | Direct (lowercase with underscore) |
| providerId | provider_id | Direct (lowercase with underscore) |
| patientId | patient_id | Direct (lowercase with underscore) |
| status | status | Direct (enum: INITIATED\|ACTIVE\|COMPLETED\|FAILED) |
| startTime | start_time | Unix timestamp → TIMESTAMP WITH TIME ZONE |
| endTime | end_time | Unix timestamp → TIMESTAMP WITH TIME ZONE |
| joinUrl | join_url | Direct (string) |
| meetingId | meeting_id | Direct (string) |
| mediaRegion | media_region | Direct (string) |
| transcriptionEnabled | transcription_enabled | Direct (boolean) |
| transcriptId | transcript_id | Direct UUID |
| transcriptLanguage | transcript_language | Direct (string) |
| soapNoteId | soap_note_id | Direct UUID |
| finalizationStatus | finalization_status | Direct (string) |
| createdAt | created_at | Unix timestamp → TIMESTAMP WITH TIME ZONE |
| updatedAt | updated_at | Unix timestamp → TIMESTAMP WITH TIME ZONE |

### Timestamp Conversion
- DynamoDB stores milliseconds since epoch (JavaScript Date.getTime())
- PostgreSQL expects ISO 8601 format or Unix seconds (with timezone)
- Conversion: `to_timestamp(dynamodb_timestamp / 1000)` or convert to ISO string

---

## Table 2: medzen-soap-notes → clinical_notes

### DynamoDB Schema
```
PK: id (String)
Attributes:
  - id: UUID
  - sessionId: String
  - appointmentId: String
  - soapData: Object (JSON)
    - chiefComplaint: String
    - subjective: Object
    - objective: Object
    - assessment: Object
    - plan: Object
  - status: String (DRAFT | REVIEWED | SIGNED | ARCHIVED)
  - aiModel: String
  - aiGeneratedAt: Number (timestamp)
  - createdAt: Number (timestamp)
  - updatedAt: Number (timestamp)
```

### Supabase Schema
```sql
CREATE TABLE clinical_notes (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL,
  appointment_id UUID NOT NULL,
  note_type TEXT NOT NULL DEFAULT 'SOAP',
  status TEXT NOT NULL,
  chief_complaint TEXT,
  subjective JSONB,
  objective JSONB,
  assessment JSONB,
  plan JSONB,
  ai_model TEXT,
  ai_generated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Data Transformation Rules

| DynamoDB Field | Supabase Column | Transformation |
|---|---|---|
| id | id | Direct UUID |
| sessionId | session_id | Direct UUID |
| appointmentId | appointment_id | Direct UUID |
| soapData.chiefComplaint | chief_complaint | Extract string |
| soapData.subjective | subjective | Extract as JSONB |
| soapData.objective | objective | Extract as JSONB |
| soapData.assessment | assessment | Extract as JSONB |
| soapData.plan | plan | Extract as JSONB |
| status | status | Direct (enum: DRAFT\|REVIEWED\|SIGNED\|ARCHIVED) |
| aiModel | ai_model | Direct (string, e.g., "claude-opus-4-5-20251101-v1:0") |
| aiGeneratedAt | ai_generated_at | Unix timestamp → TIMESTAMP WITH TIME ZONE |
| createdAt | created_at | Unix timestamp → TIMESTAMP WITH TIME ZONE |
| updatedAt | updated_at | Unix timestamp → TIMESTAMP WITH TIME ZONE |
| (new column) | note_type | DEFAULT 'SOAP' |

### Special Handling
- **JSON Objects**: Convert DynamoDB Object type to PostgreSQL JSONB
- **Nested Objects**: Preserve full structure in JSONB (no flattening)
- **Missing Fields**: Default subjective/objective/assessment/plan to `{}` if not present

---

## Table 3: medzen-meeting-audit → video_call_audit_log

### DynamoDB Schema
```
PK: id (String)
SK: timestamp (Number)
Attributes:
  - id: UUID
  - sessionId: String
  - eventType: String (CALL_INITIATED | CALL_JOINED | TRANSCRIPTION_STARTED | etc.)
  - eventData: Object (JSON - varies by event type)
  - timestamp: Number (milliseconds)
  - createdAt: Number (timestamp)
```

### Supabase Schema
```sql
CREATE TABLE video_call_audit_log (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Data Transformation Rules

| DynamoDB Field | Supabase Column | Transformation |
|---|---|---|
| id | id | Direct UUID |
| sessionId | session_id | Direct UUID |
| eventType | event_type | Direct (string, uppercase) |
| eventData | event_data | Direct JSONB |
| timestamp OR createdAt | created_at | Unix timestamp → TIMESTAMP WITH TIME ZONE (use later timestamp) |

### Event Types Preserved
- CALL_INITIATED
- CALL_JOINED
- CALL_DISCONNECTED
- TRANSCRIPTION_STARTED
- TRANSCRIPTION_COMPLETED
- TRANSCRIPTION_FAILED
- SOAP_GENERATION_STARTED
- SOAP_GENERATION_COMPLETED
- SOAP_GENERATION_FAILED

---

## Migration Steps

### Pre-Migration Validation
1. Count records in each DynamoDB table
2. Verify Supabase tables exist and are empty
3. Export sample records from DynamoDB for testing

### Migration Execution
1. Export all records from medzen-video-sessions
2. Transform and insert into video_call_sessions
3. Validate record count and sample data
4. Export all records from medzen-soap-notes
5. Transform and insert into clinical_notes
6. Validate record count and sample data
7. Export all records from medzen-meeting-audit
8. Transform and insert into video_call_audit_log
9. Validate record count and sample data

### Post-Migration Validation
1. Run SQL validation queries (see validate_migration.sql)
2. Compare record counts: DynamoDB source vs Supabase destination
3. Spot-check 10-20 records for data integrity
4. Verify RLS policies are not blocking valid queries
5. Test edge functions with migrated data

### Rollback Plan
- Maintain DynamoDB tables in read-only mode for 30 days
- Keep export files as backup
- Document any data discrepancies
- Restore from backup if critical issues found

---

## Known Limitations & Special Cases

### medzen-video-sessions
- Records with NULL/missing timestamps: Set to migration_time
- Invalid meetingIds (malformed): Log and preserve as-is for investigation
- Timezone handling: All timestamps converted to UTC

### medzen-soap-notes
- Nested SOAP objects with varying structures: Preserve as JSONB (supports flexible schema)
- Missing SOAP components: Store as empty object {} instead of NULL
- Historical records with old AI models: Preserve model name exactly (e.g., "claude-3-sonnet")

### medzen-meeting-audit
- Event data may contain nested objects at arbitrary depth: JSONB handles natively
- Audit records span from early 2024 to present: All included in migration
- No deduplication: Each record migrated exactly as stored

---

## Verification Queries

See `validate_migration.sql` for:
- Record count comparisons
- Sample data spot-checks
- Timezone verification
- JSONB content validation
- RLS policy testing
