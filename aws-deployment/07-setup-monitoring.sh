#!/bin/bash

################################################################################
# EHRbase AWS Production - Monitoring and Alerting Setup
# Sets up CloudWatch dashboards, alarms, and SNS notifications
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Production - Monitoring Setup"
echo "=========================================="
echo ""

# Load environment variables
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

source .env

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check required variables
if [ -z "$ALB_DNS" ] || [ -z "$VPC_ID" ]; then
    echo -e "${RED}Error:${NC} Required variables not found"
    echo "Run ./04-setup-ecs.sh first"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  Project: ${PROJECT_NAME}"
echo "  Region: ${AWS_REGION}"
echo "  Environment: Production"
echo ""

################################################################################
# 1. CREATE SNS TOPIC FOR ALERTS
################################################################################

echo "=========================================="
echo "Step 1: Creating SNS Topic for Alerts"
echo "=========================================="
echo ""

SNS_TOPIC_NAME="${PROJECT_NAME}-alerts"

# Check if topic already exists
EXISTING_TOPIC=$(aws sns list-topics \
    --region $AWS_REGION \
    --query "Topics[?contains(TopicArn, '${SNS_TOPIC_NAME}')].TopicArn" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_TOPIC" ]; then
    echo -e "${YELLOW}⚠${NC}  SNS topic already exists: $SNS_TOPIC_NAME"
    SNS_TOPIC_ARN="$EXISTING_TOPIC"
else
    echo "Creating SNS topic: $SNS_TOPIC_NAME"

    SNS_TOPIC_ARN=$(aws sns create-topic \
        --name $SNS_TOPIC_NAME \
        --region $AWS_REGION \
        --query 'TopicArn' \
        --output text)

    echo -e "${GREEN}✓${NC} SNS topic created"
fi

echo "  Topic ARN: $SNS_TOPIC_ARN"
echo ""

# Prompt for email subscription
read -p "Enter email address for alerts (or press Enter to skip): " ALERT_EMAIL

if [ -n "$ALERT_EMAIL" ]; then
    echo "Subscribing $ALERT_EMAIL to alerts..."

    aws sns subscribe \
        --topic-arn $SNS_TOPIC_ARN \
        --protocol email \
        --notification-endpoint $ALERT_EMAIL \
        --region $AWS_REGION

    echo -e "${GREEN}✓${NC} Email subscription created"
    echo -e "${YELLOW}Important:${NC} Check $ALERT_EMAIL and confirm the subscription"
else
    echo -e "${YELLOW}⚠${NC}  No email configured - you can add subscriptions later"
    echo "  aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol email --notification-endpoint your@email.com"
fi

# Save SNS ARN to .env
if ! grep -q "SNS_TOPIC_ARN=" .env; then
    echo "" >> .env
    echo "# Monitoring" >> .env
    echo "SNS_TOPIC_ARN=$SNS_TOPIC_ARN" >> .env
    echo -e "${GREEN}✓${NC} SNS ARN saved to .env"
fi

################################################################################
# 2. CREATE CLOUDWATCH ALARMS - ECS
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Creating ECS CloudWatch Alarms"
echo "=========================================="
echo ""

# ECS CPU Utilization Alarm
echo "Creating ECS CPU utilization alarm..."

aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-ecs-high-cpu" \
    --alarm-description "ECS service CPU utilization is above 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=ClusterName,Value=${PROJECT_NAME}-cluster Name=ServiceName,Value=${PROJECT_NAME}-service \
    --alarm-actions $SNS_TOPIC_ARN \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} ECS CPU alarm created"

# ECS Memory Utilization Alarm
echo "Creating ECS memory utilization alarm..."

aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-ecs-high-memory" \
    --alarm-description "ECS service memory utilization is above 80%" \
    --metric-name MemoryUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=ClusterName,Value=${PROJECT_NAME}-cluster Name=ServiceName,Value=${PROJECT_NAME}-service \
    --alarm-actions $SNS_TOPIC_ARN \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} ECS memory alarm created"

# ECS Running Task Count Alarm
echo "Creating ECS task count alarm..."

aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-ecs-low-tasks" \
    --alarm-description "ECS service has less than 2 running tasks" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic SampleCount \
    --period 60 \
    --evaluation-periods 2 \
    --threshold 2 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=ClusterName,Value=${PROJECT_NAME}-cluster Name=ServiceName,Value=${PROJECT_NAME}-service \
    --alarm-actions $SNS_TOPIC_ARN \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} ECS task count alarm created"

################################################################################
# 3. CREATE CLOUDWATCH ALARMS - RDS
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Creating RDS CloudWatch Alarms"
echo "=========================================="
echo ""

# RDS CPU Utilization Alarm
echo "Creating RDS CPU utilization alarm..."

aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-rds-high-cpu" \
    --alarm-description "RDS CPU utilization is above 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=${PROJECT_NAME}-db \
    --alarm-actions $SNS_TOPIC_ARN \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} RDS CPU alarm created"

# RDS Storage Space Alarm
echo "Creating RDS storage space alarm..."

aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-rds-low-storage" \
    --alarm-description "RDS free storage space is below 10GB" \
    --metric-name FreeStorageSpace \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 10737418240 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=${PROJECT_NAME}-db \
    --alarm-actions $SNS_TOPIC_ARN \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} RDS storage alarm created"

# RDS Connection Count Alarm
echo "Creating RDS connection count alarm..."

aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-rds-high-connections" \
    --alarm-description "RDS database connections are above 80" \
    --metric-name DatabaseConnections \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=${PROJECT_NAME}-db \
    --alarm-actions $SNS_TOPIC_ARN \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} RDS connection count alarm created"

################################################################################
# 4. CREATE CLOUDWATCH ALARMS - ALB
################################################################################

echo ""
echo "=========================================="
echo "Step 4: Creating ALB CloudWatch Alarms"
echo "=========================================="
echo ""

# Get ALB ARN suffix for dimensions
ALB_FULL_NAME=$(aws elbv2 describe-load-balancers \
    --names ${PROJECT_NAME}-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region $AWS_REGION)

ALB_SUFFIX=$(echo $ALB_FULL_NAME | grep -o 'app/.*')

# Get Target Group ARN suffix
TG_FULL_ARN=$(aws elbv2 describe-target-groups \
    --names ${PROJECT_NAME}-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "")

if [ -n "$TG_FULL_ARN" ]; then
    TG_SUFFIX=$(echo $TG_FULL_ARN | grep -o 'targetgroup/.*')

    # ALB Target Response Time Alarm
    echo "Creating ALB response time alarm..."

    aws cloudwatch put-metric-alarm \
        --alarm-name "${PROJECT_NAME}-alb-high-response-time" \
        --alarm-description "ALB target response time is above 2 seconds" \
        --metric-name TargetResponseTime \
        --namespace AWS/ApplicationELB \
        --statistic Average \
        --period 300 \
        --evaluation-periods 2 \
        --threshold 2 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=LoadBalancer,Value=$ALB_SUFFIX \
        --alarm-actions $SNS_TOPIC_ARN \
        --region $AWS_REGION

    echo -e "${GREEN}✓${NC} ALB response time alarm created"

    # ALB Unhealthy Target Count Alarm
    echo "Creating ALB unhealthy target alarm..."

    aws cloudwatch put-metric-alarm \
        --alarm-name "${PROJECT_NAME}-alb-unhealthy-targets" \
        --alarm-description "ALB has unhealthy targets" \
        --metric-name UnHealthyHostCount \
        --namespace AWS/ApplicationELB \
        --statistic Average \
        --period 60 \
        --evaluation-periods 2 \
        --threshold 1 \
        --comparison-operator GreaterThanOrEqualToThreshold \
        --dimensions Name=LoadBalancer,Value=$ALB_SUFFIX Name=TargetGroup,Value=$TG_SUFFIX \
        --alarm-actions $SNS_TOPIC_ARN \
        --region $AWS_REGION

    echo -e "${GREEN}✓${NC} ALB unhealthy target alarm created"

    # ALB 5xx Error Rate Alarm
    echo "Creating ALB 5xx error rate alarm..."

    aws cloudwatch put-metric-alarm \
        --alarm-name "${PROJECT_NAME}-alb-high-5xx-errors" \
        --alarm-description "ALB 5xx error rate is above 5%" \
        --metric-name HTTPCode_Target_5XX_Count \
        --namespace AWS/ApplicationELB \
        --statistic Sum \
        --period 300 \
        --evaluation-periods 2 \
        --threshold 10 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=LoadBalancer,Value=$ALB_SUFFIX \
        --alarm-actions $SNS_TOPIC_ARN \
        --region $AWS_REGION

    echo -e "${GREEN}✓${NC} ALB 5xx error alarm created"
