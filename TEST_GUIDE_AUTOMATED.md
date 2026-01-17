# MedZen Video Call & Transcription Automated Test Guide

## Overview

This guide covers the automated test suite for MedZen's video call and speech-to-text (transcription) functionality. The tests validate:

- **Web Video Calls**: Testing Chime SDK integration on Chrome
- **Android Video Calls**: Testing mobile video call functionality with camera/microphone
- **Speech-to-Text Transcription**: Testing AWS Transcribe medical transcription

## Quick Start

### Run All Tests

```bash
./run_all_tests_automated.sh --all --report
```

This will:
1. Run all test suites (web, Android, transcription)
2. Generate individual test logs
3. Create an HTML report with results

### Run Specific Test Suite

```bash
# Web tests only
./run_all_tests_automated.sh --web

# Android tests only
./run_all_tests_automated.sh --android

# Transcription tests only
./run_all_tests_automated.sh --transcription

# All with HTML report
./run_all_tests_automated.sh --all --report
```

## Prerequisites

### Environment Setup

1. **Supabase credentials**:
   ```bash
   export SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
   export SUPABASE_KEY="eyJhbGc..." # Your anon key
   ```

2. **Firebase credentials**:
   ```bash
   export FIREBASE_PROJECT="medzen-bf20e"
   export FIREBASE_TEST_TOKEN="your-test-token"
   ```

### For Web Testing (Chrome)

```bash
# Start Flutter web app
flutter run -d chrome

# App will be available at http://localhost:54321
```

### For Android Testing

```bash
# List emulators
emulator -list-avds

# Start emulator with camera/microphone enabled
emulator -avd <emulator-name> -camera-back emulated -camera-front emulated

# OR run app on emulator
flutter run -d emulator-5554
```

**Enable camera in Android emulator**:
1. Open AVD Manager
2. Select emulator → Edit
3. Under "Boot options", select "Cold Boot"
4. Ensure "Use host GPU" is checked
5. Start emulator

### For Transcription Testing

- Ensure active video call session exists (or tests will use test session IDs)
- AWS credentials configured via IAM policies
- Supabase edge functions deployed

## Test Scripts

### 1. `test_video_call_web_automated.sh`

Tests video call functionality on web (Chrome).

#### Tests Included:

| Test # | Name | Purpose |
|--------|------|---------|
| 1 | Provider creates meeting | Verify providers can initiate video calls |
| 2 | Patient cannot create | Security: ensure only providers can start calls |
| 3 | Patient joins meeting | Verify patients can join active calls |
| 4 | Authorization checks | Validate Firebase token authentication |
| 5 | Session persistence | Verify sessions stored in database |
| 6 | Token structure | Validate meeting token has required fields |
| 7 | Chime SDK availability | Check CDN accessibility |
| 8 | Firebase token refresh | Verify token refresh requirement |

#### Run:
```bash
./test_video_call_web_automated.sh [provider_email] [patient_email]

# Example:
./test_video_call_web_automated.sh provider@test.medzen.health patient@test.medzen.health
```

#### Expected Output:
```
[INFO] TEST 1: Provider creates a video call meeting...
[✓ PASS] Provider successfully created meeting (ID: a1b2c3d4...)
[INFO] TEST 2: Patient attempts to create meeting (should fail)...
[✓ PASS] Patient correctly rejected from creating meeting
...
✓ All tests passed!
```

### 2. `test_video_call_android_automated.sh`

Tests video call functionality on Android emulator.

#### Tests Included:

| Test # | Name | Purpose |
|--------|------|---------|
| 1 | Emulator running | Verify Android emulator is active |
| 2 | Camera permission | Check AndroidManifest has CAMERA permission |
| 3 | Microphone permission | Check AndroidManifest has RECORD_AUDIO permission |
| 4 | Grant permissions | Grant runtime permissions to app |
| 5 | App installed | Verify MedZen app is on emulator |
| 6 | Firebase config | Check Firebase dependencies in build.gradle |
| 7 | Chime SDK integration | Verify AWS Chime SDK available |
| 8 | WebView permissions | Check INTERNET permission |
| 9 | API connectivity | Test emulator can reach external APIs |
| 10 | Native method channels | Verify platform channel implementation |
| 11 | Target SDK version | Check minimum SDK requirements met |
| 12 | UI flow test | Launch app and verify basic navigation |
| 13 | Camera mock support | Verify emulator camera mocking available |

