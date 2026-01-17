"""
MedZen Bedrock Token Usage Monitoring Lambda Function
Monitors daily token usage and sends alerts when approaching limits
"""

import json
import boto3
import requests
import logging
import os
from datetime import datetime, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients
cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')
sns = boto3.client('sns', region_name='us-east-1')

# Constants
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://noaeltglphdlkbflipit.supabase.co')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')
SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:558069890522:medzen-token-alerts'
DAILY_TOKEN_LIMIT = 10000000  # 10M tokens/day (adjust based on AWS limit increase)
WARNING_THRESHOLD = 0.80  # Alert at 80% of limit
CRITICAL_THRESHOLD = 0.95  # Critical at 95% of limit


def get_daily_token_usage(date: str) -> dict:
    """
    Get total token usage for a specific date from Supabase.

    Args:
        date: Date in YYYY-MM-DD format

    Returns:
        Dict with token usage stats
    """
    try:
        headers = {
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }

        # Query the daily summary view filtered by date
        # Format: /rest/v1/bedrock_daily_token_summary?usage_date=eq.2024-01-13
        response = requests.get(
            f'{SUPABASE_URL}/rest/v1/bedrock_daily_token_summary?usage_date=eq.{date}',
            headers=headers,
            timeout=10
        )

        if response.status_code != 200:
            logger.error(f"Supabase query failed: {response.status_code} - {response.text}")
            return {
                'date': date,
                'total_tokens': 0,
                'error': f'Supabase returned {response.status_code}'
            }

        data = response.json()

        if not data:
            # No data for this date yet
            return {
                'date': date,
                'total_tokens': 0,
                'input_tokens': 0,
                'output_tokens': 0,
                'total_sessions': 0,
                'model_breakdown': {},
                'usage_percentage': 0.0
            }

        # data is a list with one item from the view
        row = data[0]

        # Query individual records to get model breakdown
        model_data = requests.get(
            f'{SUPABASE_URL}/rest/v1/bedrock_model_performance?usage_date=eq.{date}',
            headers=headers,
            timeout=10
        )

        model_breakdown = {}
        if model_data.status_code == 200:
            for model_row in model_data.json():
                model = model_row.get('model', 'unknown')
                model_breakdown[model] = {
                    'input': model_row.get('total_input_tokens', 0),
                    'output': model_row.get('total_output_tokens', 0),
                    'count': model_row.get('sessions_count', 0)
                }

        total_tokens = row.get('total_tokens', 0) or 0

        return {
            'date': date,
            'total_tokens': total_tokens,
            'input_tokens': row.get('total_input_tokens', 0) or 0,
            'output_tokens': row.get('total_output_tokens', 0) or 0,
            'total_sessions': row.get('total_sessions', 0) or 0,
            'model_breakdown': model_breakdown,
            'usage_percentage': (total_tokens / DAILY_TOKEN_LIMIT) * 100 if DAILY_TOKEN_LIMIT > 0 else 0
        }

    except Exception as e:
        logger.error(f"Error querying token usage: {str(e)}")
        return {
            'date': date,
            'total_tokens': 0,
            'error': str(e)
        }


def publish_metrics(usage: dict):
    """
    Publish token usage metrics to CloudWatch.

    Args:
        usage: Token usage dict from get_daily_token_usage
    """
    try:
        cloudwatch.put_metric_data(
            Namespace='MedZen/Bedrock',
            MetricData=[
                {
                    'MetricName': 'DailyTokenUsage',
                    'Value': usage['total_tokens'],
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow()
                },
                {
                    'MetricName': 'UsagePercentage',
                    'Value': usage['usage_percentage'],
                    'Unit': 'Percent',
                    'Timestamp': datetime.utcnow()
                },
                {
                    'MetricName': 'SessionCount',
                    'Value': usage['total_sessions'],
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
        logger.info(f"Published metrics: {usage['total_tokens']} tokens ({usage['usage_percentage']:.1f}%)")
    except Exception as e:
        logger.error(f"Error publishing metrics: {str(e)}")


def send_alert(usage: dict, severity: str):
    """
    Send SNS alert about token usage.

    Args:
        usage: Token usage dict
        severity: 'warning' or 'critical'
    """
    try:
        subject = f"[{severity.upper()}] Bedrock Token Usage Alert - {usage['date']}"

        # Build message body
        message_body = f"""
MedZen Bedrock Token Usage Alert

Date: {usage['date']}
Severity: {severity.upper()}

Current Usage:
- Total Tokens: {usage['total_tokens']:,}
- Input Tokens: {usage['input_tokens']:,}
- Output Tokens: {usage['output_tokens']:,}
- Sessions Processed: {usage['total_sessions']}

Limit Status:
- Daily Limit: {DAILY_TOKEN_LIMIT:,}
- Usage: {usage['usage_percentage']:.1f}%
- Remaining: {DAILY_TOKEN_LIMIT - usage['total_tokens']:,}

Model Breakdown:
"""

        for model, stats in usage.get('model_breakdown', {}).items():
            message_body += f"\n{model}:"
            message_body += f"\n  - Input: {stats['input']:,}"
            message_body += f"\n  - Output: {stats['output']:,}"
            message_body += f"\n  - Sessions: {stats['count']}"

        message_body += """

Action Items:
"""
        if severity == 'warning':
            message_body += """
1. Monitor token usage closely
2. Consider enabling fallback models
3. Prepare for potential throttling
4. Contact AWS Support to increase limits if needed
"""
        else:  # critical
            message_body += """
1. Fallback models are already in use
2. Queued requests will be retried during off-peak hours
3. Contact AWS Support immediately to increase limits
4. Consider scheduling non-urgent SOAP generation during off-peak hours
5. Monitor SQS queue depth for backlog status
"""

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message_body
        )
        logger.info(f"Published {severity} alert to SNS")

    except Exception as e:
        logger.error(f"Error sending alert: {str(e)}")


def lambda_handler(event, context):
    """
    AWS Lambda handler for monitoring Bedrock token usage.
    Triggered by CloudWatch Events (hourly).
    """

    today = datetime.utcnow().strftime('%Y-%m-%d')

    logger.info(f"Starting token usage monitoring for {today}")

    # Get daily usage
    usage = get_daily_token_usage(today)

    if 'error' in usage:
        logger.error(f"Failed to get usage data: {usage['error']}")
        return {
            'statusCode': 500,
            'error': 'FailedToQueryUsage',
            'message': usage['error']
        }

    # Publish metrics
    publish_metrics(usage)

    # Check thresholds and send alerts
    usage_pct = usage['usage_percentage']

    if usage_pct >= CRITICAL_THRESHOLD:
        logger.critical(f"CRITICAL: Token usage at {usage_pct:.1f}%")
        send_alert(usage, 'critical')
        return {
            'statusCode': 200,
            'alert': 'critical',
            'usage': usage
        }
    elif usage_pct >= WARNING_THRESHOLD:
        logger.warning(f"WARNING: Token usage at {usage_pct:.1f}%")
        send_alert(usage, 'warning')
        return {
            'statusCode': 200,
            'alert': 'warning',
            'usage': usage
        }
    else:
        logger.info(f"Token usage normal: {usage_pct:.1f}%")
        return {
            'statusCode': 200,
            'alert': 'none',
            'usage': usage
        }


# For local testing
if __name__ == '__main__':
    test_date = datetime.utcnow().strftime('%Y-%m-%d')
    usage = get_daily_token_usage(test_date)
    print(f"Usage for {test_date}: {json.dumps(usage, indent=2, default=str)}")
