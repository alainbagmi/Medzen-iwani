# Update ChimeMeetingWebview Widget in FlutterFlow

## Problem
FlutterFlow is loading old code that tries to load `assets/html/chime_meeting.html`, but the new version uses self-contained HTML.

Error:
```
Invalid argument(s) (key): Asset for key "assets/html/chime_meeting.html" not found.
```

## Solution: Update Custom Widget in FlutterFlow

### Step 1: Copy the Widget Code

The correct widget code is in:
```
/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/lib/custom_code/widgets/chime_meeting_webview.dart
```

### Step 2: Update in FlutterFlow UI

1. **Open FlutterFlow Editor** (https://app.flutterflow.io/)

2. **Navigate to Custom Code**:
   - Left sidebar → Custom Code
   - Select "Widgets" tab
   - Find `ChimeMeetingWebview` widget

3. **Replace the Code**:
   - Click on `ChimeMeetingWebview` to edit
   - **DELETE ALL EXISTING CODE** in the editor
   - **PASTE THE ENTIRE CONTENTS** of `chime_meeting_webview.dart`
   - Make sure to include everything from line 1 to line 646

4. **Key Verification Points**:
   - Line 142 should have: `..loadHtmlString(_getChimeHTML());`
   - Line 225 should have: `String _getChimeHTML() {`
   - Line 233 should have: `<script src="https://cdn.jsdelivr.net/npm/amazon-chime-sdk-js@3.19.0/build/amazon-chime-sdk.min.js"`
   - Should be approximately 646 lines total

5. **Save Changes**:
   - Click "Save" in FlutterFlow
   - Wait for compilation to complete
   - FlutterFlow will recompile the custom widget

### Step 3: Test the Changes

1. **Run on Mobile Device** (not just local):
   - FlutterFlow → Test Mode
   - Or deploy to TestFlight/Firebase App Distribution

2. **Verify Video Call**:
   - Navigate to Join Call page
   - Tap "Join Video Call"
   - Should see Chime SDK loading without asset errors

## Why This Happened

**Local Development:**
- Uses the new `ChimeMeetingWebview` code from your repository
- Loads HTML directly via `loadHtmlString()`
- No external asset files needed

**FlutterFlow Platform:**
- Still has old version of the widget
- Tries to load `assets/html/chime_meeting.html`
- Fails because asset doesn't exist (and isn't needed)

## Common Mistakes to Avoid

❌ **DON'T** just add the HTML file to assets - this doesn't fix the root cause
❌ **DON'T** update only part of the widget - replace the entire code
❌ **DON'T** forget to save in FlutterFlow - changes must be saved on their platform
❌ **DON'T** test only locally - FlutterFlow needs its own widget updated

## Verification Checklist

- [ ] Opened FlutterFlow editor
- [ ] Found ChimeMeetingWebview in Custom Code → Widgets
- [ ] Replaced entire widget code
- [ ] Verified line 142 has `loadHtmlString(_getChimeHTML())`
- [ ] Saved changes in FlutterFlow
- [ ] Waited for compilation to complete
- [ ] Tested on FlutterFlow platform (not just local)
- [ ] Video call works without asset errors

## Alternative: Use FlutterFlow CLI (if available)

If you have FlutterFlow CLI access:

```bash
# Push custom widget to FlutterFlow
flutterflow push --widget ChimeMeetingWebview \
  --file lib/custom_code/widgets/chime_meeting_webview.dart
```

## If Problems Persist

1. **Clear FlutterFlow Cache**:
   - FlutterFlow → Settings → Clear Cache
   - Re-save the widget

2. **Check Widget Dependencies**:
   - Verify `webview_flutter` package is in dependencies
   - Should be version `4.13.0` or higher

3. **Check pubspec.yaml**:
   - `assets/html/` should NOT be needed
   - If present, it's safe to remove

4. **Compare Widget Code**:
   - In FlutterFlow, click "View Code" on ChimeMeetingWebview
   - Compare with local file - they should be identical
   - Look specifically for `loadHtmlString` vs `loadFlutterAsset`

## Post-Update Actions

After updating the widget in FlutterFlow:

1. **Re-export Project** (optional but recommended):
   ```bash
   # Download latest export from FlutterFlow
   # Extract to temporary location
   # Use safe-reexport.sh to merge changes
   ./safe-reexport.sh ~/Downloads/export.zip
   ```

2. **Commit Changes**:
   ```bash
   git add lib/custom_code/widgets/chime_meeting_webview.dart
   git commit -m "feat: Sync ChimeMeetingWebview widget with FlutterFlow"
   git push origin main
   ```

## Success Indicators

✅ No "Asset for key 'assets/html/chime_meeting.html' not found" error
✅ Video call initializes properly
✅ Chime SDK loads from CDN
✅ Local and FlutterFlow builds work identically
✅ Can join video calls from both provider and patient sides

## Need Help?

If the issue persists:
1. Check FlutterFlow's custom widget editor shows the new code
2. Verify the widget was actually saved (check timestamp)
3. Try creating a NEW custom widget with the correct code
4. Contact FlutterFlow support about widget syncing issues