fi

################################################################################
# 5. CREATE CLOUDWATCH DASHBOARD
################################################################################

echo ""
echo "=========================================="
echo "Step 5: Creating CloudWatch Dashboard"
echo "=========================================="
echo ""

DASHBOARD_NAME="${PROJECT_NAME}-production"

# Create dashboard JSON
cat > /tmp/dashboard-body.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "CPUUtilization", { "stat": "Average", "label": "ECS CPU" } ],
                    [ ".", "MemoryUtilization", { "stat": "Average", "label": "ECS Memory" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_REGION}",
                "title": "ECS Service - CPU & Memory",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", { "stat": "Average", "label": "RDS CPU" } ],
                    [ ".", "DatabaseConnections", { "stat": "Average", "yAxis": "right", "label": "DB Connections" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_REGION}",
                "title": "RDS - CPU & Connections",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", { "stat": "Average", "label": "Response Time" } ],
                    [ ".", "RequestCount", { "stat": "Sum", "yAxis": "right", "label": "Request Count" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_REGION}",
                "title": "ALB - Response Time & Request Count",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", { "stat": "Sum", "label": "2xx", "color": "#2ca02c" } ],
                    [ ".", "HTTPCode_Target_4XX_Count", { "stat": "Sum", "label": "4xx", "color": "#ff7f0e" } ],
                    [ ".", "HTTPCode_Target_5XX_Count", { "stat": "Sum", "label": "5xx", "color": "#d62728" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_REGION}",
                "title": "ALB - HTTP Response Codes",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeStorageSpace", { "stat": "Average", "label": "Free Storage" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_REGION}",
                "title": "RDS - Storage Space (Bytes)",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 12,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HealthyHostCount", { "stat": "Average", "label": "Healthy", "color": "#2ca02c" } ],
                    [ ".", "UnHealthyHostCount", { "stat": "Average", "label": "Unhealthy", "color": "#d62728" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_REGION}",
                "title": "ALB - Target Health",
                "period": 60
            }
        }
    ]
}
EOF

echo "Creating CloudWatch dashboard: $DASHBOARD_NAME"

aws cloudwatch put-dashboard \
    --dashboard-name $DASHBOARD_NAME \
    --dashboard-body file:///tmp/dashboard-body.json \
    --region $AWS_REGION

rm /tmp/dashboard-body.json

echo -e "${GREEN}✓${NC} CloudWatch dashboard created"
echo ""
echo "  Dashboard URL:"
echo "  https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"

################################################################################
# 6. CREATE LOG INSIGHTS QUERIES
################################################################################

echo ""
echo "=========================================="
echo "Step 6: Creating Log Insights Queries"
echo "=========================================="
echo ""

# Create queries directory
mkdir -p log-insights-queries

# Query 1: Recent errors
cat > log-insights-queries/recent-errors.txt << 'EOF'
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /Exception/
| sort @timestamp desc
| limit 50
EOF

echo -e "${GREEN}✓${NC} Created query: recent-errors.txt"

# Query 2: Response times
cat > log-insights-queries/response-times.txt << 'EOF'
fields @timestamp, @message
| filter @message like /status/
| parse @message /duration=(?<duration>\d+)/
| stats avg(duration), max(duration), min(duration), pct(duration, 95) by bin(5m)
EOF

echo -e "${GREEN}✓${NC} Created query: response-times.txt"

# Query 3: Top error messages
cat > log-insights-queries/top-errors.txt << 'EOF'
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() as error_count by @message
| sort error_count desc
| limit 20
EOF

echo -e "${GREEN}✓${NC} Created query: top-errors.txt"

# Query 4: Database connection issues
cat > log-insights-queries/database-issues.txt << 'EOF'
fields @timestamp, @message
| filter @message like /database/ or @message like /connection/ or @message like /timeout/
| sort @timestamp desc
| limit 50
EOF

echo -e "${GREEN}✓${NC} Created query: database-issues.txt"

echo ""
echo "Log Insights queries saved to: log-insights-queries/"
echo ""
echo "Usage:"
echo "  1. Go to CloudWatch > Logs > Insights"
echo "  2. Select log group: /ecs/${PROJECT_NAME}"
echo "  3. Copy/paste query from log-insights-queries/ directory"

################################################################################
# 7. CREATE MONITORING DOCUMENTATION
################################################################################

echo ""
echo "Creating monitoring documentation..."

cat > monitoring-guide.md << EOF
# EHRbase Production Monitoring Guide

**Date:** $(date)
**Environment:** Production
**Region:** ${AWS_REGION}

## CloudWatch Dashboard

**Dashboard Name:** ${DASHBOARD_NAME}

**URL:** https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}

