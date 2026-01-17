"""
MedZen Lambda: Update Supabase SOAP Notes
Syncs generated SOAP note to primary Supabase database
"""

import json
import os
import requests
from datetime import datetime

def lambda_handler(event, context):
    """
    Updates Supabase with SOAP note data

    Input:
    {
        "soapNoteId": "uuid",
        "sessionId": "uuid",
        "appointmentId": "uuid",
        "soapData": {
            "chief_complaint": "...",
            "subjective": {...},
            "objective": {...},
            "assessment": {...},
            "plan": {...}
        },
        "aiRawJson": {...},
        "medicalCodes": {...} (optional)
    }

    Output:
    {
        "statusCode": 200,
        "soapNoteId": "uuid",
        "message": "SOAP note created/updated in Supabase"
    }
    """

    try:
        soap_note_id = event.get('soapNoteId')
        session_id = event.get('sessionId')
        appointment_id = event.get('appointmentId')
        soap_data = event.get('soapData', {})
        ai_raw_json = event.get('aiRawJson', {})
        medical_codes = event.get('medicalCodes', {})

        if not all([soap_note_id, session_id, appointment_id]):
            raise ValueError("soapNoteId, sessionId, and appointmentId are required")

        # Supabase configuration
        supabase_url = os.environ['SUPABASE_URL']
        supabase_key = os.environ['SUPABASE_SERVICE_KEY']

        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }

        print(f"[Supabase] Updating SOAP note {soap_note_id} in Supabase...")

        # Prepare SOAP note record for insertion
        soap_note_record = {
            'id': soap_note_id,
            'session_id': session_id,
            'appointment_id': appointment_id,
            'status': 'draft',
            'chief_complaint': soap_data.get('chief_complaint', ''),
            'subjective': json.dumps(soap_data.get('subjective', {})),
            'objective': json.dumps(soap_data.get('objective', {})),
            'assessment': json.dumps(soap_data.get('assessment', {})),
            'plan': json.dumps(soap_data.get('plan', {})),
            'ai_raw_json': json.dumps(ai_raw_json),
            'medical_codes': json.dumps(medical_codes) if medical_codes else None,
            'ai_generated_at': datetime.utcnow().isoformat() + 'Z',
            'created_at': datetime.utcnow().isoformat() + 'Z',
        }

        # Try to insert SOAP note
        insert_url = f"{supabase_url}/rest/v1/soap_notes"
        insert_response = requests.post(
            insert_url,
            headers=headers,
            json=soap_note_record,
            timeout=10
        )

        if insert_response.status_code in [200, 201]:
            print(f"[Supabase] Successfully created SOAP note {soap_note_id}")
        elif insert_response.status_code == 409:
            # Note already exists, update it
            print(f"[Supabase] SOAP note already exists, updating...")

            update_url = f"{supabase_url}/rest/v1/soap_notes?id=eq.{soap_note_id}"
            update_response = requests.patch(
                update_url,
                headers=headers,
                json=soap_note_record,
                timeout=10
            )

            if update_response.status_code not in [200, 204]:
                raise Exception(f"Failed to update SOAP note: {update_response.text}")

            print(f"[Supabase] Successfully updated SOAP note {soap_note_id}")
        else:
            raise Exception(f"Failed to create SOAP note: {insert_response.text}")

        # Update session to link SOAP note
        print(f"[Supabase] Linking SOAP note to session {session_id}...")

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
            print(f"[Supabase] Warning: Failed to link SOAP to session: {session_response.text}")
            # Don't fail entire operation if session link fails
        else:
            print(f"[Supabase] Successfully linked SOAP note to session")

        return {
            'statusCode': 200,
            'soapNoteId': soap_note_id,
            'sessionId': session_id,
            'appointmentId': appointment_id,
            'message': 'SOAP note created/updated in Supabase',
        }

    except Exception as e:
        print(f"Error updating Supabase: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'SupabaseUpdateFailed',
            'message': str(e)
        }


def create_soap_history_record(supabase_url, supabase_key, soap_note_id, session_id, version_info):
    """
    Creates a history record for SOAP note versioning
    """

    headers = {
        'apikey': supabase_key,
        'Authorization': f'Bearer {supabase_key}',
        'Content-Type': 'application/json',
    }

    history_record = {
        'soap_note_id': soap_note_id,
        'session_id': session_id,
        'version_number': 1,
        'change_type': 'created',
        'change_summary': 'Initial AI-generated draft',
        'created_at': datetime.utcnow().isoformat() + 'Z',
    }

    try:
        history_url = f"{supabase_url}/rest/v1/soap_note_history"
        requests.post(
            history_url,
            headers=headers,
            json=history_record,
            timeout=10
        )
        print("[Supabase] Created history record for SOAP note")
    except Exception as e:
        print(f"[Supabase] Warning: Failed to create history record: {str(e)}")
        # Don't fail if history creation fails
