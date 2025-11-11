# EHR System Implementation Roadmap
## Full Multi-Role OpenEHR Integration

---

## Executive Summary

**Goal:** Create comprehensive EHR records for ALL user types (Patient, Provider, Facility Admin, System Admin) using role-appropriate OpenEHR templates.

**Current State:**
- ✅ EHRs created for all users via `onUserCreated` function
- ✅ 22 patient clinical templates already in EHRbase
- ❌ Using generic demographic template for all users
- ❌ No role-specific compositions

**Target State:**
- ✅ EHRs for all users with role-appropriate templates
- ✅ Patient: Clinical compositions (vital signs, diagnoses, meds)
- ✅ Provider: Professional profile compositions (credentials, specialties)
- ✅ Facility Admin: Facility management compositions (services, staff)
- ✅ System Admin: Administrative compositions (audit logs, config)

---

## Phase 1: Quick Win - Simplified Approach (1-2 days)

### Option A: User Profiles Table (Recommended - Simplest)

**Problem:** Role is not available at signup time (user selects role AFTER account creation)

**Solution:** Store all role-specific data in existing `user_profiles` table, sync to EHRbase later

**Implementation Steps:**

1. **Keep current `onUserCreated` function AS-IS**
   - Creates basic EHR for everyone
   - No role-specific template yet (role unknown at signup time)

2. **Add role-based composition creation AFTER role selection**
   - User selects role → Update `user_profiles.role`
   - Trigger creates appropriate EHRbase composition based on role
   - Sync via existing `ehrbase_sync_queue`

3. **Database Changes:**
```sql
-- Add trigger to create EHR composition when role is set
CREATE OR REPLACE FUNCTION queue_role_profile_sync()
RETURNS TRIGGER AS $$
BEGIN
  -- Only queue if role changed and EHR exists
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      template_id,
      sync_type,
      sync_status,
      data_snapshot,
      created_at
    )
    SELECT
      'user_profiles',
      NEW.id::TEXT,
      CASE NEW.role
        WHEN 'patient' THEN 'medzen.patient.demographics.v1'
        WHEN 'provider' THEN 'medzen.provider.profile.v1'
        WHEN 'facility_admin' THEN 'medzen.facility.profile.v1'
        WHEN 'system_admin' THEN 'medzen.admin.profile.v1'
        ELSE 'medzen.patient.demographics.v1'
      END,
      'profile_create',
      'pending',
      jsonb_build_object(
        'user_id', NEW.user_id,
        'role', NEW.role,
        'profile_data', row_to_json(NEW.*)
      ),
      NOW()
    WHERE EXISTS (
      SELECT 1 FROM electronic_health_records
      WHERE patient_id = NEW.user_id::TEXT
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_queue_role_profile_sync ON user_profiles;
CREATE TRIGGER trigger_queue_role_profile_sync
  AFTER INSERT OR UPDATE OF role ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION queue_role_profile_sync();
```

4. **Update `sync-to-ehrbase` edge function:**
```typescript
// Add to supabase/functions/sync-to-ehrbase/index.ts

// Map roles to template builders
const templateBuilders = {
  'patient': buildPatientDemographics,
  'provider': buildProviderProfile,
  'facility_admin': buildFacilityProfile,
  'system_admin': buildAdminProfile,
};

function buildProviderProfile(data: any) {
  return {
    _type: 'COMPOSITION',
    name: {
      _type: 'DV_TEXT',
      value: 'Provider Professional Profile'
    },
    archetype_details: {
      template_id: {
        value: 'medzen.provider.profile.v1'
      }
    },
    // ... rest of composition structure
  };
}

// Similar for other roles
```

**Advantages:**
- ✅ Minimal changes to current system
- ✅ Role-specific templates created at right time
- ✅ Uses existing sync infrastructure
- ✅ Easy to test and rollback

**Timeline:** 1-2 days

---

## Phase 2: Full Implementation (1-2 weeks)

### Step 1: Create Template Files (Day 1-2)

