# How to Find Your PowerSync Instance URL

**Your PowerSync Dashboard:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/68f7dabe05eb05000765f43a

---

## Quick Steps to Find Instance URL

### Option 1: Check Instance Settings

1. **Open your PowerSync Dashboard** (link above)
2. Look for **"Instance"** or **"Instances"** in the left sidebar
3. Click on your instance/app
4. Look for one of these sections:
   - **"Instance Details"**
   - **"Connection Settings"**
   - **"Endpoint"**
   - **"Instance URL"**

5. You should see a URL in one of these formats:
   ```
   https://[instance-id].journeyapps.com
   https://[region]-[instance-id].journeyapps.com
   wss://[instance-id].journeyapps.com
   ```

### Option 2: Check Overview/Home

1. On the main dashboard page
2. Look for **"Endpoint"** or **"Instance URL"** in the overview card
3. It may be labeled as:
   - "Sync Endpoint"
   - "PowerSync Endpoint"
   - "Instance Address"

### Option 3: Look in Settings

1. Click the **Settings** gear icon (⚙️)
2. Look for **"General"** or **"Instance"** tab
3. Find **"Instance URL"** or **"Endpoint URL"**

---

## What the URL Should Look Like

**Correct formats:**
- ✅ `https://68f7dabe05eb05000765f43a.journeyapps.com`
- ✅ `https://us-east-68f7dabe.journeyapps.com`
- ✅ `wss://prod-instance123.journeyapps.com`

**NOT these (these are dashboard URLs):**
- ❌ `https://powersync.journeyapps.com/org/...`
- ❌ `https://powersync.journeyapps.com/app/...`

---

## Once You Have the Instance URL

**Reply with the instance URL** and I'll use the PowerSync MCP tools to:

1. ✅ Check instance health
2. ✅ Get sync status
3. ✅ Configure bucket info
4. ✅ Set up Supabase secrets automatically
5. ✅ Test the complete integration

**Example reply:**
```
My instance URL is: https://68f7dabe05eb05000765f43a.journeyapps.com
```

---

## Alternative: I Can Guide You Through the Dashboard

If you can't find the instance URL, you can:

1. **Take a screenshot** of your PowerSync Dashboard main page
2. **Share it** with me
3. I'll help you locate the instance URL

Or describe what you see on your dashboard and I'll guide you to the right section.

---

## Why We Need This

The PowerSync MCP tools I have available can:

- **Check instance health** - Verify your PowerSync instance is running properly
- **Get sync status** - See if data is syncing correctly
- **Monitor connections** - See active client connections
- **Get sync metrics** - Check performance and data volume
- **Configure buckets** - Verify sync rules are working

But all these tools need the **instance URL** to connect to your PowerSync service.

---

**Next Step:** Find your instance URL and share it with me! 🚀
