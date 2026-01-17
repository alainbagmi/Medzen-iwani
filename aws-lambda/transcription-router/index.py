"""
MedZen Medical Transcription Router Lambda

Routes audio transcription to appropriate service based on language:
- AWS Transcribe Medical: English (medical entity extraction built-in)
- AWS Transcribe Standard: French
- OpenAI Whisper: Fulfulde, Pidgin English, Central African languages

Author: MedZen Development Team
Version: 1.0.0
"""

import json
import os
import boto3
import logging
import uuid
from datetime import datetime
from typing import Dict, Any, Optional, Tuple
from urllib.parse import urlparse

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
transcribe_client = boto3.client('transcribe')
transcribe_medical_client = boto3.client('transcribe')
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'eu-central-1'))

# Environment variables
OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY')
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET', 'medzen-transcriptions')
SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

# Language configurations
AWS_TRANSCRIBE_MEDICAL_LANGUAGES = {
    'en-US': 'en-US',
    'en-GB': 'en-GB',
    'en-AU': 'en-AU',
    'en-IN': 'en-IN',
    'en': 'en-US'  # Default English
}

AWS_TRANSCRIBE_STANDARD_LANGUAGES = {
    'fr-FR': 'fr-FR',
    'fr-CA': 'fr-CA',
    'fr': 'fr-FR'  # Default French
}