**Files to Create:**
```
ehrbase-templates/
  ├── medzen.patient.demographics.v1.json
  ├── medzen.provider.profile.v1.json        # ✅ Already created
  ├── medzen.provider.schedule.v1.json
  ├── medzen.facility.profile.v1.json
  ├── medzen.facility.services.v1.json
  ├── medzen.admin.profile.v1.json
  └── medzen.admin.audit.v1.json
```

**Template Creation Tool:**
Use EHRbase Template Designer or Better Template Designer: https://tools.openehr.org/designer/

**Upload to EHRbase:**
```bash
# For each template
curl -X POST "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
  -H "Authorization: Basic $(echo -n 'ehrbase-admin:PASSWORD' | base64)" \
  -H "Content-Type: application/xml" \
  --data-binary @template.opt
```

### Step 2: Update Database Schema (Day 3)

```sql
-- Migration: 20251103000000_add_role_based_ehr_support.sql

-- Add role tracking to electronic_health_records
ALTER TABLE electronic_health_records
ADD COLUMN IF NOT EXISTS user_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS primary_template_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS role_profile_synced_at TIMESTAMPTZ;

-- Add role to sync queue
ALTER TABLE ehrbase_sync_queue
ADD COLUMN IF NOT EXISTS user_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS composition_category VARCHAR(100);

-- Backfill existing records (optional)
UPDATE electronic_health_records ehr
SET user_role = COALESCE(up.role, 'patient')
FROM user_profiles up
WHERE ehr.patient_id = up.user_id::TEXT;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ehr_user_role
  ON electronic_health_records(user_role);
CREATE INDEX IF NOT EXISTS idx_sync_queue_role
  ON ehrbase_sync_queue(user_role);
```

### Step 3: Update Cloud Functions (Day 4-5)

**Option 1: Keep Current Flow (Recommended)**

`firebase/functions/index.js` - NO CHANGES NEEDED
- Current `onUserCreated` continues creating basic EHRs
- Role-specific compositions created later by trigger

**Option 2: Wait for Role (More Complex)**

If you want to create role-specific EHR immediately:

```javascript
// firebase/functions/index.js

exports.onUserRoleSelected = functions.firestore
  .document('user_profiles/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only process if role changed
    if (before.role === after.role) return;

    const userId = context.params.userId;

    // Get user's EHR ID
    const { data: ehr } = await supabase
      .from('electronic_health_records')
      .select('ehr_id')
      .eq('patient_id', userId)
      .single();

    if (!ehr) {
      console.error('No EHR found for user', userId);
      return;
    }

    // Create role-specific composition in EHRbase
    const template_id = getTemplateIdForRole(after.role);
    const composition = buildCompositionForRole(after.role, after);

    await createEHRbaseComposition(ehr.ehr_id, composition);

    // Update record
    await supabase
      .from('electronic_health_records')
      .update({
        user_role: after.role,
        primary_template_id: template_id,
        role_profile_synced_at: new Date().toISOString()
      })
      .eq('patient_id', userId);
  });

function getTemplateIdForRole(role) {
  const templates = {
    'patient': 'medzen.patient.demographics.v1',
    'provider': 'medzen.provider.profile.v1',
    'facility_admin': 'medzen.facility.profile.v1',
    'system_admin': 'medzen.admin.profile.v1',
  };
  return templates[role] || templates['patient'];
}
```

### Step 4: Update Edge Functions (Day 6-7)

`supabase/functions/sync-to-ehrbase/index.ts`:

```typescript
// Add role-specific builders
import { buildPatientDemographics } from './builders/patient.ts';
import { buildProviderProfile } from './builders/provider.ts';
import { buildFacilityProfile } from './builders/facility.ts';
import { buildAdminProfile } from './builders/admin.ts';

// In main sync function
const roleBuilders = {
  patient: buildPatientDemographics,
  provider: buildProviderProfile,
  facility_admin: buildFacilityProfile,
  system_admin: buildAdminProfile,
};

// Get user role from data_snapshot
const userRole = queueItem.data_snapshot?.role || 'patient';
const builder = roleBuilders[userRole] || roleBuilders.patient;

// Build composition
const composition = builder(queueItem.data_snapshot);

// Post to EHRbase
await postCompositionToEHRbase(ehrId, composition);
```

