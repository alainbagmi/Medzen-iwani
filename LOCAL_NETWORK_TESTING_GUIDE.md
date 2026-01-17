# Local Network Testing Guide for Video Calls

## Quick Start

Your MedZen app is now configured to run on your local network, allowing you to test video calls from any device (phone, tablet, computer) connected to the same WiFi.

### Your Network Configuration

- **Local IP Address:** `192.168.1.239`
- **Port:** `8080`
- **WiFi Network:** Make sure all devices are on the same WiFi network

---

## Access URLs

### From This Computer (Mac)
```
http://localhost:8080
```

### From Other Devices (Phone, Tablet, etc.)
```
http://192.168.1.239:8080
```

---

## How to Start the Server

### Option 1: Use the Debug Script (Recommended)
```bash
./start_web_server_debug.sh
```

This will:
- ✅ Check if port is available
- ✅ Show all access URLs
- ✅ Enable verbose debugging
- ✅ Log all output to `logs/` directory
- ✅ Display errors in real-time

### Option 2: Manual Start
```bash
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080 -v
```

---

## Testing Video Calls on Your Phone

1. **Connect your phone to the same WiFi as your Mac**
   - Open WiFi settings
   - Connect to the same network as your development machine

2. **Open the URL on your phone's browser:**
   ```
   http://192.168.1.239:8080
   ```

3. **Test the video call:**
   - Log in with test credentials
   - Navigate to scheduled appointment
   - Click "Join Video Call"
   - Grant camera/microphone permissions when prompted

4. **Test with another device simultaneously:**
   - Open the same URL on another phone/tablet
   - Log in with a different user (provider/patient)
   - Join the same video call
   - You should see each other in the video grid

---

## Troubleshooting

### Issue: "Site can't be reached" on phone

**Cause:** Firewall blocking connections or wrong network

**Solutions:**

1. **Check you're on the same WiFi:**
   ```bash
   # On Mac, verify your network
   networksetup -getairportnetwork en0

   # On phone, go to WiFi settings and verify network name matches
   ```

2. **Allow incoming connections (macOS Firewall):**
   - System Settings → Network → Firewall
   - Click "Options"
   - Ensure "Block all incoming connections" is OFF
   - Or add Flutter to allowed apps

3. **Try a different browser on phone:**
   - Chrome (recommended)
   - Safari
   - Firefox

4. **Verify server is running:**
   ```bash
   # Check if port 8080 is listening
   lsof -i :8080
   ```

### Issue: Port 8080 already in use

**Error:**
```
Port 8080 is already in use!
```

**Solution:**
```bash
# Kill the process using port 8080
kill -9 $(lsof -ti:8080)

# Then restart the server
./start_web_server_debug.sh
```

### Issue: Video call fails with SDK timeout

**Cause:** Same as emulator - CDN loading issues

**Solution:**
The web version should work better than the emulator because:
- ✅ Better WebView/browser implementation
- ✅ Direct network access (no emulator isolation)
- ✅ Proper WebRTC support

If it still fails:
1. Check browser console for errors (F12)
2. Verify internet connectivity on the phone
3. Try on WiFi vs mobile data

### Issue: Camera/microphone not working

**Cause:** Browser permissions

**Solution:**

**On iOS (Safari/Chrome):**
- Safari may prompt once, must allow
- Settings → Safari → Camera/Microphone → Allow

**On Android (Chrome):**
- Chrome will prompt for permissions
- Settings → Site Settings → Camera/Microphone → Allow

---

## Monitoring and Debugging

### View Real-Time Logs

The debug script logs everything to `logs/` directory:
```bash
# Follow the latest log file
tail -f logs/web_server_*.log

# Search for errors
grep -i "error\|exception\|failed" logs/web_server_*.log

# Search for video call events
grep -i "chime\|video\|sdk" logs/web_server_*.log
```

### Check Browser Console (DevTools)

**On your phone:**
1. **iPhone (Safari):**
   - Settings → Safari → Advanced → Web Inspector
   - Connect iPhone to Mac
   - Safari (Mac) → Develop → [Your iPhone] → [Page]

2. **Android (Chrome):**
   - Open `chrome://inspect` on your Mac
   - Select your phone's Chrome instance
   - Click "Inspect"

**Common errors to look for:**
- `ChimeSDK is not defined` - SDK failed to load
- `NotAllowedError` - Permissions denied
- `NetworkError` - Connection issues
- 401/403 errors - Authentication issues

### Monitor Network Requests

In browser DevTools → Network tab:
- Look for the Chime SDK JavaScript file loading
- Check API calls to Supabase edge functions
- Verify meeting token requests succeed (200 status)

---

## Testing Checklist

Before declaring video calls "working", test all these scenarios:

