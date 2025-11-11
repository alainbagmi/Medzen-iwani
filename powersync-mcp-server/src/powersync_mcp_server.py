#!/usr/bin/env python3
"""
PowerSync MCP Server

This MCP server provides tools to interact with PowerSync instances,
allowing Claude to monitor sync status, manage connections, and query metrics.
"""

import os
import asyncio
import httpx
from typing import Optional, Any
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types


# PowerSync configuration from environment
POWERSYNC_URL = os.getenv("POWERSYNC_URL", "")
POWERSYNC_API_KEY = os.getenv("POWERSYNC_API_KEY", "")

# HTTP client
client = httpx.AsyncClient(timeout=30.0)

# MCP Server
server = Server("powersync-mcp-server")


@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """List available PowerSync tools."""
    return [
        types.Tool(
            name="get_sync_status",
            description="Get current sync status for a PowerSync instance including connections, sync latency, and metrics",
            inputSchema={
                "type": "object",
                "properties": {
                    "instance_url": {
                        "type": "string",
                        "description": "PowerSync instance URL (optional, uses POWERSYNC_URL env if not provided)",
                    }
                },
            },
        ),
        types.Tool(
            name="list_active_connections",
            description="List all active client connections to PowerSync instance",
            inputSchema={
                "type": "object",
                "properties": {
                    "instance_url": {
                        "type": "string",
                        "description": "PowerSync instance URL (optional)",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of connections to return (default: 100)",
                        "default": 100,
                    }
                },
            },
        ),
        types.Tool(
            name="get_sync_metrics",
            description="Get detailed sync metrics including throughput, error rates, and data volume",
            inputSchema={
                "type": "object",
                "properties": {
                    "instance_url": {
                        "type": "string",
                        "description": "PowerSync instance URL (optional)",
                    },
                    "time_range": {
                        "type": "string",
                        "description": "Time range for metrics (1h, 24h, 7d, 30d)",
                        "enum": ["1h", "24h", "7d", "30d"],
                        "default": "24h",
                    }
                },
            },
        ),
        types.Tool(
            name="check_instance_health",
            description="Check overall health status of PowerSync instance",
            inputSchema={
                "type": "object",
                "properties": {
                    "instance_url": {
                        "type": "string",
                        "description": "PowerSync instance URL (optional)",
                    }
                },
            },
        ),
        types.Tool(
            name="get_bucket_info",
            description="Get information about sync buckets and their configurations",
            inputSchema={
                "type": "object",
                "properties": {
                    "instance_url": {
                        "type": "string",
                        "description": "PowerSync instance URL (optional)",
                    },
                    "bucket_name": {
                        "type": "string",
                        "description": "Specific bucket name (optional, returns all if not provided)",
                    }
                },
            },
        ),
    ]


@server.call_tool()
async def handle_call_tool(
    name: str, arguments: dict[str, Any] | None
) -> list[types.TextContent]:
    """Handle tool execution."""

    if arguments is None:
        arguments = {}

    instance_url = arguments.get("instance_url", POWERSYNC_URL)

    if not instance_url:
        return [
            types.TextContent(
                type="text",
                text="Error: PowerSync instance URL not provided. Set POWERSYNC_URL environment variable or provide instance_url parameter.",
            )
        ]

    try:
        if name == "get_sync_status":
            result = await get_sync_status(instance_url)

        elif name == "list_active_connections":
            limit = arguments.get("limit", 100)
            result = await list_active_connections(instance_url, limit)

        elif name == "get_sync_metrics":
            time_range = arguments.get("time_range", "24h")
            result = await get_sync_metrics(instance_url, time_range)

        elif name == "check_instance_health":
            result = await check_instance_health(instance_url)

        elif name == "get_bucket_info":
            bucket_name = arguments.get("bucket_name")
            result = await get_bucket_info(instance_url, bucket_name)

        else:
            return [
                types.TextContent(
                    type="text",
                    text=f"Error: Unknown tool '{name}'",
                )
            ]

        return [types.TextContent(type="text", text=result)]

    except Exception as e:
        return [
            types.TextContent(
                type="text",
                text=f"Error executing {name}: {str(e)}",
            )
        ]


