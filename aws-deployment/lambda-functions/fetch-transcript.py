"""
MedZen Lambda: Fetch Transcript from Supabase
Retrieves the call transcript from Supabase based on sessionId or transcriptId
"""

import json
import boto3
import os
from datetime import datetime
import requests

def lambda_handler(event, context):
    """
    Fetches transcript from Supabase database

    Input:
    {
        "sessionId": "uuid",
        "transcriptId": "uuid" (optional)
    }

    Output:
    {
        "transcriptId": "uuid",
        "sessionId": "uuid",
        "rawText": "full transcript...",
        "speakerMap": {...},
        "totalDuration": 3600,
        "confidence": 0.95,
        "source": "chime_live"
    }
    """

    try:
        session_id = event.get('sessionId')
        transcript_id = event.get('transcriptId')

        if not session_id:
            raise ValueError("sessionId is required")

        # Supabase configuration from environment
        supabase_url = os.environ['SUPABASE_URL']
        supabase_key = os.environ['SUPABASE_SERVICE_KEY']

        # Build query
        if transcript_id:
            # Query by transcript ID (faster)
            query = f"{supabase_url}/rest/v1/call_transcripts?id=eq.{transcript_id}&select=*"
        else:
            # Query by session ID (get most recent)
            query = f"{supabase_url}/rest/v1/call_transcripts?session_id=eq.{session_id}&order=created_at.desc&limit=1&select=*"

        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }

        response = requests.get(query, headers=headers, timeout=10)
        response.raise_for_status()

        data = response.json()
        if not data or len(data) == 0:
            raise ValueError(f"No transcript found for sessionId: {session_id}")

        transcript = data[0]

        return {
            'statusCode': 200,
            'transcriptId': transcript['id'],
            'sessionId': transcript['session_id'],
            'rawText': transcript['raw_text'] or '',
            'speakerMap': transcript.get('speaker_map', {}),
            'totalDuration': transcript.get('total_duration_seconds', 0),
            'confidence': float(transcript.get('confidence_overall', 0.85)),
            'source': transcript.get('source', 'chime_live'),
            'processingStatus': transcript.get('processing_status', 'completed'),
            'totalSegments': transcript.get('total_segments', 0)
        }

    except Exception as e:
        print(f"Error fetching transcript: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'FetchTranscriptFailed',
            'message': str(e)
        }
