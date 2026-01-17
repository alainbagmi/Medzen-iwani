"""
MedZen SOAP Queue Processing Lambda Function
Processes queued SOAP generation requests from SQS with exponential backoff
"""

import json
import boto3
import logging
from datetime import datetime
import time

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients
lambda_client = boto3.client('lambda', region_name='us-east-1')
sqs_client = boto3.client('sqs', region_name='us-east-1')

# Constants
SOAP_GENERATION_FUNCTION = 'medzen-generate-soap-from-transcript'
SQS_QUEUE_URL = 'https://sqs.us-east-1.amazonaws.com/558069890522/medzen-soap-retry-queue'
MAX_RETRY_ATTEMPTS = 5


def process_queue_message(message_body: dict) -> bool:
    """
    Process a single queued SOAP generation request.

    Args:
        message_body: Message from SQS containing original event

    Returns:
        True if successful, False if should remain in queue for retry
    """
    try:
        event = message_body.get('event', {})
        retry_count = message_body.get('retry_count', 0)
        queued_at = message_body.get('queued_at')

        logger.info(f"Processing queued request: session={event.get('sessionId')}, retry={retry_count}")

        # Check if max retries exceeded
        if retry_count >= MAX_RETRY_ATTEMPTS:
            logger.error(f"Max retries exceeded for session {event.get('sessionId')} after {queued_at}")
            return True  # Remove from queue - hard failure

        # Add retry info to event
        event['retry_count'] = retry_count
        event['original_queue_time'] = queued_at

        # Invoke the main SOAP generation Lambda
        response = lambda_client.invoke(
            FunctionName=SOAP_GENERATION_FUNCTION,
            InvocationType='RequestResponse',
            Payload=json.dumps(event)
        )

        # Check response
        status_code = response.get('StatusCode')
        if status_code == 200:
            response_payload = json.loads(response.get('Payload').read())

            if response_payload.get('statusCode') == 200:
                logger.info(f"Successfully processed queued request: {event.get('sessionId')}")
                return True  # Remove from queue - success

            elif response_payload.get('statusCode') == 429:
                # Still throttled, keep in queue
                logger.warning(f"Request still throttled, keeping in queue: {event.get('sessionId')}")
                return False

            else:
                # Other error, might be worth retrying
                logger.warning(f"Request failed with status {response_payload.get('statusCode')}, keeping in queue")
                return False

        else:
            logger.error(f"Lambda invocation failed with status {status_code}")
            return False

    except Exception as e:
        logger.error(f"Error processing queue message: {str(e)}", exc_info=True)
        return False


def lambda_handler(event, context):
    """
    AWS Lambda handler for processing SQS queue of failed SOAP generation requests.

    SQS Event format:
    {
        "Records": [
            {
                "messageId": "...",
                "receiptHandle": "...",
                "body": "{...original event...}",
                "attributes": {...}
            }
        ]
    }
    """

    logger.info(f"Processing {len(event.get('Records', []))} messages from SQS queue")

    successful = 0
    failed = 0
    batch_item_failures = []

    for record in event.get('Records', []):
        try:
            message_id = record.get('messageId')
            receipt_handle = record.get('receiptHandle')

            # Parse message body
            message_body = json.loads(record.get('body', '{}'))

            # Process the message
            if process_queue_message(message_body):
                # Delete from queue on success
                sqs_client.delete_message(
                    QueueUrl=SQS_QUEUE_URL,
                    ReceiptHandle=receipt_handle
                )
                successful += 1
                logger.info(f"Deleted message from queue: {message_id}")
            else:
                # Keep in queue for retry
                failed += 1
                batch_item_failures.append({'itemId': message_id})
                logger.warning(f"Keeping message in queue for retry: {message_id}")

        except Exception as e:
            logger.error(f"Error processing record {record.get('messageId')}: {str(e)}", exc_info=True)
            failed += 1
            batch_item_failures.append({'itemId': record.get('messageId')})

    logger.info(f"Queue processing complete: {successful} successful, {failed} failed/queued")

    return {
        'statusCode': 200,
        'processed': successful,
        'queued': failed,
        'batchItemFailures': batch_item_failures
    }


# For local testing
if __name__ == '__main__':
    test_event = {
        'Records': [
            {
                'messageId': 'test-1',
                'receiptHandle': 'test-handle',
                'body': json.dumps({
                    'event': {
                        'sessionId': 'test-session-123',
                        'appointmentId': 'apt-123',
                        'transcript': 'Test transcript',
                        'providerId': 'prov-123'
                    },
                    'reason': 'Bedrock throttling',
                    'queued_at': datetime.utcnow().isoformat() + 'Z',
                    'retry_count': 0
                })
            }
        ]
    }

    result = lambda_handler(test_event, None)
    print(f"Result: {json.dumps(result, indent=2)}")
