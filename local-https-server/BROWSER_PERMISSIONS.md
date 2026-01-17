# MedZen Web App - Browser Permission Guide

## Access URL
```
https://10.10.11.138:8443
```

Access from any device on the same network using this URL.

---

## Step 1: Accept Self-Signed Certificate

Since this is a local development server with a self-signed certificate, you'll see a security warning. Here's how to proceed in each browser:

### Google Chrome
1. You'll see "Your connection is not private" warning
2. Click **Advanced** (bottom left)
3. Click **Proceed to 10.10.11.138 (unsafe)**
4. The page will load

### Mozilla Firefox
1. You'll see "Warning: Potential Security Risk Ahead"
2. Click **Advanced...**
3. Click **Accept the Risk and Continue**
4. The page will load

### Safari (macOS)
1. You'll see "This Connection Is Not Private"
2. Click **Show Details**
3. Click **visit this website**
4. Enter your Mac password if prompted
5. Click **Visit Website**

### Microsoft Edge
1. You'll see "Your connection isn't private" warning
2. Click **Advanced**
3. Click **Continue to 10.10.11.138 (unsafe)**
4. The page will load

### Opera
1. You'll see a security warning
2. Click **Help me understand** or **Advanced**
3. Click **Proceed to 10.10.11.138 (unsafe)**
4. The page will load

### Brave
1. You'll see "Your connection is not private" warning
2. Click **Advanced**
3. Click **Proceed to 10.10.11.138 (unsafe)**
4. The page will load

---

## Step 2: Grant Camera & Microphone Permissions

When you start a video call, the app will request camera and microphone access. Here's how to grant permissions in each browser:

### Google Chrome

**When prompted:**
1. A popup appears asking "10.10.11.138 wants to use your camera and microphone"
2. Click **Allow**

**If blocked or to change settings:**
1. Click the **lock/info icon** (🔒) in the address bar
2. Find **Camera** and **Microphone** settings
3. Change both to **Allow**
4. Click outside the popup to close
5. **Refresh the page** (Ctrl+R / Cmd+R)

**Via Chrome Settings:**
1. Go to `chrome://settings/content/camera`
2. Add `https://10.10.11.138:8443` to "Allowed" list
3. Go to `chrome://settings/content/microphone`
4. Add `https://10.10.11.138:8443` to "Allowed" list

### Mozilla Firefox

**When prompted:**
1. A popup appears asking to share camera and microphone
2. Select your camera and microphone devices from dropdowns
3. Check "Remember this decision" (optional)
4. Click **Allow**

**If blocked or to change settings:**
1. Click the **shield icon** (🛡️) in the address bar
2. Click **Connection secure** > **More Information**
3. Go to **Permissions** tab
4. Find **Use the Camera** and **Use the Microphone**
5. Uncheck "Use Default" and select **Allow**
6. Close the dialog and **refresh the page**

**Via Firefox Settings:**
1. Go to `about:preferences#privacy`
2. Scroll to **Permissions**
3. Click **Settings...** next to Camera
4. Add `https://10.10.11.138:8443` and set to **Allow**
5. Repeat for Microphone

### Safari (macOS)

**When prompted:**
1. A dialog appears asking to allow camera and microphone
2. Click **Allow** for each

**If blocked or to change settings:**
1. Go to **Safari** menu > **Settings for This Website...**
2. Find **Camera** and **Microphone** dropdowns
3. Change both to **Allow**
4. Close the dialog and **refresh the page**

**Via Safari Preferences:**
1. Go to **Safari** > **Preferences** > **Websites**
2. Select **Camera** from the left sidebar
3. Find `10.10.11.138` and set to **Allow**
4. Select **Microphone** and do the same

### Microsoft Edge

**When prompted:**
1. A popup appears asking to allow camera and microphone
2. Click **Allow**

