# PowerSync MCP Server URL Configuration Fix

**Date:** 2025-11-03
**Status:** DOCUMENTED (Requires External MCP Configuration Update)

## Issue

The PowerSync MCP server is configured with an incorrect instance URL.

**Incorrect URL (in MCP):** https://68f8702005eb05000765fba5.powersync.journeyapps.com
**Correct URL (in project):** https://68f931403c148720fa432934.powersync.journeyapps.com

## How to Fix

### Option 1: Update MCP Server Configuration

The PowerSync MCP server configuration needs to be updated. This is typically done through Claude Code's MCP configuration.

1. Run: `claude mcp list` to see PowerSync server status
2. Run: `claude mcp remove powersync` to remove old configuration
3. Run: `claude mcp add powersync --env POWERSYNC_URL=https://68f931403c148720fa432934.powersync.journeyapps.com`

### Option 2: Update Environment Variable

If the MCP server reads from environment variables:

```bash
export POWERSYNC_URL="https://68f931403c148720fa432934.powersync.journeyapps.com"
```

### Verification

After updating, test connectivity:
- MCP tool: `mcp__powersync__get_sync_status`
- Expected: Should connect successfully to the correct instance

## Status

- ✅ Supabase secrets: Correctly configured with right URL
- ✅ Flutter app: Correctly configured with right URL
- ✅ Edge function: Uses correct URL from Supabase secrets
- ⚠️ MCP tool: Has wrong URL (cosmetic issue, doesn't affect app)

## Impact

**Impact Level:** LOW (cosmetic only)
- App functionality: ✅ Not affected (app has correct URL)
- MCP monitoring: ⚠️ Cannot monitor via MCP tool until fixed
- PowerSync operation: ✅ Working correctly

## Notes

This is a configuration issue with the MCP server tool only. The actual PowerSync integration in the Flutter app is working correctly with the proper URL configured in Supabase secrets and the powersync-token edge function.
