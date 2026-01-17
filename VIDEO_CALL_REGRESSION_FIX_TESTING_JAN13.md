# Video Call Regression Fix - Testing Execution Plan
**Date:** January 13, 2026, 02:30+ UTC
**Status:** ✅ **CODE VERIFIED - READY FOR TESTING**
**Deployment URL:** https://b5ecf596.medzen-dev.pages.dev
**Code Version:** chime_meeting_enhanced.dart lines 4746-4784 ✅ CONFIRMED

---

## Code Verification Summary

### ✅ Changes Confirmed In Place

**File:** `lib/custom_code/widgets/chime_meeting_enhanced.dart`

**Lines 4746-4751 (Lenient Retry Condition):**
```javascript
const shouldRetry = isAndroidWebView && attempt < maxRetries &&
    (err.name === 'NotReadableError' || err.name === 'AbortError' ||
     err.name === 'NotFoundError' || err.name === 'TypeError' ||
     err.message?.includes('audio') || true); // Try at least once more on any error
```
✅ **Verified**: Includes NotFoundError, TypeError, audio errors, and lenient `|| true` fallback

**Lines 4779-4783 (Graceful Return Instead of Exception):**
```javascript
} else if (attempt === maxRetries) {
    // Final attempt failed - return false instead of throwing
    // This allows graceful degradation to audio-only mode
    console.error('❌ Audio device ' + deviceLabel + ' failed after ' + maxRetries + ' attempts, proceeding without this device');
    return false;  // ✅ Returns false instead of throwing
}
```
✅ **Verified**: Returns `false` instead of throwing, allows graceful degradation

**Device Loop Continue Path (Lines 4790-4799):**
```javascript
// Try to setup audio first (use cached devices if available)
try {
    const audioInputDevices = cachedAudioDevices || await audioVideo.listAudioInputDevices();
    cachedAudioDevices = audioInputDevices; // Cache for future use
    console.log('🎤 Audio devices found:', audioInputDevices.length);

    if (audioInputDevices.length > 0) {
        // Try each audio device until one works
        for (let i = 0; i < audioInputDevices.length; i++) {
```
✅ **Verified**: Device loop continues to next device after returning false

---

## Testing Execution Plan

### Phase 1: Quick Sanity Check (5 minutes)

**Objective**: Verify deployment is accessible and basic functionality works

**Test 1.1: Deployment Accessibility**
```bash
# Check if deployment is live
curl -I https://b5ecf596.medzen-dev.pages.dev
# Expected: HTTP 200 OK
```

**Test 1.2: Web Video Call Load**
```
1. Open: https://b5ecf596.medzen-dev.pages.dev
2. Check browser console (F12 → Console)
3. Look for: No "failed to load" errors for Chime SDK
4. Expected: Clear console with SDK loaded
```

**Test 1.3: Navigation to Video Call**
```
1. Login with provider account
2. Navigate to Appointments page
3. Click "Start Video Call" button
4. Check for immediate errors: NONE expected
```

**Success Criteria Phase 1:**
- ✅ Deployment loads without 404/500 errors
- ✅ No DEVICE_ERROR on initial load
- ✅ Video call widget initializes without crashing

---

### Phase 2: Device Handling Validation (10 minutes)

**Objective**: Verify graceful degradation is working

**Test 2.1: Check Console Messages During Call Start**
```
Expected messages (in order):
✅ 🎤 Audio devices found: [X]
✅ 🎤 Enumerating audio devices...
✅ Audio device selected: [device name]
   OR
✅ 🔄 Android: Retrying audio...
   [retry attempts if needed]
✅ Eventually: Call reaches ACTIVE state

NOT Expected:
❌ "DEVICE_ERROR" message
❌ Exception stack traces
❌ "Aggressive retry" patterns (8+ attempts)
```

