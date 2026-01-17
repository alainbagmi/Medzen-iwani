# Video Call Initialization Fix Plan

## Issues Identified

### 1. Video Call Stuck on "Initializing..." Status
The video call can hang indefinitely at multiple points in the initialization flow with no timeout or error recovery.

### 2. Malformed Image URL (Reverted Fix)
The fix for the malformed image URL in `chime_video_call_page_widget.dart:164` was reverted, causing runtime errors.

## Root Causes

### Critical Blocking Points (No Timeouts)
1. **HTTP Request Timeout** (`join_room.dart:216`)
   - Edge function call has no timeout parameter
   - Can hang indefinitely if network issues or function errors

2. **WebView Load Timeout** (`chime_meeting_webview.dart:59-86`)
   - Waits for `onProgress: 100%` that may never arrive
   - If Chime SDK CDN fails to load, app hangs forever

3. **Media Permission Timeout** (`chime_meeting_webview.dart:362-365`)
   - JavaScript `getUserMedia()` can hang if permissions are stuck
   - No timeout recovery in JS code

4. **No Error Recovery UI**
   - Users cannot retry if initialization fails
   - No way to exit stuck state without force-closing app

## Implementation Plan

### Phase 1: Add Timeouts to Critical Operations

#### File: `lib/custom_code/actions/join_room.dart`

**Change 1: Add HTTP request timeout (line 216)**
```dart
// BEFORE:
final response = await http.post(
  Uri.parse(functionUrl),
  headers: {
    'X-Firebase-Token': userToken,
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'action': action,
    'appointmentId': appointmentId,
    if (meetingId != null) 'meetingId': meetingId,
  }),
);

// AFTER:
final response = await http.post(
  Uri.parse(functionUrl),
  headers: {
    'X-Firebase-Token': userToken,
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'action': action,
    'appointmentId': appointmentId,
    if (meetingId != null) 'meetingId': meetingId,
  }),
).timeout(
  const Duration(seconds: 15),
  onTimeout: () {
    throw TimeoutException('Video call setup timed out. Please try again.');
  },
);
```

**Import required:**
Add `import 'dart:async';` at the top of the file.

---

#### File: `lib/custom_code/widgets/chime_meeting_webview.dart`

**Change 2: Add WebView initialization timeout**

Add a Timer in the `_ChimeMeetingWebviewState` class:

```dart
class _ChimeMeetingWebviewState extends State<ChimeMeetingWebview> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  Timer? _initializationTimer; // ADD THIS
  bool _hasTimedOut = false; // ADD THIS

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    // ADD THIS: Start initialization timeout
    _initializationTimer = Timer(const Duration(seconds: 20), () {
      if (_isLoading && !_hasTimedOut) {
        setState(() {
          _hasTimedOut = true;
          _isLoading = false;
        });
        _showTimeoutError();
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _initializationTimer?.cancel(); // ADD THIS
    super.dispose();
  }

  void _showTimeoutError() {
    // ADD THIS METHOD
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Video call initialization timed out. Please check your connection and try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Close',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && _isLoading && !_hasTimedOut) {
              _initializationTimer?.cancel(); // ADD THIS
              setState(() => _isLoading = false);
              _joinMeeting();
            }
          },
          onPageStarted: (String url) {
            if (!_hasTimedOut) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (!_hasTimedOut) {
              setState(() => _isLoading = false);
            }
          },
          // ADD THIS: Handle navigation errors
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            _initializationTimer?.cancel();
            if (!_hasTimedOut) {
              setState(() {
                _hasTimedOut = true;
                _isLoading = false;
              });
              _showTimeoutError();
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessageFromWebView(message.message);
        },
      )
      ..loadHtmlString(_getChimeHTML());
  }
```

**Import required:**
Add `import 'dart:async';` at the top of the file.

**Change 3: Add JavaScript-level timeout for media permissions**

In the `_getChimeHTML()` method, modify the `joinMeeting` function (around line 362-365):

```javascript
// BEFORE:
updateStatus('Requesting permissions...', 'connecting');
const stream = await navigator.mediaDevices.getUserMedia({
    video: true,
    audio: true
});
stream.getTracks().forEach(track => track.stop());

// AFTER:
updateStatus('Requesting permissions...', 'connecting');

// Add timeout wrapper
const mediaPromise = navigator.mediaDevices.getUserMedia({
    video: true,
    audio: true
});

const timeoutPromise = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Media permission request timed out')), 10000)
);

try {
    const stream = await Promise.race([mediaPromise, timeoutPromise]);
    stream.getTracks().forEach(track => track.stop());
} catch (error) {
    if (error.message.includes('timed out')) {
        throw new Error('Permission request timed out. Please grant camera and microphone access.');
    }
    throw error;
}
```

---

