# 24-Hour Post-Deployment Monitoring Checklist
## Patient Medical History System

**Deployment Date:** _______________
**Deployment Time:** _______________
**Monitoring Lead:** _______________
**Support Team Contact:** _______________

---

## Quick Reference: What to Watch For

### 🔴 CRITICAL (Stop Everything)
- Function returning 500 errors consistently
- Database connection pool exhausted (> 95% used)
- RLS policies blocking legitimate access (403 errors)
- Data corruption or missing records
- System unable to merge medical records

### 🟠 MAJOR (Investigate Immediately)
- Function error rate > 5%
- Response times > 5 seconds consistently
- Merge function failing silently
- Provider reports: "Can't see patient history"
- Provider reports: "Notes didn't save"

### 🟡 MINOR (Monitor, Plan Fix)
- Response times 2-5 seconds
- Occasional timeouts (< 1 per hour)
- AI draft quality varies (< 80% complete)
- UI layout issues on mobile

### 🟢 INFO (Normal)
- Functions responding 200 OK
- Response times < 2 seconds
- Error rate < 1%
- Providers can see history
- Notes save successfully

---

## Timeline & Frequency

```
Hour 0    │ Hour 2    │ Hour 4    │ Hour 8    │ Hour 12   │ Hour 16   │ Hour 20   │ Hour 24
Deployment│ ✓✓✓✓ Check │ ✓✓✓ Check │ ✓✓ Check │ ✓ Check  │ ✓ Check  │ ✓ Check  │ Final
          │ Every 30min│Every hour │Every 2hr │Every 4hr │Every 4hr │Every 4hr │ report
```

---

## HOUR 0: Deployment Execution

### Immediately After Deployment (T+0-5 minutes)

**Time: ___:___**

- [ ] **Announce to stakeholders:** "Deployment in progress"
- [ ] **Start monitoring tabs:**
  ```bash
  # Terminal 1: Function logs
  npx supabase functions logs update-patient-medical-record --tail --project-ref noaeltglphdlkbflipit

  # Terminal 2: Check database connections
  # Supabase Dashboard → Settings → Database → Live Users
  # Watch for spikes > 80% of connection pool

  # Terminal 3: Health check script (optional)
  watch -n 5 'curl -s https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record'
  ```
- [ ] **Verify logs are flowing** (should see function invocations)
- [ ] **Check database connections** (should be normal levels)
- [ ] **No error spikes** in logs

**If any 🔴 CRITICAL issue:**
→ STOP immediately, initiate rollback (see ROLLBACK SECTION at end)

---

### T+5-10 minutes

**Time: ___:___**

- [ ] **Test basic function call:**
  ```bash
  curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/get-patient-history \
    -H "Content-Type: application/json" \
    -d '{"patientId": "[TEST_ID]", "appointmentId": "[TEST_ID]"}'
  ```
  Expected: `{ "success": true, ... }`
  Actual: _______________

- [ ] **Check error rate:** Should be 0-2%
  Error rate observed: ____%

- [ ] **Check database size** hasn't changed unexpectedly
  Size before: _________ | Size now: _________

- [ ] **All 4 functions responding:**
  - [ ] create-context-snapshot: ✅/❌ (response: __________)
  - [ ] get-patient-history: ✅/❌ (response: __________)
  - [ ] update-patient-medical-record: ✅/❌ (response: __________)
  - [ ] generate-soap-draft-v2: ✅/❌ (response: __________)

**Status:** [ ] Green | [ ] Yellow | [ ] Red

---

### T+10-15 minutes

**Time: ___:___**

- [ ] **Notify providers** deployment is complete
- [ ] **Prepare test patient:** Arrange brief test call with willing provider
- [ ] **Gather support contacts** for escalation
- [ ] **Set up monitoring dashboard:**
  ```
  Browser Tab 1: Supabase Functions Dashboard
  Browser Tab 2: Edge Function Logs
  Browser Tab 3: Database Metrics
  ```

**Status:** Ready for provider testing

---

## HOURS 1-4: Intensive Monitoring (Every 30 minutes)

### Health Check Template (Repeat Every 30 Minutes)

**Check Time: ___:___** (Hour ____)

#### A. Function Health

```bash
# Get function stats
npx supabase functions list --project-ref noaeltglphdlkbflipit
```

**Checklist:**
- [ ] All 4 functions showing "Active: yes"
- [ ] Recent executions (not old)
- [ ] No rapid deployment cycles (indicates repeated failures)

**Observation:**
```
Function Name                         Active  Last Deploy
create-context-snapshot              [ ]     ________
get-patient-history                  [ ]     ________
update-patient-medical-record        [ ]     ________
generate-soap-draft-v2               [ ]     ________
```

