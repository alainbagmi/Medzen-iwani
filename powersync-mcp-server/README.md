# PowerSync MCP Server

MCP server for interacting with PowerSync sync engine instances.

## Features

- 🔍 Get sync status and metrics
- 📊 Monitor active connections
- 🏥 Check instance health
- 📦 View bucket configurations
- ⚡ Real-time sync monitoring

## Tools

### get_sync_status
Get current sync status including connections, latency, and last sync time.

### list_active_connections
List all active client connections to the PowerSync instance.

### get_sync_metrics
Get detailed sync metrics including throughput, error rates, and data volume over time.

### check_instance_health
Quick health check of the PowerSync instance.

### get_bucket_info
Get information about sync buckets and their configurations.

## Installation

```bash
# Using uv (recommended)
uv pip install -e powersync-mcp-server

# Or using pip
pip install -e powersync-mcp-server
```

## Configuration

Set these environment variables:

```bash
# Required: Your PowerSync instance URL
export POWERSYNC_URL="https://your-instance.journeyapps.com"

# Optional: API key for authenticated requests
export POWERSYNC_API_KEY="your-api-key"
```

## Usage with Claude Code

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "powersync": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "powersync-mcp-server",
        "python",
        "src/powersync_mcp_server.py"
      ],
      "env": {
        "POWERSYNC_URL": "https://your-instance.journeyapps.com",
        "POWERSYNC_API_KEY": "your-api-key-if-needed"
      }
    }
  }
}
```

## Example Usage

Once configured, you can ask Claude:

- "What's the current sync status?"
- "How many active connections are there?"
- "Check if the PowerSync instance is healthy"
- "Show me sync metrics for the last 24 hours"
- "What buckets are configured?"

## Dashboard Access

For the MedZen project, access your PowerSync dashboard at:
https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898

## Development

```bash
# Install in development mode
uv pip install -e .

# Run directly
python src/powersync_mcp_server.py
```

## Notes

- This server provides basic monitoring capabilities
- Full metrics and detailed data require PowerSync API access
- Most detailed information is available in the PowerSync web dashboard
- The server can work without API key for basic health checks

## Links

- PowerSync Dashboard: https://powersync.journeyapps.com/
- PowerSync Docs: https://docs.powersync.com/
- MCP Specification: https://modelcontextprotocol.io/
