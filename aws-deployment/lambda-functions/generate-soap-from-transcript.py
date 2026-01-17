"""
MedZen SOAP Note Generation Lambda Function
Invokes AWS Bedrock Claude Opus 4.5 to generate SOAP notes from medical transcripts
"""

import json
import boto3
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients
import requests
bedrock_client = boto3.client('bedrock-runtime', region_name='us-east-1')
sqs_client = boto3.client('sqs', region_name='us-east-1')

# Constants
MODEL_ID_PRIMARY = 'us.anthropic.claude-opus-4-5-20251101-v1:0'
MODEL_ID_FALLBACK = 'us.anthropic.claude-3-5-sonnet-20241022-v2:0'
SQS_QUEUE_URL = os.environ.get('SOAP_RETRY_QUEUE_URL', 'https://sqs.us-east-1.amazonaws.com/558069890522/medzen-soap-retry-queue')
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://noaeltglphdlkbflipit.supabase.co')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')
ENABLE_FALLBACK = os.environ.get('ENABLE_FALLBACK_MODEL', 'true').lower() == 'true'
SYSTEM_PROMPT = """You are a clinical documentation assistant generating SOAP notes from medical call transcripts.

CRITICAL INSTRUCTIONS:
1. Return ONLY a single valid JSON object - No markdown, no text before/after, no explanations
2. Never hallucinate - Use "unknown" for any information not explicitly stated or reasonably inferred
3. Telemedicine-aware - Acknowledge missing vitals and physical exams; do not pretend they exist
4. Safety first - Always include red flags and return precautions relevant to the chief complaint
5. Honest assessment - Mark uncertainties in source.data_quality.uncertainties
6. Doctor-friendly - Generate a note that's easy for the provider to review and edit

The JSON must follow the exact schema provided. Key rules:
- chief_complaint: 1-2 sentences, primary reason for visit
- subjective.hpi: Chronological narrative with symptom details (onset, duration, severity, context)
- subjective.ros: Systematically document positives, negatives, and unknowns for each body system
- objective.vitals: Set "measured": false if vitals NOT taken; do NOT hallucinate vital signs
- objective.physical_exam_limited: For telemedicine, set "performed": false and use telemedicine_observations
- assessment.problem_list: Include differential diagnoses with likelihood estimates
- plan: Document exact medications, doses, frequencies from conversation; include rationale
- safety.requires_clinician_review: Always true if any gaps or uncertainties
- doctor_editing: Include specific clarifications provider should ask about

For telemedicine visits:
- Do NOT add vitals that weren't measured
- Do NOT describe physical exam findings that weren't observed
- Use "unknown" liberally for missing information
- Add limitations to safety.limitations and doctor_editing.sections_needing_attention

If language of transcript is French:
- Output all free-text fields in FRENCH
- Keep medication names and medical terminology as stated
- Set "language": "fr" in output

JSON Schema Summary (you MUST follow this exactly):
{
  "schema_version": "1.0.0",
  "generated_at": "ISO8601 timestamp",
  "language": "en or fr",
  "encounter": { encounter_type, appointment_id, session_id, start_time, end_time, timezone, location },
  "participants": { provider, patient },
  "source": { transcript, data_quality },
  "chief_complaint": "string",
  "subjective": { hpi, ros, pmh, psh, medications, allergies, social_history, family_history },
  "objective": { vitals, telemedicine_observations, physical_exam_limited, diagnostics_reviewed },
  "assessment": { problem_list, clinical_impression_summary },
  "plan": { treatments, orders, follow_up, patient_education, work_school_notes },
  "coding_billing": { suggested_cpt, mdm_level_suggestion, rationale },
  "safety": { medication_safety_notes, limitations, requires_clinician_review },
  "doctor_editing": { draft_quality, recommended_clarifications, sections_needing_attention }
}"""


def load_system_prompt() -> str:
    """
    Load the comprehensive system prompt.
    Can be overridden to load from S3 for easier updates without redeploying Lambda.
    """
    return SYSTEM_PROMPT


def queue_for_retry(event: Dict[str, Any], reason: str = "Bedrock throttling") -> bool:
    """
    Queue request to SQS for later retry processing.

    Args:
        event: Original Lambda event
        reason: Reason for queueing

    Returns:
        True if successfully queued, False otherwise
    """
    try:
        sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps({
                'event': event,
                'reason': reason,
                'queued_at': datetime.utcnow().isoformat() + 'Z',
                'retry_count': event.get('retry_count', 0) + 1
            })
        )
        logger.info(f"Request queued for retry: {event.get('sessionId')}")
        return True
    except Exception as e:
        logger.error(f"Failed to queue request: {str(e)}")
        return False


