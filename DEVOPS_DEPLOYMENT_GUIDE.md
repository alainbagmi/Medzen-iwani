# IT/DevOps Production Deployment Guide
## Patient Medical History System

**Status:** Ready for Production
**Deployment Target:** Production (`noaeltglphdlkbflipit`)
**Estimated Downtime:** 5 minutes
**Rollback Time:** < 10 minutes

---

## Pre-Deployment Checklist

### 1. Obtain Clinical Approval
- [ ] Medical directors have reviewed system
- [ ] Clinical sign-off document received and filed
- [ ] Any clinical conditions documented
- [ ] Legal/compliance team approval (if required)

### 2. Verify System Components
- [ ] All 4 edge functions deployed (see versions below)
- [ ] Database migrations applied (run: `npx supabase migration list`)
- [ ] Supabase connection active
- [ ] Firebase Auth configured correctly
- [ ] RLS policies in place

### 3. Notify Stakeholders
- [ ] Clinical team notified of deployment window
- [ ] IT support team briefed
- [ ] Patient/provider communications scheduled
- [ ] Support contact list prepared

### 4. Prepare Rollback Plan
- [ ] Rollback procedure reviewed (see section below)
- [ ] Point-in-time recovery coordinates noted
- [ ] Edge function previous versions documented
- [ ] Database backup confirmed available

---

## Deployment Steps

### Step 1: Pre-Deployment Database Snapshot
**Time: 2 minutes**

```bash
# Create database backup point (Supabase Dashboard)
# Settings → Backups → Request backup
# Note backup timestamp: _______________
```

Or via Supabase CLI:
```bash
npx supabase db pull --db-only --project-ref noaeltglphdlkbflipit
# This saves current schema locally
```

**Verification:**
- [ ] Backup created successfully
- [ ] Timestamp recorded

### Step 2: Verify Edge Function Deployment Status
**Time: 5 minutes**

```bash
npx supabase functions list --project-ref noaeltglphdlkbflipit
```

**Expected Output:**
```
Name                              Version  Active  Updated At
create-context-snapshot           v11      yes     [recent]
get-patient-history              v3       yes     [recent]
update-patient-medical-record    v4       yes     [recent]
generate-soap-draft-v2           v13      yes     [recent]
```

**Verification Checks:**
- [ ] All 4 functions show as "yes" under Active
- [ ] All functions deployed within last 24 hours
- [ ] No recent error deployments

### Step 3: Execute Test Data Cleanup
**Time: 2 minutes**

If test data still exists from E2E testing:

**Via Supabase Dashboard:**
1. Navigate to SQL Editor → New Query
2. Copy/paste cleanup script (from PRODUCTION_DEPLOYMENT_FINAL.md)
3. Execute and verify all cleanup counts = 0

**Or via CLI:**
```bash
# Save cleanup SQL to file
cat > /tmp/cleanup.sql << 'EOF'
DELETE FROM public.soap_notes
WHERE id IN ('c5b820ae-3f82-471d-b875-9af8b2b0ec0b', '298d5300-df6d-4645-9f3e-ab8df13a97f6');

DELETE FROM public.appointments
WHERE id IN ('d1747d20-00b8-4ef3-9f12-44dd3d5f9b41', '049f2f4f-be5a-4ef6-86ff-002709d22294');

DELETE FROM public.video_call_sessions
WHERE id = '9badb5d0-cb5f-4b56-89c0-10dcefc65296';

DELETE FROM public.patient_profiles
WHERE user_id = '805148ca-76b5-48b2-88e7-0ebfd13bc580';

DELETE FROM public.medical_provider_profiles
WHERE user_id = 'cb184de2-68c6-4fa7-98dc-885d6e5c244e';

DELETE FROM public.users
WHERE id IN ('805148ca-76b5-48b2-88e7-0ebfd13bc580', 'cb184de2-68c6-4fa7-98dc-885d6e5c244e');
EOF

# Execute via psql (requires db admin credentials)
psql "postgresql://[user]:[password]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres" \
  -f /tmp/cleanup.sql
```

**Verification:**
- [ ] All test records deleted (0 counts returned)
- [ ] No errors in execution

### Step 4: Production Environment Variables Verification
**Time: 3 minutes**

Verify all edge functions have correct environment variables set:

**In Supabase Dashboard → Edge Functions → Settings:**

```bash
# For each function, verify:
SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co
SUPABASE_ANON_KEY=[your-anon-key]
FIREBASE_PROJECT_ID=medzen-bf20e
FIREBASE_ADMIN_KEY=[json-format-key]
OPENEHR_URL=[if applicable]
AWS_REGION=eu-central-1
TRANSCRIBE_ROLE_ARN=[if applicable]
```

**Verification:**
- [ ] No secrets hardcoded in functions
- [ ] All environment variables set
- [ ] Firebase credentials valid
- [ ] No placeholder values

### Step 5: Verify Database Schema
**Time: 5 minutes**

Run schema verification queries:

```bash
npx supabase db remote list --project-ref noaeltglphdlkbflipit
```