**Widgets:**
- ECS Service CPU & Memory utilization
- RDS CPU utilization & database connections
- ALB response time & request count
- ALB HTTP response codes (2xx, 4xx, 5xx)
- RDS storage space
- ALB target health (healthy/unhealthy hosts)

## CloudWatch Alarms

### ECS Alarms
1. **${PROJECT_NAME}-ecs-high-cpu**
   - Triggers when: CPU > 80% for 10 minutes
   - Action: Auto-scaling, SNS notification

2. **${PROJECT_NAME}-ecs-high-memory**
   - Triggers when: Memory > 80% for 10 minutes
   - Action: SNS notification

3. **${PROJECT_NAME}-ecs-low-tasks**
   - Triggers when: Running tasks < 2 for 2 minutes
   - Action: SNS notification (check service health)

### RDS Alarms
1. **${PROJECT_NAME}-rds-high-cpu**
   - Triggers when: CPU > 80% for 10 minutes
   - Action: SNS notification (consider upgrading instance)

2. **${PROJECT_NAME}-rds-low-storage**
   - Triggers when: Free storage < 10GB
   - Action: SNS notification (increase storage)

3. **${PROJECT_NAME}-rds-high-connections**
   - Triggers when: Connections > 80 for 10 minutes
   - Action: SNS notification (check for connection leaks)

### ALB Alarms
1. **${PROJECT_NAME}-alb-high-response-time**
   - Triggers when: Response time > 2 seconds for 10 minutes
   - Action: SNS notification (investigate performance)

2. **${PROJECT_NAME}-alb-unhealthy-targets**
   - Triggers when: Unhealthy targets >= 1 for 2 minutes
   - Action: SNS notification (check ECS tasks)

3. **${PROJECT_NAME}-alb-high-5xx-errors**
   - Triggers when: 5xx errors > 10 in 5 minutes for 10 minutes
   - Action: SNS notification (check application logs)

## SNS Topic

**Topic ARN:** ${SNS_TOPIC_ARN}

**Subscriptions:**
- Email: $([ -n "$ALERT_EMAIL" ] && echo "$ALERT_EMAIL" || echo "None configured")