def log_token_usage(session_id: str, appointment_id: str, input_tokens: int, output_tokens: int, model: str):
    """
    Log token usage to Supabase for monitoring.

    Args:
        session_id: Session identifier
        appointment_id: Appointment identifier
        input_tokens: Number of input tokens used
        output_tokens: Number of output tokens used
        model: Model used for generation
    """
    if not SUPABASE_SERVICE_KEY:
        logger.warning("SUPABASE_SERVICE_KEY not configured, skipping token logging")
        return

    try:
        headers = {
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }

        data = {
            'session_id': session_id,
            'appointment_id': appointment_id,
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'input_tokens': input_tokens,
            'output_tokens': output_tokens,
            'model': model
        }

        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/bedrock_token_usage',
            json=data,
            headers=headers,
            timeout=10
        )

        if response.status_code in [200, 201]:
            logger.info(f"Logged {input_tokens + output_tokens} tokens for session {session_id}")
        else:
            logger.warning(f"Failed to log tokens to Supabase: {response.status_code} - {response.text[:200]}")

    except Exception as e:
        logger.warning(f"Failed to log token usage: {str(e)}")


def invoke_bedrock(transcript: str, metadata: Optional[Dict[str, Any]] = None, use_fallback: bool = False) -> Dict[str, Any]:
    """
    Invoke AWS Bedrock to generate SOAP note from transcript.
    Supports fallback to Claude 3.5 Sonnet if primary model is throttled.

    Args:
        transcript: Medical conversation transcript
        metadata: Optional metadata (appointment_id, session_id, provider_name, patient_name, etc.)
        use_fallback: Use fallback model instead of primary

    Returns:
        Dict with SOAP note JSON or error
    """

    try:
        # Prepare metadata context
        metadata_context = ""
        if metadata:
            if metadata.get('appointment_id'):
                metadata_context += f"Appointment ID: {metadata['appointment_id']}\n"
            if metadata.get('session_id'):
                metadata_context += f"Session ID: {metadata['session_id']}\n"
            if metadata.get('provider_name'):
                metadata_context += f"Provider: {metadata['provider_name']}\n"
            if metadata.get('provider_specialty'):
                metadata_context += f"Provider Specialty: {metadata['provider_specialty']}\n"
            if metadata.get('patient_name'):
                metadata_context += f"Patient: {metadata['patient_name']}\n"
            if metadata.get('call_start_time'):
                metadata_context += f"Call Start Time: {metadata['call_start_time']}\n"
            if metadata.get('call_end_time'):
                metadata_context += f"Call End Time: {metadata['call_end_time']}\n"
            if metadata.get('language'):
                metadata_context += f"Transcript Language: {metadata['language']}\n"

        # Prepare user message
        user_message = f"""Please generate a SOAP note from the following medical transcript.

{metadata_context}
---TRANSCRIPT START---
{transcript}
---TRANSCRIPT END---

Generate the SOAP note as a single, complete JSON object following the exact schema. Return ONLY the JSON object, no other text."""

        # Select model based on fallback flag
        model_id = MODEL_ID_FALLBACK if use_fallback else MODEL_ID_PRIMARY
        model_name = "Claude 3.5 Sonnet (Fallback)" if use_fallback else "Claude Opus 4.5 (Primary)"

        # Prepare Bedrock request
        request_body = {
            "anthropic_version": "bedrock-2023-06-01",
            "max_tokens": 4096,
            "system": load_system_prompt(),
            "messages": [
                {
                    "role": "user",
                    "content": user_message
                }
            ]
        }

        logger.info(f"Invoking Bedrock {model_name} for SOAP generation")
        logger.info(f"Transcript length: {len(transcript)} characters")

        # Call Bedrock
        try:
            response = bedrock_client.invoke_model(
                modelId=model_id,
                contentType='application/json',
                accept='application/json',
                body=json.dumps(request_body)
            )
        except bedrock_client.exceptions.ThrottlingException as e:
            logger.warning(f"Bedrock throttling error: {str(e)}")
            if not use_fallback and ENABLE_FALLBACK:
                logger.info("Attempting to retry with fallback model (Claude 3.5 Sonnet)")
                return invoke_bedrock(transcript, metadata, use_fallback=True)
            else:
                logger.error("Throttled and no fallback available or fallback also failed")
                return {
                    'statusCode': 429,
                    'error': 'BedrockThrottled',
                    'message': 'Bedrock is currently throttled. Request has been queued for retry.',
                    'retryable': True
                }
        except Exception as e:
            if 'Too many tokens per day' in str(e) or 'ThrottlingException' in str(e):
                logger.warning(f"Token limit exceeded: {str(e)}")
                if not use_fallback and ENABLE_FALLBACK:
                    logger.info("Attempting to retry with fallback model (Claude 3.5 Sonnet)")
                    return invoke_bedrock(transcript, metadata, use_fallback=True)
                else:
                    return {
                        'statusCode': 429,
                        'error': 'TokenLimitExceeded',
                        'message': 'Daily token limit exceeded. Request has been queued for retry.',
                        'retryable': True
                    }
            raise

        # Parse response
        response_body = json.loads(response['body'].read().decode('utf-8'))

        # Extract content
        if 'content' not in response_body or len(response_body['content']) == 0:
            logger.error("Bedrock response missing content")
            return {
                'statusCode': 500,
                'error': 'InvalidBedrockResponse',
                'message': 'Bedrock response missing content field'
            }

        # Get the text response
        response_text = response_body['content'][0]['text']

        logger.info(f"Bedrock response received: {len(response_text)} characters")

        # Parse JSON from response
        try:
            # Try to extract JSON from response (handle potential markdown code blocks)
            json_str = response_text

            # If response is wrapped in markdown code blocks, extract
            if '```json' in json_str:
                json_str = json_str.split('```json')[1].split('```')[0].strip()
            elif '```' in json_str:
                json_str = json_str.split('```')[1].split('```')[0].strip()

            soap_note = json.loads(json_str)

            # Validate schema version
            if 'schema_version' not in soap_note:
                logger.warning("SOAP note missing schema_version, adding default")
                soap_note['schema_version'] = '1.0.0'

            # Ensure generated_at timestamp
            if 'generated_at' not in soap_note:
                soap_note['generated_at'] = datetime.utcnow().isoformat() + 'Z'

            logger.info("SOAP note generated successfully")

            # Log token usage
            input_tokens = response_body.get('usage', {}).get('input_tokens', 0)
            output_tokens = response_body.get('usage', {}).get('output_tokens', 0)

            if metadata:
                log_token_usage(
                    metadata.get('session_id', 'unknown'),
                    metadata.get('appointment_id', 'unknown'),
                    input_tokens,
                    output_tokens,
                    model_name
                )

            return {
                'statusCode': 200,
                'soap_note': soap_note,
                'bedrock_tokens': {
                    'input': input_tokens,
                    'output': output_tokens,
                    'model': model_name
                }
            }

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Bedrock response as JSON: {str(e)}")
            logger.error(f"Response text: {response_text[:500]}")
            return {
                'statusCode': 500,
                'error': 'InvalidJsonResponse',
                'message': f'Bedrock returned invalid JSON: {str(e)}',
                'raw_response': response_text[:1000]  # First 1000 chars for debugging
            }

    except Exception as e:
        logger.error(f"Error invoking Bedrock: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'error': 'BedrockInvocationError',
            'message': str(e)
        }


