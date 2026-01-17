"""
MedZen Transcription Callback Handler

Handles completed AWS Transcribe jobs and processes the results.
Triggered by EventBridge rules when transcription jobs complete.

Author: MedZen Development Team
Version: 1.0.0
"""

import json
import os
import boto3
import logging
import requests
from datetime import datetime
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
transcribe_client = boto3.client('transcribe')
transcribe_medical_client = boto3.client('transcribe')
comprehend_medical = boto3.client('comprehendmedical')
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'eu-central-1'))

# Environment variables
SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET', 'medzen-transcriptions')


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle transcription job completion events from EventBridge.

    Event format (from AWS Transcribe EventBridge):
    {
        "source": "aws.transcribe",
        "detail-type": "Transcribe Job State Change",
        "detail": {
            "TranscriptionJobName": "medzen-medical-xxx",
            "TranscriptionJobStatus": "COMPLETED"
        }
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        detail = event.get('detail', {})
        job_name = detail.get('TranscriptionJobName') or detail.get('MedicalTranscriptionJobName')
        job_status = detail.get('TranscriptionJobStatus') or detail.get('MedicalTranscriptionJobStatus')

        if not job_name:
            logger.warning("No job name in event, skipping")
            return {'statusCode': 200, 'body': 'No job name'}

        # Determine job type from name prefix
        is_medical = job_name.startswith('medzen-medical-')

        if job_status == 'COMPLETED':
            if is_medical:
                process_medical_transcription(job_name)
            else:
                process_standard_transcription(job_name)

        elif job_status == 'FAILED':
            handle_failed_job(job_name, is_medical)

        return {
            'statusCode': 200,
            'body': json.dumps({'processed': job_name, 'status': job_status})
        }

    except Exception as e:
        logger.error(f"Callback processing error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def process_medical_transcription(job_name: str) -> None:
    """Process completed AWS Transcribe Medical job."""
    logger.info(f"Processing medical transcription job: {job_name}")

    # Get job details
    response = transcribe_medical_client.get_medical_transcription_job(
        MedicalTranscriptionJobName=job_name
    )

    job = response['MedicalTranscriptionJob']
    transcript_uri = job['Transcript']['TranscriptFileUri']
    appointment_id = extract_appointment_id(job_name)

    # Download transcript
    transcript_data = download_transcript(transcript_uri)

    if not transcript_data:
        logger.error(f"Failed to download transcript for {job_name}")
        return

    # Extract transcript text
    results = transcript_data.get('results', {})
    transcripts = results.get('transcripts', [])
    full_text = ' '.join([t.get('transcript', '') for t in transcripts])

    # Get speaker-labeled segments
    segments = extract_speaker_segments(results)

    # Medical entities are already extracted by AWS Transcribe Medical
    entities = results.get('entities', [])

    # Format entities for storage
    formatted_entities = format_medical_entities(entities)

    # Store in Supabase
    store_completed_transcription(
        appointment_id=appointment_id,
        job_name=job_name,
        transcript_text=full_text,
        segments=segments,
        entities=formatted_entities,
        language='en-US',
        service='aws_transcribe_medical'
    )


def process_standard_transcription(job_name: str) -> None:
    """Process completed AWS Transcribe Standard job."""
    logger.info(f"Processing standard transcription job: {job_name}")

    # Get job details
    response = transcribe_client.get_transcription_job(
        TranscriptionJobName=job_name
    )

    job = response['TranscriptionJob']
    transcript_uri = job['Transcript']['TranscriptFileUri']
    language_code = job['LanguageCode']
    appointment_id = extract_appointment_id(job_name)

    # Download transcript
    transcript_data = download_transcript(transcript_uri)

    if not transcript_data:
        logger.error(f"Failed to download transcript for {job_name}")
        return

    # Extract transcript text
    results = transcript_data.get('results', {})
    transcripts = results.get('transcripts', [])
    full_text = ' '.join([t.get('transcript', '') for t in transcripts])

    # Get speaker-labeled segments
    segments = extract_speaker_segments(results)

    # For non-English (French), extract entities using Bedrock
    entities = extract_entities_with_bedrock(full_text, language_code)

    # Store in Supabase
    store_completed_transcription(
        appointment_id=appointment_id,
        job_name=job_name,
        transcript_text=full_text,
        segments=segments,
        entities=entities,
        language=language_code,
        service='aws_transcribe_standard'
    )


def extract_appointment_id(job_name: str) -> Optional[str]:
    """Extract appointment ID from job name."""
    # Format: medzen-medical-{appointment_id}-{random}
    # or: medzen-standard-{appointment_id}-{random}
    parts = job_name.split('-')
    if len(parts) >= 4:
        return parts[2]
    return None


def download_transcript(uri: str) -> Optional[Dict]:
    """Download transcript JSON from S3 or HTTPS."""
    try:
        if uri.startswith('s3://'):
            # Parse S3 URI
            from urllib.parse import urlparse
            parsed = urlparse(uri)
            bucket = parsed.netloc
            key = parsed.path.lstrip('/')

            response = s3_client.get_object(Bucket=bucket, Key=key)
            return json.loads(response['Body'].read())

        elif uri.startswith('https://'):
            response = requests.get(uri)
            return response.json()

    except Exception as e:
        logger.error(f"Failed to download transcript: {e}")
        return None


def extract_speaker_segments(results: Dict) -> list:
    """Extract speaker-labeled segments from transcript results."""
    segments = []

    items = results.get('items', [])
    speaker_labels = results.get('speaker_labels', {})
    speaker_segments = speaker_labels.get('segments', [])

    for seg in speaker_segments:
        speaker_label = seg.get('speaker_label', 'Unknown')
        start_time = float(seg.get('start_time', 0))
        end_time = float(seg.get('end_time', 0))

        # Collect words for this segment
        words = []
        for item in seg.get('items', []):
            content = item.get('content', '')
            words.append(content)

        segments.append({
            'speaker': speaker_label,
            'start_time': start_time,
            'end_time': end_time,
            'text': ' '.join(words)
        })

    return segments


def format_medical_entities(entities: list) -> list:
    """Format AWS Transcribe Medical entities for storage."""
    formatted = []

    for entity in entities:
        formatted.append({
            'text': entity.get('Content', ''),
            'type': entity.get('Category', 'UNKNOWN'),
            'score': entity.get('Score', 0.0),
            'begin_offset': entity.get('BeginOffset', 0),
            'end_offset': entity.get('EndOffset', 0),
            'traits': entity.get('Traits', []),
            'attributes': entity.get('Attributes', [])
        })

    return formatted


def extract_entities_with_bedrock(transcript_text: str, language_code: str) -> list:
    """Extract medical entities using Bedrock Claude for non-English text."""
    if not transcript_text:
        return []

    # Get language name
    language_names = {
        'fr-FR': 'French',
        'fr-CA': 'Canadian French',
        'fr': 'French'
    }
    language_name = language_names.get(language_code, 'French')

    prompt = f"""Analyze this medical consultation transcript in {language_name} and extract medical entities.

TRANSCRIPT:
{transcript_text}

Extract the following types of entities:
1. SYMPTOMS - Patient symptoms or complaints
2. DIAGNOSES - Medical conditions or diagnoses mentioned
3. MEDICATIONS - Drug names, dosages, frequencies
4. PROCEDURES - Medical procedures or treatments
5. VITAL_SIGNS - Blood pressure, temperature, pulse, etc.
6. MEDICAL_HISTORY - Past conditions or family history
7. ALLERGIES - Drug or food allergies

Return a JSON array with this format for each entity found:
[
  {{
    "text": "original text in {language_name}",
    "text_en": "English translation",
    "type": "SYMPTOM|DIAGNOSIS|MEDICATION|PROCEDURE|VITAL_SIGN|HISTORY|ALLERGY",
    "icd10_code": "ICD-10 code if applicable",
    "confidence": 0.0-1.0,
    "context": "brief context where this was mentioned"
  }}
]

Only return valid JSON, no other text."""

    try:
        response = bedrock_runtime.invoke_model(
            modelId='anthropic.claude-3-5-sonnet-20241022-v2:0',
            body=json.dumps({
                'anthropic_version': 'bedrock-2023-05-31',
                'max_tokens': 4096,
                'messages': [
                    {
                        'role': 'user',
                        'content': prompt
                    }
                ]
            })
        )

        response_body = json.loads(response['body'].read())
        content = response_body.get('content', [{}])[0].get('text', '[]')

        # Parse JSON response
        entities = json.loads(content)
        return entities if isinstance(entities, list) else []

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse entity extraction response: {e}")
        return []
    except Exception as e:
        logger.error(f"Entity extraction error: {e}")
        return []


def handle_failed_job(job_name: str, is_medical: bool) -> None:
    """Handle failed transcription job."""
    logger.error(f"Transcription job failed: {job_name}")

    appointment_id = extract_appointment_id(job_name)
    if not appointment_id:
        return

    try:
        # Get failure reason
        if is_medical:
            response = transcribe_medical_client.get_medical_transcription_job(
                MedicalTranscriptionJobName=job_name
            )
            failure_reason = response['MedicalTranscriptionJob'].get('FailureReason', 'Unknown')
        else:
            response = transcribe_client.get_transcription_job(
                TranscriptionJobName=job_name
            )
            failure_reason = response['TranscriptionJob'].get('FailureReason', 'Unknown')

        # Update Supabase with failure status
        update_transcription_status(
            appointment_id=appointment_id,
            status='FAILED',
            error_message=failure_reason
        )

    except Exception as e:
        logger.error(f"Failed to handle job failure: {e}")


def store_completed_transcription(
    appointment_id: str,
    job_name: str,
    transcript_text: str,
    segments: list,
    entities: list,
    language: str,
    service: str
) -> None:
    """Store completed transcription in Supabase."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        logger.warning("Supabase credentials not configured")
        return

    try:
        data = {
            'transcription_status': 'COMPLETED',
            'transcription_completed_at': datetime.utcnow().isoformat(),
            'raw_transcript': transcript_text,
            'transcript_segments': json.dumps(segments, ensure_ascii=False),
            'medical_entities': json.dumps(entities, ensure_ascii=False),
            'transcription_language': language,
            'transcription_service': service,
            'updated_at': datetime.utcnow().isoformat()
        }

        # Find session by job name pattern (appointment_id is in the job name)
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/video_call_sessions?transcription_job_name=eq.{job_name}",
            headers={
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            json=data
        )

        if response.status_code not in [200, 201, 204]:
            logger.error(f"Supabase update failed: {response.status_code} - {response.text}")
        else:
            logger.info(f"Transcription stored for job {job_name}")

    except Exception as e:
        logger.error(f"Failed to store transcription: {e}")


def update_transcription_status(
    appointment_id: str,
    status: str,
    error_message: Optional[str] = None
) -> None:
    """Update transcription status in Supabase."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        return

    try:
        data = {
            'transcription_status': status,
            'updated_at': datetime.utcnow().isoformat()
        }

        if error_message:
            data['transcription_error'] = error_message

        requests.patch(
            f"{SUPABASE_URL}/rest/v1/video_call_sessions?appointment_id=eq.{appointment_id}",
            headers={
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            json=data
        )

    except Exception as e:
        logger.error(f"Failed to update status: {e}")