Verify these tables exist:
- [ ] `patient_profiles` (with columns: cumulative_medical_record, medical_record_last_updated_at, medical_record_last_soap_note_id)
- [ ] `soap_notes` (main SOAP table)
- [ ] `soap_subjective_allergies` (normalized)
- [ ] `soap_plan_medication` (normalized)
- [ ] `soap_assessment_problem_list` (normalized)
- [ ] `soap_objective_vital_signs` (normalized)
- [ ] Plus 8 additional normalized SOAP tables

Verify merge function exists:
```sql
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'merge_soap_into_cumulative_record';
-- Should return 1 row
```

**Verification:**
- [ ] All required tables present
- [ ] Merge function present
- [ ] No schema errors

### Step 6: RLS Policy Verification
**Time: 3 minutes**

Verify Row-Level Security policies are in place:

```bash
npx supabase db pull --schema-only --project-ref noaeltglphdlkbflipit
# Then review: lib/flutter_flow/migrations/policies.sql
```

**Key RLS Policies to Verify:**
- [ ] `patient_profiles` - Patients see own records, providers see their patients
- [ ] `soap_notes` - Providers see their own notes, patients see their records
- [ ] `medical_provider_profiles` - Patients see providers, providers see self

**Verification:**
- [ ] All RLS policies enabled
- [ ] No policies grant excessive permissions
- [ ] Firebase auth integration working (auth.uid() checks)

---

## Deployment Execution Window

### During Deployment (5-minute window)

**Announce to stakeholders:**
```
🔧 System Deployment: Patient Medical History System is being deployed
   Duration: ~5 minutes
   Impact: Brief delay in medical history retrieval (~1-2 seconds)
   Expected completion: [TIME]
```

### Health Checks During Deployment

Monitor logs in real-time:

```bash
# Terminal 1: Monitor function logs
npx supabase functions logs update-patient-medical-record --tail --project-ref noaeltglphdlkbflipit

# Terminal 2: Monitor database connections
# Via Supabase Dashboard → Settings → Database → Connection Info
# Watch for connection pool exhaustion

# Terminal 3: Monitor errors
npx supabase functions logs create-context-snapshot --tail --project-ref noaeltglphdlkbflipit
```

**Things to Watch For:**
- ❌ Functions returning 500 errors
- ❌ Database connection timeouts
- ❌ RLS policy violations (403 errors)
- ❌ Firebase token validation failures (401 errors)
- ⚠️ Response times > 5 seconds (investigate after deployment)

---

## Post-Deployment Verification (Within 30 minutes)

### 1. Function Health Check
**Time: 5 minutes**

```bash
# Test each function with real credentials
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/get-patient-history \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "[REAL_TEST_PATIENT_ID]",
    "appointmentId": "[REAL_APPOINTMENT_ID]"
  }'

# Expected: { "success": true, "hasHistory": [true|false], ... }
```

**Verification:**
- [ ] Function returns 200 OK
- [ ] Response includes expected fields
- [ ] No error codes (401, 403, 500)
- [ ] Response time < 2 seconds

### 2. Database Query Performance Check
**Time: 5 minutes**

```sql
-- Check if merge function executed recently
SELECT
  user_id,
  medical_record_last_updated_at,
  jsonb_object_keys(cumulative_medical_record) as record_keys,
  jsonb_array_length(cumulative_medical_record->'conditions') as condition_count
FROM patient_profiles
WHERE medical_record_last_updated_at > NOW() - INTERVAL '1 hour'
LIMIT 5;

-- Expected: Recent timestamps, proper JSONB structure
```

**Verification:**
- [ ] Query returns results within 1 second
- [ ] JSONB structure is valid
- [ ] No NULL values in required fields

### 3. Error Rate Check
**Time: 5 minutes**

```bash
# Check error logs from past 30 minutes
npx supabase functions logs update-patient-medical-record --tail --project-ref noaeltglphdlkbflipit

# Expected: No ERROR or FATAL level logs
# Expected: Occasional INFO logs showing successful executions
```

**Verification:**
- [ ] Error rate < 1%
- [ ] No recurring errors
- [ ] All function invocations completing

### 4. Provider Login & Feature Access Check
**Time: 10 minutes**

**Manual Testing (have provider team test):**
1. Provider logs into app
2. Navigates to patient appointment
3. Pre-call dialog loads (should show patient medical history)
4. Completes call
5. SOAP notes dialog appears (should be ready to document)
6. Saves SOAP note

**Expected Behavior:**
- ✅ Medical history displays (allergies, medications, conditions)
- ✅ SOAP form loads without errors
- ✅ No 401/403 authentication errors
- ✅ SOAP saves and triggers merge function
- ✅ Follow-up: New appointment shows updated history

**Verification:**
- [ ] Pre-call medical history displays correctly
- [ ] No UI errors in console
- [ ] SOAP save completes successfully
- [ ] Post-call update triggered

### 5. Database Size Check
**Time: 3 minutes**

```bash
# Monitor storage growth
# Via Supabase Dashboard → Settings → Database → Storage
# Note: Expected growth from SOAP notes + cumulative records
```

