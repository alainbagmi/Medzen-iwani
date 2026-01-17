# Comprehensive Testing & Validation Plan - January 13, 2026

**Status:** All fixes applied and ready for validation
**Last Updated:** 2026-01-13
**Scope:** Video call system, transcription, Android build, and end-to-end workflows

---

## Quick Status Summary

| Component | Status | Verified |
|-----------|--------|----------|
| **CHIME_API_ENDPOINT** | ✅ Set to `https://156da6e3xb.execute-api.eu-central-1.amazonaws.com/meetings` | Yes |
| **Edge Function** | ✅ chime-meeting-token redeployed | Yes |
| **API Health** | ✅ All components (API, Lambda, DynamoDB) healthy | Yes |
| **Android Stub File** | ✅ Created `lib/custom_code/widgets/chime_meeting_enhanced_stub.dart` | Yes |
| **Android APK Build** | ✅ Built successfully: `build/app/outputs/flutter-apk/app-debug.apk` | Yes |
| **Web Deployment** | ✅ Live at `https://4ea68cf7.medzen-dev.pages.dev` | Not yet tested |

---

## Testing Phase 1: Web Video Calls (CRITICAL PATH)

### Objective
Validate that video calls work end-to-end on the web deployment with the fixed CHIME_API_ENDPOINT.

### Prerequisites
- Valid Firebase credentials (patient and provider accounts)
- Scheduled appointment between provider and patient
- Modern browser (Chrome, Firefox, Edge)
- Stable internet connection

### Test 1.1: Basic Video Call Initialization
**Expected:** User can initiate video call and see video grid

1. **Open Web App**
   ```
   https://4ea68cf7.medzen-dev.pages.dev
   ```

2. **Login as Provider**
   - Use Firebase credentials for medical provider account
   - Verify authentication succeeds

3. **Navigate to Appointments**
   - Go to Appointments page
   - Select an appointment with a patient
   - Verify appointment details display correctly

4. **Start Video Call**
   - Click "Start Video Call" button
   - **Watch browser console** (F12 → Console tab)
   - Look for these logs in order:
     ```
     ✅ FlutterChannel shim installed for Web (iframe)
     📦 SDK script loaded from CDN
     📊 Status: SDK ready, joining meeting...
     ✅ Chime SDK ready - notifying Flutter
     ✓ Meeting created: meeting-...
     ✓ New video session created in database
     ✅ Meeting joined successfully via postMessage
     ```

5. **Verify UI Elements**
   - [ ] Video grid appears (dark background with video tiles)
   - [ ] Local video preview shows in corner
   - [ ] Remote video placeholder shows (waiting for participant)
   - [ ] Bottom control buttons visible:
     - [ ] Mute/Unmute button
     - [ ] Camera On/Off button
     - [ ] Leave Call button
     - [ ] Chat button
     - [ ] Transcription button (if enabled)
   - [ ] No error messages visible

6. **Check Network Tab**
   - F12 → Network tab
   - Look for successful request to:
     ```
     https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token
     ```
   - Status should be **200 OK** ✅
   - If 500: Function returned error (check logs)
   - If 401: Firebase auth failed (check token)

### Test 1.2: Audio/Video Functionality
**Expected:** Camera and microphone work, video transmits

1. **Verify Camera Permission**
   - Browser should show camera permission dialog
   - Grant permission
   - Local video should appear in corner box

2. **Test Microphone**
   - Unmute button should be active
   - Speak clearly: "Test audio, testing microphone"
   - Verify audio indicator shows activity
   - Mute/unmute should work (mute indicator toggles)

3. **Test Video Quality**
   - Local video should be clear and responsive
   - Movement should be smooth
   - Verify orientation changes are handled (if on mobile)

### Test 1.3: Call Controls
**Expected:** All buttons work correctly

