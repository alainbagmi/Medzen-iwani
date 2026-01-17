# MedZen EHRbase Production Monitoring - Setup Complete ✓

**Date:** December 5, 2025
**Region:** eu-west-1 (Ireland)
**Environment:** Production
**Status:** ✅ Fully Operational

---

## 🎯 Summary

CloudWatch monitoring and alerting has been successfully configured for the MedZen EHRbase production environment. The system includes comprehensive monitoring across all infrastructure components with automatic alerting via SNS.

## 📊 Deployed Resources

### 1. SNS Topic for Alerts
- **Topic Name:** `medzen-ehrbase-alerts`
- **Topic ARN:** `arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts`
- **Email Subscription:** `alain@mylestechsolutions.com` (pending confirmation)
- **Test Message:** Sent successfully (MessageId: 27ee0b6e-d449-5a95-b35d-6ac3f79be40b)

### 2. CloudWatch Alarms (9 Total)

#### ECS Service Alarms (3)
| Alarm Name | Metric | Threshold | State |
|------------|--------|-----------|-------|
| `medzen-ehrbase-ecs-high-cpu` | CPU Utilization | > 80% for 10 min | OK |
| `medzen-ehrbase-ecs-high-memory` | Memory Utilization | > 80% for 10 min | INSUFFICIENT_DATA* |
| `medzen-ehrbase-ecs-low-tasks` | Running Tasks | < 2 for 2 min | INSUFFICIENT_DATA* |

#### RDS Database Alarms (3)
| Alarm Name | Metric | Threshold | State |
|------------|--------|-----------|-------|
| `medzen-ehrbase-rds-high-cpu` | CPU Utilization | > 80% for 10 min | INSUFFICIENT_DATA* |
| `medzen-ehrbase-rds-low-storage` | Free Storage | < 10GB | INSUFFICIENT_DATA* |
| `medzen-ehrbase-rds-high-connections` | DB Connections | > 80 for 10 min | INSUFFICIENT_DATA* |

#### Application Load Balancer Alarms (3)
| Alarm Name | Metric | Threshold | State |
|------------|--------|-----------|-------|
| `medzen-ehrbase-alb-high-response-time` | Response Time | > 2s for 10 min | INSUFFICIENT_DATA* |
| `medzen-ehrbase-alb-unhealthy-targets` | Unhealthy Hosts | ≥ 1 for 2 min | INSUFFICIENT_DATA* |
| `medzen-ehrbase-alb-high-5xx-errors` | 5xx Errors | > 10 in 5 min | INSUFFICIENT_DATA* |

**Note:** *INSUFFICIENT_DATA state is normal for newly created alarms. They will transition to OK or ALARM as data accumulates.*

### 3. CloudWatch Dashboard
- **Dashboard Name:** `medzen-ehrbase-production`
- **URL:** [View Dashboard](https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=medzen-ehrbase-production)
- **Widgets:**
  - ECS CPU & Memory Utilization
  - RDS CPU & Database Connections
  - ALB Response Time & Request Count
  - ALB HTTP Response Codes (2xx, 4xx, 5xx)
  - RDS Free Storage Space
  - ALB Target Health (Healthy/Unhealthy)

### 4. CloudWatch Logs Insights Queries
Pre-built queries saved in `log-insights-queries/` directory:

| Query File | Purpose |
|------------|---------|
| `recent-errors.txt` | Shows recent ERROR and Exception messages |
| `response-times.txt` | Analyzes API response times with percentiles |
| `top-errors.txt` | Lists most frequent error messages |
| `database-issues.txt` | Filters database connection issues |

**Usage:**
1. Open [CloudWatch Logs Insights](https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:logs-insights)
2. Select log group: `/ecs/medzen-ehrbase`
3. Copy/paste query from file
4. Adjust time range
5. Click "Run query"

### 5. Documentation
- **Monitoring Guide:** `monitoring-guide.md` - Complete operational runbook
- **Log Queries:** `log-insights-queries/` - 4 pre-built queries

---

## ⚡ Quick Access Links

