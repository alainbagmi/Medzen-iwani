"""
MedZen Lambda: Enrich Transcript Metadata
Enriches the transcript with appointment metadata and builds the SOAP generation prompt
"""

import json
import os
import requests
from datetime import datetime

def lambda_handler(event, context):
    """
    Enriches transcript with appointment metadata

    Input:
    {
        "appointmentId": "uuid",
        "sessionId": "uuid",
        "transcript": {
            "transcriptId": "uuid",
            "rawText": "merged transcript...",
            "speakerMap": [...],
            "totalDuration": 3600
        }
    }

    Output:
    {
        "sessionId": "uuid",
        "appointmentId": "uuid",
        "transcriptId": "uuid",
        "enrichedData": {
            "appointment": {...},
            "provider": {...},
            "patient": {...},
            "transcriptSummary": "...",
            "generationPrompt": "..."
        }
    }
    """

    try:
        appointment_id = event.get('appointmentId')
        session_id = event.get('sessionId')
        transcript = event.get('transcript', {})

        if not appointment_id or not session_id:
            raise ValueError("appointmentId and sessionId are required")

        # Supabase configuration from environment
        supabase_url = os.environ['SUPABASE_URL']
        supabase_key = os.environ['SUPABASE_SERVICE_KEY']

        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }

        print(f"[Enrich] Fetching appointment data for {appointment_id}...")

        # Fetch appointment with related data
        appointment_query = f"{supabase_url}/rest/v1/appointments?id=eq.{appointment_id}&select=id,start_time,end_time,timezone,reason_for_visit,provider_id,patient_id,medical_provider_profiles(id,display_name,specialty),patient_profiles(id,display_name,age,gender)"

        response = requests.get(appointment_query, headers=headers, timeout=10)
        response.raise_for_status()

        data = response.json()
        if not data or len(data) == 0:
            raise ValueError(f"No appointment found for appointmentId: {appointment_id}")

        appointment = data[0]

        provider_data = appointment.get('medical_provider_profiles', {})
        patient_data = appointment.get('patient_profiles', {})

        print(f"[Enrich] Got appointment data: Provider={provider_data.get('display_name')}, Patient={patient_data.get('display_name')}")

        # Extract transcript text
        transcript_text = transcript.get('rawText', '')
        speaker_map = transcript.get('speakerMap', [])

        # Build enriched data structure
        enriched_data = {
            'appointment': {
                'id': appointment['id'],
                'startTime': appointment.get('start_time'),
                'endTime': appointment.get('end_time'),
                'timezone': appointment.get('timezone', 'UTC'),
                'reasonForVisit': appointment.get('reason_for_visit', 'General consultation'),
            },
            'provider': {
                'id': appointment.get('provider_id'),
                'name': provider_data.get('display_name', 'Provider'),
                'specialty': provider_data.get('specialty', 'General Practice'),
            },
            'patient': {
                'id': appointment.get('patient_id'),
                'name': patient_data.get('display_name', 'Patient'),
                'age': patient_data.get('age'),
                'gender': patient_data.get('gender'),
            },
            'transcript': {
                'totalDuration': transcript.get('totalDuration', 0),
                'segmentCount': transcript.get('totalSegments', 0),
                'speakerCount': len(speaker_map) if speaker_map else 0,
            }
        }

        # Build generation prompt for Claude 3 Opus
        prompt = build_soap_generation_prompt(
            transcript_text,
            enriched_data,
            speaker_map
        )

        enriched_data['generationPrompt'] = prompt

        print(f"[Enrich] Metadata enrichment complete, prompt length: {len(prompt)}")

        return {
            'statusCode': 200,
            'sessionId': session_id,
            'appointmentId': appointment_id,
            'transcriptId': transcript.get('transcriptId'),
            'enrichedData': enriched_data
        }

    except Exception as e:
        print(f"Error enriching metadata: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'MetadataEnrichmentFailed',
            'message': str(e)
        }


def build_soap_generation_prompt(transcript_text, enriched_data, speaker_map):
    """
    Builds the system and user prompt for SOAP note generation via Claude 3 Opus
    """

    appointment = enriched_data['appointment']
    provider = enriched_data['provider']
    patient = enriched_data['patient']

    prompt = f"""You are a medical scribe assistant helping to generate a clinical SOAP note from a doctor-patient conversation transcript.

CONTEXT INFORMATION:
- Provider: {provider['name']} ({provider['specialty']})
- Patient: {patient['name']} (Age: {patient.get('age', 'Unknown')}, Gender: {patient.get('gender', 'Unknown')})
- Chief Complaint: {appointment['reasonForVisit']}
- Appointment Date/Time: {appointment['startTime']} ({appointment['timezone']})
- Session Duration: {enriched_data['transcript']['totalDuration']} seconds

CONVERSATION TRANSCRIPT:
---
{transcript_text}
---

Please generate a comprehensive SOAP note based on this conversation. Structure your response as a JSON object with the following fields:

{{
  "chief_complaint": "Brief statement of patient's main complaint",
  "subjective": {{
    "history_of_present_illness": "Detailed narrative of current illness",
    "past_medical_history": "Relevant past medical conditions",
    "medications": "Current medications mentioned",
    "allergies": "Any allergies mentioned",
    "family_history": "Family history mentioned",
    "social_history": "Social factors that may affect health"
  }},
  "objective": {{
    "vital_signs": "Any vital signs mentioned",
    "physical_examination": "Examination findings",
    "diagnostic_results": "Lab results or test findings",
    "measurements": "Height, weight, BMI, etc."
  }},
  "assessment": {{
    "primary_diagnosis": "Primary diagnosis code and description",
    "differential_diagnoses": "Other possible diagnoses",
    "clinical_impression": "Overall clinical impression"
  }},
  "plan": {{
    "diagnosis_plan": "Plan for confirmed diagnoses",
    "medications": "Medications prescribed/continued",
    "procedures": "Any procedures recommended",
    "follow_up": "Follow-up instructions",
    "patient_education": "Education provided to patient",
    "referrals": "Referrals to specialists if needed"
  }},
  "medical_codes": {{
    "icd10": "ICD-10 diagnosis codes",
    "cpt": "CPT procedure codes"
  }}
}}

IMPORTANT GUIDELINES:
1. Extract ONLY information explicitly mentioned in the transcript
2. Use medical terminology appropriately for the SOAP format
3. Be concise but comprehensive
4. Mark uncertain or unclear information with [unclear from transcript]
5. Do NOT fabricate clinical information not mentioned
6. Follow standard medical documentation practices
7. Include clinical reasoning where appropriate
8. Ensure all sections are populated (use N/A if not mentioned in transcript)

Generate the SOAP note now:"""

    return prompt