| Control | Test | Expected Result |
|---------|------|-----------------|
| **Mute Button** | Click to toggle | Audio indicator shows muted/unmuted state |
| **Camera Button** | Click to toggle | Video preview disappears/reappears |
| **Leave Call** | Click button | Call ends, redirects to appointments page |
| **Chat Button** | Click button | Chat panel opens (if integrated) |
| **Transcription** | Click button | Transcription status updates |

### Test 1.4: Remote Participant Join
**Expected:** Second participant can join same meeting

1. **Open Second Browser/Session**
   - Login as patient account
   - Navigate to same appointment
   - Click "Join Video Call" button

2. **Verify Connection**
   - [ ] Remote video appears in provider's video grid
   - [ ] Provider's video appears in patient's video grid
   - [ ] Audio transmits both directions
   - [ ] No latency issues
   - [ ] No video/audio sync issues

### Test 1.5: Call Persistence
**Expected:** Call remains stable for duration of test

1. **Monitor for 2 minutes**
   - Check for connection drops
   - Verify no freezing or stuttering
   - Monitor browser console for errors
   - Check Network tab for failed requests

2. **Verify Database Records**
   - Database table `video_call_sessions` should have new record
   - Record should have:
     - [ ] `chime_meeting_id` (not null)
     - [ ] `appointment_id` (correct appointment)
     - [ ] `provider_id` (logged-in provider)
     - [ ] `patient_id` (participating patient)
     - [ ] `call_start_time` (current timestamp)
     - [ ] `call_end_time` (null until call ends)

---

## Testing Phase 2: Medical Transcription (CRITICAL PATH)

### Objective
Validate that AWS Transcribe Medical captures and processes audio correctly with medical vocabulary.

### Test 2.1: Transcription Start/Stop
**Expected:** User can control transcription during active video call

**Prerequisites:** Active video call in progress (from Test 1.4)

1. **Start Transcription**
   - Click "Start Transcription" button
   - Watch for status change: "Transcription: Starting..."
   - Wait for: "Transcription: Active" or "Transcription: Recording"
   - **Check Database:**
     ```sql
     SELECT transcription_status, transcript
     FROM video_call_sessions
     WHERE appointment_id = '[YOUR_APPOINTMENT_ID]'
     ORDER BY call_start_time DESC LIMIT 1;
     ```
     Should show: `transcription_status = 'active'` or `'recording'`

2. **Speak Medical Content**
   - Provider speaks clearly:
     ```
     "Patient presents with hypertension and type two diabetes.
      Prescribed lisinopril ten milligrams once daily and metformin
      five hundred milligrams twice daily. Follow up in three months."
     ```
   - Speak at normal conversational pace
   - Avoid mumbling or background noise

3. **Monitor Live Captions**
   - Watch for real-time captions to appear below video (if UI supports)
   - Captions should show recognized medical terms:
     - [ ] "hypertension" (not "high blood pressure")
     - [ ] "diabetes" (not "diabetics")
     - [ ] "lisinopril" (drug name)
     - [ ] "metformin" (drug name)
   - Medical vocabulary should be used over generic terms

4. **Stop Transcription**
   - Click "Stop Transcription" button
   - Status should change to: "Transcription: Processing..." → "Transcription: Complete"
   - Wait 5-30 seconds for AWS Transcribe to process
   - **Verify in Database:**
     ```sql
     SELECT transcription_status, transcript, transcript_language
     FROM video_call_sessions
     WHERE appointment_id = '[YOUR_APPOINTMENT_ID]'
     ORDER BY call_start_time DESC LIMIT 1;
     ```
     Should show:
     - `transcription_status = 'completed'`
     - `transcript` contains the spoken text
     - `transcript_language = 'en-US'` (for English)

### Test 2.2: Transcript Accuracy
**Expected:** Transcribed text matches spoken content with medical accuracy

1. **Review Full Transcript**
   - After transcription completes, view transcript
   - Compare with what was actually spoken
   - Medical terms should be correctly recognized

