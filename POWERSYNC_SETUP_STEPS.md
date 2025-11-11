# PowerSync Setup - Step-by-Step Guide

**Your PowerSync Dashboard:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/68f7dabe05eb05000765f43a

---

## Step 1: Get Your PowerSync Instance URL (2 min)

You need to find your PowerSync instance endpoint URL.

**Follow these steps:**

1. Open your PowerSync Dashboard (link above)
2. Click on your instance/app in the dashboard
3. Look for **"Instance"** or **"Endpoint"** section
4. You should see a URL like one of these formats:
   - `https://[instance-id].powersync.journeyapps.com`
   - `https://[region]-[instance-id].powersync.journeyapps.com`
   - Or in the settings: `wss://[instance-id].powersync.journeyapps.com`

**Save this URL - you'll need it for the secrets!**

**Example:**
```
https://abc123-medzen.powersync.journeyapps.com
```

---

## Step 2: Generate PowerSync API Credentials (3 min)

In your PowerSync Dashboard:

1. Navigate to **Settings** (gear icon) or **API Keys** section
2. Look for **"Generate RSA Key Pair"** or **"Generate API Key"** button
3. Click it
4. **IMPORTANT:** Copy and save both:

   **a) Key ID** (will look like):
   ```
   abc123def456ghi789jkl
   ```

   **b) Private Key** (PEM format - copy ENTIRE block):
   ```
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
   (many lines - copy ALL of them)
   ...
   -----END PRIVATE KEY-----
   ```

⚠️ **WARNING:** You can ONLY view the private key once! If you lose it, you must generate a new pair.

**Save both to a secure location** (password manager, encrypted file, etc.)

---

## Step 3: Connect PowerSync to Supabase Database (5 min)

### 3.1 Get Your Supabase Connection String

1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Select your **MedZen Iwani** project
3. Go to **Project Settings → Database**
4. Under **Connection string**, select **"Transaction"** mode (NOT "Session")
5. Copy the connection string (will look like):
   ```
   postgresql://postgres.PROJECT_REF:[YOUR-PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres
   ```
6. **Replace `[YOUR-PASSWORD]`** with your actual Supabase database password

### 3.2 Connect in PowerSync Dashboard

1. In PowerSync Dashboard, look for:
   - **"Database"** section
   - **"Data Sources"** section
   - **"Connect to Database"** button
   - **"Postgres Connection"** settings

2. Paste your Supabase connection string

3. Click **"Test Connection"**
   - ✅ Should show: "Connection successful"
   - ❌ If it fails:
     - Verify password is correct
     - Ensure you used "Transaction" mode
     - Check connection string format

4. Click **"Save"** or **"Connect"**

### 3.3 Enable Supabase Authentication

1. Get your Supabase JWT Secret:
   - Supabase Dashboard → **Project Settings → API**
   - Scroll to **JWT Settings**
   - Copy the **JWT Secret** (long string)

2. In PowerSync Dashboard:
   - Find **"Authentication"** or **"JWT Settings"** section
   - Paste the JWT Secret
   - Enable **"Supabase Authentication"** or similar option
   - Click **"Save"**

---

## Step 4: Configure PowerSync Sync Rules (3 min)

In PowerSync Dashboard:

1. Find **"Sync Rules"** section (usually in left sidebar or settings)
2. You'll see a text editor with YAML/configuration
3. **Replace ALL the content** with this:

```yaml
bucket_definitions:
  global:
    # Each user gets their own isolated data bucket based on Firebase UID
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()

    data:
      # Sync user's own profile
      - SELECT * FROM users WHERE id = bucket.user_id

      # Sync user's electronic health records
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id

      # Sync user's vital signs
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id

      # Sync user's lab results
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id

      # Sync user's prescriptions
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id

      # Sync user's immunizations
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id

      # Sync user's medical records
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id

      # Sync user's EHRbase sync queue entries
      - SELECT * FROM ehrbase_sync_queue
        WHERE record_id IN (
          SELECT id::text FROM users WHERE id = bucket.user_id
        )
```

