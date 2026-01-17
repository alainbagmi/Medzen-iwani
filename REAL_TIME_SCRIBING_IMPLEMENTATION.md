# Real-Time Medical Scribing Implementation Plan

## Overview

This document outlines the implementation of real-time medical scribing (live transcription) for MedZen video calls using AWS Chime SDK.

## Current State

### ✅ What Exists
- **Post-recording transcription**: Recordings are transcribed after meetings end
- **Multilingual support**: 100+ languages with auto-detection
- **Medical entity extraction**: AWS Comprehend Medical extracts conditions, medications, ICD-10 codes
- **Custom vocabularies**: Support for medical terms, African languages, Pidgin, Camfranglais
- **Infrastructure**: Lambda functions, S3 buckets, DynamoDB audit tables

### ❌ What's Missing
- **Live transcription during calls**: No real-time captions displayed during meetings
- **Real-time medical scribing**: No live medical entity detection
- **Streaming transcription data**: No WebSocket/streaming infrastructure

## Architecture

### Real-Time Transcription Flow

```
┌─────────────────┐
│ Chime Meeting   │
│  (Audio Stream) │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Amazon Chime SDK                    │
│ - startLiveTranscription()          │
│ - Subscribes to transcription events│
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Amazon Transcribe (Streaming)       │
│ - Real-time speech-to-text          │
│ - Medical vocabulary support        │
│ - Multi-language auto-detection     │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Chime Meeting Session               │
│ - Receives transcription events     │
│ - Displays live captions            │
│ - Stores transcript segments        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Supabase (Optional Real-time Store) │
│ - video_call_sessions table         │
│ - Live transcript_segments          │
└─────────────────────────────────────┘
```

## Implementation Components

### 1. Enable Live Transcription in Chime SDK

**File**: `lib/custom_code/widgets/chime_meeting_webview.dart`

**Changes Needed**:
1. Add `enableLiveTranscription` flag to widget parameters
2. Modify embedded JavaScript to call `meetingSession.audioVideo.startLiveTranscription()`
3. Subscribe to transcription events: `transcriptionStatusDidChange`, `transcriptionDataReceived`
4. Display live captions in the UI overlay
5. Store transcript segments to Supabase in real-time

**Key Methods to Add**:
```javascript
// In embedded Chime SDK JavaScript
async function enableLiveTranscription(meetingSession, options) {
  const config = {
    engineTranscribeSettings: {
      languageCode: options.languageCode || 'en-US',
      identifyLanguage: options.autoDetect || false,
      languageOptions: options.languageOptions || ['en-US'],
      vocabularyName: options.customVocabulary || null,
      region: 'eu-central-1' // Use primary region
    },
    engineTranscribeMedicalSettings: {
      languageCode: 'en-US', // Medical transcription only supports English
      specialty: 'PRIMARYCARE',
      type: 'CONVERSATION'
    }
  };

  // Enable medical transcription if English, otherwise standard
  const useMedicalTranscription = options.languageCode?.startsWith('en');

  if (useMedicalTranscription) {
    await meetingSession.audioVideo.startLiveTranscription(
      config.engineTranscribeMedicalSettings
    );
  } else {
    await meetingSession.audioVideo.startLiveTranscription(
      config.engineTranscribeSettings
    );
  }

  // Subscribe to transcription events
  meetingSession.audioVideo.transcriptionController.subscribeToTranscriptEvent(
    (transcript) => {
      handleTranscriptEvent(transcript);
    }
  );
}

function handleTranscriptEvent(transcript) {
  if (transcript.results && transcript.results.length > 0) {
    const result = transcript.results[0];

    if (result.alternatives && result.alternatives.length > 0) {
      const transcriptText = result.alternatives[0].transcript;
      const isPartial = result.isPartial;
      const speakerId = result.channelId; // Speaker identification

      // Display in UI
      updateLiveCaptions(transcriptText, isPartial, speakerId);

      // Store final transcripts
      if (!isPartial) {
        storeTranscriptSegment(transcriptText, speakerId);
      }
    }
  }
}
```