def lambda_handler(event, context):
    """
    AWS Lambda handler for SOAP generation.

    Expected input:
    {
        "sessionId": "string",
        "appointmentId": "string",
        "transcript": "string",
        "providerId": "string",
        "providerName": "string (optional)",
        "providerSpecialty": "string (optional)",
        "patientName": "string (optional)",
        "callStartTime": "ISO8601 (optional)",
        "callEndTime": "ISO8601 (optional)",
        "transcriptLanguage": "en|fr (optional, default: en)"
    }

    Returns:
    {
        "statusCode": 200 or error code,
        "soapNote": { ... },
        "sessionId": "string",
        "appointmentId": "string",
        "bedrockTokens": { ... }
    }
    """

    try:
        logger.info(f"SOAP Generation Lambda invoked with event: {json.dumps(event, default=str)[:200]}")

        # Extract inputs
        session_id = event.get('sessionId')
        appointment_id = event.get('appointmentId')
        transcript = event.get('transcript', '')
        provider_id = event.get('providerId')

        # Validate required fields
        if not session_id:
            return {
                'statusCode': 400,
                'error': 'MissingSessionId',
                'message': 'sessionId is required'
            }

        if not appointment_id:
            return {
                'statusCode': 400,
                'error': 'MissingAppointmentId',
                'message': 'appointmentId is required'
            }

        if not transcript or len(transcript.strip()) == 0:
            return {
                'statusCode': 400,
                'error': 'EmptyTranscript',
                'message': 'transcript cannot be empty'
            }

        # Prepare metadata
        metadata = {
            'appointment_id': appointment_id,
            'session_id': session_id,
            'provider_id': provider_id,
            'provider_name': event.get('providerName', 'Unknown Provider'),
            'provider_specialty': event.get('providerSpecialty'),
            'patient_name': event.get('patientName', 'Patient'),
            'call_start_time': event.get('callStartTime'),
            'call_end_time': event.get('callEndTime'),
            'language': event.get('transcriptLanguage', 'en')
        }

        # Generate SOAP note via Bedrock
        result = invoke_bedrock(transcript, metadata)

        # Prepare response
        response = {
            'statusCode': result.get('statusCode', 500),
            'sessionId': session_id,
            'appointmentId': appointment_id
        }

        if result['statusCode'] == 200:
            response['soapNote'] = result['soap_note']
            response['bedrockTokens'] = result.get('bedrock_tokens', {})
            logger.info(f"SOAP note generated successfully for session {session_id}")
        elif result.get('statusCode') == 429 and result.get('retryable'):
            # Queue for retry if throttled
            response['error'] = result.get('error', 'Unknown error')
            response['message'] = result.get('message', 'Generation throttled')
            response['queued'] = queue_for_retry(event, result.get('message'))
            logger.warning(f"SOAP generation throttled for session {session_id}, queued for retry")
        else:
            response['error'] = result.get('error', 'Unknown error')
            response['message'] = result.get('message', 'Generation failed')
            if 'raw_response' in result:
                response['debugInfo'] = result['raw_response']
            logger.error(f"SOAP generation failed for session {session_id}: {result.get('message')}")

        return response

    except Exception as e:
        logger.error(f"Lambda handler error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'error': 'LambdaHandlerError',
            'message': str(e),
            'sessionId': event.get('sessionId'),
            'appointmentId': event.get('appointmentId')
        }


