"""
MedZen Lambda: Save SOAP Note to Supabase
Persists generated SOAP note and Bedrock token tracking to Supabase database
"""

import json
import os
import requests
from datetime import datetime
import uuid


def lambda_handler(event, context):
    """
    Saves SOAP note and token tracking to Supabase

    Input:
    {
        "sessionId": "uuid",
        "appointmentId": "uuid",
        "soapData": {
            "chief_complaint": "...",
            "subjective": {...},
            "objective": {...},
            "assessment": {...},
            "plan": {...}
        },
        "bedrockTokens": {
            "input_tokens": 1234,
            "output_tokens": 5678
        },
        "aiModel": "claude-opus-4-5-20251101-v1:0"
    }

    Output:
    {
        "statusCode": 200,
        "soapNote": {
            "id": "uuid",
            "sessionId": "uuid",
            "appointmentId": "uuid",
            ...
        },
        "bedrockTokens": {...}
    }
    """

    try:
        session_id = event.get('sessionId')
        appointment_id = event.get('appointmentId')
        soap_data = event.get('soapData', {})
        bedrock_tokens = event.get('bedrockTokens', {})
        ai_model = event.get('aiModel', 'claude-opus-4-5-20251101-v1:0')

        if not all([session_id, appointment_id]):
            raise ValueError("sessionId and appointmentId are required")

        # Supabase configuration
        supabase_url = os.environ['SUPABASE_URL']
        supabase_key = os.environ['SUPABASE_SERVICE_KEY']

        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }

        soap_note_id = str(uuid.uuid4())
        print(f"[SaveSOAP] Creating SOAP note {soap_note_id} for session {session_id}...")

        # Prepare clinical_notes record
        clinical_note_record = {
            'id': soap_note_id,
            'session_id': session_id,
            'appointment_id': appointment_id,
            'note_type': 'SOAP',
            'status': 'draft',
            'chief_complaint': soap_data.get('chief_complaint', ''),
            'subjective': json.dumps(soap_data.get('subjective', {})),
            'objective': json.dumps(soap_data.get('objective', {})),
            'assessment': json.dumps(soap_data.get('assessment', {})),
            'plan': json.dumps(soap_data.get('plan', {})),
            'ai_model': ai_model,
            'ai_generated_at': datetime.utcnow().isoformat() + 'Z',
            'created_at': datetime.utcnow().isoformat() + 'Z',
        }

        # Save SOAP note to clinical_notes table
        clinical_notes_url = f"{supabase_url}/rest/v1/clinical_notes"
        clinical_response = requests.post(
            clinical_notes_url,
            headers=headers,
            json=clinical_note_record,
            timeout=10
        )

        if clinical_response.status_code not in [200, 201]:
            raise Exception(f"Failed to create clinical note: {clinical_response.text}")

        print(f"[SaveSOAP] Successfully created clinical note {soap_note_id}")

        # Track Bedrock token usage if tokens were provided
        if bedrock_tokens and (bedrock_tokens.get('input_tokens') or bedrock_tokens.get('output_tokens')):
            save_bedrock_token_usage(
                supabase_url,
                supabase_key,
                session_id,
                appointment_id,
                soap_note_id,
                bedrock_tokens,
                ai_model
            )

        # Link SOAP note to session
        print(f"[SaveSOAP] Linking SOAP note to session {session_id}...")

        session_update_url = f"{supabase_url}/rest/v1/video_call_sessions?id=eq.{session_id}"
        session_update_body = {
            'soap_note_id': soap_note_id,
            'finalization_status': 'completed',
            'finalized_at': datetime.utcnow().isoformat() + 'Z',
        }

        session_response = requests.patch(
            session_update_url,
            headers=headers,
            json=session_update_body,
            timeout=10
        )

        if session_response.status_code not in [200, 204]:
            print(f"[SaveSOAP] Warning: Failed to link SOAP to session: {session_response.text}")
            # Don't fail entire operation if session link fails
        else:
            print(f"[SaveSOAP] Successfully linked SOAP note to session")

        return {
            'statusCode': 200,
            'soapNote': {
                'id': soap_note_id,
                'sessionId': session_id,
                'appointmentId': appointment_id,
                'status': 'draft',
                'aiModel': ai_model
            },
            'bedrockTokens': bedrock_tokens,
            'message': 'SOAP note saved to Supabase'
        }

    except ValueError as e:
        print(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'error': 'InvalidInput',
            'message': str(e)
        }
    except Exception as e:
        print(f"Error saving SOAP note: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'SOAPSaveFailed',
            'message': str(e)
        }


def save_bedrock_token_usage(supabase_url, supabase_key, session_id, appointment_id, soap_note_id, bedrock_tokens, ai_model):
    """
    Saves Bedrock token usage tracking to bedrock_token_tracking table
    """

    try:
        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }

        token_record = {
            'session_id': session_id,
            'appointment_id': appointment_id,
            'soap_note_id': soap_note_id,
            'ai_model': ai_model,
            'input_tokens': bedrock_tokens.get('input_tokens', 0),
            'output_tokens': bedrock_tokens.get('output_tokens', 0),
            'total_tokens': (bedrock_tokens.get('input_tokens', 0) + bedrock_tokens.get('output_tokens', 0)),
            'created_at': datetime.utcnow().isoformat() + 'Z',
        }

        token_url = f"{supabase_url}/rest/v1/bedrock_token_tracking"
        token_response = requests.post(
            token_url,
            headers=headers,
            json=token_record,
            timeout=10
        )

        if token_response.status_code in [200, 201]:
            print(f"[SaveSOAP] Tracked Bedrock tokens - Input: {bedrock_tokens.get('input_tokens', 0)}, Output: {bedrock_tokens.get('output_tokens', 0)}")
        else:
            print(f"[SaveSOAP] Warning: Failed to track Bedrock tokens: {token_response.text}")

    except Exception as e:
        print(f"[SaveSOAP] Warning: Failed to save token tracking: {str(e)}")
        # Don't fail operation if token tracking fails
