# User Testing Scripts README

**Purpose**: Test and manage user creation flow for MedZen healthcare application

**Created**: 2025-12-16

---

## Overview

This directory contains scripts for:
1. **Testing** - Verify `onUserCreated` function works correctly across all systems
2. **Deletion** - Safely delete test users from all integrated systems
3. **Verification** - Check user data exists in expected locations

---

## Scripts Available

### 1. `test_user_creation_complete.js` (Node.js)

**Purpose**: Complete end-to-end test of user creation flow

**What it does**:
- Creates test user in Firebase Auth
- Waits for `onUserCreated` Cloud Function to execute
- Verifies user created in all 4 systems:
  - Firebase Auth ✓
  - Firebase Firestore ✓
  - Supabase Auth ✓
  - Supabase Database ✓
  - EHRbase ✓
  - electronic_health_records table ✓

**Prerequisites**:
```bash
# Install dependencies (if not already installed)
cd firebase/functions && npm install

# Set environment variables
export SUPABASE_SERVICE_KEY="your-supabase-service-role-key"
export EHRBASE_PASSWORD="your-ehrbase-password"

# Optional (defaults provided)
export SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
export EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
export EHRBASE_USERNAME="ehrbase-admin"
```

**Usage**:
```bash
# Test user creation
node test_user_creation_complete.js --email testuser123@example.com --password TestPass123!

# Cleanup all test users (emails starting with 'test')
node test_user_creation_complete.js --cleanup

# Show help
node test_user_creation_complete.js --help
```

**Example Output**:
```
✅ Firebase Admin initialized
ℹ️  ═══════════════════════════════════════════════════════════════
ℹ️    MedZen User Creation Test
ℹ️  ═══════════════════════════════════════════════════════════════

ℹ️  📝 Step 1: Creating Firebase Auth user...
✅ Created Firebase Auth user: abc123xyz
   Email: testuser123@example.com
   UID: abc123xyz

ℹ️  📝 Step 2: Waiting for onUserCreated Cloud Function (~5 seconds)...
✅ Wait complete - checking results...

ℹ️  📝 Step 3: Verifying Firebase Firestore...
✅ Found Firestore document
   Supabase User ID: def456uvw

ℹ️  📝 Step 4: Verifying Supabase Auth and Database...
✅ Found Supabase Auth user: def456uvw
   Email: testuser123@example.com
   Email Confirmed: Yes

✅ Found Supabase users table record
   ID: def456uvw
   Email: testuser123@example.com
   Firebase UID: abc123xyz
   Created At: 2025-12-16T10:30:45.123Z

ℹ️  📝 Step 5: Verifying electronic_health_records...
✅ Found electronic_health_records entry
   EHR ID: ghi789rst
   Patient ID: def456uvw
   Created At: 2025-12-16T10:30:46.456Z

ℹ️  📝 Step 6: Verifying EHRbase EHR...
✅ Found EHR in EHRbase
   EHR ID: ghi789rst
   System ID: ehr.medzenhealth.app
   Time Created: 2025-12-16T10:30:46.789Z

ℹ️  ═══════════════════════════════════════════════════════════════
ℹ️    Test Results
ℹ️  ═══════════════════════════════════════════════════════════════

  Firebase Auth:           ✅ PASS
  Firebase Firestore:      ✅ PASS
  Supabase Auth:           ✅ PASS
  Supabase Database:       ✅ PASS
  EHR Record (Supabase):   ✅ PASS
  EHRbase EHR:             ✅ PASS

✅ 🎉 All tests PASSED!

ℹ️  Duration: 5432ms
```

---

### 2. `delete_user_complete.js` (Node.js)

**Purpose**: Delete a user from ALL systems including Firebase Auth/Firestore

**What it does**:
- Looks up user by email, Firebase UID, or Supabase ID
- Deletes from all systems:
  - Firebase Auth ✓
  - Firebase Firestore ✓
  - Supabase Auth ✓
  - Supabase Database (CASCADE) ✓
  - EHRbase ✓