**Add Email Subscription:**
\`\`\`bash
aws sns subscribe \\
  --topic-arn ${SNS_TOPIC_ARN} \\
  --protocol email \\
  --notification-endpoint your@email.com \\
  --region ${AWS_REGION}
\`\`\`

**Add SMS Subscription:**
\`\`\`bash
aws sns subscribe \\
  --topic-arn ${SNS_TOPIC_ARN} \\
  --protocol sms \\
  --notification-endpoint +1234567890 \\
  --region ${AWS_REGION}
\`\`\`

## Log Groups

**ECS Logs:** /ecs/${PROJECT_NAME}

**View Recent Logs:**
\`\`\`bash
aws logs tail /ecs/${PROJECT_NAME} --follow --region ${AWS_REGION}
\`\`\`

**Filter Errors:**
\`\`\`bash
aws logs tail /ecs/${PROJECT_NAME} --follow --filter-pattern "ERROR" --region ${AWS_REGION}
\`\`\`

## CloudWatch Logs Insights Queries

Pre-built queries available in \`log-insights-queries/\` directory:

1. **recent-errors.txt** - Shows recent ERROR and Exception messages
2. **response-times.txt** - Analyzes API response times with percentiles
3. **top-errors.txt** - Lists most frequent error messages
4. **database-issues.txt** - Filters database connection issues

**How to Use:**
1. Open CloudWatch > Logs > Insights
2. Select log group: /ecs/${PROJECT_NAME}
3. Copy/paste query from file
4. Adjust time range
5. Click "Run query"

## Metric Math Examples

### Request Success Rate
\`\`\`
m1 = HTTPCode_Target_2XX_Count (sum)
m2 = RequestCount (sum)
e1 = (m1/m2)*100
\`\`\`

### Error Rate
\`\`\`
m1 = HTTPCode_Target_5XX_Count (sum)
m2 = RequestCount (sum)
e1 = (m1/m2)*100
\`\`\`

## Troubleshooting Guide

### High CPU on ECS
1. Check dashboard for traffic spikes
2. Review recent deployments
3. Check for inefficient queries in logs
4. Consider increasing task count or CPU allocation

### High Memory on ECS
1. Check for memory leaks in application logs
2. Review EHRbase configuration (heap size)
3. Consider increasing memory allocation
4. Check for large dataset queries

### Database Connection Issues
1. Check RDS connection count alarm
2. Review application connection pool settings
3. Look for connection timeouts in logs
4. Verify RDS security group rules

### High Response Times
1. Check RDS CPU and storage performance
2. Review slow query logs
3. Check for network issues (ALB → ECS → RDS)
4. Verify target health in ALB

### 5xx Errors
1. Check ECS task logs immediately
2. Verify database connectivity
3. Check for application exceptions
4. Review recent code deployments

## Operational Runbook

### Daily Checks
- Review dashboard for anomalies
- Check all alarms are in OK state
- Verify target health (all healthy)
- Review error logs for patterns

### Weekly Checks
- Review storage trends (RDS, ECS logs)
- Analyze response time trends
- Check for recurring errors
- Review auto-scaling events

### Monthly Checks
- Review monthly costs vs. budget
- Analyze long-term performance trends
- Review and update alarm thresholds
- Test alarm notifications

### Incident Response
1. Check CloudWatch dashboard for affected services
2. Review relevant alarm details
3. Check ECS task logs: \`aws logs tail /ecs/${PROJECT_NAME} --follow\`
4. Check RDS metrics and slow query logs
5. Review ALB access logs if needed
6. Document incident and resolution

## Useful AWS CLI Commands

**View All Alarms:**
\`\`\`bash
aws cloudwatch describe-alarms \\
  --alarm-name-prefix ${PROJECT_NAME} \\
  --region ${AWS_REGION}
\`\`\`

**Get Alarm History:**
\`\`\`bash
aws cloudwatch describe-alarm-history \\
  --alarm-name ${PROJECT_NAME}-ecs-high-cpu \\
  --region ${AWS_REGION}
\`\`\`

**Get Metric Statistics:**
\`\`\`bash
aws cloudwatch get-metric-statistics \\
  --namespace AWS/ECS \\
  --metric-name CPUUtilization \\
  --dimensions Name=ClusterName,Value=${PROJECT_NAME}-cluster Name=ServiceName,Value=${PROJECT_NAME}-service \\
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \\
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \\
  --period 300 \\
  --statistics Average \\
  --region ${AWS_REGION}
\`\`\`

**Test SNS Notification:**
\`\`\`bash
aws sns publish \\
  --topic-arn ${SNS_TOPIC_ARN} \\
  --subject "Test Alert" \\
  --message "This is a test notification from EHRbase monitoring" \\
  --region ${AWS_REGION}
\`\`\`

## Cost Monitoring

**CloudWatch Costs:**
- Dashboard: \$3/month
- Alarms: \$0.10/alarm/month (~\$0.90 for 9 alarms)
- Log Ingestion: \$0.50/GB
- Log Storage: \$0.03/GB/month
- Insights Queries: \$0.005/GB scanned

**Estimated Monthly Cost:** ~\$10-30 depending on log volume

**View CloudWatch Costs:**
1. Go to AWS Cost Explorer
2. Filter by Service: CloudWatch
3. Group by: Usage Type
4. Review log ingestion and storage trends

## Integration with External Tools

### Slack Integration (Optional)
1. Create AWS Chatbot in AWS Console
2. Configure Slack workspace
3. Add SNS topic ${SNS_TOPIC_ARN}
4. Alarms will post to Slack channel

### PagerDuty Integration (Optional)
1. Create PagerDuty service with AWS CloudWatch integration
2. Get PagerDuty endpoint URL
3. Subscribe HTTPS endpoint to SNS topic:
   \`\`\`bash
   aws sns subscribe \\
     --topic-arn ${SNS_TOPIC_ARN} \\
     --protocol https \\
     --notification-endpoint <PAGERDUTY_URL>
   \`\`\`

## Maintenance Windows

When performing maintenance:

1. **Silence Alarms Temporarily:**
   \`\`\`bash
   aws cloudwatch disable-alarm-actions \\
     --alarm-names ${PROJECT_NAME}-ecs-high-cpu ${PROJECT_NAME}-ecs-high-memory \\
     --region ${AWS_REGION}
   \`\`\`

2. **Perform Maintenance**

3. **Re-enable Alarms:**
   \`\`\`bash
   aws cloudwatch enable-alarm-actions \\
     --alarm-names ${PROJECT_NAME}-ecs-high-cpu ${PROJECT_NAME}-ecs-high-memory \\
     --region ${AWS_REGION}
   \`\`\`

## Support Contacts

- **AWS Support:** [AWS Support Center](https://console.aws.amazon.com/support/home)
- **EHRbase Documentation:** https://ehrbase.readthedocs.io/
- **Project Documentation:** See deployment scripts and guides in aws-deployment/

EOF

echo -e "${GREEN}✓${NC} Monitoring guide saved: monitoring-guide.md"

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Monitoring Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Created Resources:${NC}"
echo "  ✓ SNS Topic: $SNS_TOPIC_NAME"
echo "  ✓ CloudWatch Alarms: 9 alarms"
echo "    - ECS: CPU, Memory, Task Count"
echo "    - RDS: CPU, Storage, Connections"
echo "    - ALB: Response Time, Health, 5xx Errors"
echo "  ✓ CloudWatch Dashboard: $DASHBOARD_NAME"
echo "  ✓ Log Insights Queries: 4 queries"
echo "  ✓ Monitoring Documentation"
echo ""

if [ -n "$ALERT_EMAIL" ]; then
    echo -e "${YELLOW}Important:${NC}"
    echo "  Confirm email subscription for $ALERT_EMAIL"
    echo "  Check your inbox for AWS SNS confirmation email"
    echo ""
fi

echo -e "${BLUE}Access Dashboard:${NC}"
echo "  https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"
echo ""

echo -e "${BLUE}View Alarms:${NC}"
echo "  https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#alarmsV2:"
echo ""

echo -e "${BLUE}View Logs:${NC}"
echo "  aws logs tail /ecs/${PROJECT_NAME} --follow --region ${AWS_REGION}"
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Confirm email subscription"
echo "  2. Review dashboard and alarms"
echo "  3. Test notifications: aws sns publish --topic-arn $SNS_TOPIC_ARN --subject 'Test' --message 'Test alert'"
echo "  4. Set up DNS and SSL: ./08-setup-dns-ssl.sh (optional)"
echo "  5. Monitor system for 24 hours"
echo ""

echo -e "${BLUE}Documentation:${NC}"
echo "  - Monitoring Guide: monitoring-guide.md"
echo "  - Log Insights Queries: log-insights-queries/"
echo ""
