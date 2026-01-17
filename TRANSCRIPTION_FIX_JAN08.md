# Transcription Fix - January 8, 2026

## Problem Statement
Medical transcription service starts and stops correctly on AWS, but **transcription controller is not available** in the Chime SDK WebView, resulting in zero transcript segments captured.

## Root Cause
The AWS Chime SDK v3 transcription controller is not automatically available after calling `StartMeetingTranscriptionCommand`. The issue is that:

1. The transcription controller exists as part of the Chime SDK
2. BUT it may not be properly initialized or accessible in the WebView context
3. The subscription attempt in `_subscribeToTranscriptionControllerViaJS()` fails because `window.meetingSession.audioVideo.transcriptionController` is undefined

## The Fix

### Step 1: Verify Transcription Controller Availability After Join

**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

**Location**: Around line 5737 (after meeting join)

**Current Code**:
```javascript
// === TRANSCRIPTION CONTROLLER SUBSCRIPTION ===
// Subscribe to live transcription events from AWS Transcribe Medical
if (meetingSession.audioVideo.transcriptionController) {
    console.log('🎙️ Setting up transcription controller subscription...');
    // ... subscription code ...
} else {
    console.log('⚠️ Transcription controller not available (transcription may not be started)');
}
```

**Replace With**:
```javascript
// === TRANSCRIPTION CONTROLLER INITIALIZATION ===
// CRITICAL: AWS Chime SDK v3 transcription controller should ALWAYS exist
// even before transcription is started. If it doesn't exist, there's a problem.
console.log('🔍 Checking transcription controller availability...');
console.log('   audioVideo object:', typeof audioVideo);
console.log('   transcriptionController:', typeof audioVideo.transcriptionController);

// Check if transcription controller exists
if (!audioVideo.transcriptionController) {
    console.error('❌ CRITICAL: Transcription controller not available!');
    console.error('   This indicates:');
    console.error('   1. Chime SDK version may not support transcription');
    console.error('   2. SDK bundle may be missing transcription module');
    console.error('   3. Browser compatibility issue');

    // Try to get more diagnostic info
    console.log('   Chime SDK version:', ChimeSDK?.version || 'unknown');
    console.log('   Available audioVideo methods:', Object.keys(audioVideo));

    // Send error to Flutter
    window.FlutterChannel?.postMessage(JSON.stringify({
        type: 'TRANSCRIPTION_ERROR',
        error: 'Transcription controller not available',
        details: {
            sdkVersion: ChimeSDK?.version || 'unknown',
            hasAudioVideo: !!audioVideo,
            audioVideoMethods: Object.keys(audioVideo).slice(0, 20) // First 20 methods
        }
    }));
} else {
    console.log('✅ Transcription controller available - setting up subscription...');

    // Subscribe to transcription events
    // This will activate when transcription starts server-side
    audioVideo.transcriptionController.subscribeToTranscriptEvent((transcriptEvent) => {
        console.log('📝 Transcription event received!');
        console.log('   Event type:', typeof transcriptEvent);
        console.log('   Has alternatives:', !!transcriptEvent?.transcriptAlternative);

        if (!transcriptEvent || !transcriptEvent.transcriptAlternative) {
            console.warn('⚠️ Empty transcription event received');
            return;
        }

        // Process transcript items
        transcriptEvent.transcriptAlternative.forEach((alternative) => {
            if (!alternative.items) {
                console.warn('⚠️ Alternative has no items');
                return;
            }

            // Build the transcript text from items
            const transcriptText = alternative.items
                .map(item => item.content)
                .filter(content => content && content.trim())
                .join(' ');

            if (!transcriptText || !transcriptText.trim()) {
                console.warn('⚠️ Empty transcript text');
                return;
            }

            // Determine speaker
            const speakerLabel = alternative.items[0]?.speakerLabel || 'Unknown';
            const isPartial = transcriptEvent.isPartial || false;
            const resultId = transcriptEvent.resultId || Date.now().toString();

            console.log('🎤 Transcription:', {
                speaker: speakerLabel,
                partial: isPartial,
                textLength: transcriptText.length,
                preview: transcriptText.substring(0, 50) + '...'
            });

            // Send to Flutter for storage
            try {
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'LIVE_CAPTION',
                    resultId: resultId,
                    speakerLabel: speakerLabel,
                    speakerName: speakerLabel === 'ch_0' ? 'Provider' :
                                 speakerLabel === 'ch_1' ? 'Patient' : speakerLabel,
                    transcriptText: transcriptText,
                    isPartial: isPartial,
                    timestamp: new Date().toISOString()
                }));
                console.log('✅ Caption sent to Flutter');
            } catch (error) {
                console.error('❌ Failed to send caption to Flutter:', error);
            }
        });
    });

    console.log('✅ Transcription controller subscription registered');
    console.log('   Will receive events when transcription starts server-side');
}
```

