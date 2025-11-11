# How to Get PowerSync API Key

## Option 1: Via Dashboard UI (Recommended)

### Step 1: Login to PowerSync

1. Go to: https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
2. Login with:
   - Email: `info@mylestechsolutionsllc.com`
   - Password: `Mylestech@2025`

### Step 2: Navigate to API Settings

Look for one of these menu locations (PowerSync UI varies):

**Option A - Organization Settings:**
1. Click on your organization name (top left or top right)
2. Look for **Settings** or **Organization Settings**
3. Find **API Keys** or **Access Tokens** section

**Option B - Instance Settings:**
1. Click on **Settings** in the left sidebar
2. Look for **API** or **API Keys** or **Access Tokens** tab

**Option C - Developer/Integration Settings:**
1. Click on **Integrations** or **Developer** in the sidebar
2. Look for **API Keys** or **Tokens**

### Step 3: Generate API Key

1. Click **Generate API Key** or **Create New Token** or **New API Key**
2. Give it a name like: `MCP Server` or `Claude Code Integration`
3. Copy the key (it will look like `ps_api_...` or similar)
4. **Save it immediately** - you won't be able to see it again!

---

## Option 2: Check PowerSync Documentation

If you can't find it in the UI:

1. **Look for Help/Documentation link** in the PowerSync Dashboard
2. Or check PowerSync docs: https://docs.powersync.com/
3. Search for "API Key" or "Authentication"

---

## Option 3: Contact PowerSync Support

If the API key option isn't visible:

1. Your account might need specific permissions
2. Click **Help** or **Support** in the PowerSync Dashboard
3. Ask: "How do I generate an API key for programmatic access?"

---

## Important Note

**The PowerSync MCP Server is optional!**

If you can't find the API key right now, you can:
1. Skip the MCP server setup for now
2. Complete the main PowerSync connection (Steps 1-5)
3. Come back to the MCP server later

The MCP server is just for monitoring via Claude Code. The main functionality (offline sync) doesn't need it.

---

## What the API Key is Used For

The API key allows the PowerSync MCP server to:
- Query sync status
- Check instance health
- View metrics
- List active connections

**It's NOT required for:**
- Flutter app sync (uses JWT tokens from Edge Function)
- PowerSync Dashboard access (uses your login)
- Database connection (uses Postgres credentials)

---

## Next Steps

### If you found the API key:
1. Copy it
2. Update `.mcp.json`:
   ```json
   {
     "mcpServers": {
       "powersync": {
         "env": {
           "POWERSYNC_API_KEY": "paste_your_api_key_here"
         }
       }
     }
   }
   ```
3. Restart Claude Code

### If you can't find it:
1. Skip the MCP server for now
2. Continue with **Step 1** of `POWERSYNC_FINAL_SETUP_GUIDE.md`
3. Connect PowerSync to Supabase (this is the critical part)
4. We can add the MCP server later

---

## Simplified Next Steps (Without MCP Server)

You can complete the PowerSync setup without the MCP server:

1. ✅ **Connect PowerSync to Supabase** (Step 1 of guide)
   - Login to PowerSync Dashboard
   - Add database connection string
   - Test and save

2. ✅ **Deploy Sync Rules** (Step 2 of guide)
   - Copy from `powersync-sync-rules.yaml`
   - Paste in Dashboard
   - Deploy

3. ✅ **Get RSA Keys** (for Edge Function)
   - Settings → RSA Keys in PowerSync
   - Generate if needed
   - Copy Key ID and Private Key

4. ✅ **Configure Supabase**
   ```bash
   npx supabase secrets set POWERSYNC_URL=https://687fe5badb7a810007220898.powersync.journeyapps.com
   npx supabase secrets set POWERSYNC_KEY_ID=your_key_id
   npx supabase secrets set POWERSYNC_PRIVATE_KEY="your_private_key"
   ```

5. ✅ **Deploy Edge Function**
   ```bash
   npx supabase functions deploy powersync-token
   ```

That's it! The PowerSync connection will work without the MCP server.

---

## When to Come Back to MCP Server

Add the MCP server later when you want to:
- Query sync status from Claude Code
- Monitor PowerSync health
- Debug sync issues
- Check metrics

For now, focus on getting the main connection working!