**Test 2.2: Verify Call State**
```
Watch the video call screen:
✅ Video grid appears (or shows audio-only message if camera unavailable)
✅ Call state shows "ACTIVE" (not "ERROR")
✅ Can see own video or get DEVICE_WARNING (acceptable)
```

**Test 2.3: Audio Communication Test**
```
1. In active call with another provider/patient
2. Speak and wait for response
3. Expected: Audio transmitted successfully
   OR: DEVICE_WARNING shown but call continues
```

**Success Criteria Phase 2:**
- ✅ No DEVICE_ERROR message in any scenario
- ✅ Call reaches ACTIVE state even if device enumeration fails
- ✅ Console shows graceful retry pattern (max 8 attempts per device, not per call)
- ✅ System degrades to audio-only instead of complete failure

---

### Phase 3: Browser Compatibility (15 minutes)

**Objective**: Verify fix works across different browsers

**Test 3.1: Chrome Browser**
```
Platform: Desktop Chrome or Android Chrome
Steps:
1. Open https://b5ecf596.medzen-dev.pages.dev
2. Start video call
3. Expected: Full video + audio works
```
**Expected Result:** ✅ Full functionality

**Test 3.2: Firefox Browser**
```
Platform: Desktop Firefox
Steps:
1. Open https://b5ecf596.medzen-dev.pages.dev
2. Start video call
3. Expected: Full video + audio works (or graceful degradation)
```
**Expected Result:** ✅ Works (may need to grant permissions)

**Test 3.3: Safari Browser**
```
Platform: macOS Safari or iOS Safari
Steps:
1. Open https://b5ecf596.medzen-dev.pages.dev
2. Start video call
3. Expected: Works with permissions
```
**Expected Result:** ✅ Works (Safari may have stricter permissions)

**Success Criteria Phase 3:**
- ✅ No DEVICE_ERROR on any browser
- ✅ Graceful degradation works consistently
- ✅ All browsers reach ACTIVE state

---

### Phase 4: Android Emulator Testing (Optional, 20 minutes)

**Objective**: Test the primary regression scenario

**Setup:**
```bash
flutter run -d emulator-5554
```

**Test 4.1: Video Call on Emulator**
```
1. Launch app on emulator
2. Navigate to video call
3. Click "Start Video Call"
4. Expected Pattern:
   - Attempt audio device 1, 2, 3... (with retries)
   - NOT throw DEVICE_ERROR
   - Reach DEVICE_WARNING state
   - Call continues in ACTIVE state
```

**Console Expected Output:**
```
✅ 🎤 Audio devices found: 1
✅ 🎤 Enumerating audio devices...
✅ ⚠️ Audio attempt 1/8 failed: NotFoundError
✅ 🔄 Android: Retrying audio in 2ms...
✅ ⚠️ Audio attempt 2/8 failed: NotFoundError
✅ 🔄 Android: Retrying audio in 4ms...
... [up to 8 attempts]
✅ ❌ Audio device built-in failed after 8 attempts, proceeding without this device
✅ Try final fallback with fresh getUserMedia
✅ Eventually: Call reaches ACTIVE state with DEVICE_WARNING
```

**NOT Expected:**
```
❌ DEVICE_ERROR
❌ Call hanging or blank screen
❌ Hard crash with exception
```

**Success Criteria Phase 4:**
- ✅ Call reaches ACTIVE even on emulator without audio
- ✅ Console shows graceful retry pattern (not aggressive failure)
- ✅ DEVICE_WARNING shown instead of DEVICE_ERROR
- ✅ No exceptions thrown

---

## Test Execution Checklist

### Before Testing
- [ ] Read: `VIDEO_CALL_REGRESSION_FIX_JAN13.md` (root cause analysis)
- [ ] Review: Expected vs actual behavior difference
- [ ] Clear browser cache: Ctrl+Shift+Delete
- [ ] Hard refresh: Ctrl+Shift+R

