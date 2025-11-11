# PowerSync Setup Instructions - Ready to Deploy!

## 🎯 Your Connection Details

I have everything ready for you:

**Supabase:**
- Project: `noaeltglphdlkbflipit`
- URL: `https://noaeltglphdlkbflipit.supabase.co`
- Database Host: `aws-0-us-east-1.pooler.supabase.com`
- Database Port: `6543`
- Database: `postgres`
- Username: `postgres.noaeltglphdlkbflipit`
- Password: `Mylestech2025`

**PowerSync:**
- Instance: `687fe5badb7a810007220898`
- Dashboard: https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898

**Connection String:**
```
postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
```

---

## 📋 Step-by-Step Setup (15 minutes)

### Step 1: Configure Supabase Database (5 min)

Run the PowerSync permissions migration:

```bash
npx supabase db push
```

This will:
- ✅ Enable replication for PowerSync
- ✅ Grant necessary permissions
- ✅ Set up Row Level Security policies
- ✅ Create monitoring views

**Verify it worked:**
```bash
# Check the health
npx supabase db execute --sql "SELECT * FROM check_powersync_health();"
```

Expected output:
```
check_name              | status | details
-----------------------|--------|---------------------------
Replication Enabled    | OK     | Publication exists
Active Replication... | OK     | X active slot(s)
Table Permissions      | OK     | 8 tables accessible
```

### Step 2: Connect PowerSync to Supabase (5 min)

1. **Open PowerSync Dashboard:**
   👉 https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898

2. **Navigate to Settings/Configuration**

3. **Add Database Connection:**
   - Click **Configure Database** or **Add Data Source**

4. **Enter Connection Details:**

   **Option A - Use Connection String (Easiest):**
   ```
   postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
   ```

   **Option B - Use Individual Fields:**
   ```
   Connection Type: PostgreSQL
   Host: aws-0-us-east-1.pooler.supabase.com
   Port: 6543
   Database: postgres
   Username: postgres.noaeltglphdlkbflipit
   Password: Mylestech2025
   SSL Mode: require
   ```

5. **Click "Test Connection"**
   - Should see: ✅ Connection Successful

6. **Save Configuration**

### Step 3: Deploy Sync Rules (5 min)

1. **In PowerSync Dashboard, go to "Sync Rules"**

2. **Copy the sync rules from `powersync-sync-rules.yaml`:**

   The file is ready at:
   ```
   /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/powersync-sync-rules.yaml
   ```

3. **Paste into PowerSync Dashboard**

4. **Click "Validate"** to check syntax

5. **Click "Deploy"** or "Save"

6. **Test the rules:**
   - Use the built-in **Test** feature
   - Enter a test Firebase UID
   - Should return user data

---

## ✅ Verification Checklist

After completing the steps above, verify:

### In PowerSync Dashboard

- [ ] **Database Status:** Connected ✅
- [ ] **Sync Rules:** Deployed ✅
- [ ] **Metrics:** Showing activity ✅
- [ ] **Replication Lag:** < 1 second ✅

### In Supabase

Run this to check PowerSync health:

```sql
SELECT * FROM check_powersync_health();
```

All checks should return `OK` status.

### Test Data Sync

1. **Insert test data in Supabase:**

```sql
INSERT INTO users (id, firebase_uid, email, first_name, last_name, created_at)
VALUES (
  gen_random_uuid(),
  'test-firebase-uid-powersync',
  'powersync-test@medzen.com',
  'PowerSync',
  'Test',
  NOW()
)
RETURNING id, firebase_uid, email;
```

2. **Check PowerSync Dashboard:**
   - Go to **Data** or **Metrics**
   - Should see the new record within 1-2 seconds
   - If it appears: ✅ Sync is working!

3. **Clean up test data:**

```sql
DELETE FROM users WHERE firebase_uid = 'test-firebase-uid-powersync';
```

---

## 🔧 Troubleshooting

### Issue: "Connection Failed"

**Check:**
1. Password is correct: `Mylestech2025`
2. Host is: `aws-0-us-east-1.pooler.supabase.com`
3. Port is: `6543`
4. SSL mode is: `require`

**Test connection manually:**
```bash
psql "postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require"
```

### Issue: "Replication Error"

**Check Supabase replication settings:**

```sql
-- Check if publication exists
SELECT * FROM pg_publication WHERE pubname = 'powersync';

-- Check replication slots
SELECT * FROM pg_replication_slots WHERE slot_name LIKE 'powersync%';
```

### Issue: "Sync Rules Validation Error"

**Common causes:**
- Table doesn't exist
- SQL syntax error
- Wrong table name

**Fix:**
1. Validate YAML syntax online
2. Test SQL queries in Supabase SQL Editor
3. Check table names match exactly

---

## 🚀 Next Steps

Once PowerSync is connected to Supabase:

1. ✅ **Deploy PowerSync Token Function**
   ```bash
   npx supabase functions deploy powersync-token
   ```

2. ✅ **Set PowerSync Secrets**
   - Get RSA Key ID and Private Key from PowerSync Dashboard
   - Run:
   ```bash
   npx supabase secrets set POWERSYNC_URL=https://687fe5badb7a810007220898.powersync.journeyapps.com
   npx supabase secrets set POWERSYNC_KEY_ID=your-key-id
   npx supabase secrets set POWERSYNC_PRIVATE_KEY="your-private-key"
   ```

3. ✅ **Test Flutter App**
   - Initialize PowerSync in app
   - Test offline writes
   - Verify sync works

---

## 🔒 Security Note

**IMPORTANT:** Your database password (`Mylestech2025`) is now visible in this conversation.

**After setup, consider:**
1. Rotating the password in Supabase
2. Using a more complex password
3. Storing credentials securely

**To rotate password:**
1. Go to Supabase Dashboard → Settings → Database
2. Click "Reset Database Password"
3. Update PowerSync connection with new password

---

## 📊 Monitoring

**PowerSync Dashboard:**
- Real-time sync metrics
- Error logs
- Connection status
- Data volume

**Supabase:**
```sql
-- Monitor replication lag
SELECT * FROM v_powersync_replication_status;

-- Check sync health
SELECT * FROM check_powersync_health();
```

---

## ✨ You're Ready!

Everything is configured and ready to deploy. Just follow Steps 1-3 above and you'll have:

- ✅ Supabase ←→ PowerSync connection
- ✅ Real-time bidirectional sync
- ✅ Offline-first data flow
- ✅ Complete EHR system

**Estimated time:** 15 minutes
**Difficulty:** Easy (just copy-paste!)

Let me know when you've completed the steps and I'll help you test the connection!
