# EHRbase Production Monitoring Guide

**Date:** Fri Dec  5 19:16:11 WAT 2025
**Environment:** Production
**Region:** eu-west-1

## CloudWatch Dashboard

**Dashboard Name:** medzen-ehrbase-production

**URL:** https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=medzen-ehrbase-production

**Widgets:**
- ECS Service CPU & Memory utilization
- RDS CPU utilization & database connections
- ALB response time & request count
- ALB HTTP response codes (2xx, 4xx, 5xx)
- RDS storage space
- ALB target health (healthy/unhealthy hosts)

## CloudWatch Alarms

### ECS Alarms
1. **medzen-ehrbase-ecs-high-cpu**
   - Triggers when: CPU > 80% for 10 minutes
   - Action: Auto-scaling, SNS notification

2. **medzen-ehrbase-ecs-high-memory**
   - Triggers when: Memory > 80% for 10 minutes
   - Action: SNS notification

3. **medzen-ehrbase-ecs-low-tasks**
   - Triggers when: Running tasks < 2 for 2 minutes
   - Action: SNS notification (check service health)

### RDS Alarms
1. **medzen-ehrbase-rds-high-cpu**
   - Triggers when: CPU > 80% for 10 minutes
   - Action: SNS notification (consider upgrading instance)

2. **medzen-ehrbase-rds-low-storage**
   - Triggers when: Free storage < 10GB
   - Action: SNS notification (increase storage)

3. **medzen-ehrbase-rds-high-connections**
   - Triggers when: Connections > 80 for 10 minutes
   - Action: SNS notification (check for connection leaks)

### ALB Alarms
1. **medzen-ehrbase-alb-high-response-time**
   - Triggers when: Response time > 2 seconds for 10 minutes
   - Action: SNS notification (investigate performance)

2. **medzen-ehrbase-alb-unhealthy-targets**
   - Triggers when: Unhealthy targets >= 1 for 2 minutes
   - Action: SNS notification (check ECS tasks)

3. **medzen-ehrbase-alb-high-5xx-errors**
   - Triggers when: 5xx errors > 10 in 5 minutes for 10 minutes
   - Action: SNS notification (check application logs)

## SNS Topic

**Topic ARN:** arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts

**Subscriptions:**
- Email: alain@mylestechsolutions.com

**Add Email Subscription:**
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --protocol email \
  --notification-endpoint your@email.com \
  --region eu-west-1
```

**Add SMS Subscription:**
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --protocol sms \
  --notification-endpoint +1234567890 \
  --region eu-west-1
```

## Log Groups

**ECS Logs:** /ecs/medzen-ehrbase

**View Recent Logs:**
```bash
aws logs tail /ecs/medzen-ehrbase --follow --region eu-west-1
```

**Filter Errors:**
```bash
aws logs tail /ecs/medzen-ehrbase --follow --filter-pattern "ERROR" --region eu-west-1
```

## CloudWatch Logs Insights Queries

Pre-built queries available in `log-insights-queries/` directory:

1. **recent-errors.txt** - Shows recent ERROR and Exception messages
2. **response-times.txt** - Analyzes API response times with percentiles
3. **top-errors.txt** - Lists most frequent error messages
4. **database-issues.txt** - Filters database connection issues

**How to Use:**
1. Open CloudWatch > Logs > Insights
2. Select log group: /ecs/medzen-ehrbase
3. Copy/paste query from file
4. Adjust time range
5. Click "Run query"

## Metric Math Examples

### Request Success Rate
```
m1 = HTTPCode_Target_2XX_Count (sum)
m2 = RequestCount (sum)
e1 = (m1/m2)*100
```

### Error Rate
```
m1 = HTTPCode_Target_5XX_Count (sum)
m2 = RequestCount (sum)
e1 = (m1/m2)*100
```

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
3. Check ECS task logs: `aws logs tail /ecs/medzen-ehrbase --follow`
4. Check RDS metrics and slow query logs
5. Review ALB access logs if needed
6. Document incident and resolution

## Useful AWS CLI Commands

**View All Alarms:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix medzen-ehrbase \
  --region eu-west-1
```

**Get Alarm History:**
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name medzen-ehrbase-ecs-high-cpu \
  --region eu-west-1
```

**Get Metric Statistics:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=medzen-ehrbase-cluster Name=ServiceName,Value=medzen-ehrbase-service \
  --start-time  \
  --end-time 2025-12-05T18:16:11 \
  --period 300 \
  --statistics Average \
  --region eu-west-1
```

**Test SNS Notification:**
```bash
aws sns publish \
  --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
  --subject "Test Alert" \
  --message "This is a test notification from EHRbase monitoring" \
  --region eu-west-1
```

## Cost Monitoring

**CloudWatch Costs:**
- Dashboard: $3/month
- Alarms: $0.10/alarm/month (~$0.90 for 9 alarms)
- Log Ingestion: $0.50/GB
- Log Storage: $0.03/GB/month
- Insights Queries: $0.005/GB scanned

**Estimated Monthly Cost:** ~$10-30 depending on log volume

**View CloudWatch Costs:**
1. Go to AWS Cost Explorer
2. Filter by Service: CloudWatch
3. Group by: Usage Type
4. Review log ingestion and storage trends

## Integration with External Tools

### Slack Integration (Optional)
1. Create AWS Chatbot in AWS Console
2. Configure Slack workspace
3. Add SNS topic arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts
4. Alarms will post to Slack channel

### PagerDuty Integration (Optional)
1. Create PagerDuty service with AWS CloudWatch integration
2. Get PagerDuty endpoint URL
3. Subscribe HTTPS endpoint to SNS topic:
   ```bash
   aws sns subscribe \
     --topic-arn arn:aws:sns:eu-west-1:558069890522:medzen-ehrbase-alerts \
     --protocol https \
     --notification-endpoint <PAGERDUTY_URL>
   ```

## Maintenance Windows

When performing maintenance:

1. **Silence Alarms Temporarily:**
   ```bash
   aws cloudwatch disable-alarm-actions \
     --alarm-names medzen-ehrbase-ecs-high-cpu medzen-ehrbase-ecs-high-memory \
     --region eu-west-1
   ```

2. **Perform Maintenance**

3. **Re-enable Alarms:**
   ```bash
   aws cloudwatch enable-alarm-actions \
     --alarm-names medzen-ehrbase-ecs-high-cpu medzen-ehrbase-ecs-high-memory \
     --region eu-west-1
   ```

## Support Contacts

- **AWS Support:** [AWS Support Center](https://console.aws.amazon.com/support/home)
- **EHRbase Documentation:** https://ehrbase.readthedocs.io/
- **Project Documentation:** See deployment scripts and guides in aws-deployment/