**Prerequisites**: Same as test script

**Usage**:
```bash
# Delete by email (dry-run first recommended)
node delete_user_complete.js --email testuser@example.com --dry-run --verbose

# Actually delete
node delete_user_complete.js --email testuser@example.com --verbose

# Delete by Firebase UID
node delete_user_complete.js --firebase-uid abc123xyz --verbose

# Delete by Supabase ID
node delete_user_complete.js --supabase-id def456uvw --verbose

# Show help
node delete_user_complete.js --help
```

**Example Output**:
```
✅ Firebase Admin initialized
ℹ️  ═══════════════════════════════════════════════════════════════
ℹ️    MedZen Complete User and EHR Deletion Script
ℹ️  ═══════════════════════════════════════════════════════════════

⚠️  🔍 DRY-RUN MODE - No actual deletions will be performed

ℹ️  📝 Step 1: Looking up user in Supabase...
✅ Found user in Supabase:
   Supabase ID: def456uvw
   Email: testuser@example.com
   Firebase UID: abc123xyz

ℹ️  📝 Step 2: Looking up EHR record...
✅ Found EHR record: ghi789rst

ℹ️  📝 Step 3: Looking up Firebase user...
✅ Found Firebase user:
   UID: abc123xyz
   Email: testuser@example.com
   Email Verified: true

ℹ️  ═══════════════════════════════════════════════════════════════
ℹ️    Deletion Summary
ℹ️  ═══════════════════════════════════════════════════════════════

ℹ️  The following data will be deleted:

  📧 Email: testuser@example.com
  🔥 Firebase UID: abc123xyz
  🗄️  Supabase ID: def456uvw
  🏥 EHR ID: ghi789rst

ℹ️  Affected systems:
  ✓ Firebase Auth user
  ✓ Firebase Firestore documents
  ✓ Supabase Auth user
  ✓ Supabase users table record
  ✓ All related medical data (CASCADE)
  ✓ EHRbase EHR record

⚠️  Proceeding with deletion in 3 seconds... (Ctrl+C to cancel)

ℹ️  📝 Step 4: Deleting from Supabase database (CASCADE)...
⚠️  [DRY-RUN] Would delete user from Supabase users table
   This would CASCADE delete all related records

... (continues for all steps)

ℹ️  ═══════════════════════════════════════════════════════════════
ℹ️    Dry-Run Complete
ℹ️  ═══════════════════════════════════════════════════════════════

ℹ️  This was a dry-run. No actual deletions were performed.
```

---

### 3. `delete_user_and_ehr.sh` (Bash)

**Purpose**: Shell script version of user deletion (no Firebase Admin SDK)

**What it does**:
- Deletes from Supabase systems only (Auth + Database + EHRbase)
- Provides instructions for manual Firebase deletion
- Good for environments where Firebase Admin SDK not available

**Prerequisites**:
```bash
# Set environment variables
export SUPABASE_SERVICE_KEY="your-supabase-service-role-key"
export EHRBASE_PASSWORD="your-ehrbase-password"

# Optional (defaults provided)
export SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
export EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
export EHRBASE_USERNAME="ehrbase-admin"

# Make executable
chmod +x delete_user_and_ehr.sh
```

**Usage**:
```bash
# Dry-run first (recommended)
./delete_user_and_ehr.sh --email testuser@example.com --dry-run --verbose

# Actually delete
./delete_user_and_ehr.sh --email testuser@example.com --verbose

# Delete by Firebase UID
./delete_user_and_ehr.sh --firebase-uid abc123xyz --verbose

# Delete by Supabase ID
./delete_user_and_ehr.sh --supabase-id def456uvw --verbose

# Show help
./delete_user_and_ehr.sh --help
```

**Note**: This script cannot delete from Firebase Auth/Firestore. You'll need to run:
```bash
firebase auth:delete <firebase-uid> --force
firebase firestore:delete users/<firebase-uid> --recursive
```

---

## Typical Workflows

### Workflow 1: Test User Creation