### Phase 2: Fix Malformed Image URL

#### File: `lib/home_pages/chime_video_call_page/chime_video_call_page_widget.dart`

**Change 4: Replace malformed image URL with proper fallback (line 157-173)**

```dart
// BEFORE:
Material(
  color: Colors.transparent,
  elevation: 40.0,
  shape: const CircleBorder(),
  child: Container(
    width: 120.0,
    height: 120.0,
    decoration: BoxDecoration(
      image: DecorationImage(
        fit: BoxFit.cover,
        image: Image.network(
          '500x500?doctor',  // MALFORMED URL
        ).image,
      ),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white,
        width: 3.0,
      ),
    ),
  ),
),

// AFTER:
Material(
  color: Colors.transparent,
  elevation: 40.0,
  shape: const CircleBorder(),
  child: Container(
    width: 120.0,
    height: 120.0,
    decoration: BoxDecoration(
      color: FlutterFlowTheme.of(context).secondaryBackground,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white,
        width: 3.0,
      ),
    ),
    child: Icon(
      Icons.person,
      color: Colors.white,
      size: 60.0,
    ),
  ),
),
```

**Note:** This file may be auto-generated by FlutterFlow. If the fix gets reverted again, we need to:
1. Update the FlutterFlow project directly to use a proper image source
2. OR add a safe image loading widget that handles null/invalid URLs gracefully

---

### Phase 3: Add Error Recovery UI

#### File: `lib/custom_code/widgets/chime_meeting_webview.dart`

**Change 5: Add retry mechanism**

Modify the `build` method to show retry option on timeout:

```dart
@override
Widget build(BuildContext context) {
  return Container(
    width: widget.width ?? double.infinity,
    height: widget.height ?? double.infinity,
    child: Stack(
      children: [
        if (!_hasTimedOut)
          WebViewWidget(controller: _webViewController),
        if (_hasTimedOut)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.0,
                  color: Colors.red,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Connection Timed Out',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Unable to connect to video call',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Readex Pro',
                    color: Colors.white70,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 24.0),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasTimedOut = false;
                      _isLoading = true;
                    });
                    _initializeWebView();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        if (_isLoading && !_hasTimedOut)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Initializing video call...',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Readex Pro',
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
```

---

## Testing Plan

### 1. Timeout Testing
- **Test timeout behavior**: Turn off WiFi during initialization
- **Expected**: Should show timeout error after 20 seconds with retry option
- **Verify**: No indefinite "Initializing..." hang

### 2. Edge Function Timeout
- **Test HTTP timeout**: Comment out edge function temporarily
- **Expected**: Error message after 15 seconds
- **Verify**: User-friendly error, not stuck state

### 3. Media Permission Timeout
- **Test media timeout**: Deny permissions on first prompt
- **Expected**: Proper error message within 10 seconds
- **Verify**: Can retry and grant permissions

### 4. Normal Flow
- **Test happy path**: Normal video call with good connection
- **Expected**: Joins meeting within 5-10 seconds
- **Verify**: No regressions, video/audio work correctly

### 5. Image URL Fix
- **Test image loading**: Open chime video call page
- **Expected**: No runtime error, person icon displayed
- **Verify**: Android logs clean, no "No host specified" error

---

## Rollback Plan

If fixes cause issues:

1. **Revert timeout changes**: Remove `.timeout()` calls if they cause false positives
2. **Adjust timeout values**: Increase from 15s to 30s if legitimate calls timeout
3. **Disable retry UI**: Comment out retry UI if it conflicts with navigation

---

## Success Criteria

✅ No indefinite "Initializing..." hang
✅ Clear error messages when initialization fails
✅ Users can retry without restarting app
✅ No Android runtime errors for image URLs
✅ Video calls complete in < 10 seconds on good connection
✅ Graceful degradation on poor network

---

## Implementation Order

1. **Phase 1, Change 1**: HTTP timeout (lowest risk, highest impact)
2. **Phase 2**: Fix malformed image URL (prevents crashes)
3. **Phase 1, Change 2**: WebView timeout (medium complexity)
4. **Phase 1, Change 3**: JavaScript media timeout (higher complexity)
5. **Phase 3**: Error recovery UI (final polish)

Test after each change to isolate any issues.

---

## Additional Recommendations

### Future Enhancements
1. **Add telemetry**: Log initialization time and failure points
2. **Graceful degradation**: Offer audio-only if video fails
3. **Connection quality indicator**: Warn users about poor network before joining
4. **Pre-flight check**: Test camera/mic before attempting connection

### FlutterFlow Integration
If `chime_video_call_page_widget.dart` keeps getting regenerated:
- Update the source in FlutterFlow UI builder
- OR wrap the widget in a custom wrapper that handles image loading safely
- OR use FlutterFlow's image widget instead of raw Image.network()
