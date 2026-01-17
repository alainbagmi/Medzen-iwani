# MedZen Transcription Monitoring & Cost Optimization

This guide covers the CloudWatch alerts, duration limits, and cost tracking features for medical transcription.

## Features Implemented

### 1. CloudWatch Alerts for Transcription Failures

**Alarms configured:**
| Alarm | Threshold | Description |
|-------|-----------|-------------|
| `medzen-transcription-job-failures` | 3 failures/15 min | Transcription job failures |
| `medzen-transcription-callback-errors` | 2 errors/5 min | Lambda callback errors |
| `medzen-recording-handler-errors` | 2 errors/5 min | Recording handler errors |
| `medzen-transcription-high-latency` | 30s avg | Processing latency |
| `medzen-transcription-duration-limit-exceeded` | 1 per hour | Jobs exceeding max duration |
| `medzen-transcription-daily-budget-exceeded` | $50/day | Daily cost exceeded |
| `medzen-transcription-daily-budget-warning` | 80% of budget | Budget warning |
| `medzen-transcription-high-volume` | 50 jobs/hour | Suspicious volume |
| `medzen-transcription-stuck-jobs` | 2 hours | Long-running jobs |

### 2. Duration Limits for Cost Optimization

**Configuration:**
- Default max duration: **120 minutes** (2 hours)
- Absolute max duration: **240 minutes** (4 hours)
- Minimum duration: **5 minutes**
- AWS Transcribe Medical pricing: **$0.0750/minute**

**How it works:**
1. When starting transcription, specify `maxDurationMinutes` (optional)
2. System validates and clamps to allowed range (5-240 minutes)
3. A cleanup Lambda runs every 15 minutes to auto-stop stuck jobs
4. Jobs exceeding limits are marked as `timeout` status

### 3. Cost Tracking

**New database columns in `video_call_sessions`:**
- `transcription_duration_seconds` - Actual duration
- `transcription_estimated_cost_usd` - Calculated cost
- `transcription_max_duration_minutes` - Configured limit
- `transcription_auto_stopped` - If auto-stopped
- `transcription_error` - Error message
- `transcription_completed_at` - Completion timestamp

**Daily usage tracking in `transcription_usage_daily`:**
- Total sessions, duration, and cost per day
- Success/failure/timeout counts
- Average and max durations
- Automatic aggregation via triggers

## Deployment

### Deploy CloudWatch Stack

```bash
# Set environment variables (optional)
export AWS_REGION=eu-central-1
export ENVIRONMENT=production
export ALERT_EMAIL=alerts@example.com

# Run deployment script
./aws-deployment/scripts/deploy-transcription-monitoring.sh
```

### Apply Database Migration

```bash
npx supabase db push --linked
```

### Deploy Edge Functions

```bash
npx supabase functions deploy start-medical-transcription chime-transcription-callback
```

## API Changes

### Start Transcription

```typescript
// Request
POST /functions/v1/start-medical-transcription
{
  "meetingId": "string",
  "sessionId": "string",
  "action": "start",
  "maxDurationMinutes": 60, // Optional: 5-240 minutes
  "language": "en-US",
  "specialty": "PRIMARYCARE"
}

// Response
{
  "success": true,
  "message": "Medical transcription started",
  "config": {
    "language": "en-US",
    "specialty": "PRIMARYCARE",
    "speakerIdentification": true,
    "maxDurationMinutes": 60,
    "estimatedMaxCost": 4.50,
    "budgetRemaining": 45.50
  }
}
```

### Stop Transcription

```typescript
// Response now includes stats
{
  "success": true,
  "message": "Medical transcription stopped",
  "stats": {
    "durationSeconds": 1847,
    "durationMinutes": 30.8,
    "estimatedCost": 2.31
  }
}
```

### Budget Exceeded Response

If daily budget is exceeded, start returns HTTP 429:

```json
{
  "error": "Daily transcription budget exceeded",
  "details": {
    "usedToday": 50.25,
    "budgetRemaining": 0
  }
}
```

## CloudWatch Dashboard

Access the dashboard at:
```
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=medzen-transcription-monitoring
```

**Widgets:**
1. **Transcription Job Status** - Success/failure/in-progress over time
2. **Duration & Cost** - Total minutes and estimated cost
3. **Errors by Type** - Timeout, API, validation, duration limit
4. **Lambda Performance** - Recording handler and processor errors
5. **Daily Cost Tracking** - Current day spend vs budget

## CloudWatch Metrics

All metrics published to namespace: `medzen/Transcription`

| Metric | Unit | Description |
|--------|------|-------------|
| `TranscriptionStarted` | Count | Jobs started |
| `TranscriptionStopped` | Count | Jobs stopped |
| `SuccessfulJobs` | Count | Completed successfully |
| `FailedJobs` | Count | Failed jobs |
| `TimeoutErrors` | Count | Duration limit exceeded |
| `APIErrors` | Count | AWS API errors |
| `DatabaseErrors` | Count | Supabase errors |
| `CallbackErrors` | Count | Callback processing errors |
| `InProgressJobs` | Count | Currently running |
| `TotalDurationMinutes` | None | Total transcription time |
| `EstimatedCostUSD` | None | Estimated costs |
| `DailyCostUSD` | None | Daily running total |
| `BudgetExceeded` | Count | Budget limit hit |
| `DurationLimitExceeded` | Count | Duration limit hit |

## Analytics View

Query transcription analytics:

```sql
SELECT * FROM transcription_analytics
ORDER BY usage_date DESC
LIMIT 30;
```

Returns:
- `usage_date` - Date
- `total_sessions` - Number of transcription sessions
- `successful_transcriptions` - Completed successfully
- `failed_transcriptions` - Failed count
- `timeout_transcriptions` - Auto-stopped count
- `total_duration_minutes` - Total minutes used
- `avg_duration_minutes` - Average session length
- `max_duration_minutes` - Longest session
- `total_cost_usd` - Total estimated cost
- `success_rate_percent` - Success percentage
- `timeout_rate_percent` - Timeout percentage

## Environment Variables

For edge functions, set these in Supabase dashboard:

```
AWS_REGION=eu-central-1
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
DAILY_TRANSCRIPTION_BUDGET_USD=50
ENVIRONMENT=production
```

For CloudFormation, SSM parameters are used:
- `/${project}/${env}/supabase-url`
- `/${project}/${env}/supabase-service-key`

## Troubleshooting

### Transcription not starting

1. Check CloudWatch logs: `/aws/lambda/medzen-recording-handler`
2. Verify AWS Transcribe Medical is available in your region
3. Check daily budget hasn't been exceeded

### Jobs timing out prematurely

1. Increase `maxDurationMinutes` in request (up to 240)
2. Check `transcription_max_duration_minutes` in database
3. Verify cleanup Lambda isn't too aggressive

### Cost spikes

1. Check CloudWatch dashboard for unusual volume
2. Review `transcription_usage_daily` table
3. Reduce `DAILY_TRANSCRIPTION_BUDGET_USD` to limit spending
4. Lower default max duration

### Alerts not firing

1. Verify SNS subscription is confirmed (check email)
2. Check alarm state in CloudWatch console
3. Verify metrics are being published (check namespace)
