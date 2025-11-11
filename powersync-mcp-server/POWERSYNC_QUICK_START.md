# PowerSync Quick Start - Essential Steps Only

**Skip the MCP server for now. Here are just the essential steps to get PowerSync working.**

---

## Your Credentials

**PowerSync Dashboard:**
- URL: https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
- Username: info@mylestechsolutionsllc.com
- Password: Mylestech@2025

**Supabase Connection String:**
```
postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
```

---

## Step 1: Connect PowerSync to Supabase (5 minutes)

1. **Login to PowerSync Dashboard:**
   - Go to the URL above
   - Login with the credentials above

2. **Add Database Connection:**
   - Click **Settings** (or **Configuration**)
   - Look for **Database** or **Data Source** section
   - Click **Add Database** or **Configure Database**

3. **Enter Connection String:**
   - Paste this entire string:
     ```
     postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
     ```
   - Click **Test Connection** → Should see ✅ Success
   - Click **Save**

---

## Step 2: Deploy Sync Rules (3 minutes)

1. **Open the sync rules file:**
   ```bash
   cat powersync-sync-rules.yaml
   ```

2. **In PowerSync Dashboard:**
   - Go to **Sync Rules** tab
   - Delete any existing content in the editor
   - Paste the entire contents of `powersync-sync-rules.yaml`
   - Click **Validate** → Should see ✅ Valid
   - Click **Deploy** or **Save**

---

## Step 3: Get RSA Keys (5 minutes)

1. **In PowerSync Dashboard:**
   - Go to **Settings**
   - Look for **RSA Keys** or **JWT Keys** section

2. **Generate or View Keys:**
   - If no keys exist, click **Generate RSA Key Pair**
   - Copy and save:
     - **Key ID** (example: `abc123-def456-...`)
     - **Private Key** (entire key including BEGIN/END lines)

**Save these somewhere safe - you'll need them in Step 4!**

---

## Step 4: Configure Supabase (5 minutes)

Run these commands (replace placeholders with keys from Step 3):

```bash
npx supabase secrets set POWERSYNC_URL=https://687fe5badb7a810007220898.powersync.journeyapps.com

npx supabase secrets set POWERSYNC_KEY_ID=paste_your_key_id_here

npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
paste_your_private_key_here
-----END PRIVATE KEY-----"
```

**Verify:**
```bash
npx supabase secrets list
```

---

## Step 5: Deploy Edge Function (2 minutes)

```bash
npx supabase functions deploy powersync-token
```

---

## Step 6: Verify (5 minutes)

### Check PowerSync Dashboard
- Status: ✅ Database Connected
- Sync Rules: ✅ Deployed

### Test Data Sync
```sql
INSERT INTO users (id, firebase_uid, email, first_name, last_name, created_at)
VALUES (gen_random_uuid(), 'test-sync-' || extract(epoch from now())::text, 'test@medzen.com', 'Sync', 'Test', NOW())
RETURNING id, firebase_uid;
```

Check PowerSync Dashboard → Should see record within 1-2 seconds

Clean up:
```sql
DELETE FROM users WHERE email = 'test@medzen.com';
```

---

## ✅ Done! PowerSync is Connected

Next: Initialize PowerSync in your Flutter app (already coded in lib/powersync/database.dart)
