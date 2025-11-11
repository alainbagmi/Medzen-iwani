# PowerSync Quick Start (5 Minutes)

**Your code is ready!** ✅ Just need to configure the infrastructure.

## Current Status

✅ **IMPLEMENTED:**
- PowerSync package installed
- Schema, connector, and initialization code ready
- Edge Function created
- Database migration prepared
- Auto-initialization in `main.dart`

⚠️ **NEEDS CONFIGURATION:**
- PowerSync Cloud instance
- Supabase database setup
- Secrets configuration

---

## 🚀 Quick Setup (Follow in Order)

### Step 1: Apply Database Migration (2 min)

```bash
npx supabase db push
```

✅ Creates PostgreSQL publication for replication
✅ Sets up permissions for PowerSync
✅ Enables Row Level Security

---

### Step 2: Create PowerSync Instance (2 min)

1. Go to: https://powersync.journeyapps.com
2. Click **"Create Instance"**
3. Name: `medzen-iwani`
4. Region: Select closest to users
5. **Save your instance URL**: `https://YOUR_INSTANCE.journeyapps.com`

---

### Step 3: Get API Credentials (1 min)

In PowerSync Dashboard:
1. Go to **Settings → API Keys**
2. Click **"Generate RSA Key Pair"**
3. **SAVE THESE NOW** (can't retrieve later):
   - **Key ID**: `abc123...`
   - **Private Key**: Copy the entire PEM block

---

### Step 4: Connect PowerSync to Supabase (3 min)

**4.1** Get Supabase connection string:
- Supabase Dashboard → **Settings → Database**
- Copy **"Transaction"** connection string
- Replace `[YOUR-PASSWORD]` with your actual password

**4.2** In PowerSync Dashboard:
- Paste connection string
- Click **"Test Connection"**
- Should show: ✅ "Connection successful"

**4.3** Enable Supabase Auth:
- Get JWT Secret from Supabase: **Settings → API → JWT Secret**
- Paste in PowerSync Dashboard
- Enable **"Supabase Authentication"**
- Click **"Save"**

---

### Step 5: Configure Sync Rules (2 min)

In PowerSync Dashboard → **Sync Rules**, paste:

```yaml
bucket_definitions:
  global:
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()
    data:
      - SELECT * FROM users WHERE id = bucket.user_id
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id
      - SELECT * FROM ehrbase_sync_queue WHERE record_id IN (SELECT id::text FROM users WHERE id = bucket.user_id)
```

Click **"Validate"** → **"Save & Deploy"**

---

### Step 6: Set Supabase Secrets (2 min)

```bash
# Replace YOUR_INSTANCE, YOUR_KEY_ID, and paste your private key
npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE.journeyapps.com
npx supabase secrets set POWERSYNC_KEY_ID=abc123def456
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG...
(paste all lines here)
-----END PRIVATE KEY-----"
```

Verify:
```bash
npx supabase secrets list
# Should show: POWERSYNC_URL, POWERSYNC_KEY_ID, POWERSYNC_PRIVATE_KEY
```

---

### Step 7: Deploy Edge Function (1 min)

```bash
npx supabase functions deploy powersync-token
```

Should output: ✅ `Deployed Function powersync-token`

---

### Step 8: Test! 🎉

```bash
flutter run
```

**Expected Console Output:**
```
🚀 Starting system initialization...
✅ Firebase: Initialized
✅ Supabase: Initialized
⚡ PowerSync: Initializing...
🔑 PowerSync: Fetching credentials...
✅ PowerSync: Initialized and connected

📊 System Status:
  Firebase:   ✅ initialized
  Supabase:   ✅ initialized
  PowerSync:  ✅ initialized  ← Should be green!
  EHRbase:    ✅ initialized
  Network:    🟢 Online
```

---

## ✅ Verification Checklist

Run this command to verify your setup:
```bash
./verify_powersync_setup.sh
```

Or manually check:
- [ ] Database migration applied (`npx supabase db push`)
- [ ] PowerSync instance created
- [ ] PowerSync connected to Supabase database
- [ ] Sync rules configured and deployed
- [ ] Secrets set in Supabase (`npx supabase secrets list`)
- [ ] Edge Function deployed (`npx supabase functions deploy powersync-token`)
- [ ] App runs and PowerSync shows ✅ initialized

---

## 🧪 Test Offline Mode

1. Run app and log in
2. Enable **Airplane Mode** on device
3. Create a new medical record (vital signs, prescription, etc.)
4. Should succeed ✅
5. Disable **Airplane Mode**
6. PowerSync automatically syncs 🔄
7. Check Supabase Dashboard - data should appear

---

## 🐛 Troubleshooting

### PowerSync shows "not configured" error
```bash
# Check secrets
npx supabase secrets list

# Should show all 3 secrets. If not, go back to Step 6
```

### PowerSync shows "offline" in logs
- Check internet connection
- Verify PowerSync instance URL is correct
- Check PowerSync Dashboard → Database connection is green
- Try: `npx supabase functions invoke powersync-token --headers "Authorization: Bearer YOUR_JWT"`

### Edge Function fails
```bash
# View logs
npx supabase functions logs powersync-token --follow

# Common issues:
# - Secrets not set
# - Invalid private key format
# - User not authenticated
```

### Data not syncing
- Check Sync Rules are deployed in PowerSync Dashboard
- Verify table names match exactly (`users`, `vital_signs`, etc.)
- Check user has `firebase_uid` in the `users` table

---

## 📚 Documentation

- **Full Setup Guide:** [POWERSYNC_SETUP.md](./POWERSYNC_SETUP.md)
- **Architecture Overview:** [CLAUDE.md](./CLAUDE.md) (search for "PowerSync")
- **PowerSync Docs:** https://docs.powersync.com/
- **Supabase + PowerSync:** https://docs.powersync.com/integration-guides/supabase-+-powersync

---

## 🎯 What You Get

✅ **Offline-first:** All medical data works without internet
✅ **Auto-sync:** Changes sync automatically when online
✅ **Conflict resolution:** Last-write-wins (configurable)
✅ **Real-time:** Updates appear instantly on all devices
✅ **HIPAA-compliant:** Encrypted at rest and in transit
✅ **No data loss:** Writes never fail, always queued

---

## 🚀 Next Steps

Once PowerSync is working:

1. **Monitor in Production:**
   - PowerSync Dashboard for replication health
   - Supabase logs for Edge Function calls
   - Flutter app logs for sync status

2. **Add Sync Status UI:**
   - Show online/offline indicator
   - Display last sync time
   - Add manual sync button

3. **Optimize Performance:**
   - Review sync rules for minimal data transfer
   - Consider pagination for large datasets
   - Monitor PowerSync logs for slow queries

---

**Total Setup Time:** ~15 minutes
**Difficulty:** ⭐⭐☆☆☆ (Moderate)

**Questions?** See [POWERSYNC_SETUP.md](./POWERSYNC_SETUP.md) for detailed troubleshooting.