| Resource | URL |
|----------|-----|
| CloudWatch Dashboard | [medzen-ehrbase-production](https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=medzen-ehrbase-production) |
| CloudWatch Alarms | [View All Alarms](https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#alarmsV2:) |
| CloudWatch Logs | [ECS Logs](https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups/log-group/$252Fecs$252Fmedzen-ehrbase) |
| Logs Insights | [Query Logs](https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:logs-insights) |
| SNS Topic | [medzen-ehrbase-alerts](https://eu-west-1.console.aws.amazon.com/sns/v3/home?region=eu-west-1#/topic/arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts) |

---

## 🚀 Immediate Next Steps

### 1. Confirm Email Subscription (CRITICAL)
```bash
# Check your email: alain@mylestechsolutions.com
# Click the "Confirm subscription" link in the AWS SNS email
```

### 2. Verify Test Alert Received
The test notification was sent successfully. You should receive an email at `alain@mylestechsolutions.com` once you confirm the subscription.

### 3. Review Dashboard (24 hours)
Monitor the dashboard for the first 24 hours to ensure all metrics are collecting properly and alarms transition from INSUFFICIENT_DATA to OK state.

### 4. Test Alarm Notifications
```bash
# After confirming email subscription, send another test:
aws sns publish \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --subject "MedZen EHRbase - Test Alert" \
  --message "Testing alarm notification system" \
  --region eu-west-1
```

---

## 📋 Common Commands

### View Real-Time Logs
```bash
aws logs tail /ecs/medzen-ehrbase --follow --region eu-west-1
```

### Filter Error Logs
```bash
aws logs tail /ecs/medzen-ehrbase --follow --filter-pattern "ERROR" --region eu-west-1
```

### Check Alarm States
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix medzen-ehrbase \
  --region eu-west-1 \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}' \
  --output table
```

### Get Alarm History
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name medzen-ehrbase-ecs-high-cpu \
  --region eu-west-1
```

### Send Test Notification
```bash
aws sns publish \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --subject "Test Alert" \
  --message "This is a test notification" \
  --region eu-west-1
```

---

## 🔧 Operational Guidelines

### Daily Checks
- [ ] Review CloudWatch dashboard for anomalies
- [ ] Verify all alarms are in OK or INSUFFICIENT_DATA state (no ALARM)
- [ ] Check ALB target health (all healthy)
- [ ] Review error logs for patterns

### Weekly Checks
- [ ] Review storage trends (RDS, ECS logs)
- [ ] Analyze response time trends
- [ ] Check for recurring errors
- [ ] Review auto-scaling events

### Monthly Checks
- [ ] Review monthly AWS costs vs. budget
- [ ] Analyze long-term performance trends
- [ ] Review and update alarm thresholds if needed
- [ ] Test alarm notifications

### Incident Response
1. Check CloudWatch dashboard for affected services
2. Review relevant alarm details
3. Check ECS task logs: `aws logs tail /ecs/medzen-ehrbase --follow`
4. Check RDS metrics and slow query logs
5. Review ALB access logs if needed
6. Document incident and resolution

---

## 💰 Cost Estimate

### CloudWatch Costs (Monthly)
- **Dashboard:** $3.00
- **Alarms (9 alarms):** $0.90
- **Log Ingestion:** ~$5-15 (varies with usage)
- **Log Storage:** ~$1-5 (depends on retention)
- **Insights Queries:** ~$1-5 (depends on query frequency)

**Total Estimated Monthly Cost:** $10-30

---

## 🔄 Integration Options

### Slack Integration (Optional)
1. Create AWS Chatbot in AWS Console
2. Configure Slack workspace
3. Add SNS topic to Chatbot
4. Alarms will post to Slack channel

### PagerDuty Integration (Optional)
```bash
# Subscribe PagerDuty endpoint to SNS topic
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --protocol https \
  --notification-endpoint <PAGERDUTY_ENDPOINT_URL> \
  --region eu-west-1
```

### Additional Email Subscriptions
```bash
# Add more email addresses
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --protocol email \
  --notification-endpoint another@email.com \
  --region eu-west-1
```

### SMS Notifications
```bash
# Add SMS alerts for critical issues
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --protocol sms \
  --notification-endpoint +1234567890 \
  --region eu-west-1
```

---

## 📈 Monitoring Metrics Reference

### ECS Service Metrics
- **CPUUtilization:** Percentage of allocated CPU being used
- **MemoryUtilization:** Percentage of allocated memory being used
- **DesiredTaskCount:** Number of tasks that should be running
- **RunningTaskCount:** Number of tasks currently running

### RDS Metrics
- **CPUUtilization:** Database instance CPU usage
- **DatabaseConnections:** Number of active database connections
- **FreeStorageSpace:** Available storage space (bytes)
- **ReadLatency/WriteLatency:** Disk I/O latency

### ALB Metrics
- **TargetResponseTime:** Time for targets to respond
- **RequestCount:** Number of requests processed
- **HealthyHostCount:** Number of healthy targets
- **UnHealthyHostCount:** Number of unhealthy targets
- **HTTPCode_Target_2XX_Count:** Successful responses
- **HTTPCode_Target_4XX_Count:** Client errors
- **HTTPCode_Target_5XX_Count:** Server errors

---

## ⚠️ Alert Thresholds Rationale

### CPU Thresholds (80%)
- Allows headroom for traffic spikes
- Triggers before performance degrades
- Gives time for auto-scaling to respond

### Memory Thresholds (80%)
- Prevents out-of-memory errors
- Early warning for memory leaks
- Time to investigate before critical

### Response Time (2 seconds)
- Acceptable for healthcare APIs
- Indicates performance issues
- Triggers investigation before user impact

### Storage (10GB)
- Adequate warning before full
- Time to increase storage
- Prevents database outages

### Connection Count (80)
- Based on RDS instance max connections
- Warns of connection pool issues
- Prevents connection exhaustion

---

## 📚 Additional Resources

- **AWS Documentation:**
  - [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
  - [CloudWatch Dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html)
  - [Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)

- **Project Documentation:**
  - `monitoring-guide.md` - Detailed operational runbook
  - `PRODUCTION_DEPLOYMENT_GUIDE.md` - Production deployment checklist
  - `DEPLOYMENT_COMPLETE.md` - Full system deployment guide

- **Support:**
  - AWS Support: [AWS Support Center](https://console.aws.amazon.com/support/home)
  - EHRbase Documentation: https://ehrbase.readthedocs.io/

---

## ✅ Verification Checklist

- [x] SNS topic created
- [x] Email subscription added (pending confirmation)
- [x] Test notification sent successfully
- [x] 9 CloudWatch alarms configured
- [x] CloudWatch dashboard deployed
- [x] Log Insights queries created
- [x] Monitoring documentation generated
- [ ] Email subscription confirmed by user
- [ ] Dashboard reviewed after 24 hours
- [ ] All alarms in OK state (after data collection)

---

## 🎉 Success!

Your MedZen EHRbase production monitoring is now fully operational. The system will automatically alert you via email when any thresholds are exceeded.

**Important:** Don't forget to confirm your email subscription to start receiving alerts!

For detailed operational procedures, see `monitoring-guide.md`.