```bash
# 1. Create test user
node test_user_creation_complete.js \
  --email testuser$(date +%s)@example.com \
  --password TestPass123!

# 2. Review results
# All systems should show ✅ PASS

# 3. Check Firebase Functions logs (if any failures)
firebase functions:log --limit 50

# 4. Clean up test user
node delete_user_complete.js \
  --email testuser@example.com \
  --verbose
```

### Workflow 2: Batch Test Multiple Users

```bash
# Create 5 test users
for i in {1..5}; do
  echo "Creating test user $i..."
  node test_user_creation_complete.js \
    --email "testuser${i}@example.com" \
    --password "TestPass123!"
  sleep 2
done

# Cleanup all at once
node test_user_creation_complete.js --cleanup
```

### Workflow 3: Debug Failed User Creation

```bash
# 1. Attempt user creation
node test_user_creation_complete.js \
  --email debugtest@example.com \
  --password TestPass123!

# 2. If failures, check Firebase Functions logs
firebase functions:log --limit 100 | grep -A 10 "onUserCreated"

# 3. Check Firebase Functions configuration
firebase functions:config:get

# 4. Verify Supabase connection
curl -X GET \
  "${SUPABASE_URL}/rest/v1/users?select=count" \
  -H "apikey: ${SUPABASE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}"

# 5. Verify EHRbase connection
curl -X GET \
  "${EHRBASE_URL}/rest/openehr/v1/" \
  -u "${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}"

# 6. Clean up failed user (if needed)
node delete_user_complete.js \
  --email debugtest@example.com \
  --verbose
```

---

## Environment Variables Reference

### Required

| Variable | Description | How to Get |
|----------|-------------|------------|
| `SUPABASE_SERVICE_KEY` | Supabase service role key | Supabase Dashboard → Settings → API → service_role key |

### Optional (have defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `SUPABASE_URL` | `https://noaeltglphdlkbflipit.supabase.co` | Supabase project URL |
| `EHRBASE_URL` | `https://ehr.medzenhealth.app/ehrbase` | EHRbase REST API URL |
| `EHRBASE_USERNAME` | `ehrbase-admin` | EHRbase username |
| `EHRBASE_PASSWORD` | (none) | EHRbase password (required for EHRbase operations) |

### Setting Environment Variables

**macOS/Linux** (temporary - current session only):
```bash
export SUPABASE_SERVICE_KEY="your-key-here"
export EHRBASE_PASSWORD="your-password-here"
```

**macOS/Linux** (permanent - add to `~/.zshrc` or `~/.bashrc`):
```bash
echo 'export SUPABASE_SERVICE_KEY="your-key-here"' >> ~/.zshrc
echo 'export EHRBASE_PASSWORD="your-password-here"' >> ~/.zshrc
source ~/.zshrc
```

**Windows** (PowerShell):
```powershell
$env:SUPABASE_SERVICE_KEY="your-key-here"
$env:EHRBASE_PASSWORD="your-password-here"
```

---

## Troubleshooting

### Issue: "SUPABASE_SERVICE_KEY environment variable is required"

**Solution**:
```bash
# Get service key from Supabase Dashboard
# Settings → API → service_role key (starts with eyJ...)
export SUPABASE_SERVICE_KEY="eyJ..."
```

### Issue: "Firebase Admin initialization failed"

**Solution**:
```bash
# Ensure Firebase Admin SDK credentials are configured
# Option 1: Set GOOGLE_APPLICATION_CREDENTIALS
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/firebase-adminsdk.json"

# Option 2: Use Firebase CLI login
firebase login
cd firebase/functions
npm install
```

### Issue: "User not found in Supabase database"

**Possible Causes**:
1. User was never created (check Firebase Functions logs)
2. User was already deleted
3. onUserCreated function failed

**Check**:
```bash
# View Firebase Functions logs
firebase functions:log --limit 50

# Check if onUserCreated deployed
firebase functions:list | grep onUserCreated
```

### Issue: "EHRbase authentication failed"

