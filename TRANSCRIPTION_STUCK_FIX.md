# Transcription "Stuck" Issue - FIXED

## Problem
The app was getting stuck on "generating transcription" after video calls. The `PostCallClinicalNotesDialog` would check the transcription status once, and if the AWS Transcribe job was still in progress, it would show an error message and stop trying.

## Root Cause
Located in `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart:92-188`

**Original Flow:**
1. Video call ends → AWS Transcribe starts processing
2. `PostCallClinicalNotesDialog` opens immediately
3. `_checkTranscriptAndGenerateNote()` queries database **once**
4. If `transcription_status == 'in_progress'`, shows error and sets `_isGenerating = false`
5. User stuck with no way to retry or wait for completion

## Solution Implemented
Added **automatic polling** with progress indication:

### Changes Made
1. **Added polling state variables:**
   ```dart
   int _pollAttempts = 0;
   static const int _maxPollAttempts = 60; // 60 × 3 sec = 3 min max
   static const Duration _pollInterval = Duration(seconds: 3);
   ```

2. **Updated `_checkTranscriptAndGenerateNote()` logic:**
   - When `transcription_status == 'in_progress'`:
     - Check if max attempts reached (60 attempts)
     - If not, wait 3 seconds and recursively retry
     - Keep loading state active with progress counter
   - After 3 minutes (60 attempts), shows timeout error with manual entry option

3. **Enhanced UI feedback:**
   - Shows current polling attempt: "Checking status (5/60)..."
   - Different messages for polling vs AI generation
   - Clear indication that transcription is processing

### New Flow
1. Video call ends → AWS Transcribe starts processing
2. Dialog opens and checks status
3. If `in_progress`:
   - Shows "Waiting for transcription... Checking status (1/60)..."
   - Waits 3 seconds
   - Checks again
   - Repeats up to 60 times (3 minutes total)
4. When transcript ready, automatically proceeds to generate clinical note
5. If timeout, shows clear error with manual entry option

## Expected Transcription Times
Based on AWS Transcribe Medical documentation:
- **Typical**: 30 seconds - 2 minutes for most calls
- **Factors affecting time**:
  - Recording length
  - Audio quality
  - Number of speakers
  - AWS service load

## User Experience Improvements
✅ No more "stuck" state - dialog actively polls for completion
✅ Progress indication shows it's working
✅ Automatic retry without user intervention
✅ 3-minute timeout is reasonable for most calls
✅ Clear error messages with guidance if timeout occurs
✅ Manual entry option always available as fallback

## Testing Checklist
- [ ] Complete a video call with transcription enabled
- [ ] Verify dialog shows polling progress
- [ ] Confirm clinical note generates when transcript ready
- [ ] Test timeout scenario (if AWS is slow)
- [ ] Verify manual entry works if transcription fails

## Files Modified
- `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart`
  - Lines 56-77: Added polling state variables
  - Lines 138-209: Implemented polling logic for `in_progress` status
  - Lines 707-737: Updated UI to show polling progress

## Next Steps
1. Test with a real video call
2. Monitor logs for polling behavior
3. Adjust `_maxPollAttempts` or `_pollInterval` if needed based on real-world usage
4. Consider adding a "Cancel" button during polling if users want to skip

## Related Files
- Video call widget: `lib/custom_code/widgets/chime_meeting_enhanced.dart`
- Transcription action: `lib/custom_code/actions/control_medical_transcription.dart`
- Edge function: `supabase/functions/start-medical-transcription/index.ts`
- Callback handler: `supabase/functions/chime-transcription-callback/index.ts`
