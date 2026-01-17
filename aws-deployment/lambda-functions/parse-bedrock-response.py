"""
MedZen Lambda: Parse Bedrock Response
Parses Claude 3 Opus response from Bedrock into structured SOAP JSON
"""

import json
import re
import uuid
from datetime import datetime

def lambda_handler(event, context):
    """
    Parses Bedrock response into structured SOAP note

    Input:
    {
        "bedrockResponse": {
            "content": [
                {
                    "type": "text",
                    "text": "JSON string of SOAP note..."
                }
            ]
        },
        "sessionId": "uuid"
    }

    Output:
    {
        "statusCode": 200,
        "soapNoteId": "uuid",
        "sessionId": "uuid",
        "sections": {
            "chief_complaint": "...",
            "subjective": {...},
            "objective": {...},
            "assessment": {...},
            "plan": {...}
        },
        "rawResponse": {...},
        "generatedAt": "2026-01-15T..."
    }
    """

    try:
        bedrock_response = event.get('bedrockResponse', {})
        session_id = event.get('sessionId')

        if not session_id:
            raise ValueError("sessionId is required")

        print(f"[Parse] Parsing Bedrock response for session {session_id}...")

        # Extract text from Bedrock response
        # Bedrock returns: { "content": [ { "type": "text", "text": "..." } ] }
        content_blocks = bedrock_response.get('content', [])

        response_text = ""
        for block in content_blocks:
            if block.get('type') == 'text':
                response_text = block.get('text', '')
                break

        if not response_text:
            raise ValueError("No text content in Bedrock response")

        print(f"[Parse] Extracted response text: {len(response_text)} characters")

        # Try to extract JSON from response
        # Claude might wrap it in markdown code blocks
        soap_json = extract_json_from_response(response_text)

        if not soap_json:
            raise ValueError("Could not extract valid JSON from Bedrock response")

        # Validate required SOAP sections
        required_sections = ['chief_complaint', 'subjective', 'objective', 'assessment', 'plan']
        for section in required_sections:
            if section not in soap_json:
                print(f"[Parse] Warning: Missing section '{section}', adding empty placeholder")
                soap_json[section] = {}

        # Generate SOAP note ID
        soap_note_id = str(uuid.uuid4())
        generated_at = datetime.utcnow().isoformat() + 'Z'

        # Structure for database storage
        parsed_soap = {
            'soapNoteId': soap_note_id,
            'sessionId': session_id,
            'sections': {
                'chief_complaint': soap_json.get('chief_complaint', ''),
                'subjective': soap_json.get('subjective', {}),
                'objective': soap_json.get('objective', {}),
                'assessment': soap_json.get('assessment', {}),
                'plan': soap_json.get('plan', {}),
            },
            'medicalCodes': soap_json.get('medical_codes', {}),
            'rawResponse': soap_json,
            'generatedAt': generated_at,
            'processingStatus': 'completed',
        }

        print(f"[Parse] SOAP parsing complete, ID: {soap_note_id}")

        return {
            'statusCode': 200,
            'soapNoteId': soap_note_id,
            'sessionId': session_id,
            'sections': parsed_soap['sections'],
            'medicalCodes': parsed_soap['medicalCodes'],
            'rawResponse': parsed_soap['rawResponse'],
            'generatedAt': generated_at,
        }

    except Exception as e:
        print(f"Error parsing Bedrock response: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'ParseBedtrockResponseFailed',
            'message': str(e)
        }


def extract_json_from_response(response_text):
    """
    Extract and parse JSON from Claude's response
    Handles markdown code blocks and raw JSON
    """

    # Try to find JSON in markdown code blocks first
    json_match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', response_text, re.DOTALL)

    if json_match:
        json_str = json_match.group(1).strip()
    else:
        # Try to find raw JSON object
        # Look for opening brace
        brace_index = response_text.find('{')
        if brace_index != -1:
            json_str = response_text[brace_index:]
        else:
            return None

    try:
        # Try to parse as JSON
        soap_data = json.loads(json_str)
        return soap_data
    except json.JSONDecodeError as e:
        print(f"[Parse] JSON decode error: {str(e)}")

        # Try to fix common issues
        # Remove trailing commas
        json_str = re.sub(r',(\s*[}\]])', r'\1', json_str)

        try:
            soap_data = json.loads(json_str)
            return soap_data
        except json.JSONDecodeError:
            return None


def validate_soap_structure(soap_json):
    """
    Validates that SOAP JSON has expected structure
    """

    expected_sections = {
        'chief_complaint': str,
        'subjective': dict,
        'objective': dict,
        'assessment': dict,
        'plan': dict,
    }

    for section, expected_type in expected_sections.items():
        if section not in soap_json:
            return False

        if not isinstance(soap_json[section], expected_type):
            return False

    return True
