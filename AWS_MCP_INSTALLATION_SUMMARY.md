# AWS MCP Server Installation Summary

**Date:** October 28, 2025
**Project:** medzen-iwani
**Status:** ✅ Successfully Installed

---

## Installation Overview

AWS MCP (Model Context Protocol) server has been successfully installed and configured for the MedZen-Iwani project. This enables Claude Code to interact directly with AWS services using your configured credentials.

---

## What Was Installed

### AWS API MCP Server
- **Package:** `awslabs.aws-api-mcp-server@latest`
- **Version:** FastMCP 2.13.0.2
- **Transport:** stdio (standard input/output)
- **Dependencies:** 83 packages including awscli, botocore, cryptography

### Configuration

**MCP Server Config** (`~/.config/claude-code/mcp_servers.json`):
```json
{
  "aws-api": {
    "command": "uvx",
    "args": ["awslabs.aws-api-mcp-server@latest"],
    "env": {
      "AWS_REGION": "us-east-1",
      "AWS_PROFILE": "default",
      "FASTMCP_LOG_LEVEL": "ERROR"
    }
  }
}
```

**Project Settings** (`.claude/settings.local.json`):
- Added "aws-api" to `enabledMcpjsonServers`
- Pre-approved permission: `Bash(uvx awslabs.aws-api-mcp-server@latest:*)`

---

## AWS Credentials Used

- **Account ID:** 558069890522
- **IAM User:** mylestech
- **Region:** us-east-1
- **Profile:** default
- **Credentials:** Configured via `~/.aws/credentials` and `~/.aws/config`

---

## Available AWS MCP Servers

The AWS MCP repository includes 60+ specialized servers. You now have the **AWS API MCP Server** installed, which provides comprehensive AWS service interactions.

### Other Available Servers (Not Installed)

If you need more specialized functionality, you can install additional servers:

| Server | Purpose | Install Command |
|--------|---------|-----------------|
| **S3** | S3 bucket and object operations | `uvx awslabs.s3-mcp-server@latest` |
| **DynamoDB** | DynamoDB table operations | `uvx awslabs.dynamodb-mcp-server@latest` |
| **Lambda** | Lambda function management | `uvx awslabs.lambda-mcp-server@latest` |
| **Bedrock KB** | Bedrock knowledge base retrieval | `uvx awslabs.bedrock-kb-retrieval-mcp-server@latest` |
| **HealthLake** | FHIR healthcare data (⭐ relevant for MedZen) | `uvx awslabs.healthlake-mcp-server@latest` |
| **ECS** | Container orchestration | `uvx awslabs.ecs-mcp-server@latest` |
| **CloudWatch** | Logs and metrics | `uvx awslabs.cloudwatch-logs-mcp-server@latest` |

