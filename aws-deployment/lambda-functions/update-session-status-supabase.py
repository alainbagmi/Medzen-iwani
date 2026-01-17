"""
MedZen Lambda: Update Video Call Session Status in Supabase
Updates the finalization status of a video call session after SOAP generation
"""

import json
import os
import requests
from datetime import datetime


def lambda_handler(event, context):
    """
    Updates video call session status in Supabase

    Input:
    {
        "sessionId": "uuid",
        "status": "soap_generated",
        "soapGenerated": true
    }

    Output:
    {
        "statusCode": 200,
        "sessionId": "uuid",
        "status": "soap_generated",
        "message": "Session status updated successfully"
    }
    """

    try:
        session_id = event.get('sessionId')
        status = event.get('status', 'soap_generated')
        soap_generated = event.get('soapGenerated', True)

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

        print(f"[UpdateSessionStatus] Updating session {session_id} status to {status}...")

        # Prepare update body
        update_body = {
            'finalization_status': status,
            'soap_generated': soap_generated,
            'updated_at': datetime.utcnow().isoformat() + 'Z',
        }

        # Update video_call_sessions table
        update_url = f"{supabase_url}/rest/v1/video_call_sessions?id=eq.{session_id}"
        update_response = requests.patch(
            update_url,
            headers=headers,
            json=update_body,
            timeout=10
        )

        if update_response.status_code not in [200, 204]:
            raise Exception(f"Failed to update session status: {update_response.text}")

        print(f"[UpdateSessionStatus] Successfully updated session {session_id} to {status}")

        return {
            'statusCode': 200,
            'sessionId': session_id,
            'status': status,
            'soapGenerated': soap_generated,
            'message': 'Session status updated successfully'
        }

    except ValueError as e:
        print(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'error': 'InvalidInput',
            'message': str(e)
        }
    except Exception as e:
        print(f"Error updating session status: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'UpdateSessionStatusFailed',
            'message': str(e)
        }