**Verification:**
- [ ] Database size increase reasonable (< 100MB expected)
- [ ] No runaway queries consuming resources
- [ ] Connection pool not exhausted

---

## Monitoring Dashboard Setup (Ongoing)

### Real-Time Monitoring

**Enable Function Metrics:**
```bash
# In Supabase Dashboard → Edge Functions → [Function Name]
# Enable: Execution metrics, Error rates, Response times
```

**Create Alert Rules (if available):**
- [ ] Alert if function error rate > 5%
- [ ] Alert if function response time > 5 seconds
- [ ] Alert if database connections > 80% of pool

### Log Aggregation

**Centralize logs for quick access:**
```bash
# Save logs to file for analysis
npx supabase functions logs all --tail --project-ref noaeltglphdlkbflipit > /var/log/supabase-functions.log

# Monitor key events
tail -f /var/log/supabase-functions.log | grep -E "ERROR|FATAL|merge_soap"
```

---

## Rollback Procedure (If Needed)

### Immediate Rollback (< 10 minutes)

**Step 1: Disable New Functionality in App**

Edit in FlutterFlow or code:
```dart
// Temporarily disable cumulative record updates
bool enableCumulativeRecordUpdates = false;  // Set to false

// Comment out call to update-patient-medical-record
// Until issue is resolved
```

Re-deploy app update (or notify users app restart required)

**Step 2: Stop Edge Function Execution**

```bash
# Revert function to previous version
npx supabase functions deploy update-patient-medical-record \
  --project-ref noaeltglphdlkbflipit \
  --version v3  # Previous stable version
```

**Step 3: Verify Rollback**

```bash
# Test previous function version
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record \
  -d '{"test": true}'

# Check logs for previous version behavior
```

### Database Rollback (If Data Corruption)

**Step 1: Restore from Backup**

```bash
# Via Supabase Dashboard:
# Settings → Backups → Choose snapshot timestamp → Restore
```

**Step 2: Verify Restoration**

```sql
-- Verify data integrity after restore
SELECT COUNT(*) as total_soap_notes FROM public.soap_notes;
SELECT COUNT(*) as total_appointments FROM public.appointments;
SELECT COUNT(DISTINCT user_id) as unique_patients FROM public.patient_profiles;
-- Compare to expected counts
```

**Step 3: Re-sync Any Missing Data**

```bash
# If restoration was recent, may need to re-create data
# from alternate source (audit logs, etc.)
```

### Complete Rollback Checklist

- [ ] App functionality disabled or reverted
- [ ] Edge functions reverted to previous version
- [ ] Database restored to backup point (if needed)
- [ ] RLS policies verified
- [ ] Provider team notified
- [ ] Root cause identified
- [ ] Post-incident review scheduled

---

## 24-Hour Monitoring Schedule

### Hour 0-4 (Immediate Post-Deployment)
**Frequency: Every 30 minutes**

- [ ] Function error rate < 2%
- [ ] Database response time < 500ms
- [ ] Provider feedback: No critical issues
- [ ] No memory/connection pool exhaustion

### Hour 4-12 (First Business Day)
**Frequency: Hourly**

- [ ] Function success rate > 98%
- [ ] Cumulative records being updated correctly
- [ ] No stuck/hanging queries
- [ ] Provider adoption rate (usage metrics)

### Hour 12-24 (Next Business Day Completion)
**Frequency: Every 4 hours**

- [ ] Sustained success rate > 99%
- [ ] Performance stable
- [ ] Provider feedback positive
- [ ] Ready for normal support transition

---

## Deployment Sign-Off

**Deployment Completed:** _____________________
**Verified By:** _____________________
**Date/Time:** _____________________

**Handoff to Support:**
- [ ] 24-hour monitoring complete
- [ ] All verification checks passed
- [ ] Support team briefed
- [ ] Escalation contacts provided
- [ ] Documentation updated

**Issues Encountered During Deployment:**
```
[Document any issues and how they were resolved]
```

**Notes for Future Deployments:**
```
[Document lessons learned and improvements for next time]
```

---

## Support Contact Matrix

**During Deployment (Deployment Hour):**
- Technical Lead: [Name] - [Phone]
- Database Admin: [Name] - [Phone]
- Clinical Liaison: [Name] - [Phone]

**Post-Deployment (24-Hour Period):**
- Duty Officer: [Name] - [Phone]
- Escalation: [Name] - [Email]

**Normal Support (After 24 Hours):**
- Primary Contact: [Name] - [Phone/Email]
- Secondary Contact: [Name] - [Phone/Email]

---

## Additional Resources

- **System Architecture:** See `PRODUCTION_DEPLOYMENT_FINAL.md` → "System Overview"
- **Database Schema:** See `supabase/migrations/20260117000000_*.sql`
- **Edge Function Source:** See `supabase/functions/*/index.ts`
- **RLS Policies:** See `supabase/migrations/` (policies section)
- **Rollback Plan:** See section above or contact technical lead

---

**Thank you for your careful execution of this deployment. Your attention to detail ensures a safe, stable production launch.**
