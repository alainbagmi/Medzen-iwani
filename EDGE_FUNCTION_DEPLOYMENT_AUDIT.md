# Edge Function Deployment Audit - January 17, 2026

**Date:** January 17, 2026
**Status:** Audit Complete - 9 Missing Deployments Identified
**Total Functions:** 47 local | 40 deployed | 38 matching

---

## Executive Summary

The production Supabase instance has **38 of 47 local edge functions deployed**.

**Key Findings:**
- ✅ **38 functions properly deployed and ACTIVE**
- ❌ **9 functions exist locally but NOT deployed to production**
- ⚠️ **2 functions deployed but NOT in local repository** (legacy production functions)

---

## Deployed vs Local Comparison

### Total Count
| Category | Count |
|----------|-------|
| Local Functions | 47 |
| Deployed Functions | 40 |
| Matching (Both) | 38 |
| **Missing Deployment** | **9** |
| **Orphaned (Deployed Only)** | **2** |

---

## Functions Missing from Production Deployment

### Priority 1: CRITICAL - SOAP Workflow (4 functions)

These functions are essential for Phase 2.2 SOAP generation workflow but are NOT deployed:

#### 1. **generate-precall-soap** ❌ NOT DEPLOYED
- **Purpose:** Generate SOAP notes before video call completion
- **Status:** Local directory exists but not deployed
- **Dependencies:** Patient history, AI model
- **Risk Level:** MEDIUM - May be used in pre-call assessment flow
- **Action Required:** `npx supabase functions deploy generate-precall-soap`

#### 2. **get-patient-history** ❌ NOT DEPLOYED
- **Purpose:** Fetch patient medical history for SOAP generation context
- **Status:** Local directory exists but not deployed
- **Dependencies:** patient_profiles, clinical_notes tables
- **Risk Level:** HIGH - Referenced in generate-soap-from-transcript edge function
- **Current Workaround:** Function is duplicated in generate-soap-from-transcript/index.ts (lines 430-559)
- **Action Required:** `npx supabase functions deploy get-patient-history`
- **Note:** While this function exists locally as standalone, the main SOAP generation function has inline implementation, so production works but inconsistently

#### 3. **list-bedrock-models** ❌ NOT DEPLOYED
- **Purpose:** List available Bedrock AI models
- **Status:** Local directory exists but not deployed
- **Dependencies:** AWS Bedrock API
- **Risk Level:** LOW - Utility function for admin/debugging
- **Action Required:** `npx supabase functions deploy list-bedrock-models`

#### 4. **manage-bedrock-models** ❌ NOT DEPLOYED
- **Purpose:** Manage which Bedrock models are available for different roles
- **Status:** Local directory exists but not deployed
- **Dependencies:** AWS Bedrock, ai_assistants table
- **Risk Level:** MEDIUM - May be needed for role-based AI model selection
- **Action Required:** `npx supabase functions deploy manage-bedrock-models`

### Priority 2: ORCHESTRATION (1 function)

#### 5. **orchestrate-bedrock-models** ❌ NOT DEPLOYED
- **Purpose:** Route AI requests to appropriate Bedrock models based on role
- **Status:** Local directory exists but not deployed
- **Dependencies:** bedrock-ai-chat, manage-bedrock-models
- **Risk Level:** MEDIUM - May be part of AI model selection flow
- **Action Required:** `npx supabase functions deploy orchestrate-bedrock-models`

### Priority 3: INFRASTRUCTURE (3 functions)

#### 6. **process-live-transcription** ❌ NOT DEPLOYED
- **Purpose:** Process live transcription segments during active calls
- **Status:** Local directory exists but not deployed
- **Dependencies:** Call transcription pipeline
- **Risk Level:** HIGH - Should handle real-time transcription updates
- **Action Required:** `npx supabase functions deploy process-live-transcription`

#### 7. **deploy-soap-migration** ❌ NOT DEPLOYED
- **Purpose:** Deployment helper for SOAP schema migrations
- **Status:** Local directory exists but not deployed
- **Dependencies:** Database migrations
- **Risk Level:** LOW - Utility function, not production-critical
- **Action Required:** `npx supabase functions deploy deploy-soap-migration` (optional)

