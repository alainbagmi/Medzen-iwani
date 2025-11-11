# 🚨 CRITICAL FUNCTIONS PROTECTION

**STATUS:** PRODUCTION DEPLOYMENT - ACTIVE
**LAST UPDATED:** 2025-11-11T20:17:00Z
**PROTECTION LEVEL:** MAXIMUM

---

## ⚠️ CRITICAL WARNING

**DO NOT DELETE OR MODIFY THESE FUNCTIONS WITHOUT EXPLICIT AUTHORIZATION**

The following Firebase Cloud Functions are **CRITICAL** for production operations and handle authentication, user creation, and data integrity across 4 interconnected systems:

1. **`onUserCreated`** - Firebase Auth trigger (user.onCreate)
2. **`onUserDeleted`** - Firebase Auth trigger (user.onDelete)

**Deleting or breaking these functions will:**
- ❌ Break user signup/login flows
- ❌ Leave orphaned records in Supabase
- ❌ Corrupt data across Firebase, Supabase, PowerSync, and EHRbase
- ❌ Violate HIPAA/GDPR compliance requirements
- ❌ Cause production outage affecting all 4 user roles

---

## 🔒 Protection Mechanisms

### 1. Git Version Control

**Location:** `firebase/functions/index.js`
- Lines 65-236: `onUserCreated` function
- Lines 441-545: `onUserDeleted` function

**Commit Hash:** bc0a475
**Commit Message:** "feat: Add production-ready onUserDeleted function with cascade deletion"

**To restore from git:**
```bash
# If functions are accidentally modified/deleted
git checkout bc0a475 -- firebase/functions/index.js

# Or restore from latest main
git restore firebase/functions/index.js

# Redeploy immediately
cd firebase/functions
firebase deploy --only functions:onUserCreated,onUserDeleted --project medzen-bf20e
```

### 2. Backup Copies

**Primary Backup:** Git repository (always committed)
**Documentation Backups:**
- `PRODUCTION_READY_ONUSERCREATED.md` - Complete onUserCreated documentation
- `PRODUCTION_READY_ONUSERDELETED.md` - Complete onUserDeleted documentation

Both files contain the complete function code and can be used to restore if needed.

### 3. Firebase Console Protection

**Function Names:**
- `onUserCreated` (us-central1)
- `onUserDeleted` (us-central1)

**Important:** Firebase Console allows manual deletion. To prevent accidents:

1. **Required Role:** Only project owners should have delete permissions
2. **Verification Before Delete:** Always check function name 3x before deleting
3. **Never delete functions starting with "on"** - these are lifecycle triggers

### 4. Deployment Lock File

This file (`CRITICAL_FUNCTIONS_PROTECTION.md`) serves as a deployment lock. If you see this file in the repository, **DO NOT DELETE THESE FUNCTIONS**.

---

## 🛡️ Emergency Recovery Procedure

If functions are accidentally deleted or broken:

### Step 1: Restore from Git
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
git restore firebase/functions/index.js
```

### Step 2: Verify Function Code
```bash
# Check onUserCreated exists (lines 65-236)
sed -n '65,236p' firebase/functions/index.js | grep -q "onUserCreated" && echo "✅ onUserCreated found"

# Check onUserDeleted exists (lines 441-545)
sed -n '441,545p' firebase/functions/index.js | grep -q "onUserDeleted" && echo "✅ onUserDeleted found"
```

### Step 3: Redeploy Immediately
```bash
cd firebase/functions
npm install
firebase deploy --only functions --project medzen-bf20e
```

### Step 4: Verify Deployment
```bash
# Check function logs
firebase functions:log --only onUserCreated --project medzen-bf20e | head -10
firebase functions:log --only onUserDeleted --project medzen-bf20e | head -10
```

### Step 5: Test Functions
```bash
# Test user creation
./test_onusercreated_deployment.sh