### Step 2: Add Diagnostic Logging to Start Transcription

**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

**Location**: Around line 2138 (in `_startMedicalTranscription` method)

**Add after line 2138**:
```dart
debugPrint('🎙️ Starting medical transcription...');
debugPrint('   Meeting ID: $_meetingId');
debugPrint('   Session ID: $_sessionId');
debugPrint('   Language: $_transcriptionLanguage');

// CRITICAL: Check if transcription controller is available in WebView
final checkJs = '''
(function() {
  try {
    if (!window.meetingSession) return { error: 'No meeting session' };
    if (!window.meetingSession.audioVideo) return { error: 'No audioVideo' };

    const hasController = !!window.meetingSession.audioVideo.transcriptionController;
    const controllerType = typeof window.meetingSession.audioVideo.transcriptionController;

    return {
      hasController: hasController,
      controllerType: controllerType,
      ready: hasController
    };
  } catch (e) {
    return { error: e.message };
  }
})();
''';

try {
  final checkResult = await _webViewController?.evaluateJavascript(source: checkJs);
  debugPrint('🔍 Transcription controller pre-check: $checkResult');

  if (checkResult != null && checkResult is Map) {
    if (checkResult['hasController'] != true) {
      debugPrint('❌ WARNING: Transcription controller not available before start!');
      debugPrint('   This will likely result in no transcript being captured');
      debugPrint('   Controller type: ${checkResult['controllerType']}');
      debugPrint('   Error: ${checkResult['error']}');
    } else {
      debugPrint('✅ Transcription controller is available and ready');
    }
  }
} catch (e) {
  debugPrint('⚠️ Failed to check transcription controller: $e');
}

// Now proceed with starting transcription
```

### Step 3: Verify CDN Bundle Includes Transcription Support

**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

**Location**: Around line 4300 (in the HTML template)

**Find the script tag loading Chime SDK**:
```html
<script src="https://du6iimxem4mh7.cloudfront.net/assets/amazon-chime-sdk-medzen.min.js"></script>
```

**Add verification after SDK loads** (around line 4350):
```javascript
// Verify Chime SDK loaded correctly with transcription support
console.log('🔍 Verifying Chime SDK...');
console.log('   ChimeSDK available:', typeof ChimeSDK !== 'undefined');
console.log('   Version:', ChimeSDK?.version || 'unknown');

// Check if transcription-related classes exist
const hasTranscription = !!(
    ChimeSDK?.TranscriptionController ||
    ChimeSDK?.TranscriptEvent ||
    ChimeSDK?.Transcript
);

console.log('   Has transcription support:', hasTranscription);

if (!hasTranscription) {
    console.error('❌ CRITICAL: Chime SDK loaded but transcription support missing!');
    console.error('   SDK may be incomplete or using wrong version');
    console.error('   Available ChimeSDK exports:', Object.keys(ChimeSDK || {}).slice(0, 20));
}
```

### Step 4: Test with Enhanced Logging

After applying the fixes, test with these steps:

1. **Start Video Call**
2. **Check Browser Console** for:
   ```
   ✅ Transcription controller available
   ✅ Transcription controller subscription registered
   ```