Full list: [AWS MCP Repository](https://github.com/awslabs/mcp)

---

## How to Use AWS MCP

### Example Tasks You Can Now Perform

1. **List S3 Buckets**
   ```
   "List all S3 buckets in my AWS account"
   ```

2. **DynamoDB Operations**
   ```
   "Show me all DynamoDB tables and their item counts"
   ```

3. **Lambda Functions**
   ```
   "List all Lambda functions and their runtime versions"
   ```

4. **EC2 Instances**
   ```
   "Show me all running EC2 instances with their instance types and IPs"
   ```

5. **IAM Users and Roles**
   ```
   "List all IAM users and their access keys"
   ```

6. **CloudWatch Logs**
   ```
   "Get the latest logs from [log-group-name]"
   ```

7. **Cost and Billing**
   ```
   "What's my AWS spend for this month?"
   ```

### Claude Code Integration

Once you restart Claude Code, the AWS MCP server will be available automatically. You can:
- Ask Claude to perform AWS operations
- Use AWS services as context for development
- Automate AWS infrastructure tasks
- Query AWS resources during debugging

---

## Healthcare-Specific Use Cases

Since MedZen-Iwani is a healthcare application, here are AWS services that might be relevant:

### AWS HealthLake (FHIR-Compliant)
- **Current:** Using EHRbase (OpenEHR)
- **Alternative:** AWS HealthLake supports FHIR R4
- **Install:** `uvx awslabs.healthlake-mcp-server@latest`
- **Use Case:** If you need FHIR compatibility alongside OpenEHR

### Amazon Transcribe Medical
- **Purpose:** Medical transcription with specialized vocabulary
- **Use Case:** Doctor's notes, patient interviews, telemedicine calls
- **Integration:** Via AWS API MCP Server

### Amazon Bedrock
- **Purpose:** AI/ML models for healthcare applications
- **Use Case:** Medical summarization, clinical decision support
- **Integration:** Via Bedrock KB Retrieval MCP Server

### AWS IoT Core
- **Purpose:** Connect medical devices
- **Use Case:** Wearables, glucose monitors, blood pressure cuffs
- **Integration:** Via AWS API MCP Server

---

## Verification Steps

### 1. Test AWS MCP Server (Manual)

Run this command to verify the server works:
```bash
uvx awslabs.aws-api-mcp-server@latest --help
```

Expected output:
```
╭──────────────────────────────────────────────────────────────────────────────╮
│                         ▄▀▀ ▄▀█ █▀▀ ▀█▀ █▀▄▀█ █▀▀ █▀█                        │
│                         █▀  █▀█ ▄▄█  █  █ ▀ █ █▄▄ █▀▀                        │
│                               FastMCP 2.13.0.2                               │
│                    🖥  Server name: AWS-API-MCP                               │
│                    📦 Transport:   STDIO                                     │
╰──────────────────────────────────────────────────────────────────────────────╯
```

### 2. Test AWS Credentials

```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDA...",
    "Account": "558069890522",
    "Arn": "arn:aws:iam::558069890522:user/mylestech"
}
```

### 3. Test Claude Code Integration

1. Restart Claude Code
2. Ask: "List my AWS S3 buckets"
3. Verify Claude uses the AWS MCP server to retrieve the list

---

## Configuration Files Modified

1. **`~/.config/claude-code/mcp_servers.json`**
   - Added "aws-api" server configuration
   - Total MCP servers: 12 (was 11)

2. **`.claude/settings.local.json`**
   - Added "aws-api" to `enabledMcpjsonServers`
   - Added permission for uvx AWS MCP server command

---

## Security Considerations

### Current Setup
- ✅ Uses IAM user credentials (`mylestech`)
- ✅ Credentials stored in `~/.aws/credentials` (secure)
- ✅ No credentials committed to code
- ✅ Region set to us-east-1
- ✅ Log level set to ERROR (minimal logging)

### Best Practices
- **Rotate Access Keys:** Regularly rotate IAM access keys
- **Use IAM Roles:** Consider switching to IAM roles with temporary credentials
- **Least Privilege:** Ensure IAM user has only necessary permissions
- **MFA:** Enable MFA for IAM user
- **CloudTrail:** Enable CloudTrail to audit AWS API calls

### HIPAA Compliance (If Applicable)
- Ensure AWS account has HIPAA BAA signed
- Use encrypted services (S3-SSE, RDS encryption, etc.)
- Enable VPC endpoints for private connectivity
- Use AWS PrivateLink for sensitive workloads

---

## Troubleshooting

### MCP Server Not Loading
```bash
# Check uvx is installed
uvx --version

# Test server manually
uvx awslabs.aws-api-mcp-server@latest --help

# Check Claude Code logs
cat ~/.claude-code/logs/latest.log | grep aws-api
```

### AWS Credentials Issues
```bash
# Verify credentials
aws sts get-caller-identity

# Check AWS config
cat ~/.aws/credentials
cat ~/.aws/config

# Test with specific profile
export AWS_PROFILE=default
aws s3 ls
```

### Permission Errors
- Check IAM user permissions in AWS Console
- Verify IAM policies are attached
- Review CloudTrail logs for access denied errors

---

## Comparison: AWS MCP vs Current Stack

| Feature | Current Stack | AWS Alternative |
|---------|--------------|-----------------|
| **Authentication** | Firebase Auth | AWS Cognito |
| **Database** | Supabase PostgreSQL | AWS RDS/Aurora |
| **File Storage** | Supabase Storage + R2 | AWS S3 |
| **Functions** | Firebase + Cloudflare | AWS Lambda |
| **EHR Storage** | EHRbase (OpenEHR) | AWS HealthLake (FHIR) |
| **Offline Sync** | PowerSync | AWS AppSync |
| **Edge/CDN** | Cloudflare | AWS CloudFront |

**Current Stack Advantage:** No AWS costs, simpler billing, already implemented
**AWS Stack Advantage:** Unified platform, enterprise features, AWS support

---

## Next Steps

### Immediate Actions (Optional)
1. ✅ Installation complete (no action needed)
2. Restart Claude Code to activate AWS MCP
3. Test AWS integration with simple queries
4. Explore AWS services relevant to your project

### Future Considerations
1. **If migrating to AWS:**
   - Install specialized MCP servers (S3, DynamoDB, Lambda)
   - Plan migration strategy from Firebase/Supabase to AWS
   - Update CLAUDE.md with AWS architecture

2. **If using AWS alongside current stack:**
   - Identify specific AWS services needed
   - Implement hybrid architecture
   - Document integration points

3. **If NOT using AWS:**
   - AWS MCP remains dormant (no cost, no issue)
   - Can be removed later if unused
   - Keep for potential future AWS integration

---

## Uninstallation (If Needed)

To remove AWS MCP server:

1. **Remove from MCP config:**
   ```bash
   # Edit ~/.config/claude-code/mcp_servers.json
   # Delete the "aws-api" entry
   ```

2. **Remove from project settings:**
   ```bash
   # Edit .claude/settings.local.json
   # Remove "aws-api" from enabledMcpjsonServers
   ```

3. **Clear uvx cache (optional):**
   ```bash
   uv cache clean
   ```

---

## Documentation Links

- **AWS MCP Repository:** https://github.com/awslabs/mcp
- **FastMCP Documentation:** https://gofastmcp.com
- **MCP Protocol Spec:** https://modelcontextprotocol.io
- **Claude Code MCP Guide:** https://docs.claude.com/en/docs/claude-code/mcp
- **AWS CLI Documentation:** https://docs.aws.amazon.com/cli/

---

## Summary

✅ **Installed:** AWS API MCP Server
✅ **Configured:** Global + Project settings
✅ **Tested:** Server launches successfully
✅ **Credentials:** Working (Account 558069890522)
✅ **Ready:** Restart Claude Code to activate

**Total MCP Servers Now:** 28 (12 in mcp_servers.json + 16 project-specific)

---

*Installation completed by Claude Code on October 28, 2025*