2. **Verify Medical Vocabulary**
   - Check that medical-specific terms were recognized:
     - Drug names (lisinopril, metformin, etc.)
     - Medical conditions (hypertension, diabetes, etc.)
     - Medical procedures and tests
   - Should NOT be replaced with phonetically similar generic words

3. **Check Timestamps** (if available)
   - Each caption segment should have timestamp
   - Verify timestamps are in correct order
   - No large gaps or jumps

### Test 2.3: Multi-Language Transcription (If Applicable)
**Expected:** Non-English languages also support medical vocabulary

**If patient speaks French, Afrikaans, or Arabic:**

1. **Set Language in App**
   - Navigate to Language Preferences
   - Select French (fr) / Afrikaans (af) / Arabic (ar)
   - Language-specific medical vocabulary should be loaded

2. **Start Transcription with Language**
   - Speak medical content in selected language
   - Medical terms should be recognized with vocabulary boost
   - Example (French): "hypertension" should be recognized, not "high tension"

3. **Verify Database**
   ```sql
   SELECT transcript_language, transcript_language_confidence
   FROM video_call_sessions
   WHERE appointment_id = '[YOUR_APPOINTMENT_ID]';
   ```

---

## Testing Phase 3: AI Clinical Notes Generation

### Objective
Validate that AI generates accurate clinical notes from video transcripts.

### Test 3.1: Post-Call Clinical Note Generation
**Expected:** Clinical notes generated automatically after transcription completes

**Prerequisites:** Completed video call with transcription (from Tests 1.4 + 2.1)

1. **End Video Call**
   - Click "Leave Call" button
   - Both participants' calls should end
   - App should redirect to appointment details or clinical notes page

2. **Wait for Note Generation**
   - Clinical note generation is async (may take 10-30 seconds)
   - Watch for notification: "Clinical note generated" or similar
   - Or check database:
     ```sql
     SELECT ai_generated_note, note_status, generated_at
     FROM clinical_notes
     WHERE appointment_id = '[YOUR_APPOINTMENT_ID]'
     ORDER BY created_at DESC LIMIT 1;
     ```

3. **Review Generated Note**
   - Note should be in SOAP format:
     ```
     SUBJECTIVE:
     - Chief complaint
     - History of present illness
     - Patient statements from transcript

     OBJECTIVE:
     - Vital signs (if available)
     - Physical exam findings
     - Test results (if available)

     ASSESSMENT:
     - Patient's diagnoses
     - Conditions identified from transcript
     - ICD-10 codes (if extracted)

     PLAN:
     - Medications prescribed (with dosages)
     - Follow-up instructions
     - Referrals if needed
     ```

### Test 3.2: Medical Entity Extraction
**Expected:** AI correctly identifies medical entities (diagnoses, drugs, procedures)

1. **Check Extracted Entities**
   - ICD-10 codes for diagnoses:
     - Hypertension: should extract ICD-10 code (e.g., I10)
     - Diabetes: should extract ICD-10 code (e.g., E11.9)
   - Drug names and dosages:
     - "Lisinopril 10mg" should show: drug_name=lisinopril, dosage=10mg, route=oral
     - "Metformin 500mg twice daily" should extract all components
   - Procedures:
     - Any mentioned procedures should be identified

2. **Verify Extraction Accuracy**
   ```sql
   SELECT extracted_diagnoses, extracted_medications, extracted_procedures
   FROM clinical_notes
   WHERE appointment_id = '[YOUR_APPOINTMENT_ID]'
   ORDER BY created_at DESC LIMIT 1;
   ```

### Test 3.3: Note Editing and Signing
**Expected:** Provider can review, edit, and sign clinical notes

1. **Edit Note (Optional)**
   - Click "Edit" button on clinical note
   - Make any corrections needed
   - Click "Save Changes"

2. **Sign Note**
   - Click "Sign Note" button
   - Enter provider's signature or PIN (if required)
   - Verify signature timestamp recorded

