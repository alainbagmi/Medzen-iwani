# Deploy PowerSync Sync Rules - Step by Step

**Your PowerSync Dashboard:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/68f8702005eb05000765fba5

---

## Step 1: Navigate to Sync Rules (1 min)

1. **Open your PowerSync Dashboard** (link above)
2. Look in the **left sidebar** for one of these:
   - **"Sync Rules"**
   - **"Rules"**
   - **"Data Sync"**
   - **"Sync Configuration"**
3. Click on it

---

## Step 2: Copy the Sync Rules (30 seconds)

**I've created a file with your sync rules:**

📄 **File:** `POWERSYNC_SYNC_RULES.yaml`

**Copy ALL the content from that file**, or copy this:

```yaml
bucket_definitions:
  global:
    # Each user gets their own isolated data bucket based on Firebase UID
    # This ensures users can only sync their own medical data
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()

    data:
      # User's own profile data
      - SELECT * FROM users WHERE id = bucket.user_id

      # User's electronic health records
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id

      # User's vital signs (blood pressure, heart rate, temperature, etc.)
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id

      # User's lab results (test results, lab reports)
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id

      # User's prescriptions (medications)
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id

      # User's immunizations (vaccinations)
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id

      # User's general medical records
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id

      # User's EHRbase sync queue entries (for tracking OpenEHR sync)
      - SELECT * FROM ehrbase_sync_queue
        WHERE record_id IN (
          SELECT id::text FROM users WHERE id = bucket.user_id
        )
```

---

## Step 3: Paste and Validate (1 min)

1. In the PowerSync Dashboard **Sync Rules** page, you'll see a **text editor**
2. **Select ALL existing content** and **DELETE it**
3. **Paste** the sync rules from above
4. Look for a **"Validate"** or **"Check Syntax"** button
5. Click it

**Expected result:**
- ✅ "Valid" or "No errors" or "Validation passed"

**If you see errors:**
- Check that indentation is correct (YAML is sensitive to spaces)
- Ensure no extra characters were copied
- Verify table names match exactly

---

## Step 4: Deploy the Sync Rules (30 seconds)

1. Click **"Save & Deploy"** or **"Deploy"** button
2. You may see a confirmation dialog - click **"Confirm"** or **"Yes"**
3. Wait for deployment to complete (usually 5-10 seconds)

**Expected result:**
- ✅ "Deployed successfully" or similar success message
- The sync rules are now active

---

## Step 5: Verify Deployment (Optional)

After deployment, PowerSync may show:
- ✅ **Status:** Active or Running
- ✅ **Version:** v1 or timestamped version
- ✅ **Last deployed:** Current timestamp

---

## What These Sync Rules Do

### 🔒 **Privacy & Security**
- Each user ONLY syncs their own medical data
- Uses Firebase UID to identify users
- No user can access another user's data
- Enforced at PowerSync level (before data even reaches device)

### 📊 **Data Synced**
For each authenticated user, syncs:
1. ✅ User profile (`users` table)
2. ✅ Electronic health records (`electronic_health_records`)
3. ✅ Vital signs (`vital_signs`)
4. ✅ Lab results (`lab_results`)
5. ✅ Prescriptions (`prescriptions`)
6. ✅ Immunizations (`immunizations`)
7. ✅ Medical records (`medical_records`)
8. ✅ EHRbase sync queue (`ehrbase_sync_queue`)

### 🔄 **How It Works**

```
User logs in with Firebase Auth
    ↓
PowerSync gets user's Firebase UID
    ↓
Sync rules query: "SELECT id FROM users WHERE firebase_uid = ?"
    ↓
PowerSync creates user's personal "bucket"
    ↓
Only data matching bucket.user_id gets synced
    ↓
Bidirectional sync: Device ↔ PowerSync ↔ Supabase
```

---

## Next Steps After Deployment

Once sync rules are deployed, you need to:

### ✅ **Already Done:**
- Database configured ✅
- Edge Function deployed ✅
- Supabase connected to PowerSync ✅
- Sync rules deployed ✅

### ⚠️ **Still Need To Do:**

#### 1. Get PowerSync API Credentials (3 min)

In PowerSync Dashboard:
1. Go to **Settings → API Keys** (or similar)
2. Click **"Generate RSA Key Pair"**
3. **SAVE BOTH:**
   - **Key ID** (looks like: `abc123def456`)
   - **Private Key** (PEM format with headers)

⚠️ **You can only view the private key ONCE!**

#### 2. Set Supabase Secrets (2 min)

Once you have the credentials, run these commands:

```bash
# Navigate to project
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL=https://68f8702005eb05000765fba5.journeyapps.com

# Set Key ID (replace with your actual Key ID)
npx supabase secrets set POWERSYNC_KEY_ID=YOUR_KEY_ID_HERE

# Set Private Key (paste entire key including headers)
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----"
```

**Verify:**
```bash
npx supabase secrets list
# Should show all 3 secrets
```

#### 3. Test! (5 min)

```bash
flutter run
```

Look for:
```
✅ PowerSync: Initialized and connected
```

---

## 🐛 Common Issues

### Issue: Validation fails with "table not found"

**Cause:** Table names don't match Supabase schema

**Solution:**
- Verify table names in Supabase Dashboard
- Ensure tables exist in `public` schema
- Check spelling exactly

### Issue: Sync rules deploy but no data syncs

**Cause:** User doesn't have `firebase_uid` in database

**Solution:**
```sql
-- Check in Supabase SQL Editor:
SELECT id, firebase_uid FROM users LIMIT 10;

-- If firebase_uid is null, that's the problem
-- It should be populated when user signs up via Firebase
```

### Issue: "Parameters query returned no results"

**Cause:** The `firebase_uid` in the database doesn't match the token

**Check:**
1. User is authenticated with Firebase
2. Firebase UID is stored in Supabase `users.firebase_uid`
3. PowerSync token contains correct user ID

---

## 📞 Need Help?

After deploying sync rules, if you see issues:

1. **Check PowerSync Dashboard logs** - Look for sync errors
2. **Verify table permissions** - Ensure postgres user can SELECT from all tables
3. **Test the parameters query manually:**
   ```sql
   -- In Supabase SQL Editor:
   SELECT id as user_id FROM users WHERE firebase_uid = 'some-test-uid';
   ```

---

## ✅ Completion Checklist

- [ ] Navigated to Sync Rules in PowerSync Dashboard
- [ ] Copied sync rules from POWERSYNC_SYNC_RULES.yaml
- [ ] Pasted into PowerSync Dashboard editor
- [ ] Clicked "Validate" - saw ✅ success
- [ ] Clicked "Deploy" - saw ✅ deployed successfully
- [ ] Generated PowerSync API credentials (Key ID + Private Key)
- [ ] Set Supabase secrets (3 secrets total)
- [ ] Tested with `flutter run`

---

**Current Step:** Deploy the sync rules in PowerSync Dashboard!

**After that:** Generate API credentials and set Supabase secrets.

🚀 **You're almost done!**