**Solution**:
```bash
# Verify EHRbase credentials
export EHRBASE_USERNAME="ehrbase-admin"
export EHRBASE_PASSWORD="your-actual-password"

# Test connection
curl -u "${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}" \
  "${EHRBASE_URL}/rest/openehr/v1/"
```

### Issue: Test passes but app login fails

**Possible Causes**:
1. Email not verified in Firebase Auth
2. Password doesn't meet requirements
3. App-specific user role not set

**Check**:
```bash
# Check Firebase Auth user
firebase auth:export users.json
cat users.json | jq '.users[] | select(.email=="testuser@example.com")'

# Check Supabase user record
curl -X GET \
  "${SUPABASE_URL}/rest/v1/users?email=eq.testuser@example.com&select=*" \
  -H "apikey: ${SUPABASE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" | jq '.'
```

---

## Data Verification Queries

### Check User in All Systems

**Firebase Auth**:
```bash
firebase auth:export users.json
cat users.json | jq '.users[] | select(.email=="testuser@example.com")'
```

**Supabase**:
```sql
-- Supabase Auth
SELECT * FROM auth.users WHERE email = 'testuser@example.com';

-- Supabase Database
SELECT * FROM users WHERE email = 'testuser@example.com';

-- EHR Record
SELECT ehr.*
FROM electronic_health_records ehr
JOIN users u ON ehr.patient_id = u.id
WHERE u.email = 'testuser@example.com';
```

**EHRbase**:
```bash
# Get EHR ID first from Supabase query above, then:
curl -X GET \
  "${EHRBASE_URL}/rest/openehr/v1/ehr/<ehr-id>" \
  -H "Accept: application/json" \
  -u "${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}" | jq '.'
```

---

## Best Practices

### 1. Always Use Unique Test Emails

```bash
# Good - timestamp ensures uniqueness
node test_user_creation_complete.js \
  --email "testuser$(date +%s)@example.com" \
  --password "TestPass123!"

# Avoid - may conflict with existing user
node test_user_creation_complete.js \
  --email "test@example.com" \
  --password "TestPass123!"
```

### 2. Dry-Run Before Deletion

```bash
# Always dry-run first to verify what will be deleted
node delete_user_complete.js --email test@example.com --dry-run --verbose

# Then delete if correct
node delete_user_complete.js --email test@example.com --verbose
```

### 3. Clean Up After Testing

```bash
# Cleanup all test users when done
node test_user_creation_complete.js --cleanup
```

### 4. Monitor Firebase Functions Logs

```bash
# Tail logs in real-time during testing
firebase functions:log --limit 50 --follow

# In another terminal, run tests
node test_user_creation_complete.js --email test@example.com --password Test123!
```

---

## Related Documentation

- **Template ID Issue**: `TEMPLATE_ID_ISSUE_AND_SOLUTION.md`
- **System Integration**: `SYSTEM_INTEGRATION_STATUS.md`
- **Testing Guide**: `TESTING_GUIDE.md`
- **Quick Start**: `QUICK_START.md`
- **Main Documentation**: `CLAUDE.md`

---

## Quick Command Reference

```bash
# Test user creation
node test_user_creation_complete.js --email test@example.com --password Test123!

# Delete user (all systems)
node delete_user_complete.js --email test@example.com --verbose

# Delete user (Supabase only - shell script)
./delete_user_and_ehr.sh --email test@example.com --verbose

# Cleanup all test users
node test_user_creation_complete.js --cleanup

# Check Firebase Functions logs
firebase functions:log --limit 50

# Check Firebase Functions config
firebase functions:config:get

# Deploy Firebase Functions
firebase deploy --only functions

# Check Supabase user
curl -X GET \
  "${SUPABASE_URL}/rest/v1/users?email=eq.test@example.com&select=*" \
  -H "apikey: ${SUPABASE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" | jq '.'
```

---

**Document Version**: 1.0
**Last Updated**: 2025-12-16
**Maintained By**: MedZen Development Team