### Basic Functionality
- [ ] App loads on phone browser
- [ ] User can log in
- [ ] Navigation works
- [ ] Appointment list displays

### Video Call Flow
- [ ] Join call button appears
- [ ] Camera permission prompt appears
- [ ] Microphone permission prompt appears
- [ ] Permissions can be granted
- [ ] Chime SDK loads (no timeout)
- [ ] Local video preview appears
- [ ] Can toggle mute/unmute
- [ ] Can toggle video on/off

### Multi-Participant Testing
- [ ] Two devices can join same call
- [ ] Both participants see each other
- [ ] Audio works in both directions
- [ ] Video quality is acceptable
- [ ] Active speaker detection works
- [ ] Participant count updates correctly

### Network Conditions
- [ ] Works on WiFi
- [ ] Works on mobile data (if available)
- [ ] Handles poor connectivity gracefully
- [ ] Reconnects after temporary disconnect

---

## Performance Tips

### For Better Performance:

1. **Use Chrome on Android** (best WebRTC support)
2. **Use Safari on iOS** (native WebRTC)
3. **Close other tabs** (reduce memory usage)
4. **Good WiFi signal** (both devices)
5. **Clear browser cache** before testing

### Expected Performance:

| Metric | Expected Value |
|--------|----------------|
| SDK load time | < 10 seconds |
| Meeting join time | < 5 seconds |
| Video latency | < 500ms |
| Audio latency | < 300ms |
| Frame rate | 15-30 fps |

---

## Network Diagnostics

### From Your Mac

```bash
# Verify you can reach the CDN
curl -I https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js

# Check your local IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Verify port is listening on all interfaces
lsof -i :8080 | grep LISTEN

# Test local network access
curl http://192.168.1.239:8080
```

### From Your Phone

Open this URL to test internet connectivity:
```
https://www.google.com
```

Then open your app:
```
http://192.168.1.239:8080
```

---

## Hot Reload for Development

While the server is running, you can hot reload changes:

```
Press 'r' in the terminal - Hot reload (fast, preserves state)
Press 'R' in the terminal - Hot restart (full restart)
Press 'q' in the terminal - Quit server
```

Any code changes will be reflected on all connected devices automatically (after reload).

---

## Production Testing Notes

### This is NOT a production deployment

This local network setup is for **development and testing only**. Do NOT use this for:
- ❌ Real patient appointments
- ❌ Production environment
- ❌ External access (outside your WiFi)
- ❌ HIPAA-compliant data

### For Production:

1. Deploy to Firebase Hosting or similar
2. Use HTTPS (required for camera/microphone)
3. Proper domain name
4. SSL certificate
5. CDN for assets

---

## Security Notes

### Current Setup:
- ⚠️ HTTP only (not HTTPS)
- ⚠️ Local network only
- ⚠️ No authentication on network level
- ⚠️ Development mode

### This means:
- ✅ Safe for local testing
- ✅ Anyone on your WiFi can access
- ❌ Not encrypted
- ❌ Not suitable for production

---

## Quick Reference Commands

```bash
# Start server with debugging
./start_web_server_debug.sh

# Check if server is running
lsof -i :8080

# Kill the server
kill -9 $(lsof -ti:8080)

# View logs
tail -f logs/web_server_*.log

# Clean build (if issues)
flutter clean && flutter pub get

# Check Flutter web
flutter doctor -v

# Rebuild web
flutter build web --release
```

---

## Alternative: Use ngrok for External Access

If you want to test from outside your local network (e.g., from mobile data):

```bash
# Install ngrok
brew install ngrok

# Start ngrok tunnel
ngrok http 8080

# Use the provided HTTPS URL
# Example: https://abc123.ngrok.io
```

**Benefits:**
- ✅ HTTPS automatically
- ✅ Works from anywhere
- ✅ Public URL for testing

**Note:** Free tier has limitations

---

## Support

If you encounter issues:

1. Check logs in `logs/` directory
2. Check browser console (F12)
3. Run diagnostics: `./fix_video_call_emulator_issues.sh`
4. See detailed guide: `VIDEO_CALL_EMULATOR_FIX_GUIDE.md`

---

## Summary

**To start testing video calls on your phone:**

1. **Start the server:**
   ```bash
   ./start_web_server_debug.sh
   ```

2. **Open on your phone:**
   ```
   http://192.168.1.239:8080
   ```

3. **Test video call:**
   - Log in
   - Join appointment
   - Grant permissions
   - Video call should work!

**Why this works better than emulator:**
- ✅ Real device hardware (camera, mic)
- ✅ Better browser WebRTC support
- ✅ No emulator network isolation
- ✅ Actual user experience

Happy testing! 🎥
