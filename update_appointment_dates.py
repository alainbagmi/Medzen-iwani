#!/usr/bin/env python3
import requests
import json
from datetime import datetime

SUPABASE_URL = "https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json"
}

# Get all scheduled appointments
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/appointments",
    headers=headers,
    params={"select": "id,scheduled_start,scheduled_end", "status": "eq.scheduled"}
)

appointments = response.json()
print(f"Found {len(appointments)} scheduled appointments to update")

# Update each appointment
for appt in appointments:
    appt_id = appt['id']

    # Extract times from existing timestamps
    start_dt = datetime.fromisoformat(appt['scheduled_start'].replace('Z', '+00:00'))
    end_dt = datetime.fromisoformat(appt['scheduled_end'].replace('Z', '+00:00'))

    # Create new timestamps with today's date (2025-12-14)
    new_start = f"2025-12-14T{start_dt.strftime('%H:%M:%S')}+00:00"
    new_end = f"2025-12-14T{end_dt.strftime('%H:%M:%S')}+00:00"

    # Update the appointment
    update_response = requests.patch(
        f"{SUPABASE_URL}/rest/v1/appointments",
        headers=headers,
        params={"id": f"eq.{appt_id}"},
        json={
            "scheduled_start": new_start,
            "scheduled_end": new_end,
            "start_date": "2025-12-14"
        }
    )

    if update_response.status_code in [200, 204]:
        print(f"✓ Updated appointment {appt_id[:8]}")
    else:
        print(f"✗ Failed to update {appt_id[:8]}: {update_response.text}")

print("\n=== Verification ===")
# Verify the updates
verify_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/appointments",
    headers=headers,
    params={
        "select": "appointment_number,scheduled_start,scheduled_end,status",
        "status": "eq.scheduled",
        "order": "scheduled_start.asc",
        "limit": "20"
    }
)

for appt in verify_response.json():
    start = appt['scheduled_start'][:16]
    end = appt['scheduled_end'][:16]
    print(f"{appt['appointment_number']}: {start} → {end}")