4. Click **"Validate"** or **"Check Syntax"**
   - ✅ Should show: "Valid" or "No errors"
   - ❌ If errors, check for:
     - Missing spaces/indentation
     - Typos in table names
     - Copy-paste issues

5. Click **"Save & Deploy"** or **"Deploy"**

**What this does:**
- Each user only syncs their own medical data
- Enforces privacy at PowerSync level
- Uses Firebase UID for user identification
- Syncs all medical record types bidirectionally

---

## Step 5: Set Supabase Secrets (2 min)

Now configure the Edge Function to use your PowerSync credentials.

**Open Terminal and run:**

```bash
# Navigate to your project
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Set PowerSync instance URL
# Replace [YOUR_INSTANCE_URL] with the URL from Step 1
npx supabase secrets set POWERSYNC_URL=https://[YOUR_INSTANCE_URL]

# Example:
# npx supabase secrets set POWERSYNC_URL=https://abc123-medzen.powersync.journeyapps.com
```

```bash
# Set PowerSync Key ID
# Replace [YOUR_KEY_ID] with the Key ID from Step 2
npx supabase secrets set POWERSYNC_KEY_ID=[YOUR_KEY_ID]

# Example:
# npx supabase secrets set POWERSYNC_KEY_ID=abc123def456ghi789jkl
```

```bash
# Set PowerSync Private Key
# IMPORTANT: Paste the ENTIRE private key including headers
# Use quotes and paste all lines
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
(paste all lines here - keep the line breaks)
...
-----END PRIVATE KEY-----"
```

**Verify secrets were set:**

```bash
npx supabase secrets list

# Should show:
# POWERSYNC_URL
# POWERSYNC_KEY_ID
# POWERSYNC_PRIVATE_KEY
```

---

## Step 6: Test the Integration! 🎉

### Test 1: Edge Function

Test that the Edge Function can generate PowerSync tokens:

```bash
# You need a valid user JWT token for this
# Get one from your Flutter app logs after logging in
# Or from Supabase Dashboard → Authentication → Users → [user] → Copy JWT

npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer [USER_JWT_TOKEN]"

# Expected response:
# {
#   "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
#   "powersync_url": "https://your-instance.powersync.journeyapps.com",
#   "expires_at": "2025-01-22T22:00:00.000Z",
#   "user_id": "uuid-here"
# }
```

### Test 2: Run Flutter App

```bash
flutter run
```

**Look for these lines in console:**

```
🚀 Starting system initialization...
✅ Firebase: Initialized
✅ Supabase: Initialized
⚡ PowerSync: Initializing...
🔑 PowerSync: Fetching credentials from powersync-token function...
✅ PowerSync: Credentials fetched successfully
   Endpoint: https://your-instance.powersync.journeyapps.com
   Expires: 2025-01-22T22:00:00.000Z
✅ PowerSync: Initialized and connected

📊 System Status:
  Firebase:   ✅ initialized
  Supabase:   ✅ initialized
  PowerSync:  ✅ initialized  ← THIS SHOULD BE GREEN!
  EHRbase:    ✅ initialized
  Network:    🟢 Online
```

### Test 3: Offline Mode

1. Log into the app
2. Put device in **Airplane Mode**
3. Try creating a vital sign or medical record
4. Should succeed ✅
5. Turn off **Airplane Mode**
6. PowerSync should automatically sync 🔄
7. Check Supabase Dashboard - data should appear

---

## ✅ Completion Checklist