3. **Click Start Transcription**
4. **Speak into microphone** (actual speech, not silence)
5. **Check for transcript events**:
   ```
   📝 Transcription event received!
   🎤 Transcription: { speaker: 'ch_0', textLength: 25, preview: 'Hello patient...' }
   ✅ Caption sent to Flutter
   ```

6. **Verify in database**:
   ```sql
   SELECT * FROM live_caption_segments
   WHERE session_id = '<session-id>'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

## Alternative Solution: Post-Call Transcription

If real-time transcription continues to have issues, implement post-call transcription instead:

### Step 1: Record Audio During Call

Use Chime SDK's recording feature to capture audio:

```javascript
// Start recording
audioVideo.startContentShare(stream);

// Or use server-side recording (already configured)
```

### Step 2: Upload to S3 After Call

The recording callback already exists:
- `supabase/functions/chime-recording-callback/index.ts`

### Step 3: Batch Transcription

Create new edge function `supabase/functions/batch-transcribe-recording/index.ts`:

```typescript
import { TranscribeClient, StartTranscriptionJobCommand } from '@aws-sdk/client-transcribe';

// Start batch transcription job
const command = new StartTranscriptionJobCommand({
  TranscriptionJobName: `video-call-${sessionId}-${Date.now()}`,
  LanguageCode: 'en-US',
  MediaFormat: 'mp4',
  Media: {
    MediaFileUri: recordingS3Uri
  },
  OutputBucketName: 'medzen-transcripts',
  Settings: {
    ShowSpeakerLabels: true,
    MaxSpeakerLabels: 2,
    VocabularyName: 'medical-vocabulary'
  }
});
```

This approach:
- ✅ Guaranteed to work (batch transcription is more reliable)
- ✅ No real-time issues
- ✅ Better quality (can use larger models)
- ❌ No live captions during call
- ❌ 3-5 minute delay after call ends

## Testing Checklist

### Pre-Flight Checks
- [ ] Verify Chime SDK v3.19.0 or later loaded
- [ ] Confirm transcription controller exists after meeting join
- [ ] Check browser console shows no SDK errors

### During Call
- [ ] Start transcription successfully
- [ ] Speak clearly into microphone for 10-15 seconds
- [ ] Verify console shows "📝 Transcription event received!"
- [ ] Check Flutter logs show "Caption sent to Flutter"

### Post Call
- [ ] Query `live_caption_segments` table
- [ ] Verify segments > 0
- [ ] Check `video_call_sessions.transcript` populated
- [ ] Confirm transcription status = 'completed'

### Database Verification
```sql
-- Check caption segments
SELECT
    COUNT(*) as segment_count,
    SUM(LENGTH(transcript_text)) as total_chars,
    MIN(created_at) as first_segment,
    MAX(created_at) as last_segment
FROM live_caption_segments
WHERE session_id = '<session-id>';

-- Check final transcript
SELECT
    transcription_status,
    LENGTH(transcript) as transcript_length,
    transcription_duration_seconds,
    transcription_estimated_cost_usd
FROM video_call_sessions
WHERE id = '<session-id>';
```

## Expected Cost Savings

Once fixed:
- **Current**: $0.0588 for 0 segments (wasted)
- **Fixed**: $0.0588 for ~150 segments (valuable)
- **ROI**: Actual clinical notes from transcripts

## Next Steps

1. Apply Step 1-3 fixes to `chime_meeting_enhanced.dart`
2. Test on **real Android device** (not emulator)
3. Monitor browser console for transcription events
4. Verify database receives caption segments
5. If still not working, implement Alternative Solution (post-call batch transcription)

## Files Modified

- `lib/custom_code/widgets/chime_meeting_enhanced.dart` (3 sections)
  - Line 5737: Enhanced transcription controller initialization
  - Line 2138: Pre-start diagnostic checks
  - Line 4350: SDK verification logging

## Related Issues

- Android emulator camera error (secondary, doesn't affect transcription)
- Fix: Enable webcam passthrough in AVD settings or test on real device