### 2. UI Components for Live Captions

**Add to Chime Meeting UI**:
```html
<!-- Live captions overlay -->
<div id="live-captions" style="
  position: absolute;
  bottom: 80px;
  left: 20px;
  right: 20px;
  background: rgba(0,0,0,0.8);
  color: white;
  padding: 15px;
  border-radius: 8px;
  font-size: 18px;
  max-height: 150px;
  overflow-y: auto;
  display: none;
">
  <div id="caption-text"></div>
</div>

<!-- Transcription controls -->
<button id="toggle-captions" onclick="toggleLiveCaptions()">
  <i class="fas fa-closed-captioning"></i> Enable Captions
</button>
```

### 3. Database Schema Updates

**Table**: `video_call_sessions`

**New Columns**:
```sql
ALTER TABLE video_call_sessions ADD COLUMN IF NOT EXISTS
  live_transcription_enabled BOOLEAN DEFAULT false,
  live_transcript_language VARCHAR(10),
  live_transcript_segments JSONB DEFAULT '[]'::jsonb,
  live_transcription_started_at TIMESTAMPTZ,
  live_transcription_ended_at TIMESTAMPTZ;
```

**New Table**: `live_transcript_segments` (optional, for real-time storage)
```sql
CREATE TABLE IF NOT EXISTS live_transcript_segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  speaker_id VARCHAR(100),
  speaker_name VARCHAR(255),
  transcript_text TEXT NOT NULL,
  language_code VARCHAR(10),
  confidence FLOAT,
  start_time FLOAT,
  end_time FLOAT,
  is_medical BOOLEAN DEFAULT false,
  medical_entities JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_live_transcript_session ON live_transcript_segments(session_id, created_at);
```

### 4. API Updates

**Supabase Edge Function**: `chime-meeting-token`

**Add transcription configuration**:
```typescript
// In chime-meeting-token/index.ts
const transcriptionConfig = {
  enableLiveTranscription: body.enableLiveTranscription ?? true,
  languageCode: body.transcriptionLanguage ?? 'en-US',
  autoDetectLanguage: body.autoDetectLanguage ?? true,
  useMedicalTranscription: body.useMedicalTranscription ?? true,
  customVocabulary: await getCustomVocabulary(body.userId)
};

return new Response(
  JSON.stringify({
    meeting: meetingData.Meeting,
    attendee: attendeeData.Attendee,
    transcriptionConfig
  }),
  { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
);
```

### 5. Flutter Widget Updates

**File**: `lib/custom_code/actions/join_room.dart`

**Add parameters**:
```dart
Future<void> joinRoom(
  BuildContext context,
  String sessionId,
  String providerId,
  String patientId,
  String appointmentId,
  bool isProvider,
  String userName,
  String profileImage,
  // NEW PARAMETERS
  bool enableLiveTranscription = true,
  String? transcriptionLanguage,
  bool autoDetectLanguage = true,
) async {
  // ... existing code ...

  final response = await SupaFlow.client.functions.invoke(
    'chime-meeting-token',
    body: {
      'appointmentId': appointmentId,
      'userId': userId,
      'enableLiveTranscription': enableLiveTranscription,
      'transcriptionLanguage': transcriptionLanguage,
      'autoDetectLanguage': autoDetectLanguage,
    },
  );

  // ... rest of implementation ...
}
```

## Cost Impact

### Without Live Transcription
- **Transcribe Batch**: ~$0.0004/sec ($1.44/hour)
- **Processing time**: After meeting ends
- **Total cost per hour meeting**: ~$1.50

### With Live Transcription
- **Transcribe Streaming**: ~$0.0005/sec ($1.80/hour)
- **Processing time**: Real-time during meeting
- **Additional cost**: ~$0.36/hour (+25%)
- **User benefit**: Immediate captions, better accessibility

### Medical Transcription (English only)
- **Transcribe Medical**: ~$0.0012/sec ($4.32/hour)
- **Higher accuracy for medical terms**: Yes
- **Entity extraction included**: Yes
- **Recommended for**: Provider-patient consultations