#### 8. **sql-update-appointment** ❌ NOT DEPLOYED
- **Purpose:** Direct SQL update for appointment records
- **Status:** Local directory exists but not deployed
- **Dependencies:** appointments table
- **Risk Level:** MEDIUM - Duplicate of update-appointment (which IS deployed)
- **Note:** `update-appointment` (DEPLOYED, v1) likely supersedes this
- **Action Required:** Verify if needed or remove from codebase

### Not Deployable

#### **chime-meeting-token-security-patch.ts** ⚠️ FILE NOT DIRECTORY
- **Type:** TypeScript file, not a function directory
- **Status:** Exists in functions folder but not a deployable unit
- **Action:** Should be moved to `_shared/` or another utilities folder
- **No deployment action needed**

---

## Deployed Functions NOT in Local Repository

### Legacy Production Functions (2)

#### 1. **Reminders**
- **Status:** DEPLOYED (v17, updated Dec 11, 2025)
- **Purpose:** Unknown - not in local repo
- **Action:** Either import from production or confirm for deletion

#### 2. **payunit**
- **Status:** DEPLOYED (v70, updated Dec 30, 2025)
- **Purpose:** Unknown - not in local repo
- **Action:** Either import from production or confirm for deletion

**Recommendation:** Backup these functions' source code from production before deletion, or add them to version control.

---

## Functions Properly Deployed ✅

All 38 of these functions are deployed and ACTIVE in production:

### Video & Communication (9)
- chime-entity-extraction (v51)
- chime-meeting-token (v93)
- chime-meeting-token-test (v12)
- chime-meeting-token-test-auth (v12)
- chime-messaging (v54)
- chime-recording-callback (v51)
- chime-transcription-callback (v51)
- call-send-message (v11)
- finalize-video-call (v17)

### AI & Clinical Notes (5)
- bedrock-ai-chat (v44)
- generate-soap-from-transcript (v8) ✅ **LATEST - Jan 17, 13:54:03**
- generate-soap-from-context (v1)
- generate-clinical-note (v11)
- start-medical-transcription (v18)

### Transcription & Call Processing (5)
- ingest-call-transcript (v1)
- finalize-call-draft (v1)
- process-ehr-sync-queue (v1)
- storage-sign-url (v1)
- cleanup-expired-recordings (v42)

### Appointments (4)
- update-appointment (v1)
- debug-update-appointment (v1)
- fix-appointment-provider (v1)
- create-test-soap-data (v2)

### User & Profile (3)
- upload-profile-picture (v58)
- cleanup-old-profile-pictures (v58)
- check-user (v28)

### Notifications (2)
- send-push-notification (v14)
- powersync-token (v62)

### Testing & Utilities (5)
- test-options (v34)
- test-imports (v34)
- test-imports-env (v34)
- test-imports-clients (v34)
- test-imports-supabase-only (v34)

### Infrastructure (3)
- refresh-powersync-views (v11)
- inspect-constraint (v1)
- test-direct-update (v1)

### Database (2)
- test-fk-constraint (v1)
- sync-to-ehrbase (v84)

---

## Deployment Action Plan

### CRITICAL (Deploy Immediately)

```bash
# 1. Deploy process-live-transcription (handles real-time transcription)
npx supabase functions deploy process-live-transcription

# 2. Deploy get-patient-history (supports SOAP generation workflow)
npx supabase functions deploy get-patient-history

# 3. Verify sql-update-appointment vs update-appointment
# If duplicate, remove sql-update-appointment from repo
```

### HIGH PRIORITY (Deploy Before Phase 2.3)

```bash
# 4. Deploy orchestrate-bedrock-models (AI model routing)
npx supabase functions deploy orchestrate-bedrock-models

# 5. Deploy manage-bedrock-models (Role-based AI model selection)
npx supabase functions deploy manage-bedrock-models

# 6. Deploy generate-precall-soap (Pre-call SOAP generation)
npx supabase functions deploy generate-precall-soap
```