3. **Verify Signed Status**
   - Note should show:
     - [ ] "Signed by [Provider Name]"
     - [ ] Signature timestamp
     - [ ] Note status changed to "Signed" or "Finalized"

### Test 3.4: EHR Sync (OpenEHR/EHRbase)
**Expected:** Signed clinical notes are synced to EHRbase

1. **Check Sync Status**
   - After signing, note should be queued for EHR sync
   - **Database check:**
     ```sql
     SELECT * FROM ehrbase_sync_queue
     WHERE clinical_note_id = '[NOTE_ID]'
     ORDER BY created_at DESC LIMIT 1;
     ```
   - Should show: `sync_status = 'pending'` → `'completed'`

2. **Verify in EHRbase** (if accessible)
   - Log into EHRbase/OpenEHR system
   - Navigate to patient's clinical data
   - New clinical note from MedZen should appear
   - Verify content matches what was signed

3. **Check Sync Logs**
   - If sync fails:
     ```sql
     SELECT sync_status, error_message, last_sync_attempt
     FROM ehrbase_sync_queue
     WHERE clinical_note_id = '[NOTE_ID]';
     ```
   - Review error message to troubleshoot

---

## Testing Phase 4: Android Mobile Testing

### Objective
Validate that video calls work on Android devices with the fixed stub file.

### Test 4.1: APK Installation
**Expected:** APK installs cleanly on Android device

**Prerequisites:**
- Android device or emulator
- `build/app/outputs/flutter-apk/app-debug.apk` file
- USB debugging enabled (if on device)

1. **Install APK**
   ```bash
   # Connect device or start emulator
   adb devices

   # Install APK
   adb install -r build/app/outputs/flutter-apk/app-debug.apk

   # Or use flutter
   flutter install -d [DEVICE_ID]
   ```

2. **Verify Installation**
   - App appears in app drawer
   - No crash on first launch
   - Firebase auth works

3. **Grant Permissions**
   - Camera permission: Allow
   - Microphone permission: Allow
   - Location permission: Allow (if prompted)
   - Storage permission: Allow (if prompted)

### Test 4.2: Video Call on Mobile
**Expected:** All features work on Android

1. **Login and Navigate**
   - Launch MedZen app
   - Login as provider
   - Go to Appointments
   - Select appointment

2. **Start Video Call**
   - Click "Start Video Call"
   - Should see pre-joining dialog with camera/mic check
   - Grant permissions if prompted
   - Chime SDK should load

3. **Verify Video Grid**
   - [ ] Local video preview shows in corner
   - [ ] Remote participant placeholder visible
   - [ ] Control buttons at bottom:
     - [ ] Mute
     - [ ] Camera
     - [ ] Leave
     - [ ] Chat (if integrated)
     - [ ] Transcription

4. **Test Audio/Video**
   - Speak: "Testing audio on Android"
   - Verify audio transmits
   - Mute/unmute works
   - Camera on/off works

5. **Test Orientation Changes**
   - Rotate device between portrait/landscape
   - Video grid should adjust responsively
   - No crashes or UI overflow

### Test 4.3: Transcription on Mobile
**Expected:** Transcription works same as web

1. **Start Transcription**
   - During active call
   - Click "Start Transcription"
   - Wait for "Transcription: Active"

2. **Speak and Monitor**
   - Speak medical content
   - Check if live captions appear
   - Stop transcription after 10-15 seconds

3. **Verify Transcript Saved**
   - Check database for transcript
   - Compare transcribed text to spoken content

### Test 4.4: Performance on Mobile
**Expected:** App runs smoothly without crashes

1. **Monitor Performance**
   - Watch for:
     - [ ] No lag or stuttering during video
     - [ ] No dropped frames (should be smooth)
     - [ ] Audio synced with video
     - [ ] No crashes during call

2. **Check Logs**
   ```bash
   adb logcat | grep -i medzen
   ```
   - Should show normal logs, no exceptions or crashes

---

## Testing Phase 5: Browser Compatibility