#### Run:
```bash
./test_video_call_android_automated.sh
```

#### Requirements:
- Emulator `emulator-5554` running
- Camera/microphone enabled in AVD settings

#### Expected Output:
```
[INFO] TEST 1: Verify Android emulator is running...
[✓ PASS] Emulator emulator-5554 is running
[INFO] TEST 2: Verify CAMERA permission in AndroidManifest.xml...
[✓ PASS] CAMERA permission found in manifest
...
✓ All tests passed!
```

### 3. `test_transcription_automated.sh`

Tests AWS Transcribe medical transcription functionality.

#### Tests Included:

| Test # | Name | Purpose |
|--------|------|---------|
| 1 | Function availability | Verify edge function is deployed |
| 2 | English US medical | Test en-US with medical vocabulary |
| 3 | Language fallback | Test Nigerian Pidgin → en-US fallback |
| 4 | Medical vocabulary | Verify specialty vocabulary support |
| 5 | Speaker diarization | Test speaker identification (Doctor vs Patient) |
| 6 | Cost calculation | Verify transcription costs tracked |
| 7 | Daily budget | Test budget enforcement |
| 8 | Idempotency | Prevent duplicate transcription starts |
| 9 | Duration limits | Verify max duration enforcement |
| 10 | Live captions | Test real-time caption streaming |
| 11 | Transcript aggregation | Verify final transcript creation |
| 12 | Regional languages | Test English variants (GB, ZA, KE, NG) |
| 13 | Cost estimation | Verify cost formula accuracy |
| 14 | Specialty selection | Test medical specialties (CARDIOLOGY, etc.) |

#### Run:
```bash
./test_transcription_automated.sh [session_id] [language]

# Examples:
./test_transcription_automated.sh
./test_transcription_automated.sh test-session-123 en-US
./test_transcription_automated.sh test-session-123 fr-FR
```

#### Language Support Tested:

**Medical Languages**:
- en-US (AWS Transcribe Medical with specialties)
- en-GB, en-ZA, en-KE, en-NG (English variants)

**Other Languages**:
- French: fr-FR, fr-CA, fr-CM, fr-SN, fr-CI, fr-CD
- African: Swahili (5 variants), Zulu, Somali, Hausa, Wolof, Kinyarwanda
- Arabic variants: ar, ar-EG, ar-MA, ar-DZ, ar-TN, ar-SD

#### Expected Output:
```
[INFO] TEST 1: Verify start-medical-transcription edge function is available...
[✓ PASS] Transcription function is available (HTTP 200)
[INFO] TEST 2: Test en-US (English US with Medical vocabulary)...
[✓ PASS] en-US transcription started successfully
...
✓ All transcription tests passed!
```

### 4. `run_all_tests_automated.sh`

Master test runner that orchestrates all tests.

#### Usage:
```bash
# Run all tests
./run_all_tests_automated.sh --all

# Run with HTML report
./run_all_tests_automated.sh --all --report

# Run specific suites
./run_all_tests_automated.sh --web --android --transcription

# Generate report only
./run_all_tests_automated.sh --report
```

#### Output:
- Creates `test_results_YYYYMMDD_HHMMSS/` directory
- Individual `.log` files for each test suite
- Optional `test_report.html` with visual summary

## Key Testing Patterns

### Web Video Call Flow

