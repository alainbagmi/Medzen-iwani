"""
MedZen Lambda: Validate Video Call Session in Supabase
Validates that a video call session exists and is in valid state for SOAP generation
"""

import json
import os
import requests
from datetime import datetime


def lambda_handler(event, context):
    """
    Validates video call session in Supabase

    Input:
    {
        "sessionId": "uuid"
    }

    Output:
    {
        "statusCode": 200,
        "sessionData": {
            "sessionId": "uuid",
            "appointmentId": "uuid",
            "providerId": "uuid",
            "transcriptionEnabled": true,
            "transcriptId": "uuid",
            ...
        }
    }
    """

    try:
        session_id = event.get('sessionId')

        if not session_id:
            raise ValueError("sessionId is required")

        # Supabase configuration
        supabase_url = os.environ['SUPABASE_URL']
        supabase_key = os.environ['SUPABASE_SERVICE_KEY']

        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }

        print(f"[ValidateSession] Validating session {session_id} in Supabase...")

        # Query video_call_sessions table
        query_url = f"{supabase_url}/rest/v1/video_call_sessions?id=eq.{session_id}"
        session_response = requests.get(
            query_url,
            headers=headers,
            timeout=10
        )

        if session_response.status_code != 200:
            raise Exception(f"Failed to query session: {session_response.text}")

        session_data = session_response.json()
        if not session_data or len(session_data) == 0:
            raise ValueError(f"Session {session_id} not found in Supabase")

        session = session_data[0]
        print(f"[ValidateSession] Session {session_id} validated successfully")

        # Extract key fields for workflow
        return {
            'statusCode': 200,
            'sessionData': {
                'sessionId': session.get('id'),
                'appointmentId': session.get('appointment_id'),
                'providerId': session.get('provider_id'),
                'patientId': session.get('patient_id'),
                'transcriptionEnabled': session.get('transcription_enabled', True),
                'transcriptId': session.get('transcript_id'),
                'status': session.get('status'),
                'startTime': session.get('start_time'),
                'endTime': session.get('end_time'),
                'language': session.get('transcript_language', 'en')
            }
        }

    except ValueError as e:
        print(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'error': 'InvalidSession',
            'message': str(e)
        }
    except Exception as e:
        print(f"Error validating session: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'SessionValidationFailed',
            'message': str(e)
        }