### MEDIUM PRIORITY (Deploy For Completeness)

```bash
# 7. Deploy list-bedrock-models (Admin utility)
npx supabase functions deploy list-bedrock-models

# 8. Deploy deploy-soap-migration (Deployment utility - optional)
npx supabase functions deploy deploy-soap-migration
```

### LOW PRIORITY (Housekeeping)

```bash
# 9. Move chime-meeting-token-security-patch.ts
mv supabase/functions/chime-meeting-token-security-patch.ts \
   supabase/functions/_shared/chime-meeting-token-security-patch.ts

# 10. Backup and remove legacy functions (optional)
# Save Reminders and payunit source from production first
# Then confirm deletion with team
```

---

## Bulk Deployment Command

Deploy all missing 9 functions at once:

```bash
npx supabase functions deploy \
  process-live-transcription \
  get-patient-history \
  orchestrate-bedrock-models \
  manage-bedrock-models \
  generate-precall-soap \
  list-bedrock-models \
  deploy-soap-migration \
  sql-update-appointment
```

---

## Impact Analysis

### Phase 2.2 SOAP Generation Status

**Current State:**
- ✅ `generate-soap-from-transcript` deployed (v8, latest)
- ✅ `generate-soap-from-context` deployed (v1)
- ✅ Core SOAP generation workflow operational
- ⚠️ `get-patient-history` functionality duplicated inline (not as separate function)
- ❌ `process-live-transcription` NOT deployed
- ❌ `generate-precall-soap` NOT deployed

**Recommendation:** Phase 2.2 SOAP generation works but would benefit from:
1. Deploying standalone `get-patient-history` function
2. Deploying `process-live-transcription` for real-time captions
3. Deploying `generate-precall-soap` for pre-call notes

### AI Model Management Status

**Current State:**
- ✅ `bedrock-ai-chat` deployed with role-based models
- ❌ `list-bedrock-models` NOT deployed (admin utility missing)
- ❌ `manage-bedrock-models` NOT deployed (model management missing)
- ❌ `orchestrate-bedrock-models` NOT deployed (model routing missing)

**Recommendation:** Deploy all three before next AI model scaling effort

---

## Legacy Functions Review

### Function: Reminders (Deployed v17)
- **Status:** Production only, not in local repo
- **Action:** Either import to repo or confirm production-only status
- **Recommendation:** Bring to version control for consistency

### Function: payunit (Deployed v70)
- **Status:** Production only, not in local repo
- **Action:** Either import to repo or confirm production-only status
- **Recommendation:** Bring to version control for consistency

---

## Verification Steps

After deploying missing functions, run:

```bash
# List all functions to verify deployment
npx supabase functions list

# Check specific function logs
npx supabase functions logs process-live-transcription --tail

# Verify function is callable
curl -X POST https://[project].supabase.co/functions/v1/get-patient-history \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "x-firebase-token: $TOKEN" \
  -d '{"patient_id": "test-uuid"}'
```

---

## Summary

| Metric | Count |
|--------|-------|
| ✅ Deployed & Active | 38 |
| ❌ Missing Deployment | 9 |
| ⚠️ Orphaned (Prod Only) | 2 |
| ⏳ Ready to Deploy | 9 |
| 📋 Total Functions | 47 |
| **Deployment Coverage** | **81%** |

**Next Steps:**
1. Deploy 9 missing functions using bulk command (5 min)
2. Verify deployments succeed (logs check)
3. Import or remove 2 legacy functions
4. Move chime-meeting-token-security-patch.ts to _shared/
5. Run integration tests for newly deployed functions

---

## Session Information

- **Audit Date:** January 17, 2026
- **Deployed Count:** 40 functions
- **Local Count:** 47 functions
- **Coverage:** 81% (38/47)
- **Status:** Ready for deployment action

---

*Generated by: Deployment Audit Process*
*For issues or clarifications on specific functions, check function logs: `npx supabase functions logs [name] --tail`*