### Objective
Validate web deployment works across multiple browsers.

### Test 5.1: Chrome/Chromium
- [ ] Open `https://4ea68cf7.medzen-dev.pages.dev`
- [ ] Start video call
- [ ] Verify all features work
- [ ] Console shows no errors

### Test 5.2: Firefox
- [ ] Open same URL
- [ ] Start video call
- [ ] Verify audio/video transmit
- [ ] Check console for WebRTC errors

### Test 5.3: Safari (macOS)
- [ ] Open same URL
- [ ] Verify video call starts
- [ ] Audio should work
- [ ] Check for WebRTC compatibility issues

### Test 5.4: Edge (Windows)
- [ ] Open same URL
- [ ] Verify Chromium-based compatibility
- [ ] Audio/video should work

---

## Testing Phase 6: Database & Backend Verification

### Objective
Validate backend services are processing data correctly.

### Test 6.1: Supabase Database
**Check all critical tables populated:**

```sql
-- Check users table
SELECT COUNT(*) as user_count FROM users WHERE firebase_uid IS NOT NULL;

-- Check appointments
SELECT COUNT(*) as appointment_count FROM appointments
WHERE provider_id IS NOT NULL AND patient_id IS NOT NULL;

-- Check video sessions (after video call test)
SELECT * FROM video_call_sessions
ORDER BY call_start_time DESC LIMIT 1;

-- Check transcription usage (after transcription test)
SELECT * FROM transcription_usage_daily
WHERE usage_date = CURRENT_DATE;

-- Check clinical notes (after AI generation test)
SELECT COUNT(*) as notes_count FROM clinical_notes
WHERE created_at > NOW() - INTERVAL '1 hour';
```

### Test 6.2: Edge Functions
**Verify all edge functions are deployed:**

```bash
npx supabase functions list
```

**Expected functions (18 core + 2 PowerSync optional):**
- ✅ bedrock-ai-chat
- ✅ check-user
- ✅ chime-meeting-token
- ✅ chime-messaging
- ✅ send-push-notification
- ✅ sync-to-ehrbase
- ✅ generate-clinical-note
- ✅ start-medical-transcription
- ✅ chime-recording-callback
- ✅ chime-transcription-callback
- ✅ chime-entity-extraction
- ✅ cleanup-expired-recordings
- ✅ ingest-call-transcript
- ✅ finalize-call-draft
- ✅ storage-sign-url
- ✅ call-send-message
- ✅ upload-profile-picture
- ✅ cleanup-old-profile-pictures

### Test 6.3: Firebase Functions
**Verify critical functions are deployed:**

```bash
firebase functions:list
```

**Expected functions:**
- ✅ onUserCreated
- ✅ onUserDeleted
- ✅ addFcmToken
- ✅ sendPushNotificationsTrigger
- ✅ sendVideoCallNotification
- ✅ sendScheduledPushNotifications

### Test 6.4: Environment Variables
**Verify Supabase secrets are set:**

```bash
npx supabase secrets list
```

**Critical variables:**
- ✅ CHIME_API_ENDPOINT = `https://156da6e3xb.execute-api.eu-central-1.amazonaws.com/meetings`
- ✅ FIREBASE_PROJECT_ID = `medzen-bf20e`
- ✅ AWS_REGION = `eu-central-1`

---

## Testing Phase 7: Error Scenarios

### Test 7.1: Network Disconnection
**Expected:** Graceful handling of network loss

1. **During Video Call**
   - Disable internet on device
   - App should show "Connection Lost" or similar
   - Re-enable internet
   - Connection should restore (or show reconnect option)

### Test 7.2: Call with Invalid Participant
**Expected:** Appropriate error message

1. **Try to join without participant**
   - Start call as provider
   - Wait 30 seconds for remote participant
   - Should show: "Waiting for participant..." or timeout gracefully

### Test 7.3: Transcription Service Unavailable
**Expected:** Graceful fallback