## Implementation Phases

### Phase 1: Core Live Transcription (This PR)
- ✅ Enable Chime SDK live transcription API
- ✅ Add UI overlay for live captions
- ✅ Store transcript segments in video_call_sessions
- ✅ Add toggle button for captions
- ⏱️ Estimated time: 2-3 hours

### Phase 2: Real-Time Medical Entities (Future)
- ⬜ Stream transcript to AWS Comprehend Medical
- ⬜ Display live medical entity highlights
- ⬜ Real-time ICD-10 code suggestions
- ⏱️ Estimated time: 4-6 hours

### Phase 3: Advanced Features (Future)
- ⬜ Speaker diarization (identify provider vs patient)
- ⬜ Multi-language code-switching detection
- ⬜ Automatic summary generation
- ⬜ Export transcript as PDF/DOCX
- ⏱️ Estimated time: 8-12 hours

## Testing Plan

### Unit Tests
1. Test `enableLiveTranscription()` API call
2. Test transcript event handling
3. Test caption display/hide toggle
4. Test segment storage to Supabase

### Integration Tests
1. Start meeting → verify live captions appear
2. Speak medical terms → verify accuracy
3. Multi-speaker scenario → verify speaker labels
4. Language switching → verify auto-detection
5. End meeting → verify segments stored correctly

### User Acceptance Testing
1. Provider enables captions during patient consultation
2. Patient can read live captions
3. Captions display in correct language
4. Transcript available after meeting ends

## Rollout Strategy

### Development (Week 1)
- Implement core live transcription
- Test on development environment
- QA with sample meetings

### Staging (Week 2)
- Deploy to staging Supabase + AWS
- Test with real users (beta testers)
- Gather feedback on accuracy and UX

### Production (Week 3)
- Deploy to production eu-central-1
- Enable for 10% of users (A/B test)
- Monitor performance and costs
- Gradual rollout to 100%

## Monitoring & Alerts

### CloudWatch Metrics
- **Transcription accuracy**: Track confidence scores
- **Latency**: Time from speech to caption display
- **Error rate**: Failed transcription events
- **Cost**: Track Transcribe usage

### Supabase Alerts
- **Storage growth**: Monitor transcript_segments size
- **Query performance**: Index on session_id + created_at
- **Real-time subscriptions**: Monitor connection count

## Rollback Plan

If issues arise:
1. **Immediate**: Disable live transcription via feature flag
2. **Fallback**: Use existing post-recording transcription
3. **Investigation**: Check CloudWatch logs
4. **Fix**: Deploy patch within 24 hours
5. **Re-enable**: Gradual rollout after fix verified

## Documentation Updates

After implementation:
1. Update `TESTING_GUIDE.md` with live transcription tests
2. Update `CHIME_VIDEO_TESTING_GUIDE.md` with caption instructions
3. Add user guide: "How to Use Live Captions"
4. Update API documentation with new parameters

## Related Files

- `lib/custom_code/widgets/chime_meeting_webview.dart` - Main widget
- `lib/custom_code/actions/join_room.dart` - Meeting join action
- `supabase/functions/chime-meeting-token/index.ts` - Meeting token generator
- `aws-deployment/cloudformation/chime-sdk-multi-region.yaml` - Infrastructure
- `lib/backend/supabase/database/tables/video_call_sessions.dart` - Schema

## Success Criteria

✅ Live captions display within 2 seconds of speech
✅ 95%+ transcription accuracy for English medical terms
✅ Support for 20+ languages with auto-detection
✅ < 500ms latency from speech to caption display
✅ Transcript segments stored in real-time to database
✅ Toggle captions on/off without disrupting call
✅ Zero impact on video/audio quality
✅ Cost increase < 30% compared to post-recording only

## Next Steps

1. ✅ Review and approve this implementation plan
2. ⬜ Implement Phase 1 changes
3. ⬜ Deploy to development environment
4. ⬜ Run automated tests
5. ⬜ User acceptance testing
6. ⬜ Production deployment with gradual rollout