# For local testing
if __name__ == '__main__':
    # Test event
    test_transcript = """
    Provider: Good afternoon, I'm Dr. Sarah Johnson. What brings you in today?

    Patient: Hi doctor. I've had a sore throat for 2 days now and it's been making it hard to swallow. I also have a fever.

    Provider: I see. How high has your fever been?

    Patient: Not sure of the exact temperature, but I took my temperature at home this morning and I think it was around 38.5 degrees Celsius. I also have been having a mild cough yesterday but it's getting better.

    Provider: Any shortness of breath or chest pain?

    Patient: No, nothing like that.

    Provider: Have you had any contact with sick people recently?

    Patient: Actually, yes. My coworker had a cold last week and I think I might have caught it from them.

    Provider: Okay. Let me examine your throat. [In-person exam would happen here, but this is telemedicine]. Since we're doing this over video, I can see your throat looks a bit red but I can't do a full exam. Have you tried anything for the pain?

    Patient: I took some paracetamol yesterday, 500 mg, twice. It helped a little but not completely.

    Provider: Okay. Based on what you've told me, this is likely a viral pharyngitis, probably from that cold exposure. I'd recommend supportive care - warm fluids, rest, throat lozenges. Continue the paracetamol as needed, but don't exceed 4 grams per day.

    Patient: Should I be worried? Like, do I need antibiotics?

    Provider: Not necessarily at this point. Let's see how you do with supportive care. If it gets worse or doesn't improve in 48 hours, come back or call me and we can do a strep test. But for now, since this is telemedicine and I suspect viral, let's try conservative management first. If you develop trouble breathing, or can't swallow liquids, seek urgent care immediately.

    Patient: Okay, that makes sense. Thank you, doctor.

    Provider: You're welcome. Rest up, drink lots of fluids, and let me know how you're doing in a couple of days.
    """

    test_event = {
        'sessionId': 'test-session-123',
        'appointmentId': 'test-apt-456',
        'transcript': test_transcript,
        'providerId': 'prov-789',
        'providerName': 'Dr. Sarah Johnson',
        'providerSpecialty': 'Primary Care',
        'patientName': 'John Doe',
        'callStartTime': '2026-01-13T14:00:00Z',
        'callEndTime': '2026-01-13T14:15:00Z',
        'transcriptLanguage': 'en'
    }

    # Would need AWS credentials configured locally to test
    # result = lambda_handler(test_event, None)
    # print(json.dumps(result, indent=2, default=str))