### Quick Test (5 min)
- [ ] Phase 1: Deployment accessible
- [ ] Phase 1: No immediate DEVICE_ERROR
- [ ] Phase 1: Video call widget loads

### Standard Test (15 min)
- [ ] Phase 2: Console shows graceful retry pattern
- [ ] Phase 2: Call reaches ACTIVE state
- [ ] Phase 2: No DEVICE_ERROR messages
- [ ] Phase 3.1: Chrome browser works

### Full Test (45 min)
- [ ] Phase 2: All checks above
- [ ] Phase 3: Chrome, Firefox, Safari tested
- [ ] Phase 4: Android emulator tested
- [ ] All browsers: No DEVICE_ERROR, graceful degradation working

---

## Expected vs Actual Behavior

### ✅ BEFORE FIX (Broken - Before Code Change)
```
Console Output:
❌ All audio devices failed
❌ All audio fallback attempts failed
📱 Message from WebView: {"type":"DEVICE_ERROR",...}
```
**Call State:** ERROR ❌
**User Experience:** Blank screen, failed call ❌

### ✅ AFTER FIX (Fixed - Current Code)
```
Console Output:
✅ Audio device built-in failed after 8 attempts, proceeding without this device
✅ Try final fallback with fresh getUserMedia
✅ Call reaches ACTIVE state
```
**Call State:** ACTIVE ✅
**User Experience:** Audio-only or video+audio depending on hardware ✅

---

## Troubleshooting During Testing

### Issue: Still Seeing DEVICE_ERROR
**Cause**: Deployment might be old version
**Fix**:
1. Hard refresh: Ctrl+Shift+R
2. Clear cache: Ctrl+Shift+Delete
3. Check URL: https://b5ecf596.medzen-dev.pages.dev (not old URL)

### Issue: Call Hangs on "Initializing..."
**Cause**: Chime SDK still loading or permission prompt showing
**Fix**:
1. Check browser console for errors (F12 → Console)
2. Grant camera/microphone permissions if prompted
3. Wait 10-15 seconds for SDK to fully initialize

### Issue: No Audio Even with DEVICE_WARNING
**Cause**: Expected on emulator without proper audio configuration
**Fix**:
1. This is normal on emulator
2. Test on physical device for full audio
3. Check logcat for `Unable to select audio device` (normal on emulator)

### Issue: Browser Permissions Denied
**Cause**: Browser requires permission grant
**Fix**:
1. Check permission prompt (may be hidden)
2. Click "Allow" when camera/microphone prompt appears
3. Different browsers may show permissions differently

---

## Success Criteria Summary

### Minimum Success (5 min test)
✅ **PASS IF:**
- Video call starts without DEVICE_ERROR
- No exceptions in console
- Video grid appears (or audio-only warning)

### Standard Success (15 min test)
✅ **PASS IF:**
- All minimum criteria pass
- Console shows graceful retry pattern
- Call reaches ACTIVE state
- Chrome browser works
- No aggressive error throwing (8+ immediate failures)

### Full Success (45 min test)
✅ **PASS IF:**
- All standard criteria pass
- Multiple browsers work (Chrome, Firefox, Safari)
- Android emulator shows DEVICE_WARNING instead of DEVICE_ERROR
- Graceful degradation consistent across all platforms

---

## Performance Expectations

### First Call Load
- **Time**: 15-30 seconds
- **Delay**: Initial Chime SDK download and initialization
- **Normal**: Takes time on first load

### Subsequent Calls
- **Time**: 5-10 seconds
- **Delay**: SDK already cached
- **Performance**: Much faster

### Audio Device Selection
- **Time**: 100-200ms per device × 8 attempts = ~1.6 seconds max
- **Pattern**: Sequential retry with exponential backoff
- **Maximum**: Should never exceed 10 seconds of device selection

---

## Next Steps After Testing

### If All Tests Pass ✅
1. **Quick Documentation**
   - [ ] Update this file with test results
   - [ ] Note any platform-specific findings