# Test user deletion
./test_user_deletion_complete.sh
```

---

## 📋 Function Dependencies

### onUserCreated Dependencies:
- **Firebase Admin SDK** - User authentication
- **Supabase Client** - User record creation
- **EHRbase REST API** - Health record creation
- **Configuration:**
  - `supabase.url`
  - `supabase.service_key`
  - `ehrbase.url`
  - `ehrbase.username`
  - `ehrbase.password`

### onUserDeleted Dependencies:
- **Firebase Admin SDK** - Firestore deletion
- **Supabase Client** - Cascade deletion
- **Configuration:**
  - `supabase.url`
  - `supabase.service_key`

**Verify Config:**
```bash
firebase functions:config:get --project medzen-bf20e
```

**If config is missing, restore from backup:**
```bash
# Contact system administrator for credential values
firebase functions:config:set supabase.url="<SUPABASE_URL>" --project medzen-bf20e
firebase functions:config:set supabase.service_key="<SERVICE_KEY>" --project medzen-bf20e
firebase functions:config:set ehrbase.url="<EHRBASE_URL>" --project medzen-bf20e
firebase functions:config:set ehrbase.username="<USERNAME>" --project medzen-bf20e
firebase functions:config:set ehrbase.password="<PASSWORD>" --project medzen-bf20e
```

---

## 🧪 Test Scripts Protection

The following test scripts **MUST NOT BE MODIFIED OR DELETED**:

### User Creation Tests:
- `test_onusercreated_deployment.sh` - End-to-end creation test
- `test_onusercreated_manual.sh` - Manual verification
- `test_onusercreated_simple.sh` - Quick test

### User Deletion Tests:
- `test_user_deletion_complete.sh` - End-to-end deletion test ⭐
- `verify_user_deletion.sh` - Manual verification
- `delete_test_user.js` - Node.js deletion utility

All scripts are:
- ✅ Committed to git
- ✅ Executable (`chmod +x *.sh`)
- ✅ Documented in production docs

**To restore test scripts:**
```bash
git restore test_*.sh verify_*.sh delete_test_user.js
chmod +x test_*.sh verify_*.sh
```

---

## 📊 System Architecture

```
Firebase Auth (Source of Truth)
      ↓
┌─────────────────────────────────────┐
│  onUserCreated (CREATE)             │
│  - Creates Supabase user            │
│  - Creates EHRbase EHR              │
│  - Creates EHR linkage              │
│  - Creates Firestore doc            │
└─────────────────────────────────────┘
      ↓
4-System Integration Complete
      ↓
User Can Login/Use App
      ↓
┌─────────────────────────────────────┐
│  onUserDeleted (DELETE)             │
│  - Deletes Supabase Auth            │
│  - Deletes users table              │
│  - Deletes EHR linkage              │
│  - Deletes Firestore doc            │
│  - PRESERVES EHRbase EHR ⚠️         │
└─────────────────────────────────────┘
```

**Breaking either function breaks the entire system.**

---

## 🔍 Monitoring

### Check Function Health:
```bash
# View recent executions
firebase functions:log --only onUserCreated --project medzen-bf20e
firebase functions:log --only onUserDeleted --project medzen-bf20e

# Check for errors in last 24 hours
firebase functions:log --only onUserCreated --project medzen-bf20e | grep "❌"
firebase functions:log --only onUserDeleted --project medzen-bf20e | grep "❌"
```

### Alert Thresholds:
- ⚠️ **Warning:** More than 5% error rate in 1 hour
- 🚨 **Critical:** More than 20% error rate OR function not found

---

## 📞 Emergency Contacts

**If functions are deleted or broken:**

1. **Immediate Action:** Follow Emergency Recovery Procedure above
2. **Escalation:** Contact system administrator
3. **Documentation:** Refer to PRODUCTION_READY_* files
4. **Git History:** Check `git log firebase/functions/index.js`

---

## 🎯 Compliance & Legal

### HIPAA Requirements:
- onUserCreated: Creates EHR for medical record storage
- onUserDeleted: **PRESERVES** EHR (6+ year retention required)

### GDPR Requirements:
- onUserDeleted: Implements "Right to Erasure"
- EHR Preservation: Legal obligation exemption applies

**Deleting these functions may violate healthcare regulations.**

---

## ✅ Verification Checklist

Before ANY modifications to these functions:

- [ ] Read this protection document completely
- [ ] Verify you have authorization from project owner
- [ ] Create git branch for changes
- [ ] Test changes in development environment first
- [ ] Run all test scripts before deploying
- [ ] Have rollback plan ready
- [ ] Monitor logs after deployment
- [ ] Document all changes

**If you cannot check ALL boxes above, DO NOT PROCEED.**

---

## 📝 Change History

| Date | Change | Author | Commit |
|------|--------|--------|--------|
| 2025-11-11 | Initial protection setup | System | bc0a475 |
| 2025-11-11 | Added onUserDeleted function | System | bc0a475 |
| 2025-11-11 | Created protection documentation | System | - |

---

**⚠️ REMEMBER: These functions are CRITICAL for production. When in doubt, DON'T DELETE.**

**🔒 PROTECTION LEVEL: MAXIMUM - DEPLOYMENT LOCKED**