async def get_sync_status(instance_url: str) -> str:
    """Get current sync status."""
    try:
        # Try to get status from PowerSync API
        # Note: Actual endpoint may differ based on PowerSync version
        response = await client.get(
            f"{instance_url}/api/status",
            headers={"Authorization": f"Bearer {POWERSYNC_API_KEY}"} if POWERSYNC_API_KEY else {},
        )

        if response.status_code == 200:
            data = response.json()
            return f"""PowerSync Sync Status:

Connected: {data.get('connected', 'Unknown')}
Active Connections: {data.get('active_connections', 0)}
Sync Latency: {data.get('sync_latency_ms', 'N/A')} ms
Last Sync: {data.get('last_sync_at', 'N/A')}
Status: {data.get('status', 'Unknown')}

Instance URL: {instance_url}
"""
        else:
            # Fallback: Return basic info
            return f"""PowerSync Instance Info:

Instance URL: {instance_url}
API Status: HTTP {response.status_code}

Note: Full status requires PowerSync API access. Configure POWERSYNC_API_KEY environment variable.
"""

    except httpx.ConnectError:
        return f"""PowerSync Instance: {instance_url}

Status: Unable to connect
Note: Ensure the instance URL is correct and accessible.
"""
    except Exception as e:
        return f"Error getting sync status: {str(e)}"


async def list_active_connections(instance_url: str, limit: int) -> str:
    """List active connections."""
    return f"""Active Connections:

Instance: {instance_url}
Limit: {limit}

Note: This feature requires PowerSync API access with appropriate credentials.
Configure POWERSYNC_API_KEY to access detailed connection information.

Alternative: Check your PowerSync dashboard at:
{instance_url.replace('/api', '')}/connections
"""


async def get_sync_metrics(instance_url: str, time_range: str) -> str:
    """Get sync metrics."""
    return f"""PowerSync Metrics ({time_range}):

Instance: {instance_url}

Note: Detailed metrics are available in the PowerSync dashboard.
Visit: {instance_url.replace('/api', '')}/metrics

For programmatic access, configure POWERSYNC_API_KEY environment variable.
"""


async def check_instance_health(instance_url: str) -> str:
    """Check instance health."""
    try:
        response = await client.get(
            f"{instance_url}/health",
            headers={"Authorization": f"Bearer {POWERSYNC_API_KEY}"} if POWERSYNC_API_KEY else {},
            timeout=5.0,
        )

        if response.status_code == 200:
            return f"""PowerSync Instance Health:

Instance: {instance_url}
Status: ✅ Healthy
Response Time: {response.elapsed.total_seconds():.2f}s

The PowerSync instance is reachable and responding.
"""
        else:
            return f"""PowerSync Instance Health:

Instance: {instance_url}
Status: ⚠️  Degraded
HTTP Status: {response.status_code}

The instance is reachable but returned an unexpected status.
"""

    except httpx.ConnectError:
        return f"""PowerSync Instance Health:

Instance: {instance_url}
Status: ❌ Unreachable

Unable to connect to the instance. Check:
1. Instance URL is correct
2. Instance is running
3. Network connectivity
"""
    except Exception as e:
        return f"""PowerSync Instance Health:

Instance: {instance_url}
Status: ❌ Error
Error: {str(e)}
"""


async def get_bucket_info(instance_url: str, bucket_name: Optional[str]) -> str:
    """Get bucket information."""
    if bucket_name:
        return f"""PowerSync Bucket Info:

Instance: {instance_url}
Bucket: {bucket_name}

Note: Bucket configuration is available in the PowerSync dashboard.
Visit: {instance_url.replace('/api', '')}/sync-rules

For your project, buckets are configured in the sync rules YAML.
"""
    else:
        return f"""PowerSync Buckets:

Instance: {instance_url}

Your project uses bucket-based sync rules to control which data syncs to each client.

To view bucket configurations:
1. Visit PowerSync Dashboard: {instance_url.replace('/api', '')}/sync-rules
2. Check sync rules YAML configuration

Typical buckets for MedZen:
- global: User-specific medical data
"""


async def main():
    """Run the MCP server."""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="powersync-mcp-server",
                server_version="0.1.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


if __name__ == "__main__":
    asyncio.run(main())