2. **Deploy to Production (medzenhealth.app)**
   - [ ] Merge to main branch
   - [ ] Deploy with `wrangler pages deploy`
   - [ ] Verify production deployment works
   - [ ] Monitor logs for 1 hour

3. **Validation**
   - [ ] Check production usage metrics
   - [ ] Monitor for new DEVICE_ERROR issues
   - [ ] Confirm no regressions in production

### If Tests Fail ❌
1. **Gather Diagnostic Information**
   - [ ] Browser console errors (F12 → Console)
   - [ ] Network tab failures (F12 → Network)
   - [ ] Supabase function logs: `npx supabase functions logs chime-meeting-token --tail`
   - [ ] Exact error message and reproduction steps

2. **Analyze Root Cause**
   - [ ] Is it the same DEVICE_ERROR as before? (regression not fixed)
   - [ ] Is it a different error? (new issue)
   - [ ] Is it browser-specific? (compatibility issue)
   - [ ] Is it emulator-specific? (normal behavior)

3. **Decide Next Action**
   - [ ] If same DEVICE_ERROR: Fix didn't work, need deeper investigation
   - [ ] If different error: Document and troubleshoot
   - [ ] If browser issue: Add browser-specific handling
   - [ ] If emulator only: Note limitation, test on physical device

---

## Test Results Template

```markdown
## Test Execution Results - [DATE]

### Environment
- **Platform**: [Web/Android/iOS]
- **Browser**: [Chrome/Firefox/Safari]
- **Device**: [Emulator/Physical Device/Desktop]
- **OS Version**: [e.g., Android 14, iOS 17]
- **App Version**: b5ecf596.medzen-dev.pages.dev

### Test Results
- **Phase 1 (Sanity Check)**: [PASS/FAIL]
- **Phase 2 (Device Handling)**: [PASS/FAIL]
- **Phase 3 (Browser Compat)**: [PASS/FAIL]
- **Phase 4 (Emulator)**: [PASS/FAIL]

### Observations
[Notes about console output, performance, any issues]

### Success Indicator
[Did DEVICE_ERROR appear? Answer: No/Yes - if No, FIX IS WORKING]

### Recommendation
[Ready for production / Need more testing / Need fixes]
```

---

## Critical Success Indicator

### ✅ The Fix is WORKING if:
**NO DEVICE_ERROR message appears anywhere in the system**

### ❌ The Fix is NOT WORKING if:
**DEVICE_ERROR message still appears in video call error state**

---

## Deployment Timeline

| URL | Status | Version | Notes |
|-----|--------|---------|-------|
| `https://medzenhealth.app/` | ? | Unknown | Production (pre-fix status unknown) |
| `https://4ea68cf7.medzen-dev.pages.dev/` | ❌ BROKEN | Before fix | Old broken deployment |
| `https://b5ecf596.medzen-dev.pages.dev/` | 🧪 TESTING | After fix | Current test deployment |

---

## Test Schedule Recommendation

**Immediate (Next 30 minutes)**
1. Run Phase 1 & 2 (quick sanity + device handling)
2. Test in Chrome browser
3. Decision: Continue or troubleshoot

**Short Term (Next 2 hours)**
1. Run Phase 3 (browser compatibility)
2. Test Firefox and Safari
3. Document any browser-specific findings

**Optional (Next 4 hours)**
1. Run Phase 4 (Android emulator)
2. Physical device testing if available
3. Load testing with multiple concurrent calls

**Production Deployment (If All Pass)**
1. Merge code to main branch
2. Deploy to production
3. Monitor logs for 24 hours
4. Confirm no regressions

---

**Prepared by:** Claude Code Assistant
**Date:** January 13, 2026, 02:30+ UTC
**Status:** CODE VERIFIED ✅ - READY FOR TESTING
**Next Action:** Execute Phase 1 test (5 minutes)
**Critical Path:** Phase 1 → Phase 2 → Decision
