# MedZen Disaster Recovery Runbook

**Version:** 1.0
**Last Updated:** November 18, 2025
**On-Call Team:** DevOps

## Quick Reference

| Metric | Target |
|--------|--------|
| **RTO** (Recovery Time) | 15 minutes |
| **RPO** (Data Loss) | 5 minutes |
| **Escalation** | Team Lead → CTO |

### Emergency Contacts

| Role | Contact |
|------|---------|
| DevOps On-Call | PagerDuty |
| AWS Support | Business Plan |
| Database Admin | Internal |

---

## Incident Classification

### Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| **P1** | Complete outage | Immediate |
| **P2** | Partial outage | 15 minutes |
| **P3** | Degraded service | 1 hour |
| **P4** | Minor issue | 4 hours |

---

## Scenario 1: EHRbase Primary Failure (af-south-1)

### Detection
- Route 53 health check fails
- CloudWatch alarm: `medzen-ehrbase-high-cpu`
- User reports: Unable to access medical records

### Automatic Failover
Route 53 automatically routes traffic to eu-west-1 when health checks fail.

### Manual Failover Steps

```bash
# 1. Verify primary is down
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services medzen-ehrbase-service \
  --region af-south-1

# 2. Promote RDS read replica to primary
aws rds promote-read-replica \
  --db-instance-identifier medzen-ehrbase-db-replica \
  --region eu-west-1

# 3. Scale up DR ECS service
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --desired-count 4 \
  --region eu-west-1

# 4. Update Route 53 (if not automatic)
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456 \
  --change-batch file://failover-dns.json

# 5. Verify DR is serving traffic
curl https://ehr.medzenhealth.app/ehrbase/rest/status
```

### Recovery (Return to Primary)

```bash
# 1. Fix primary region issues
# 2. Restore RDS from backup or create new replica
# 3. Sync data from eu-west-1 to af-south-1
# 4. Test primary thoroughly
# 5. Gradually shift traffic back (canary deployment)
# 6. Monitor for 24 hours before full cutover
```

### Estimated Time: 15-30 minutes

---

## Scenario 2: AI Service Failure (eu-west-1)

### Detection
- Lambda error rate spike
- API Gateway 5xx errors
- CloudWatch alarm: `medzen-ai-lambda-errors`

### Automatic Failover
Lambda code includes multi-region failover:
```javascript
// Failover chain: eu-west-1 → us-east-1 → af-south-1
const regions = ['eu-west-1', 'us-east-1', 'af-south-1'];
```

### Manual Intervention

```bash
# 1. Check Lambda health
aws lambda get-function \
  --function-name medzen-ai-chat-handler \
  --region eu-west-1

# 2. Check CloudWatch logs
aws logs tail /aws/lambda/medzen-ai-chat-handler \
  --region eu-west-1 \
  --follow

# 3. If Bedrock issue, force failover region
aws lambda update-function-configuration \
  --function-name medzen-ai-chat-handler \
  --region eu-west-1 \
  --environment "Variables={BEDROCK_REGION=us-east-1}"

# 4. If Lambda issue, invoke us-east-1 directly
# Update API Gateway to route to us-east-1 Lambda
```

### Rollback

```bash
# Restore original configuration
aws lambda update-function-configuration \
  --function-name medzen-ai-chat-handler \
  --region eu-west-1 \
  --environment "Variables={BEDROCK_REGION=eu-west-1}"
```

### Estimated Time: 5-10 minutes

---

## Scenario 3: Chime SDK Meeting Failure

### Detection
- Users cannot create meetings
- Recording pipeline failures
- CloudWatch alarm: `medzen-chime-meeting-errors`

### Immediate Actions

```bash
# 1. Check Chime SDK service health
aws chime list-meetings --max-results 10

# 2. Check Lambda logs
aws logs tail /aws/lambda/medzen-meeting-manager \
  --region eu-west-1

# 3. Verify S3 bucket access
aws s3 ls s3://medzen-recordings-eu-west-1/

# 4. Switch media region if af-south-1 has issues
# Update Lambda environment variable
aws lambda update-function-configuration \
  --function-name medzen-meeting-manager \
  --region eu-west-1 \
  --environment "Variables={MEDIA_REGION=eu-west-1}"
```

### Fallback to Agora

If Chime SDK is completely unavailable:
1. Enable Agora video calling in app config
2. Notify users via in-app message
3. Queue recordings for later processing

### Estimated Time: 10-15 minutes

---

## Scenario 4: RDS Database Failure

### Detection
- ECS tasks failing health checks
- CloudWatch alarm: `medzen-rds-high-connections`
- Connection timeout errors

### Point-in-Time Recovery

```bash
# 1. Find available recovery points
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier medzen-ehrbase-db \
  --region af-south-1

# 2. Restore to new instance
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier medzen-ehrbase-db \
  --target-db-instance-identifier medzen-ehrbase-db-restored \
  --restore-time 2025-11-18T10:00:00Z \
  --region af-south-1

# 3. Update ECS task definition with new endpoint
# 4. Redeploy ECS service
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --force-new-deployment \
  --region af-south-1
```

### Cross-Region Recovery

```bash
# If af-south-1 RDS is unrecoverable
# 1. Promote eu-west-1 read replica
aws rds promote-read-replica \
  --db-instance-identifier medzen-ehrbase-db-replica \
  --region eu-west-1

# 2. This becomes the new primary
# 3. Plan to create new replica in af-south-1 later
```

### Estimated Time: 30-60 minutes

---

## Scenario 5: Complete Region Failure

### Detection
- AWS status page shows regional issues
- Multiple services failing simultaneously
- Route 53 health checks failing across services

### Failover Plan

**af-south-1 Complete Failure:**