```
Provider Authentication
    ↓
Create Meeting (via chime-meeting-token edge function)
    ├── Firebase token verification
    ├── AWS Lambda call to create Chime meeting
    └── Store session in video_call_sessions table
    ↓
Patient Authentication
    ↓
Join Meeting (via chime-meeting-token edge function)
    ├── Verify call is active
    ├── Get attendee token
    └── Patient joins via Chime SDK
    ↓
Real-time Video & Chat
    ├── Video frames via Chime SDK
    └── Messages via chime_messages table
```

### Android Test Configuration

```
Emulator Setup
    ├── Camera enabled: -camera-back emulated
    ├── Microphone enabled: -camera-front emulated
    └── Network access enabled
    ↓
Permissions
    ├── AndroidManifest.xml has CAMERA
    ├── AndroidManifest.xml has RECORD_AUDIO
    └── Runtime permissions granted
    ↓
App Deployment
    ├── APK built with Flutter
    ├── Installed on emulator
    └── Firebase configured
```

### Transcription Flow

```
Video Call Recording
    ↓
Enable Transcription
    ├── Language selection
    ├── Medical specialty choice
    └── Start AWS Transcribe job
    ↓
Live Captions
    ├── Streamed via Realtime
    ├── Speaker diarization applied
    └── Segments stored in live_caption_segments
    ↓
Transcription Complete
    ├── Aggregate segments into transcript
    ├── Calculate cost
    └── Store in video_call_sessions.transcript
```

## Interpreting Results

### Pass/Fail Criteria

**PASS**:
- API returns expected status code (200, 201)
- Required fields present in response
- Authorization checks work correctly
- Database records created as expected

**FAIL**:
- Unexpected HTTP status (4xx, 5xx errors)
- Missing required response fields
- Unauthorized access allowed
- Database persistence fails

### Common Issues & Solutions

#### Web Test Issues

| Issue | Solution |
|-------|----------|
| Firebase token error | Run `getIdToken(true)` to refresh token |
| Chime SDK not loading | Check CDN URL: `https://du6iimxem4mh7.cloudfront.net/...` |
| "NO_ACTIVE_CALL" error | Provider must create meeting first |
| Authorization fails | Verify `x-firebase-token` header is lowercase |

#### Android Test Issues

| Issue | Solution |
|-------|----------|
| "Emulator not running" | Start with: `flutter run -d emulator-5554` |
| Permissions not granted | Enable in AVD Manager or restart emulator |
| App not installed | Run: `flutter run -d emulator-5554` |
| No camera access | Add `-camera-back emulated -camera-front emulated` to emulator startup |

#### Transcription Test Issues

| Issue | Solution |
|-------|----------|
| "No active session" | Create test appointment first |
| Language not supported | Check fallback language mapping |
| Budget exceeded | Reset `transcription_usage_daily` table |
| Transcript empty | Wait for transcription job to complete (2-10 min) |

## Advanced Testing

### Manual Testing on Web

1. **Start Flutter web**:
   ```bash
   flutter run -d chrome
   ```

2. **Open DevTools** (F12):
   - Check Console for errors
   - Monitor Network tab for API calls
   - Verify WebSocket for Chime SDK
   - Check video element in HTML

3. **Test Call Flow**:
   - Provider logs in
   - Provider starts video call
   - Patient logs in
   - Patient joins call
   - Both can see video
   - Chat messages send/receive
   - Call ends cleanly

### Manual Testing on Android

1. **Enable verbose logging**:
   ```bash
   flutter run -d emulator-5554 -v
   ```

2. **Monitor logs**:
   ```bash
   adb -s emulator-5554 logcat | grep -i "medzen\|chime\|video"
   ```

3. **Test Call Flow**:
   - Grant camera/microphone permissions when prompted
   - Start video call
   - Verify camera feed appears
   - Test microphone with recording
   - Test chat message sending
   - End call

### Load Testing Transcription

For high-volume transcription testing:

```bash
# Create multiple concurrent transcription requests
for i in {1..5}; do
  ./test_transcription_automated.sh &
done
wait

# Monitor costs
curl -s "$SUPABASE_URL/rest/v1/transcription_usage_daily" \
  -H "apikey: $SUPABASE_KEY" | jq '.[] | {date: .usage_date, cost: .total_cost_usd}'
```