**If blocked or to change settings:**
1. Click the **lock icon** (🔒) in the address bar
2. Click **Site permissions**
3. Find **Camera** and **Microphone**
4. Toggle both to **Allow**
5. **Refresh the page**

**Via Edge Settings:**
1. Go to `edge://settings/content/mediaAutoplay`
2. Then `edge://settings/content/camera`
3. Add `https://10.10.11.138:8443` to allowed list
4. Repeat for microphone

### Opera

**When prompted:**
1. A popup appears asking for camera/microphone access
2. Click **Allow**

**If blocked:**
1. Click the **lock icon** in the address bar
2. Find Camera and Microphone settings
3. Set both to **Allow**
4. **Refresh the page**

### Brave

**When prompted:**
1. A popup appears asking for permissions
2. Click **Allow**

**If blocked:**
1. Click the **lion icon** (Brave Shields)
2. Then click the **lock icon** in the address bar
3. Find Camera and Microphone
4. Set both to **Allow**
5. **Refresh the page**

---

## Troubleshooting

### "Permission denied" or camera/mic not working

1. **Check hardware:** Ensure your camera and microphone are connected and working
2. **Check other apps:** Close other apps that might be using the camera (Zoom, Teams, etc.)
3. **Browser restart:** Close all browser windows and reopen
4. **System permissions (macOS):**
   - Go to **System Preferences** > **Security & Privacy** > **Privacy**
   - Select **Camera** and ensure your browser is checked
   - Select **Microphone** and ensure your browser is checked
5. **System permissions (Windows):**
   - Go to **Settings** > **Privacy** > **Camera**
   - Ensure "Allow apps to access your camera" is ON
   - Ensure your browser is in the allowed list
   - Repeat for Microphone

### "NotFoundError" - No camera/microphone detected

1. Check if your camera/microphone is properly connected
2. Check Device Manager (Windows) or System Information (macOS) to verify detection
3. Try a different USB port
4. Install/update device drivers

### "NotReadableError" - Device in use by another application

1. Close all other video conferencing apps (Zoom, Teams, Skype, etc.)
2. Close other browser tabs that might be using the camera
3. Restart the browser
4. If on Windows, check Task Manager for processes using the camera

### "SecurityError" - Not HTTPS

This shouldn't happen with our HTTPS server, but if you see this:
1. Make sure you're using `https://` not `http://`
2. Make sure you accepted the certificate warning

### Video call shows "Initializing..." forever

1. Check browser console (F12 > Console) for errors
2. Ensure you're logged in to the app
3. Check that the other participant has joined
4. Try refreshing the page

---

## Browser Compatibility

| Browser | Camera | Microphone | WebRTC | Status |
|---------|--------|------------|--------|--------|
| Chrome (Desktop) | ✅ | ✅ | ✅ | Recommended |
| Firefox (Desktop) | ✅ | ✅ | ✅ | Fully Supported |
| Safari (macOS) | ✅ | ✅ | ✅ | Fully Supported |
| Edge (Chromium) | ✅ | ✅ | ✅ | Fully Supported |
| Opera | ✅ | ✅ | ✅ | Fully Supported |
| Brave | ✅ | ✅ | ✅ | Fully Supported |
| Chrome (Android) | ✅ | ✅ | ✅ | Supported |
| Safari (iOS) | ✅ | ✅ | ✅ | Supported |
| Internet Explorer | ❌ | ❌ | ❌ | Not Supported |

**Note:** Internet Explorer does not support WebRTC or modern media APIs. Please use Microsoft Edge or another modern browser.

---

## Server Information

- **Local URL:** https://localhost:8443
- **Network URL:** https://10.10.11.138:8443
- **SSL:** Self-signed certificate (development only)
- **CORS:** Enabled for local development

To stop the server, press `Ctrl+C` in the terminal where it's running, or run:
```bash
pkill -f "serve.py"
```

To restart the server:
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/local-https-server
python3 serve.py
```
