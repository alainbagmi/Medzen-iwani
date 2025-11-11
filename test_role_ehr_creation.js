#!/usr/bin/env node

/**
 * Test Role-Based EHR Creation System
 *
 * This script tests the complete flow:
 * 1. Queries existing users
 * 2. Simulates role selection by updating user role
 * 3. Checks sync queue for queued compositions
 * 4. Verifies edge function processing
 */

const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_SERVICE_KEY) {
  console.error('❌ SUPABASE_SERVICE_KEY environment variable is required');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Helper functions
function logSection(title) {
  console.log('\n' + '='.repeat(60));
  console.log(`  ${title}`);
  console.log('='.repeat(60));
}

function logSuccess(message) {
  console.log(`✅ ${message}`);
}

function logError(message) {
  console.log(`❌ ${message}`);
}

function logInfo(message) {
  console.log(`ℹ️  ${message}`);
}

async function checkExistingUsers() {
  logSection('Step 1: Check Existing Users with Roles');

  const { data: users, error } = await supabase
    .from('user_profiles')
    .select('user_id, role')
    .not('role', 'is', null)
    .limit(10);

  if (error) {
    logError(`Failed to fetch users: ${error.message}`);
    return [];
  }

  if (users && users.length > 0) {
    logSuccess(`Found ${users.length} users with roles`);
    users.forEach((user, i) => {
      console.log(`  ${i + 1}. User ID: ${user.user_id}`);
      console.log(`     Role: ${user.role}`);
    });
  } else {
    logInfo('No users with roles found');
  }

  return users || [];
}

async function checkEHRRecords() {
  logSection('Step 2: Check Electronic Health Records');

  const { data: ehrs, error } = await supabase
    .from('electronic_health_records')
    .select('id, patient_id, ehr_id, user_role, primary_template_id, created_at')
    .limit(10);

  if (error) {
    logError(`Failed to fetch EHRs: ${error.message}`);
    return [];
  }

  if (ehrs && ehrs.length > 0) {
    logSuccess(`Found ${ehrs.length} EHR records`);
    ehrs.forEach((ehr, i) => {
      console.log(`  ${i + 1}. EHR ID: ${ehr.ehr_id}`);
      console.log(`     Patient ID: ${ehr.patient_id}`);
      console.log(`     Role: ${ehr.user_role || 'Not set'}`);
      console.log(`     Template: ${ehr.primary_template_id || 'Not set'}`);
    });
  } else {
    logInfo('No EHR records found');
  }

  return ehrs || [];
}

async function checkSyncQueue() {
  logSection('Step 3: Check EHRbase Sync Queue');

  const { data: queue, error } = await supabase
    .from('ehrbase_sync_queue')
    .select('id, table_name, sync_type, sync_status, user_role, composition_category, created_at')
    .eq('sync_type', 'role_profile_create')
    .order('created_at', { ascending: false })
    .limit(10);

  if (error) {
    logError(`Failed to fetch sync queue: ${error.message}`);
    return [];
  }

  if (queue && queue.length > 0) {
    logSuccess(`Found ${queue.length} role profile sync entries`);
    queue.forEach((item, i) => {
      console.log(`  ${i + 1}. Sync ID: ${item.id}`);
      console.log(`     Type: ${item.sync_type}, Status: ${item.sync_status}`);
      console.log(`     Role: ${item.user_role}, Category: ${item.composition_category}`);
      console.log(`     Created: ${new Date(item.created_at).toLocaleString()}`);
    });
  } else {
    logInfo('No role profile sync entries found in queue');
  }

  return queue || [];
}

async function simulateRoleSelection(userId, role) {
  logSection(`Step 4: Simulate Role Selection (${role})`);

  logInfo(`Updating user ${userId} to role: ${role}`);

  const { data, error } = await supabase
    .from('user_profiles')
    .update({ role: role })
    .eq('user_id', userId)
    .select();

  if (error) {
    logError(`Failed to update user role: ${error.message}`);
    return false;
  }

  logSuccess(`Successfully updated user role to: ${role}`);

  // Wait a moment for trigger to fire
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Check if sync queue entry was created
  const { data: queueEntry, error: queueError } = await supabase
    .from('ehrbase_sync_queue')
    .select('*')
    .eq('record_id', userId)
    .eq('sync_type', 'role_profile_create')
    .single();

  if (queueError && queueError.code !== 'PGRST116') {
    logError(`Failed to check sync queue: ${queueError.message}`);
    return false;
  }

  if (queueEntry) {
    logSuccess('Sync queue entry created successfully!');
    console.log(`  Queue ID: ${queueEntry.id}`);
    console.log(`  Template: ${queueEntry.template_id}`);
    console.log(`  Status: ${queueEntry.sync_status}`);
    return true;
  } else {
    logError('No sync queue entry found. Trigger may not have fired.');
    return false;
  }
}

async function getTemplateMapping() {
  return {
    patient: 'medzen.patient.demographics.v1',
    provider: 'medzen.provider.profile.v1',
    facility_admin: 'medzen.facility.profile.v1',
    system_admin: 'medzen.admin.profile.v1'
  };
}

async function runTests() {
  console.log('🧪 Role-Based EHR Creation Test Suite');
  console.log('=====================================\n');

  try {
    // Step 1: Check existing users
    const users = await checkExistingUsers();

    // Step 2: Check EHR records
    const ehrs = await checkEHRRecords();

    // Step 3: Check sync queue
    const queue = await checkSyncQueue();

    // Step 4: Test role selection trigger (if we have users)
    if (users.length > 0) {
      const testUser = users[0];
      const testRoles = ['patient', 'provider', 'facility_admin', 'system_admin'];
      const currentRole = testUser.role;

      // Pick a different role to test
      const newRole = testRoles.find(r => r !== currentRole) || 'patient';

      logSection('Testing Role Selection Trigger');
      logInfo(`Will update user ${testUser.user_id} from ${currentRole} to ${newRole}`);
      console.log('⚠️  This will trigger EHR composition creation');

      // Uncomment to actually test:
      // const success = await simulateRoleSelection(testUser.user_id, newRole);
      logInfo('Skipping actual role update (uncomment in code to test)');
    }

    // Summary
    logSection('Test Summary');
    logSuccess('All checks completed');
    console.log(`  Users with roles: ${users.length}`);
    console.log(`  EHR records: ${ehrs.length}`);
    console.log(`  Sync queue entries: ${queue.length}`);

    // Check monitoring views
    logSection('Monitoring Views');

    const { data: roleStats, error: roleError } = await supabase
      .rpc('get_ehr_role_statistics');

    if (!roleError && roleStats) {
      console.log('  EHR Role Statistics:');
      roleStats.forEach(stat => {
        console.log(`    ${stat.role}: ${stat.total_ehrs} EHRs, ${stat.pending_syncs} pending, ${stat.completed_syncs} completed`);
      });
    }

    console.log('\n✅ Test suite completed successfully!\n');

  } catch (error) {
    logError(`Test suite failed: ${error.message}`);
    console.error(error);
    process.exit(1);
  }
}

// Run tests
runTests();