#### B. Error Rate Check

```sql
-- Count errors in past 30 minutes (via logs)
npx supabase functions logs update-patient-medical-record --tail | grep -i error | wc -l
```

**Checklist:**
- [ ] Error count < 2 errors in last 30 min
- [ ] No repeated error messages
- [ ] No cascading failures

**Observation:**
- Errors in past 30 min: ______
- Error type: _________________
- Action taken: _______________

#### C. Database Response Time

```bash
# Test query response time
time curl -s https://noaeltglphdlkbflipit.supabase.co/functions/v1/get-patient-history \
  -H "Content-Type: application/json" \
  -d '{"patientId": "[TEST_ID]"}' | jq '.duration'
```

**Checklist:**
- [ ] Response time < 2 seconds
- [ ] No timeout errors
- [ ] Database connections stable (via dashboard)

**Observation:**
- Average response time: _______ ms
- Slow queries? [ ] Yes [ ] No
- Connection pool usage: _____% (target < 70%)

#### D. Provider Feedback

**Check in with any providers testing:**
- [ ] Pre-call history loaded? [ ] Yes [ ] No
- [ ] Notes saved correctly? [ ] Yes [ ] No
- [ ] Any errors seen? [ ] Yes [ ] No (describe: _______)

**Observation:**
- Providers tested so far: ________
- Feedback: ____________________
- Issues reported: ______________

#### E. Log Review

Review logs for error patterns:
```bash
npx supabase functions logs update-patient-medical-record --tail

# Look for:
# - ERROR: [look for repeated patterns]
# - WARN: [unusual activity]
# - Timeouts
# - RLS policy violations
```

**Checklist:**
- [ ] No ERROR level logs (critical)
- [ ] WARN logs < 5 in 30 min window
- [ ] No authentication errors (401/403)
- [ ] No database connection errors

**Issues Found:**
```
Log Entry 1: ____________________
Log Entry 2: ____________________
```

---

### ✅ All Checks Green? Continue Monitoring

### 🟠 Yellow Flag? Investigate & Document

**If yellow (minor issues):**
1. Document the issue
2. Monitor next check to see if it recurs
3. If recurring: Escalate to technical lead
4. If isolated: Continue monitoring

**If red (critical):**
1. STOP deployment
2. Follow ROLLBACK procedure (see end)

---

## HOURS 4-12: Standard Monitoring (Hourly)

### Hourly Check Template

**Check Time: ___:___** (Hour ____)

**Quick 5-Minute Check:**

- [ ] Error rate < 1% (check logs)
- [ ] Response time < 2 sec (test one call)
- [ ] Database OK (check Supabase dashboard)
- [ ] No critical provider reports

**Command:**
```bash
echo "=== ERROR RATE ===" && \
  npx supabase functions logs update-patient-medical-record --tail | grep -i error | wc -l && \
echo "=== LAST 10 ENTRIES ===" && \
  npx supabase functions logs update-patient-medical-record --tail | head -10
```

**Status:** [ ] ✅ Green | [ ] 🟡 Yellow | [ ] 🔴 Red

**Issues:** ____________________

---

## HOURS 12-24: Light Monitoring (Every 4 hours)

### 4-Hour Check Template

**Check Time: ___:___** (Hour ____)

**2-Minute Status Check:**

- [ ] Function logs: Any errors? [ ] Yes [ ] No
- [ ] Provider feedback: All good? [ ] Yes [ ] No
- [ ] Database metrics: Normal? [ ] Yes [ ] No
- [ ] Any alerts triggered? [ ] Yes [ ] No

**Quick Status:**
```
Overall System Status: [ ] ✅ Stable | [ ] 🟡 Monitor | [ ] 🔴 Issues
Recommendation: [ ] Continue | [ ] Investigate | [ ] Escalate
```

---

## Continuous Monitoring Setup

### Supabase Dashboard Metrics (Keep Open)

