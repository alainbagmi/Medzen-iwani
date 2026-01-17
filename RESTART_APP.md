# Hot Restart Required - ChimeMeetingEnhanced Timeout Fix Applied

## ✅ Fix Applied
Changed SDK timeout from 60s → 120s in `ChimeMeetingEnhanced` widget

## 🔄 How to Restart

### Option 1: Hot Restart (Fastest)
1. Go to the terminal where Flutter is running
2. Press **`R`** (capital R) to hot restart
3. Wait for "Restarted application" message

### Option 2: Manual Restart
```bash
# Stop the app
# Press 'q' in the terminal

# Restart
flutter run -d emulator-5554
```

### Option 3: From DevTools
1. Open: http://127.0.0.1:9101
2. Click "Hot Restart" button

## ✅ After Restart - Test Again
1. Join video call
2. Wait up to 120 seconds for SDK to load
3. Verify: "Chime SDK loaded and ready" appears
4. Test chat messaging

## 📋 What Changed
```dart
// Before (60s timeout):
_sdkLoadTimeout = Timer(const Duration(seconds: 60), () {
  debugPrint('❌ Chime SDK load timeout after 60 seconds');

// After (120s timeout):
_sdkLoadTimeout = Timer(const Duration(seconds: 120), () {
  debugPrint('❌ Chime SDK load timeout after 120 seconds');
```

## 🔍 Expected Behavior
- Emulator: SDK should load within 120 seconds
- Physical device: SDK loads in 5-10 seconds
- No more premature timeout errors
