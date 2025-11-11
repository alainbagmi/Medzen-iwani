# PowerSync MCP Server Setup

## ✅ Installation Complete!

The PowerSync MCP server has been successfully installed and configured.

## What It Does

The PowerSync MCP server allows Claude Code to:

- 🔍 **Monitor sync status** - Check if PowerSync is connected and syncing
- 📊 **View metrics** - See throughput, latency, and error rates
- 🏥 **Health checks** - Verify your PowerSync instance is running
- 📦 **Bucket info** - View sync bucket configurations
- 👥 **Active connections** - See how many clients are connected

## Configuration

The server is configured in `.mcp.json`:

```json
{
  "powersync": {
    "command": "uv",
    "args": ["run", "--directory", "powersync-mcp-server", "python", "src/powersync_mcp_server.py"],
    "env": {
      "POWERSYNC_URL": "https://687fe5badb7a810007220898.powersync.journeyapps.com",
      "POWERSYNC_API_KEY": ""
    }
  }
}
```

### Get Your API Key (Optional)

For full API access:

1. Go to [PowerSync Dashboard](https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898)
2. Navigate to **Settings** → **API Keys**
3. Generate a new API key
4. Add it to `.mcp.json`:
   ```json
   "POWERSYNC_API_KEY": "your-api-key-here"
   ```

**Note:** Basic features work without an API key.

## Available Tools

### 1. get_sync_status
Check if PowerSync is connected and syncing.

**Example:**
> "What's the current PowerSync sync status?"

### 2. check_instance_health
Quick health check of your PowerSync instance.

**Example:**
> "Is the PowerSync instance healthy?"

### 3. get_sync_metrics
View sync metrics over time (1h, 24h, 7d, 30d).

**Example:**
> "Show me PowerSync sync metrics for the last 24 hours"

### 4. list_active_connections
See how many clients are actively connected.

**Example:**
> "How many active PowerSync connections are there?"

### 5. get_bucket_info
View information about sync buckets.

**Example:**
> "What PowerSync buckets are configured?"

## Testing the MCP Server

Try asking Claude:

```
What's the PowerSync instance health?
```

Or:

```
Check PowerSync sync status
```

## Dashboard Access

For detailed monitoring, visit your PowerSync dashboard:
https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898

## Troubleshooting

### MCP Server Not Found

Restart Claude Code to reload MCP servers:
1. Quit Claude Code
2. Reopen Claude Code
3. MCP servers load automatically

### Connection Issues

Check that:
1. Your PowerSync instance URL is correct
2. The instance is running
3. You have network connectivity

### Need More Details?

Most detailed information is available in the PowerSync web dashboard. The MCP server provides quick access to key metrics for monitoring.

## Files Created

- `powersync-mcp-server/src/powersync_mcp_server.py` - Main server code
- `powersync-mcp-server/pyproject.toml` - Python package config
- `powersync-mcp-server/README.md` - Detailed documentation
- Updated `.mcp.json` - MCP server configuration

## Next Steps

1. ✅ MCP server installed
2. ✅ Configured with your instance URL
3. Try the tools by asking Claude about PowerSync status
4. (Optional) Add API key for full access
5. Monitor your sync in real-time!

---

**Your PowerSync Instance:**
https://687fe5badb7a810007220898.powersync.journeyapps.com

**Dashboard:**
https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