**Location:** [Supabase Project](https://app.supabase.com) → Edge Functions → [Function Name]

**Watch for:**
- ✅ Green checkmarks (success)
- ⚠️ Red errors spike
- 📈 Response time trends
- 📊 Invocation count

### Log Stream (Keep Running)

```bash
# In dedicated terminal, keep running
npx supabase functions logs all --tail --project-ref noaeltglphdlkbflipit 2>&1 | tee /var/log/deployment-24h.log

# Later, search logs:
grep ERROR /var/log/deployment-24h.log
grep "merge_soap" /var/log/deployment-24h.log
```

### Database Metrics Dashboard

**Supabase Dashboard → Settings → Database → Metrics**

Watch:
- Connection pool usage (target: < 70%)
- Query performance (target: < 500ms)
- Replica lag (target: < 1 sec)

---

## Provider Testing Coordination

### If Providers Are Using System

**Check in every 2 hours:**

```
Hour: ___
□ How many providers tested? ____
□ How many patient calls? ____
□ Any issues reported? ____
□ Medical history displaying? [ ] Yes [ ] No
□ Notes saving? [ ] Yes [ ] No
□ Merge working? [ ] Yes [ ] No (any unexpected data?)
```

**Sample Provider Checklist (Share with Early Adopters):**

```
✅ Pre-call medical history visible?
✅ All allergies showing?
✅ All medications showing?
✅ All diagnoses showing?
✅ AI draft generated after call?
✅ Draft accurate? (1-2 corrections needed OK)
✅ Save button worked?
✅ No error messages?

If all ✅: Worked great!
If any ❌: Contact support team immediately
```

---

## Issues & Resolution Matrix

### Issue: Function Returning 500 Errors

**Diagnosis:**
```bash
npx supabase functions logs update-patient-medical-record --tail | grep ERROR
```

**Common Causes:**
- [ ] Firebase token invalid → Check token refresh
- [ ] Database connection lost → Check network
- [ ] Missing environment variable → Check function settings
- [ ] RLS policy blocking → Check policies

**Resolution:**
1. Check logs for specific error message
2. Identify cause from list above
3. Apply fix or escalate to technical team

---

### Issue: Slow Response Times (> 5 seconds)

**Diagnosis:**
```bash
# Check database query performance
# Supabase Dashboard → Settings → Database → Slow Queries
```

**Common Causes:**
- [ ] Large dataset (SOAP notes with 100+ entries) → Add index
- [ ] Connection pool saturated (> 85%) → Scale connections
- [ ] Merge function inefficiency → Check function logs
- [ ] Network latency → Check CDN/DNS

**Resolution:**
1. Identify slow query
2. Check if it's normal or anomalous
3. Add index if query is legitimate
4. Scale connection pool if needed

---

### Issue: Merge Function Not Updating Patient Record

**Diagnosis:**
```bash
# Check if merge was called
npx supabase functions logs update-patient-medical-record --tail | grep "merge_soap"

# Check if SOAP notes exist
psql -c "SELECT COUNT(*) FROM soap_notes WHERE created_at > NOW() - INTERVAL '1 hour';"
```

**Common Causes:**
- [ ] Merge function not deployed → Re-deploy
- [ ] Merge silently failing → Check logs for hidden errors
- [ ] RLS blocking update → Check policies allow provider to update patient_profiles
- [ ] Data format incorrect → Check SOAP data structure

**Resolution:**
1. Verify merge function was called
2. Check function logs for errors
3. Manually run merge on test patient if needed
4. Verify patient_profiles is being updated

---

### Issue: Provider Reports "Cannot See History"

**Diagnosis:**
```bash
# Test as provider (use their auth token)
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/get-patient-history \
  -H "Authorization: Bearer [PROVIDER_TOKEN]" \
  -d '{"patientId": "[PATIENT_ID]"}'
```

**Common Causes:**
- [ ] RLS policy blocking access → Fix policy
- [ ] Patient has no history → Normal for first visit
- [ ] Function not returning data → Check query
- [ ] App cache issue → Clear cache, restart app

**Resolution:**
1. Test function directly with provider token
2. If function returns data but app doesn't show it: App cache issue
3. If function returns error: RLS or auth issue
4. If function returns empty: Patient truly has no history (expected)

---

### Issue: Deduplication Not Working (Duplicates Appearing)

**Diagnosis:**
```sql
-- Check if merge function exists and worked
SELECT COUNT(*) FROM (
  SELECT jsonb_array_elements(cumulative_medical_record->'allergies') as item
  FROM patient_profiles
  WHERE user_id = '[PATIENT_ID]'
) WHERE item->>'allergen' = 'Penicillin';
-- Should return 1, not multiple
```

**Common Causes:**
- [ ] Merge function not run after second SOAP → Manually trigger
- [ ] Case sensitivity issue (PENICILLIN vs penicillin) → Check data
- [ ] Merge function has bug → Check function logs
- [ ] Data structure wrong → Check SOAP fields match merge function

**Resolution:**
1. Verify merge was called after second SOAP
2. Check function logs for errors
3. Manually re-run merge if needed
4. Check data for case/format issues

---

## Sign-Off: 24-Hour Monitoring Complete

**Date/Time Monitoring Ended:** _______________

### Final Status Report

**Overall System Status:** [ ] ✅ Stable | [ ] 🟡 Issues Present | [ ] 🔴 Requires Rollback

**Key Metrics Summary:**

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Function Error Rate | < 1% | ____% | [ ] ✅ [ ] ⚠️ [ ] ❌ |
| Response Time (avg) | < 2 sec | ____ sec | [ ] ✅ [ ] ⚠️ [ ] ❌ |
| Response Time (p95) | < 5 sec | ____ sec | [ ] ✅ [ ] ⚠️ [ ] ❌ |
| Database Conn Pool | < 70% | ____% | [ ] ✅ [ ] ⚠️ [ ] ❌ |
| Provider Feedback | > 4.5/5 | ____ /5 | [ ] ✅ [ ] ⚠️ [ ] ❌ |
| Deduplication Works | 100% | ____% | [ ] ✅ [ ] ⚠️ [ ] ❌ |

---

### Issues Encountered

**Critical Issues:** ____________________

**Major Issues:** ____________________

**Minor Issues:** ____________________

**All Resolved:** [ ] Yes [ ] No (see "Unresolved" section)

---

### Unresolved Issues (If Any)

**Issue 1:**
- Description: _______________________
- Status: [ ] Investigating [ ] Waiting for fix [ ] Accepted risk
- Owner: _______________________
- ETA for fix: _______________________

---

### Monitoring Lead Approval

**Monitoring Lead:** _______________________
**Signature:** _______________________ (or email approval)
**Date:** _______________________
**Time:** _______________________

**Recommend:** [ ] Move to normal support | [ ] Continue enhanced monitoring [ ] Rollback

---

### Hand-Off to Support Team

**Support Team Lead:** _______________________
**Briefing Time:** _______________________

**Key Points to Brief Support Team:**
1. _______________________
2. _______________________
3. _______________________

**Known Issues Support Should Watch For:**
1. _______________________
2. _______________________

**Escalation Contacts:**
- Technical Lead: _________________ Phone: _________________
- Database Admin: _________________ Phone: _________________
- On-Call Engineer: _________________ Phone: _________________

---

## ROLLBACK PROCEDURE (If Needed)

### When to Rollback

Initiate rollback if:
- 🔴 Error rate > 10% sustained for > 5 minutes
- 🔴 Function unable to respond (all returning errors)
- 🔴 Database corruption detected
- 🔴 Data loss confirmed
- 🔴 Critical clinical issue reported (wrong patient data, etc.)

### Rollback Steps

**Step 1: Announce Rollback (1 minute)**
```
🔴 ALERT: Rolling back to previous version due to [ISSUE]
   Estimated duration: 5 minutes
   Patient care: Not affected (read-only queries still work)
   Notification: Providers to be notified
```

**Step 2: Disable New Features in App (1 minute)**

Edit app configuration:
```dart
const bool enableCumulativeRecordUpdates = false;  // Disable
const bool enableAINoteDrafting = false;          // Disable
```

Re-deploy app or restart affected sessions.

**Step 3: Revert Edge Function (2 minutes)**

```bash
# List previous versions
npx supabase functions list --project-ref noaeltglphdlkbflipit

# Deploy previous stable version
npx supabase functions deploy update-patient-medical-record \
  --project-ref noaeltglphdlkbflipit \
  --version v3  # Or whichever was stable
```

**Step 4: Verify Rollback (2 minutes)**

```bash
# Test function works
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record \
  -d '{"test": true}'

# Check logs
npx supabase functions logs update-patient-medical-record --tail
```

**Step 5: Communicate to Stakeholders (1 minute)**

```
✅ Rollback Complete
   Previous version restored: v3
   Status: Stable and tested
   Medical history features: Temporarily disabled
   Next step: Investigation and fix
```

---

## Post-Rollback: Analysis & Fix

**Do Not Attempt Re-Deployment Until:**
- ✅ Root cause identified
- ✅ Fix implemented and tested
- ✅ Peer review completed
- ✅ Clinical team re-approves

**Root Cause Analysis Template:**

**What Happened:**
```
_________________________________
```

**Why It Happened:**
```
_________________________________
```

**Why Didn't Testing Catch It:**
```
_________________________________
```

**How We'll Prevent It:**
```
1. _________________________________
2. _________________________________
```

**Re-Deployment Plan:**
```
Date: _____________________
Time: _____________________
Additional Testing: _______
```

---

## End of 24-Hour Monitoring

**Thank you for careful monitoring during this critical period.**

The system is now handed over to standard support operations.

**Key Contacts for Ongoing Support:**
- System Issues: support@medzen.local
- Clinical Questions: [clinical-lead]@medzen.local
- Escalation: [technical-lead]@medzen.local

**Next Review:** 1 week post-deployment (Week 1 status check)
