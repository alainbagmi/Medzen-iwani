# Retrieve PowerSync RSA Keys - Step-by-Step Visual Guide

**Dashboard URL**: https://68f931403c148720fa432934.powersync.journeyapps.com
**Task**: Copy RSA Key ID and Private Key to configure FlutterFlow offline functionality

---

## Step 1: Access PowerSync Dashboard

The dashboard should already be open in your browser. If not:

```bash
open https://68f931403c148720fa432934.powersync.journeyapps.com
```

**What you'll see**: PowerSync dashboard homepage with navigation menu

---

## Step 2: Navigate to API Keys Section

### Option A: Direct Navigation
1. Look for **Settings** icon (⚙️ gear icon) in the sidebar or top navigation
2. Click **Settings**
3. Find and click **API Keys** or **Security** → **API Keys**

### Option B: Via Project Settings
1. Click on your project name or instance ID: `68f931403c148720fa432934`
2. Look for **Settings** tab
3. Navigate to **API Keys** or **Authentication** section

**What you're looking for**: A section showing RSA key pairs or JWT authentication

---

## Step 3: Locate Your RSA Key Pair

Since your Supabase ↔ PowerSync sync is already working, you MUST have RSA keys configured. Look for:

### What to Look For:
- Section labeled: **RSA Keys**, **JWT Keys**, **API Keys**, or **Authentication**
- A table or list showing existing key pairs
- Key ID format: UUID (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
- Key status: **Active** or **Enabled**

### If You See Multiple Keys:
- Use the one marked **Active** or **Primary**
- Check the creation date - use the most recent one
- If unsure, look for the key used by your Supabase connection

---

## Step 4: Copy Key ID

### What to Copy:
- **Field name**: Could be labeled as:
  - "Key ID"
  - "Client ID"
  - "ID"
  - "KID" (Key Identifier)

- **Format**: UUID string like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

### How to Copy:
1. Click the **Copy** button (📋) next to the Key ID, OR
2. Click **View** → Select all → Copy, OR
3. Manually select the Key ID text and copy (Cmd+C)

**Save this somewhere temporarily** - you'll need it in Step 6

---

## Step 5: Copy Private Key

### What to Look For:
- Button labeled: **View Private Key**, **Download Key**, **Show Key**, or **Export Key**
- ⚠️ Warning message: "This can only be viewed once" or "Save this securely"

### How to Get the Private Key:

#### If You See "View Private Key" Button:
1. Click **View Private Key** or **Show Private Key**
2. You'll see a text box with content starting with:
   ```
   -----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEA...
   (many lines of base64 encoded text)
   ...
   -----END RSA PRIVATE KEY-----
   ```
3. Click **Copy to Clipboard** button, OR
4. Select all text (Cmd+A) and copy (Cmd+C)

#### If You See "Download Private Key" Button:
1. Click **Download Private Key**
2. A `.pem` or `.key` file will download
3. Open the file in a text editor
4. Copy the entire contents (including BEGIN/END headers)

#### If You CAN'T Find the Private Key:
This means the key was already generated and the private key wasn't saved. In this case:

**You'll need to generate a NEW key pair**:
1. Look for **Generate New Key Pair** or **Create RSA Key** button
2. Click it
3. ⚠️ **IMPORTANT**: This will create a NEW key - you may need to update your Supabase sync configuration with this new key
4. Copy BOTH the Key ID and Private Key immediately
5. Save them securely (password manager or encrypted note)

**Save the private key somewhere temporarily** - you'll need it in Step 6

---

## Step 6: Set Keys in Supabase Secrets

Once you have BOTH keys copied, run these commands in your terminal:

### A. Open Terminal in Project Directory

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
```

### B. Set Key ID Secret

Replace `<PASTE-YOUR-KEY-ID-HERE>` with the actual Key ID you copied:

```bash
npx supabase secrets set POWERSYNC_KEY_ID="<PASTE-YOUR-KEY-ID-HERE>"
```

**Example**:
```bash
npx supabase secrets set POWERSYNC_KEY_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

### C. Set Private Key Secret

Replace `<PASTE-PRIVATE-KEY-HERE>` with the actual private key you copied.

**IMPORTANT**: Include the ENTIRE key with BEGIN/END headers:

```bash
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
<PASTE-PRIVATE-KEY-HERE>
-----END RSA PRIVATE KEY-----"
```

**Example**:
```bash
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN
OPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/ABCDEFGHIJKLMNOPQR
Sc3YMXU3MTJ1SWphSjdBK2tYMnhPV0JCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFla
YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5Ky9BQkNERUZHSElK
... (many more lines) ...
-----END RSA PRIVATE KEY-----"
```

---

## Step 7: Verify Secrets Are Set

```bash
npx supabase secrets list
```

**Expected output** - You should now see:
```
✅ POWERSYNC_URL
✅ POWERSYNC_KEY_ID          (NEW!)
✅ POWERSYNC_PRIVATE_KEY     (NEW!)
```

---

## Step 8: Redeploy Edge Function

```bash
npx supabase functions deploy powersync-token
```

**Expected output**:
```
Deploying function powersync-token...
Deployed function powersync-token in XX.XXs
```

---

## Step 9: Test Token Generation

```bash
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer $(npx supabase functions get-jwt)"
```

**Expected successful response**:
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWI...",
  "powersync_url": "https://68f931403c148720fa432934.powersync.journeyapps.com",
  "expires_at": "2025-10-31T22:30:00.000Z",
  "user_id": "uuid-of-user"
}
```

**If you see this** ✅ - FlutterFlow offline configuration is complete!

**If you see an error** ❌ - Check:
- Private key includes BEGIN/END headers
- No extra spaces or newlines before/after key
- Key ID matches the private key (both from same generation)

---

## Troubleshooting

### Can't Find API Keys Section?

Try these alternative locations:
- **Project Settings** → **Authentication**
- **Project Settings** → **Security**
- **Admin** → **API Credentials**
- **Developers** → **Keys**
- **Configuration** → **JWT Settings**

### Can't See Private Key?

If you can only see the Key ID but not the private key:
1. The key was generated previously and private key wasn't saved
2. You'll need to **generate a new key pair**
3. ⚠️ Note: This may require updating your Supabase sync configuration

### Error: "Invalid key format"

Common issues:
- Missing BEGIN/END headers
- Extra spaces before `-----BEGIN`
- Missing newline before `-----END`
- Copy-paste formatting issues

**Fix**: Copy the entire key in one selection, including all headers

### Still Stuck?

**Alternative approach - Check PowerSync Documentation**:
```bash
open https://docs.powersync.com/
```

Search for: "RSA keys" or "JWT authentication" or "API keys"

Or contact PowerSync support with your instance ID: `68f931403c148720fa432934`

---

## What These Keys Do

**Key ID**: Identifies which public key PowerSync should use to verify tokens

**Private Key**: Used by your Supabase edge function to SIGN JWT tokens

**Flow**:
1. User logs into FlutterFlow app
2. App calls Supabase edge function `powersync-token`
3. Edge function signs a JWT using your PRIVATE KEY
4. Token includes KEY ID in header
5. App sends token to PowerSync
6. PowerSync verifies token using PUBLIC KEY (already in dashboard)
7. PowerSync grants access to user's data bucket
8. Offline sync works!

---

## Security Notes

✅ **DO**:
- Keep private key in Supabase secrets (encrypted at rest)
- Save a backup in password manager
- Rotate keys every 90 days

❌ **DON'T**:
- Commit private key to git
- Share via email/Slack
- Store in code files

---

## Next Steps After Key Configuration

1. ✅ Configure PowerSync library in FlutterFlow (see FLUTTERFLOW_POWERSYNC_INTEGRATION_GUIDE.md Part 4)
2. ✅ Add `initializePowerSync()` to landing pages (see Part 5)
3. ✅ Test offline functionality (see Part 9)

**Total time remaining**: ~20 minutes to fully functional offline app

---

**Need Help?**

Check:
- `GET_POWERSYNC_RSA_KEYS.md` - Alternative guide
- `POWERSYNC_SECRETS_SETUP.md` - Detailed troubleshooting
- `POWERSYNC_FLUTTERFLOW_STATUS.md` - Overall status

Or ask Claude: "Help me troubleshoot PowerSync key configuration"