- [ ] Got PowerSync instance URL (Step 1)
- [ ] Generated API credentials - Key ID and Private Key (Step 2)
- [ ] Connected PowerSync to Supabase database (Step 3.1-3.2)
- [ ] Enabled Supabase authentication in PowerSync (Step 3.3)
- [ ] Configured and deployed sync rules (Step 4)
- [ ] Set all 3 Supabase secrets (Step 5)
- [ ] Verified secrets with `npx supabase secrets list`
- [ ] Tested Edge Function (Step 6.1)
- [ ] Ran Flutter app and saw PowerSync ✅ initialized (Step 6.2)
- [ ] Tested offline mode successfully (Step 6.3)

---

## 🐛 Troubleshooting

### Issue: Can't find PowerSync instance URL

**Where to look:**
- Dashboard → Instance Settings
- Dashboard → Overview page
- Look for "Endpoint", "Instance URL", or "WebSocket URL"
- May be labeled as "Connection URL" or "Sync Endpoint"

If you still can't find it, take a screenshot of your PowerSync Dashboard and I can help locate it.

---

### Issue: "PowerSync not configured" error in app

**Cause:** Secrets not set correctly

**Solution:**
```bash
# Check which secrets are set
npx supabase secrets list

# If any are missing, go back to Step 5 and set them
```

**Common mistakes:**
- Forgot quotes around private key
- Didn't paste entire private key (must include headers)
- Typo in instance URL

---

### Issue: Edge Function returns error

**Check logs:**
```bash
npx supabase functions logs powersync-token --follow
```

**Common errors:**
- `PowerSync credentials not configured` → Secrets not set (Step 5)
- `Invalid private key` → Private key format wrong (must be PEM)
- `Unauthorized` → User JWT token invalid or expired

---

### Issue: PowerSync shows "offline" in app logs

**Check:**
1. PowerSync instance is running (check PowerSync Dashboard)
2. Database connection is active (PowerSync Dashboard → Database)
3. Sync rules are deployed (PowerSync Dashboard → Sync Rules)
4. Secrets are correct (`npx supabase secrets list`)

**Debug:**
```bash
# Test Edge Function manually
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer [USER_JWT]"

# Should return a valid token
```

---

### Issue: Data not syncing

**Check Sync Rules:**
1. PowerSync Dashboard → Sync Rules
2. Click "Validate"
3. Ensure no errors
4. Verify table names match exactly (`users`, `vital_signs`, etc.)

**Test sync rule query manually:**
```sql
-- In Supabase SQL Editor, run:
SELECT id as user_id FROM users WHERE firebase_uid = 'test-firebase-uid';

-- Should return a user ID
```

---

## 📞 Need Help?

If you get stuck on any step:

1. **Check PowerSync Dashboard logs:**
   - Look for error messages in Dashboard
   - Check connection status indicators

2. **Check Supabase logs:**
   ```bash
   npx supabase functions logs powersync-token --follow
   ```

3. **Run database health check:**
   ```sql
   -- In Supabase SQL Editor:
   SELECT * FROM check_powersync_health();
   ```

4. **Review detailed docs:**
   - POWERSYNC_SETUP.md - Comprehensive guide
   - POWERSYNC_INTEGRATION_COMPLETE.md - What's already done

5. **Ask for help:**
   - Share any error messages
   - Include logs from Edge Function
   - Screenshot PowerSync Dashboard if needed

---

## 🎯 Expected Timeline

- **Step 1:** 2 minutes
- **Step 2:** 3 minutes
- **Step 3:** 5 minutes
- **Step 4:** 3 minutes
- **Step 5:** 2 minutes
- **Step 6:** 5 minutes testing

**Total:** ~20 minutes

---

## ✨ What You'll Have After Completion

✅ **True offline-first medical data**
- All operations work without internet
- No data loss ever
- Instant local reads

✅ **Automatic bidirectional sync**
- Changes sync when online
- Real-time updates across devices
- Conflict resolution built-in

✅ **Complete 4-system integration**
- Firebase Auth → User authentication
- Supabase → Primary database
- PowerSync → Offline-first sync
- EHRbase → Healthcare standards compliance

---

**Ready to start? Begin with Step 1! 🚀**