```bash
# 1. All traffic routes to eu-west-1 automatically
# 2. Verify all services in eu-west-1

# EHRbase
curl https://ehr-dr.medzenhealth.app/ehrbase/rest/status

# AI (already multi-region)
curl https://ai.medzenhealth.app/health

# Chime (already in eu-west-1)
# No action needed

# 3. Communicate to users
# - Expect higher latency (120-160ms vs 80-120ms)
# - All features remain available

# 4. Monitor eu-west-1 capacity
# - May need to scale ECS services
# - Watch RDS connections
```

**eu-west-1 Complete Failure:**

```bash
# 1. AI traffic fails over to us-east-1
# - Automatic in Lambda code
# - Some model limitations (no Nova in us-east-1... actually yes)

# 2. Chime meetings affected
# - Create meetings will use us-east-1 if available
# - Existing meetings continue until completion
# - Fallback to Agora for new calls

# 3. EHRbase DR becomes unavailable
# - Primary still works in af-south-1
# - No read replica until eu-west-1 recovers
```

### Estimated Time: 15-30 minutes

---

## Scenario 6: Security Incident

### Detection
- Unusual API access patterns
- IAM credential alerts
- GuardDuty findings

### Immediate Actions

```bash
# 1. ISOLATE - Disable compromised credentials
aws iam update-access-key \
  --access-key-id AKIA... \
  --status Inactive \
  --user-name compromised-user

# 2. CONTAIN - Restrict security groups
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# 3. INVESTIGATE - Check CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=compromised-user

# 4. REMEDIATE - Rotate all secrets
# Secrets Manager, API keys, database passwords

# 5. REPORT - Document incident
# Follow HIPAA breach notification requirements
```

### Escalation
- P1: Immediate escalation to CTO
- Contact legal for HIPAA implications
- Notify affected users within 60 days (if PHI breach)

---

## Communication Templates

### Internal Status Update

```
INCIDENT: [EHRbase/AI/Chime] service degradation
SEVERITY: P[1/2/3]
STATUS: Investigating / Mitigating / Resolved
IMPACT: [X] users affected
ETA: [X] minutes
ACTIONS: [What we're doing]
NEXT UPDATE: [Time]
```

### User Notification

```
MedZen Service Update

We are currently experiencing [brief description].

Impact: [What users will notice]
Workaround: [If available]
Expected resolution: [Time estimate]

We apologize for the inconvenience and are working to resolve this quickly.

Status page: https://status.medzenhealth.app
```

---

## Post-Incident Review

### Within 24 Hours

1. **Timeline:** Document exactly what happened and when
2. **Root Cause:** Identify the underlying cause
3. **Impact:** Quantify users affected, data loss
4. **Actions Taken:** What we did to resolve

### Within 1 Week

1. **Blameless Post-Mortem:** Team review
2. **Action Items:** Prevent recurrence
3. **Documentation Updates:** Update runbooks
4. **Testing:** Verify fixes in staging

### Template

```markdown
## Incident Report: [Title]

**Date:** [Date]
**Duration:** [X hours/minutes]
**Severity:** P[1/2/3]
**Author:** [Name]

### Summary
[1-2 sentence description]

### Impact
- Users affected: X
- Revenue impact: $X
- Data loss: None/X records

### Timeline
- HH:MM - [Event]
- HH:MM - [Action taken]
- HH:MM - [Resolution]

### Root Cause
[Technical explanation]

### Resolution
[What fixed it]

### Action Items
- [ ] [Action] - Owner - Due Date
- [ ] [Action] - Owner - Due Date

### Lessons Learned
[What we'll do differently]
```

---

## Testing Schedule

### Monthly
- [ ] Failover test (non-production)
- [ ] Backup restoration test
- [ ] Runbook review

### Quarterly
- [ ] Full DR drill (production)
- [ ] Security incident simulation
- [ ] Capacity planning review

### Annually
- [ ] Complete infrastructure audit
- [ ] Third-party penetration test
- [ ] Compliance review (HIPAA)

---

## Useful Commands

### Health Checks

```bash
# EHRbase
curl -I https://ehr.medzenhealth.app/ehrbase/rest/status

# AI API
curl https://ai.medzenhealth.app/health

# Chime API
curl https://meetings.medzenhealth.app/health
```

### Service Status

```bash
# ECS services
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services medzen-ehrbase-service \
  --region af-south-1

# Lambda functions
aws lambda list-functions \
  --region eu-west-1 \
  --query "Functions[?contains(FunctionName, 'medzen')]"

# RDS instances
aws rds describe-db-instances \
  --query "DBInstances[?contains(DBInstanceIdentifier, 'medzen')]"
```

### Logs

```bash
# ECS logs
aws logs tail /ecs/medzen-ehrbase --follow

# Lambda logs
aws logs tail /aws/lambda/medzen-ai-chat-handler --follow

# API Gateway logs
aws logs tail /aws/apigateway/medzen-ai-api --follow
```

---

## Appendix

### DNS Failover Configuration

```json
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "ehr.medzenhealth.app",
      "Type": "A",
      "SetIdentifier": "primary",
      "Failover": "SECONDARY",
      "AliasTarget": {
        "HostedZoneId": "Z123456",
        "DNSName": "alb-eu-west-1.amazonaws.com",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
```

### Important ARNs

```bash
# Lambda roles
arn:aws:iam::ACCOUNT:role/medzen-lambda-execution-role

# KMS keys
arn:aws:kms:af-south-1:ACCOUNT:key/xxx
arn:aws:kms:eu-west-1:ACCOUNT:key/xxx

# SNS topics
arn:aws:sns:af-south-1:ACCOUNT:medzen-global-alerts
```

---

**Last Drill:** [Date]
**Next Drill:** [Date]
**Document Owner:** DevOps Team