Create builder files:

`supabase/functions/sync-to-ehrbase/builders/provider.ts`:
```typescript
export function buildProviderProfile(data: any) {
  return {
    _type: 'COMPOSITION',
    name: {
      _type: 'DV_TEXT',
      value: 'Provider Professional Profile'
    },
    archetype_details: {
      archetype_id: {
        value: 'openEHR-EHR-COMPOSITION.report.v1'
      },
      template_id: {
        value: 'medzen.provider.profile.v1'
      },
      rm_version: '1.0.4'
    },
    language: {
      _type: 'CODE_PHRASE',
      terminology_id: {
        value: 'ISO_639-1'
      },
      code_string: 'en'
    },
    territory: {
      _type: 'CODE_PHRASE',
      terminology_id: {
        value: 'ISO_3166-1'
      },
      code_string: 'CM'  // Cameroon
    },
    category: {
      _type: 'DV_CODED_TEXT',
      value: 'persistent',
      defining_code: {
        terminology_id: {
          value: 'openehr'
        },
        code_string: '431'
      }
    },
    composer: {
      _type: 'PARTY_IDENTIFIED',
      name: 'MedZen System'
    },
    context: {
      start_time: {
        _type: 'DV_DATE_TIME',
        value: new Date().toISOString()
      },
      setting: {
        _type: 'DV_CODED_TEXT',
        value: 'Provider Registration',
        defining_code: {
          terminology_id: {
            value: 'openehr'
          },
          code_string: '238'
        }
      }
    },
    content: [
      {
        _type: 'ADMIN_ENTRY',
        name: {
          _type: 'DV_TEXT',
          value: 'Provider Demographics'
        },
        archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.person_data.v0',
        data: {
          items: [
            {
              _type: 'ELEMENT',
              name: { value: 'Provider ID' },
              value: {
                _type: 'DV_IDENTIFIER',
                id: data.user_id
              }
            },
            {
              _type: 'ELEMENT',
              name: { value: 'Full Name' },
              value: {
                _type: 'DV_TEXT',
                value: data.display_name || `${data.first_name} ${data.last_name}`
              }
            },
            {
              _type: 'ELEMENT',
              name: { value: 'Contact Email' },
              value: {
                _type: 'DV_TEXT',
                value: data.email
              }
            }
          ]
        }
      }
    ]
  };
}
```

### Step 5: Flutter Integration (Day 8-9)

Create Custom Action to initialize role-specific profile:

`lib/custom_code/actions/initialize_role_profile.dart`:
```dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';

Future<void> initializeRoleProfile(String role) async {
  try {
    final userId = SupaFlow.client.auth.currentUser?.id;
    if (userId == null) return;

    // Update user_profiles with role
    await SupaFlow.client
        .from('user_profiles')
        .update({'role': role})
        .eq('user_id', userId);

    // The database trigger will automatically queue the sync

    print('Role profile initialized for: $role');
  } catch (e) {
    print('Error initializing role profile: $e');
    rethrow;
  }
}
```

Add to role selection page:

`lib/home_pages/role_page/role_page_widget.dart`:
```dart
// After user selects role
await initializeRoleProfile(selectedRole);

// Then navigate to role-specific landing page
context.pushNamed(roleRoutes[selectedRole]);
```

### Step 6: Testing (Day 10-12)

Create test scripts for each role:

`firebase/functions/test_role_ehr_creation.js`:
```javascript
// Test EHR creation for each role
async function testRoleEHRCreation(role) {
  const testEmail = `test-${role}-${Date.now()}@medzentest.com`;

  // 1. Create Firebase user
  const user = await admin.auth().createUser({
    email: testEmail,
    password: 'TestPassword123!'
  });

  console.log(`✅ Created user: ${user.uid}`);

  // 2. Wait for onUserCreated (creates basic EHR)
  await sleep(10000);

  // 3. Set role in Supabase
  await supabase
    .from('user_profiles')
    .update({ role: role })
    .eq('firebase_uid', user.uid);

  console.log(`✅ Set role: ${role}`);

  // 4. Wait for sync
  await sleep(15000);

  // 5. Check EHRbase for composition
  const { data: ehr } = await supabase
    .from('electronic_health_records')
    .select('ehr_id, user_role, primary_template_id')
    .eq('firebase_uid', user.uid)
    .single();

  console.log(`✅ EHR created:`, ehr);

  // 6. Cleanup
  await admin.auth().deleteUser(user.uid);

  return ehr;
}

// Test all roles
const roles = ['patient', 'provider', 'facility_admin', 'system_admin'];
for (const role of roles) {
  await testRoleEHRCreation(role);
}
```

