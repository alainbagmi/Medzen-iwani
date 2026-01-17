"""
MedZen Lambda: Send Notification for SOAP Generation
Sends real-time notification to provider when SOAP note is generated and ready for review
"""

import json
import os
import requests
from datetime import datetime


def lambda_handler(event, context):
    """
    Sends notification to provider when SOAP note is generated

    Input:
    {
        "type": "soap_generated",
        "providerId": "uuid",
        "soapNoteId": "uuid",
        "sessionId": "uuid"
    }

    Output:
    {
        "statusCode": 200,
        "notificationId": "uuid",
        "message": "Notification sent successfully"
    }
    """

    try:
        notification_type = event.get('type')
        provider_id = event.get('providerId')
        soap_note_id = event.get('soapNoteId')
        session_id = event.get('sessionId')

        if not all([notification_type, provider_id, soap_note_id, session_id]):
            raise ValueError("type, providerId, soapNoteId, and sessionId are required")

        # Supabase configuration
        supabase_url = os.environ['SUPABASE_URL']
        supabase_key = os.environ['SUPABASE_SERVICE_KEY']

        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }

        print(f"[Notification] Sending {notification_type} notification for SOAP {soap_note_id} to provider {provider_id}...")

        # Fetch provider details to get FCM token
        provider_query = f"{supabase_url}/rest/v1/users?id=eq.{provider_id}&select=id,fcm_token,display_name"
        provider_response = requests.get(provider_query, headers=headers, timeout=10)
        provider_response.raise_for_status()

        provider_data = provider_response.json()
        if not provider_data or len(provider_data) == 0:
            print(f"[Notification] Warning: Provider {provider_id} not found")
            return {
                'statusCode': 200,
                'message': f'Provider {provider_id} not found, skipping notification'
            }

        provider = provider_data[0]
        fcm_token = provider.get('fcm_token')
        provider_name = provider.get('display_name', 'Provider')

        # Fetch SOAP note details for notification content
        soap_query = f"{supabase_url}/rest/v1/soap_notes?id=eq.{soap_note_id}&select=id,appointment_id,chief_complaint"
        soap_response = requests.get(soap_query, headers=headers, timeout=10)
        soap_response.raise_for_status()

        soap_data = soap_response.json()
        if not soap_data or len(soap_data) == 0:
            raise ValueError(f"SOAP note {soap_note_id} not found")

        soap_note = soap_data[0]
        chief_complaint = soap_note.get('chief_complaint', 'Clinical Note')
        appointment_id = soap_note.get('appointment_id')

        # Prepare notification content based on type
        notification_content = build_notification_content(
            notification_type,
            soap_note_id,
            appointment_id,
            chief_complaint
        )

        # Store notification record in database
        notification_record = {
            'provider_id': provider_id,
            'soap_note_id': soap_note_id,
            'session_id': session_id,
            'notification_type': notification_type,
            'title': notification_content['title'],
            'body': notification_content['body'],
            'data': json.dumps(notification_content.get('data', {})),
            'status': 'sent',
            'created_at': datetime.utcnow().isoformat() + 'Z',
        }

        notification_url = f"{supabase_url}/rest/v1/call_notifications"
        notification_response = requests.post(
            notification_url,
            headers=headers,
            json=notification_record,
            timeout=10
        )

        if notification_response.status_code not in [200, 201]:
            print(f"[Notification] Warning: Failed to store notification record: {notification_response.text}")
            # Don't fail if notification record storage fails

        notification_id = None
        try:
            stored_notification = notification_response.json()
            if isinstance(stored_notification, list) and len(stored_notification) > 0:
                notification_id = stored_notification[0].get('id')
        except Exception as e:
            print(f"[Notification] Warning: Could not extract notification ID: {str(e)}")

        # Send FCM push notification if FCM token exists
        if fcm_token:
            send_fcm_notification(
                fcm_token,
                notification_content['title'],
                notification_content['body'],
                notification_content.get('data', {})
            )
            print(f"[Notification] Sent FCM push notification to provider {provider_id}")
        else:
            print(f"[Notification] Warning: No FCM token for provider {provider_id}, skipping push notification")

        print(f"[Notification] Successfully sent {notification_type} notification")

        return {
            'statusCode': 200,
            'notificationId': notification_id,
            'message': 'Notification sent successfully'
        }

    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'NotificationFailed',
            'message': str(e)
        }


def build_notification_content(notification_type, soap_note_id, appointment_id, chief_complaint):
    """
    Builds notification content based on type
    """

    if notification_type == 'soap_generated':
        return {
            'title': 'SOAP Note Ready',
            'body': f'Your clinical SOAP note for {chief_complaint} is ready for review',
            'data': {
                'type': 'soap_generated',
                'soapNoteId': soap_note_id,
                'appointmentId': appointment_id,
                'action': 'review_soap'
            }
        }
    elif notification_type == 'soap_error':
        return {
            'title': 'SOAP Generation Failed',
            'body': f'Failed to generate SOAP note for {chief_complaint}. Please try again.',
            'data': {
                'type': 'soap_error',
                'soapNoteId': soap_note_id,
                'appointmentId': appointment_id,
                'action': 'retry_soap'
            }
        }
    elif notification_type == 'soap_pending':
        return {
            'title': 'SOAP Generation In Progress',
            'body': f'Generating clinical SOAP note for {chief_complaint}...',
            'data': {
                'type': 'soap_pending',
                'soapNoteId': soap_note_id,
                'appointmentId': appointment_id
            }
        }
    else:
        return {
            'title': 'Notification',
            'body': 'Your document is ready',
            'data': {
                'type': notification_type,
                'soapNoteId': soap_note_id
            }
        }


def send_fcm_notification(fcm_token, title, body, data):
    """
    Sends push notification via Firebase Cloud Messaging
    Requires FCM_SERVER_KEY environment variable
    """

    try:
        fcm_server_key = os.environ.get('FCM_SERVER_KEY')
        if not fcm_server_key:
            print("[Notification] Warning: FCM_SERVER_KEY not configured, skipping FCM push")
            return

        headers = {
            'Authorization': f'key={fcm_server_key}',
            'Content-Type': 'application/json'
        }

        payload = {
            'to': fcm_token,
            'notification': {
                'title': title,
                'body': body,
                'sound': 'default',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            },
            'data': data,
            'android': {
                'priority': 'high',
                'notification': {
                    'title': title,
                    'body': body,
                    'sound': 'default',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                    'channel_id': 'medzen_default'
                }
            },
            'apns': {
                'headers': {
                    'apns-priority': '10'
                },
                'payload': {
                    'aps': {
                        'alert': {
                            'title': title,
                            'body': body
                        },
                        'sound': 'default',
                        'badge': 1
                    }
                }
            }
        }

        response = requests.post(
            'https://fcm.googleapis.com/fcm/send',
            headers=headers,
            json=payload,
            timeout=10
        )

        if response.status_code == 200:
            print(f"[Notification] FCM notification sent successfully")
        else:
            print(f"[Notification] FCM error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"[Notification] Warning: Failed to send FCM notification: {str(e)}")
        # Don't fail the entire operation if FCM fails
