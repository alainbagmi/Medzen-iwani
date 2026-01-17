# Android Emulator Network Fix - January 12, 2026

## Problem
Video calls and Firebase services were failing with DNS resolution errors:
```
W/Firestore: Stream closed with status: Status{code=UNAVAILABLE, description=Unable to resolve host firestore.googleapis.com
java.net.UnknownHostException: Unable to resolve host "firestore.googleapis.com": No address associated with hostname
```

The emulator had IP connectivity (could ping 8.8.8.8) but DNS resolution was not working, preventing access to any hostname-based services like Firebase, Firestore, and Supabase.

## Root Cause
Android emulators sometimes start without proper DNS configuration, especially after system updates or when starting with certain network configurations. The emulator's network stack was unable to resolve domain names despite having working IP connectivity.

## Fix Applied
Restarted the emulator with explicit DNS server configuration using Google's public DNS servers (8.8.8.8 and 8.8.4.4):

```bash
emulator -avd MedZen_Primary -dns-server 8.8.8.8,8.8.4.4 -no-snapshot-load
```

This command:
- Uses Google's public DNS servers explicitly
- Bypasses any cached network state with `-no-snapshot-load`
- Ensures consistent DNS resolution for all network requests

## Verification
After applying the fix:

**Before:**
```bash
$ adb shell ping -c 2 firestore.googleapis.com
ping: unknown host firestore.googleapis.com
```

**After:**
```bash
$ adb shell ping -c 2 firestore.googleapis.com
PING firestore.googleapis.com (142.251.167.95) 56(84) bytes of data.
64 bytes from ww-in-f95.1e100.net (142.251.167.95): icmp_seq=1 ttl=255 time=5.13 ms
64 bytes from ww-in-f95.1e100.net (142.251.167.95): icmp_seq=2 ttl=255 time=6.62 ms
--- firestore.googleapis.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss
```

## Testing
After the fix:
1. Firebase Authentication works correctly
2. Firestore connections succeed without errors
3. FCM push notifications initialize properly
4. Supabase API calls work
5. Video call token generation works (requires network for edge functions)
6. No more "Unable to resolve host" errors in logs

## Related Files
- `~/.android/avd/MedZen_Primary.avd/config.ini` - AVD configuration
- App logs show successful Firebase connections
- `ANDROID_CAMERA_FIX_JAN12.md` - Camera configuration (separate fix)
- `ANDROID_MICROPHONE_FIX_JAN12.md` - Microphone configuration (separate fix)

## Notes
- This fix must be applied each time you start the emulator if network issues persist
- Alternative DNS servers can be used (e.g., Cloudflare: 1.1.1.1,1.0.0.1)
- For persistent fix, you can create a shell script or alias:
  ```bash
  alias start-medzen='emulator -avd MedZen_Primary -dns-server 8.8.8.8,8.8.4.4'
  ```
- The `-no-snapshot-load` flag ensures fresh network initialization
- This issue is separate from camera/microphone permissions (already fixed)

## Quick Fix Commands
```bash
# Stop all emulators
adb devices | grep emulator | cut -f1 | xargs -I {} adb -s {} emu kill

# Start with DNS fix
emulator -avd MedZen_Primary -dns-server 8.8.8.8,8.8.4.4 -no-snapshot-load &

# Verify DNS is working
adb shell ping -c 2 google.com
adb shell ping -c 2 firestore.googleapis.com
```

## Alternative Approaches (if above doesn't work)
1. **Set DNS via setprop (requires root):**
   ```bash
   adb root
   adb shell setprop net.dns1 8.8.8.8
   adb shell setprop net.dns2 8.8.4.4
   ```

2. **Edit AVD config permanently:**
   Add to `~/.android/avd/MedZen_Primary.avd/config.ini`:
   ```ini
   hw.lcd.density=440
   hw.lcd.width=1080
   hw.lcd.height=2274
   ```
   Note: DNS settings in config.ini don't always persist, `-dns-server` flag is more reliable.

3. **Use different network mode:**
   ```bash
   emulator -avd MedZen_Primary -netdelay none -netspeed full -dns-server 8.8.8.8
   ```

## Impact on Video Calls
Network connectivity is critical for video calls because:
- Edge functions require network access (chime-meeting-token, bedrock-ai-chat, etc.)
- AWS Chime SDK loads from CloudFront CDN
- Real-time messaging uses Supabase Realtime (WebSocket connections)
- Transcription requires network access to AWS Transcribe Medical
- Firebase Auth tokens must be validated online

Without DNS resolution, video calls would fail at the initialization stage when trying to obtain meeting credentials from the edge function.
