#!/usr/bin/env python3
"""
Update demo appointments to today's date (2026-01-08)
This script updates appointments with "Demo" in patient or provider names
Preserves time components while updating date portions
"""
import requests
import json
from datetime import datetime, date

SUPABASE_URL = "https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json"
}

# Today's date
TODAY = "2026-01-08"

print(f"=== Updating Demo Appointments to {TODAY} ===\n")

# Step 1: Get demo appointments from appointment_overview view
print("Step 1: Fetching demo appointments from appointment_overview...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/appointment_overview",
    headers=headers,
    params={
        "select": "id,appointment_number,patient_fullname,provider_fullname,scheduled_start,scheduled_end,appointment_start_date,status",
        "or": "(patient_fullname.ilike.*demo*,provider_fullname.ilike.*demo*)"
    }
)

if response.status_code != 200:
    print(f"✗ Failed to fetch appointments: {response.status_code}")
    print(response.text)
    exit(1)

demo_appointments = response.json()
print(f"Found {len(demo_appointments)} demo appointments\n")

if len(demo_appointments) == 0:
    print("No demo appointments found. Exiting.")
    exit(0)

# Show what we're about to update
print("=== Appointments to be updated ===")
for appt in demo_appointments[:10]:  # Show first 10
    print(f"  {appt['appointment_number']}: {appt['patient_fullname']} ↔ {appt['provider_fullname']}")
    print(f"    Current: {appt['scheduled_start'][:16]}")
if len(demo_appointments) > 10:
    print(f"  ... and {len(demo_appointments) - 10} more")
print()

# Step 2: Update each appointment
print(f"Step 2: Updating appointments to {TODAY}...\n")
updated_count = 0
failed_count = 0

for appt in demo_appointments:
    appt_id = appt['id']

    # Extract times from existing timestamps
    try:
        start_dt = datetime.fromisoformat(appt['scheduled_start'].replace('Z', '+00:00'))
        end_dt = datetime.fromisoformat(appt['scheduled_end'].replace('Z', '+00:00'))

        # Create new timestamps with today's date
        new_start = f"{TODAY}T{start_dt.strftime('%H:%M:%S')}+00:00"
        new_end = f"{TODAY}T{end_dt.strftime('%H:%M:%S')}+00:00"

        # Update the appointment
        update_response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/appointments",
            headers=headers,
            params={"id": f"eq.{appt_id}"},
            json={
                "scheduled_start": new_start,
                "scheduled_end": new_end,
                "start_date": TODAY,
                "updated_at": datetime.utcnow().isoformat() + "Z"
            }
        )

        if update_response.status_code in [200, 204]:
            print(f"✓ Updated {appt['appointment_number']} ({appt_id[:8]})")
            updated_count += 1
        else:
            print(f"✗ Failed to update {appt['appointment_number']}: {update_response.text}")
            failed_count += 1
    except Exception as e:
        print(f"✗ Error updating {appt['appointment_number']}: {str(e)}")
        failed_count += 1

print(f"\n=== Summary ===")
print(f"Total appointments: {len(demo_appointments)}")
print(f"Successfully updated: {updated_count}")
print(f"Failed: {failed_count}")

# Step 3: Verify the updates
print(f"\n=== Verification ===")
verify_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/appointment_overview",
    headers=headers,
    params={
        "select": "appointment_number,patient_fullname,provider_fullname,scheduled_start,status",
        "or": "(patient_fullname.ilike.*demo*,provider_fullname.ilike.*demo*)",
        "order": "scheduled_start.asc",
        "limit": "10"
    }
)

if verify_response.status_code == 200:
    print("\nFirst 10 updated demo appointments:")
    for appt in verify_response.json():
        start = appt['scheduled_start'][:16]
        patient = appt['patient_fullname'][:20]
        provider = appt['provider_fullname'][:20]
        print(f"  {appt['appointment_number']}: {start} | {patient} ↔ {provider}")
else:
    print(f"✗ Verification failed: {verify_response.status_code}")

print(f"\n✅ Demo appointments updated to {TODAY}!")