## Logs & Debugging

### View Test Logs

```bash
# List all test results
ls -la test_results_*/

# View specific test log
cat test_results_20240113_153000/Web_Video_Calls.log

# Search for errors
grep -i "error\|fail" test_results_*//*.log

# Extract pass/fail summary
grep -E "\[✓ PASS\]|\[✗ FAIL\]" test_results_*/*.log | sort | uniq -c
```

### View Edge Function Logs

```bash
# Chime meeting token function
npx supabase functions logs chime-meeting-token --tail

# Transcription function
npx supabase functions logs start-medical-transcription --tail

# All functions
npx supabase functions logs --tail
```

### View Firebase Logs

```bash
# View Firebase functions logs
firebase functions:log --limit 50

# Filter by function
firebase functions:log | grep -i "videocall\|transcription"
```

## Performance Metrics

### Web Video Call Metrics

Expected performance:
- Meeting creation: < 2 seconds
- Patient join: < 3 seconds
- First video frame: < 5 seconds
- Chat message latency: < 1 second

### Android Metrics

Expected performance:
- App startup: < 5 seconds
- Permission grant: < 2 seconds
- Call initialization: < 3 seconds
- Camera activation: < 2 seconds

### Transcription Metrics

Expected performance:
- Job start: < 5 seconds
- Live caption delay: 1-3 seconds (real-time streaming)
- Final transcript ready: 2-10 minutes (depends on duration)
- Cost calculation: < 1 second

## Continuous Integration

To integrate with CI/CD:

```yaml
# Example GitHub Actions
name: Test Video & Transcription
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: |
          export SUPABASE_URL=${{ secrets.SUPABASE_URL }}
          export SUPABASE_KEY=${{ secrets.SUPABASE_KEY }}
          chmod +x run_all_tests_automated.sh
          ./run_all_tests_automated.sh --all --report
      - uses: actions/upload-artifact@v2
        if: always()
        with:
          name: test-results
          path: test_results_*/
```

## Support & Troubleshooting

### Common Questions

**Q: How long do tests take?**
A: Typically 5-15 minutes depending on network and AWS latency

**Q: Can I run tests in parallel?**
A: Yes, with caution. Use different session IDs to avoid conflicts.

**Q: Do tests modify production data?**
A: No, tests use test sessions and account IDs. Use dedicated test accounts.

**Q: How often should I run tests?**
A: Before every deployment and weekly for regression testing.

### Getting Help

1. **Check logs**: `grep -i "error" test_results_*/*.log`
2. **Review edge function logs**: `npx supabase functions logs <name> --tail`
3. **Check Firebase logs**: `firebase functions:log --limit 100`
4. **Verify environment**: `echo $SUPABASE_URL $SUPABASE_KEY`
5. **Test connectivity**: `curl -I $SUPABASE_URL`

## Test Data Management

### Reset Test Environment

```bash
# Clear old test results
rm -rf test_results_*

# Reset transcription costs
npx supabase db execute "DELETE FROM transcription_usage_daily WHERE usage_date = CURRENT_DATE;"

# List active sessions
curl -s "$SUPABASE_URL/rest/v1/video_call_sessions?status=eq.active" \
  -H "apikey: $SUPABASE_KEY" | jq '.[] | .id'
```

### Test Data Cleanup

```bash
# Delete old test sessions (older than 24 hours)
npx supabase db execute "
  DELETE FROM video_call_sessions
  WHERE created_at < NOW() - INTERVAL '24 hours'
  AND appointment_id LIKE 'test-%';
"

# Archive test results
tar -czf test_results_archive_$(date +%Y%m%d).tar.gz test_results_*/
```

## See Also

- [CLAUDE.md](CLAUDE.md) - Project configuration and architecture
- [Chime SDK Documentation](https://aws.amazon.com/chime/sdk/)
- [AWS Transcribe Medical](https://docs.aws.amazon.com/transcribe/latest/dg/medical.html)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