---

## Phase 3: Advanced Features (Week 3-4)

### Feature 1: Role-Specific Dashboards

Show EHR data tailored to each role:

**Patient Dashboard:**
- Vital signs history
- Upcoming appointments
- Medications
- Lab results

**Provider Dashboard:**
- Today's appointments
- Patient list
- Consultation history
- Performance metrics

**Facility Admin Dashboard:**
- Staff roster
- Facility capacity
- Service availability
- Infrastructure status

### Feature 2: Cross-Role References

Link related EHRs:

```
Provider → treats → Patient
Provider → works at → Facility
Facility → employs → Provider
Admin → manages → All Users
```

Store relationships in compositions or separate linking table.

### Feature 3: Advanced Sync Rules

PowerSync rules for role-based data access:

```yaml
# provider_consultations
- SELECT * FROM consultations WHERE provider_id = token_parameters.user_id

# facility_staff
- SELECT * FROM facility_staff WHERE facility_id IN (
    SELECT facility_id FROM user_facility_associations WHERE user_id = token_parameters.user_id
  )

# admin_all_users
- SELECT * FROM users WHERE 1=1  # Admin sees all
```

---

## Rollout Strategy

### Week 1: Foundation
- ✅ Create template design docs
- ✅ Upload templates to EHRbase
- ✅ Database migrations
- ✅ Basic trigger setup

### Week 2: Implementation
- ✅ Update edge functions
- ✅ Update Cloud Functions (if needed)
- ✅ Flutter Custom Actions
- ✅ Initial testing

### Week 3: Testing & Refinement
- ✅ Test each role end-to-end
- ✅ Performance testing
- ✅ Bug fixes
- ✅ Documentation

### Week 4: Deployment
- ✅ Staging deployment
- ✅ User acceptance testing
- ✅ Production deployment
- ✅ Monitoring

---

## Success Metrics

1. **EHR Coverage:** 100% of users have EHRs
2. **Role-Specific Compositions:** Each role has appropriate template
3. **Sync Success Rate:** >95% sync queue success rate
4. **Performance:** <2s for role profile creation
5. **Data Integrity:** 0 orphaned records

---

## Rollback Plan

If issues occur:

1. **Database Rollback:**
```sql
-- Remove role columns
ALTER TABLE electronic_health_records DROP COLUMN IF EXISTS user_role;
ALTER TABLE ehrbase_sync_queue DROP COLUMN IF EXISTS user_role;

-- Disable trigger
DROP TRIGGER IF EXISTS trigger_queue_role_profile_sync ON user_profiles;
```

2. **Function Rollback:**
   - Redeploy previous version: `firebase deploy --only functions`
   - Revert edge function: `npx supabase functions deploy sync-to-ehrbase --no-verify-jwt`

3. **Verify System:**
   - Check user creation still works
   - Check existing EHRs accessible
   - Check PowerSync still syncing

---

## Next Steps

**Immediate (Today):**
1. ✅ Review this roadmap
2. ⏳ Create remaining template files
3. ⏳ Upload templates to EHRbase
4. ⏳ Test template uploads

**This Week:**
5. ⏳ Implement database triggers
6. ⏳ Update edge function builders
7. ⏳ Test with sample users

**Next Week:**
8. ⏳ Add Flutter integration
9. ⏳ End-to-end testing
10. ⏳ Deploy to staging

---

**Document Version:** 1.0
**Last Updated:** 2025-11-02
**Status:** Ready for Implementation