# African languages supported by Whisper
WHISPER_LANGUAGES = {
    # Fulfulde/Fula variants
    'ff': 'Fulfulde (General)',
    'fub': 'Adamawa Fulfulde',
    'fuc': 'Pulaar',
    'fue': 'Borgu Fulfulde',
    'fuf': 'Pular',
    'fuh': 'Western Niger Fulfulde',
    'fuq': 'Central-Eastern Niger Fulfulde',
    'fuv': 'Nigerian Fulfulde',
    'ful': 'Fulfulde',

    # Nigerian/Cameroonian Pidgin
    'pcm': 'Nigerian Pidgin',
    'wes': 'Cameroonian Pidgin',

    # Central African languages
    'ln': 'Lingala',
    'sg': 'Sango',
    'wo': 'Wolof',
    'tw': 'Twi',
    'bm': 'Bambara',
    'ha': 'Hausa',
    'yo': 'Yoruba',
    'ig': 'Igbo',
    'ak': 'Akan',
    'ee': 'Ewe',
    'ti': 'Tigrinya',
    'am': 'Amharic',
    'om': 'Oromo',
    'rw': 'Kinyarwanda',
    'rn': 'Kirundi',
    'sw': 'Swahili',
    'lg': 'Luganda',
    'zu': 'Zulu',
    'xh': 'Xhosa',
    'st': 'Sesotho',
    'tn': 'Setswana',
    'ts': 'Tsonga',
    've': 'Venda',
    'ss': 'Swati',
    'nr': 'Ndebele',
    'sn': 'Shona',
    'ny': 'Chichewa'
}


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for transcription routing.

    Event format:
    {
        "s3_uri": "s3://bucket/path/to/audio.mp4",
        "language_code": "en-US|fr-FR|ff|pcm|ln|...",
        "appointment_id": "uuid",
        "session_id": "uuid",
        "provider_id": "uuid",
        "patient_id": "uuid",
        "auto_detect_language": false,
        "medical_specialty": "PRIMARYCARE|CARDIOLOGY|..."
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Parse input
        s3_uri = event.get('s3_uri')
        language_code = event.get('language_code', 'en-US')
        appointment_id = event.get('appointment_id')
        session_id = event.get('session_id')
        provider_id = event.get('provider_id')
        patient_id = event.get('patient_id')
        auto_detect = event.get('auto_detect_language', False)
        medical_specialty = event.get('medical_specialty', 'PRIMARYCARE')

        if not s3_uri:
            return error_response(400, "Missing required parameter: s3_uri")

        if not appointment_id:
            return error_response(400, "Missing required parameter: appointment_id")

        # Normalize language code
        language_code = normalize_language_code(language_code)

        # Route to appropriate transcription service
        if language_code in AWS_TRANSCRIBE_MEDICAL_LANGUAGES:
            result = transcribe_with_aws_medical(
                s3_uri=s3_uri,
                language_code=AWS_TRANSCRIBE_MEDICAL_LANGUAGES[language_code],
                appointment_id=appointment_id,
                medical_specialty=medical_specialty
            )
            service_used = 'aws_transcribe_medical'

        elif language_code in AWS_TRANSCRIBE_STANDARD_LANGUAGES:
            result = transcribe_with_aws_standard(
                s3_uri=s3_uri,
                language_code=AWS_TRANSCRIBE_STANDARD_LANGUAGES[language_code],
                appointment_id=appointment_id
            )
            # Extract entities using Bedrock for non-English
            result = add_entity_extraction_bedrock(result, language_code)
            service_used = 'aws_transcribe_standard'

        elif language_code in WHISPER_LANGUAGES or is_fulfulde_variant(language_code):
            result = transcribe_with_whisper(
                s3_uri=s3_uri,
                language_code=language_code,
                appointment_id=appointment_id
            )
            service_used = 'openai_whisper'

        else:
            # Default to Whisper for unknown languages (best multilingual support)
            logger.warning(f"Unknown language code: {language_code}, defaulting to Whisper")
            result = transcribe_with_whisper(
                s3_uri=s3_uri,
                language_code=language_code,
                appointment_id=appointment_id
            )
            service_used = 'openai_whisper'

        # Store result in Supabase
        store_transcription_result(
            appointment_id=appointment_id,
            session_id=session_id,
            provider_id=provider_id,
            patient_id=patient_id,
            result=result,
            language_code=language_code,
            service_used=service_used
        )

        return success_response({
            'transcription': result,
            'language_code': language_code,
            'language_name': get_language_name(language_code),
            'service_used': service_used,
            'appointment_id': appointment_id
        })

    except Exception as e:
        logger.error(f"Transcription error: {str(e)}", exc_info=True)
        return error_response(500, f"Transcription failed: {str(e)}")


def normalize_language_code(code: str) -> str:
    """Normalize language code to lowercase and handle variants."""
    if not code:
        return 'en-US'

    code = code.lower().strip()

    # Handle common variations
    variations = {
        'english': 'en-US',
        'french': 'fr-FR',
        'francais': 'fr-FR',
        'fulfulde': 'ff',
        'fula': 'ff',
        'fulani': 'ff',
        'peul': 'ff',
        'pidgin': 'pcm',
        'nigerian pidgin': 'pcm',
        'cameroon pidgin': 'wes',
        'lingala': 'ln',
        'sango': 'sg',
        'hausa': 'ha',
        'yoruba': 'yo',
        'igbo': 'ig',
        'swahili': 'sw',
        'kiswahili': 'sw'
    }

    return variations.get(code, code)


def is_fulfulde_variant(code: str) -> bool:
    """Check if language code is a Fulfulde variant."""
    fulfulde_codes = ['ff', 'fub', 'fuc', 'fue', 'fuf', 'fuh', 'fuq', 'fuv', 'ful']
    return code.lower() in fulfulde_codes


def get_language_name(code: str) -> str:
    """Get human-readable language name."""
    all_languages = {
        **{k: 'English' for k in AWS_TRANSCRIBE_MEDICAL_LANGUAGES},
        **{k: 'French' for k in AWS_TRANSCRIBE_STANDARD_LANGUAGES},
        **WHISPER_LANGUAGES
    }
    return all_languages.get(code, code)


def transcribe_with_aws_medical(
    s3_uri: str,
    language_code: str,
    appointment_id: str,
    medical_specialty: str = 'PRIMARYCARE'
) -> Dict[str, Any]:
    """
    Transcribe using AWS Transcribe Medical.
    Includes medical entity extraction.
    """
    job_name = f"medzen-medical-{appointment_id}-{uuid.uuid4().hex[:8]}"

    # Parse S3 URI
    parsed = urlparse(s3_uri)
    bucket = parsed.netloc
    key = parsed.path.lstrip('/')

    # Get media format
    media_format = get_media_format(key)

    # Start medical transcription job
    response = transcribe_medical_client.start_medical_transcription_job(
        MedicalTranscriptionJobName=job_name,
        LanguageCode=language_code,
        MediaFormat=media_format,
        Media={'MediaFileUri': s3_uri},
        OutputBucketName=OUTPUT_BUCKET,
        OutputKey=f"transcriptions/{appointment_id}/",
        Specialty=medical_specialty,
        Type='CONVERSATION',
        ContentIdentificationType='PHI',  # Enable PHI identification
        Settings={
            'ShowSpeakerLabels': True,
            'MaxSpeakerLabels': 2,  # Provider and patient
            'VocabularyName': os.environ.get('MEDICAL_VOCABULARY', None)
        }
    )

    # Wait for job completion (for Lambda, we'd typically use Step Functions)
    # For now, return job info for async processing
    return {
        'job_name': job_name,
        'job_status': 'IN_PROGRESS',
        'service': 'aws_transcribe_medical',
        'language_code': language_code,
        'async': True,
        'output_uri': f"s3://{OUTPUT_BUCKET}/transcriptions/{appointment_id}/"
    }


def transcribe_with_aws_standard(
    s3_uri: str,
    language_code: str,
    appointment_id: str
) -> Dict[str, Any]:
    """
    Transcribe using AWS Transcribe Standard.
    Used for French and other non-English supported languages.
    """
    job_name = f"medzen-standard-{appointment_id}-{uuid.uuid4().hex[:8]}"

    # Parse S3 URI
    parsed = urlparse(s3_uri)
    bucket = parsed.netloc
    key = parsed.path.lstrip('/')

    # Get media format
    media_format = get_media_format(key)

    # Start standard transcription job
    response = transcribe_client.start_transcription_job(
        TranscriptionJobName=job_name,
        LanguageCode=language_code,
        MediaFormat=media_format,
        Media={'MediaFileUri': s3_uri},
        OutputBucketName=OUTPUT_BUCKET,
        OutputKey=f"transcriptions/{appointment_id}/",
        Settings={
            'ShowSpeakerLabels': True,
            'MaxSpeakerLabels': 2,
            'VocabularyName': os.environ.get('FRENCH_VOCABULARY', None)
        },
        ContentRedaction={
            'RedactionType': 'PII',
            'RedactionOutput': 'redacted_and_unredacted',
            'PiiEntityTypes': ['NAME', 'ADDRESS', 'EMAIL', 'PHONE', 'SSN', 'CREDIT_DEBIT_NUMBER']
        }
    )

    return {
        'job_name': job_name,
        'job_status': 'IN_PROGRESS',
        'service': 'aws_transcribe_standard',
        'language_code': language_code,
        'async': True,
        'output_uri': f"s3://{OUTPUT_BUCKET}/transcriptions/{appointment_id}/"
    }


def transcribe_with_whisper(
    s3_uri: str,
    language_code: str,
    appointment_id: str
) -> Dict[str, Any]:
    """
    Transcribe using OpenAI Whisper API.
    Used for Fulfulde, Pidgin English, and Central African languages.
    """
    import requests
    import tempfile

    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY environment variable not set")

    # Parse S3 URI and download file
    parsed = urlparse(s3_uri)
    bucket = parsed.netloc
    key = parsed.path.lstrip('/')

    # Download audio file from S3
    with tempfile.NamedTemporaryFile(suffix=get_file_extension(key), delete=False) as tmp_file:
        s3_client.download_file(bucket, key, tmp_file.name)
        tmp_path = tmp_file.name

    try:
        # Call OpenAI Whisper API
        with open(tmp_path, 'rb') as audio_file:
            response = requests.post(
                'https://api.openai.com/v1/audio/transcriptions',
                headers={
                    'Authorization': f'Bearer {OPENAI_API_KEY}'
                },
                files={
                    'file': (os.path.basename(key), audio_file, get_mime_type(key))
                },
                data={
                    'model': 'whisper-1',
                    'response_format': 'verbose_json',
                    'language': get_whisper_language_code(language_code),
                    'timestamp_granularities[]': 'segment'
                }
            )

        if response.status_code != 200:
            raise Exception(f"Whisper API error: {response.text}")

        whisper_result = response.json()

        # Extract entities using Bedrock Claude (since Whisper doesn't do medical entities)
        entities = extract_entities_with_bedrock(
            transcript_text=whisper_result.get('text', ''),
            language_code=language_code
        )

        # Format result
        result = {
            'job_name': f"whisper-{appointment_id}-{uuid.uuid4().hex[:8]}",
            'job_status': 'COMPLETED',
            'service': 'openai_whisper',
            'language_code': language_code,
            'language_detected': whisper_result.get('language'),
            'async': False,
            'transcript': {
                'text': whisper_result.get('text', ''),
                'segments': whisper_result.get('segments', []),
                'duration': whisper_result.get('duration', 0)
            },
            'entities': entities,
            'output_uri': None  # Inline result
        }

        # Store transcript to S3
        output_key = f"transcriptions/{appointment_id}/whisper-result.json"
        s3_client.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=json.dumps(result, ensure_ascii=False),
            ContentType='application/json'
        )
        result['output_uri'] = f"s3://{OUTPUT_BUCKET}/{output_key}"

        return result

    finally:
        # Cleanup temp file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def extract_entities_with_bedrock(
    transcript_text: str,
    language_code: str
) -> list:
    """
    Extract medical entities from transcript using AWS Bedrock Claude.
    Used for non-English transcripts from Whisper.
    """
    if not transcript_text:
        return []

    language_name = get_language_name(language_code)

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