1. **If transcription fails**
   - Should show: "Transcription unavailable"
   - Call should continue without transcription
   - No crash or UI freeze

---

## Quick Test Checklist

### Must Pass (Critical Path)
- [ ] **T1.1:** Video call initializes and displays video grid
- [ ] **T1.2:** Camera and microphone work
- [ ] **T1.3:** All control buttons (mute, camera, leave) functional
- [ ] **T1.4:** Remote participant can join
- [ ] **T2.1:** Transcription starts and stops
- [ ] **T2.2:** Medical vocabulary recognized (hypertension, diabetes, drug names)
- [ ] **T3.1:** Clinical note generated after call
- [ ] **T3.3:** Provider can sign clinical note
- [ ] **T4.1:** APK installs and launches
- [ ] **T4.2:** Video call works on Android

### Should Pass (Important)
- [ ] **T1.5:** Call stable for 2+ minutes
- [ ] **T2.3:** Multi-language transcription works (if available)
- [ ] **T3.4:** Clinical note syncs to EHRbase
- [ ] **T4.3:** Transcription works on Android
- [ ] **T4.4:** No crashes on mobile
- [ ] **T5.1-5.4:** Works on multiple browsers

### Validation
- [ ] **T6:** All database tables populated correctly
- [ ] **T6.2:** All 18 edge functions deployed
- [ ] **T6.3:** Firebase functions deployed
- [ ] **T6.4:** Environment variables set

---

## Test Execution Log Template

```
Test Date: ____________________
Tester Name: ____________________
Platform: [ ] Web  [ ] Android  [ ] iOS
Browser: ____________________

Test 1.1 - Video Call Init:      [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 1.2 - Audio/Video:          [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 1.3 - Call Controls:        [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 1.4 - Remote Participant:   [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 2.1 - Transcription:        [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 2.2 - Medical Accuracy:     [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 3.1 - Clinical Notes:       [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

Test 3.2 - Entity Extraction:    [ ] PASS  [ ] FAIL  [ ] SKIP
  Issues: ____________________________

OVERALL RESULT:  [ ] PASS  [ ] FAIL

Notes: ________________________________________________________
```

---

## Known Issues & Workarounds

| Issue | Symptom | Workaround |
|-------|---------|-----------|
| Browser cache | Old SDK loading | Clear cache: Ctrl+Shift+Delete, hard refresh: Ctrl+Shift+R |
| Firebase token expired | 401 Unauthorized | Re-login to refresh token |
| Transcription stuck | Status stays "Processing" | Check AWS Transcribe Medical quota; may take 30+ seconds |
| Video blank | Camera never shows | Check camera permissions granted, try different browser |
| Audio not working | Mute shows but no audio | Check microphone permissions, try different microphone device |
| Android emulator camera | No camera preview | Enable "Use camera" in emulator settings or use physical device |

---

## Success Criteria

**Video Calls Fixed:** ✅ When Tests 1.1-1.5 all PASS
**Transcription Working:** ✅ When Tests 2.1-2.3 all PASS
**Clinical Notes Ready:** ✅ When Tests 3.1-3.4 all PASS
**Mobile Support:** ✅ When Tests 4.1-4.4 all PASS
**System Complete:** ✅ When all critical path tests PASS

---

## Next Steps After Testing

1. **If all critical tests PASS:**
   - Document test results
   - Create release APK: `flutter build apk --release`
   - Prepare for production deployment

2. **If any test FAILS:**
   - Document failure and error messages
   - Check relevant debugging section in CLAUDE.md
   - Review error logs from:
     - Browser console (F12)
     - `npx supabase functions logs [name] --tail`
     - `firebase functions:log --limit 100`
     - Android logcat (if mobile)

3. **After validation:**
   - Deploy release builds
   - Configure production environment variables
   - Set up monitoring and alerting
   - Create user documentation

---

**Last Updated:** 2026-01-13
**Ready for Testing:** YES ✅
**All Prerequisites Met:** YES ✅