def add_entity_extraction_bedrock(result: Dict, language_code: str) -> Dict:
    """Add Bedrock-based entity extraction to AWS Transcribe Standard results."""
    # For async jobs, entity extraction will happen in the callback
    if result.get('async'):
        result['entity_extraction_pending'] = True
    return result


def store_transcription_result(
    appointment_id: str,
    session_id: Optional[str],
    provider_id: Optional[str],
    patient_id: Optional[str],
    result: Dict,
    language_code: str,
    service_used: str
) -> None:
    """Store transcription result in Supabase."""
    import requests

    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        logger.warning("Supabase credentials not configured, skipping database update")
        return

    try:
        # Update video_call_sessions with transcription info
        data = {
            'transcription_status': result.get('job_status', 'IN_PROGRESS'),
            'transcription_job_name': result.get('job_name'),
            'transcription_output_uri': result.get('output_uri'),
            'transcription_language': language_code,
            'transcription_service': service_used,
            'transcription_started_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }

        # If we have inline transcript (Whisper), store it
        if not result.get('async') and result.get('transcript'):
            data['raw_transcript'] = json.dumps(result['transcript'], ensure_ascii=False)
            data['medical_entities'] = json.dumps(result.get('entities', []), ensure_ascii=False)
            data['transcription_completed_at'] = datetime.utcnow().isoformat()

        # Use session_id or appointment_id for update
        filter_key = 'id' if session_id else 'appointment_id'
        filter_value = session_id or appointment_id

        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/video_call_sessions?{filter_key}=eq.{filter_value}",
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
            logger.info(f"Transcription result stored for appointment {appointment_id}")

    except Exception as e:
        logger.error(f"Failed to store transcription result: {e}")


def get_media_format(filename: str) -> str:
    """Determine media format from filename."""
    extension = filename.lower().split('.')[-1]
    format_map = {
        'mp3': 'mp3',
        'mp4': 'mp4',
        'wav': 'wav',
        'flac': 'flac',
        'ogg': 'ogg',
        'webm': 'webm',
        'm4a': 'mp4',
        'amr': 'amr'
    }
    return format_map.get(extension, 'mp4')


def get_file_extension(filename: str) -> str:
    """Get file extension including dot."""
    parts = filename.split('.')
    return f".{parts[-1]}" if len(parts) > 1 else '.mp4'


def get_mime_type(filename: str) -> str:
    """Get MIME type for file."""
    extension = filename.lower().split('.')[-1]
    mime_map = {
        'mp3': 'audio/mpeg',
        'mp4': 'video/mp4',
        'wav': 'audio/wav',
        'flac': 'audio/flac',
        'ogg': 'audio/ogg',
        'webm': 'audio/webm',
        'm4a': 'audio/mp4',
        'amr': 'audio/amr'
    }
    return mime_map.get(extension, 'audio/mp4')


def get_whisper_language_code(code: str) -> Optional[str]:
    """
    Convert internal language code to Whisper language code.
    Whisper uses ISO 639-1 codes.
    """
    # Already short codes
    if len(code) == 2:
        return code

    # Fulfulde variants -> Fulah
    if is_fulfulde_variant(code):
        return 'ff'

    # Extract base language from locale code
    if '-' in code:
        return code.split('-')[0]

    return code


def success_response(data: Dict[str, Any]) -> Dict[str, Any]:
    """Format success response."""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': True,
            'data': data
        }, ensure_ascii=False)
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Format error response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': False,
            'error': message
        })
    }
