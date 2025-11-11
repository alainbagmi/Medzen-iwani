#!/usr/bin/env node

/**
 * Test User Creation Flow
 * Tests the complete user creation process:
 * 1. Create Firebase Auth user
 * 2. Wait for Cloud Function to execute
 * 3. Verify Supabase user creation
 * 4. Verify EHRbase EHR creation
 * 5. Verify electronic_health_records entry
 */

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');

// Configuration
const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM';
const EHRBASE_URL = 'https://ehr.medzenhealth.app/ehrbase';
const EHRBASE_USERNAME = 'ehrbase-admin';
const EHRBASE_PASSWORD = 'EvenMoreSecretPassword';

// Initialize Firebase Admin
// Use Application Default Credentials (works with Firebase CLI login)
admin.initializeApp({
  projectId: 'medzen-bf20e'
});

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Test state
let testResults = {
  firebaseAuth: { status: '⏳', message: '' },
  supabaseAuth: { status: '⏳', message: '' },
  supabaseUsers: { status: '⏳', message: '' },
  ehrbaseEhr: { status: '⏳', message: '' },
  electronicHealthRecords: { status: '⏳', message: '' },
  firestoreDoc: { status: '⏳', message: '' }
};

let createdUserId = null;
let createdEhrId = null;

function printResults() {
  console.log('\n' + '='.repeat(80));
  console.log('TEST RESULTS SUMMARY');
  console.log('='.repeat(80));

  console.log('\n1. Firebase Auth User Creation:');
  console.log(`   ${testResults.firebaseAuth.status} ${testResults.firebaseAuth.message}`);

  console.log('\n2. Supabase Auth User Creation:');
  console.log(`   ${testResults.supabaseAuth.status} ${testResults.supabaseAuth.message}`);

  console.log('\n3. Supabase Users Table:');
  console.log(`   ${testResults.supabaseUsers.status} ${testResults.supabaseUsers.message}`);

  console.log('\n4. EHRbase EHR Creation:');
  console.log(`   ${testResults.ehrbaseEhr.status} ${testResults.ehrbaseEhr.message}`);

  console.log('\n5. Electronic Health Records Entry:');
  console.log(`   ${testResults.electronicHealthRecords.status} ${testResults.electronicHealthRecords.message}`);

  console.log('\n6. Firestore User Document:');
  console.log(`   ${testResults.firestoreDoc.status} ${testResults.firestoreDoc.message}`);

  console.log('\n' + '='.repeat(80));

  const allPassed = Object.values(testResults).every(r => r.status === '✅');
  if (allPassed) {
    console.log('🎉 ALL TESTS PASSED!');
  } else {
    console.log('❌ SOME TESTS FAILED - Check details above');
  }
  console.log('='.repeat(80) + '\n');
}

async function waitForCloudFunction(firebaseUid, maxWaitSeconds = 30) {
  console.log(`\n⏳ Waiting up to ${maxWaitSeconds}s for Cloud Function to complete...`);

  const startTime = Date.now();
  const maxWaitMs = maxWaitSeconds * 1000;

  while (Date.now() - startTime < maxWaitMs) {
    // Check if Firestore document exists with supabase_user_id
    const firestoreDoc = await admin.firestore().collection('users').doc(firebaseUid).get();

    if (firestoreDoc.exists && firestoreDoc.data().supabase_user_id) {
      console.log('✅ Cloud Function completed!');
      return true;
    }

    // Wait 1 second before checking again
    await new Promise(resolve => setTimeout(resolve, 1000));
    process.stdout.write('.');
  }

  console.log('\n⚠️  Timeout waiting for Cloud Function');
  return false;
}

async function verifySupabaseUser(firebaseUid) {
  console.log('\n📝 Verifying Supabase user...');

  try {
    // Get Firestore doc to find Supabase user ID
    const firestoreDoc = await admin.firestore().collection('users').doc(firebaseUid).get();
    const supabaseUserId = firestoreDoc.data()?.supabase_user_id;

    if (!supabaseUserId) {
      throw new Error('No supabase_user_id in Firestore document');
    }

    createdUserId = supabaseUserId;

    // Check Supabase auth user
    const { data: authUser, error: authError } = await supabase.auth.admin.getUserById(supabaseUserId);

    if (authError) {
      testResults.supabaseAuth = {
        status: '❌',
        message: `Auth user not found: ${authError.message}`
      };
    } else {
      testResults.supabaseAuth = {
        status: '✅',
        message: `Auth user found: ${authUser.email}`
      };
    }

    // Check Supabase users table
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', supabaseUserId)
      .single();

    if (userError) {
      testResults.supabaseUsers = {
        status: '❌',
        message: `Users table record not found: ${userError.message}`
      };
    } else {
      testResults.supabaseUsers = {
        status: '✅',
        message: `Users table record found: ${userData.email}`
      };
    }

  } catch (error) {
    console.error('❌ Error verifying Supabase user:', error.message);
    testResults.supabaseAuth = { status: '❌', message: error.message };
    testResults.supabaseUsers = { status: '❌', message: error.message };
  }
}

async function verifyEHRbase() {
  console.log('\n📝 Verifying EHRbase EHR...');

  try {
    // Get electronic_health_records entry
    const { data: ehrData, error: ehrError } = await supabase
      .from('electronic_health_records')
      .select('*')
      .eq('patient_id', createdUserId)
      .single();

    if (ehrError) {
      testResults.electronicHealthRecords = {
        status: '❌',
        message: `Record not found: ${ehrError.message}`
      };
      return;
    }

    if (!ehrData.ehr_id) {
      testResults.electronicHealthRecords = {
        status: '⚠️',
        message: `Record exists but ehr_id is null (status: ${ehrData.sync_status || 'unknown'})`
      };
      testResults.ehrbaseEhr = {
        status: '⚠️',
        message: 'EHR ID is null - EHRbase creation may have failed'
      };
      return;
    }

    createdEhrId = ehrData.ehr_id;

    testResults.electronicHealthRecords = {
      status: '✅',
      message: `Record found with EHR ID: ${ehrData.ehr_id}`
    };

    // Verify EHR exists in EHRbase
    const ehrbaseAuth = Buffer.from(`${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}`).toString('base64');

    const response = await axios.get(
      `${EHRBASE_URL}/rest/openehr/v1/ehr/${ehrData.ehr_id}`,
      {
        headers: {
          'Authorization': `Basic ${ehrbaseAuth}`,
          'Accept': 'application/json',
        }
      }
    );

    if (response.status === 200 && response.data.ehr_id) {
      testResults.ehrbaseEhr = {
        status: '✅',
        message: `EHR found in EHRbase: ${response.data.ehr_id.value || response.data.ehr_id}`
      };
    } else {
      testResults.ehrbaseEhr = {
        status: '❌',
        message: 'EHR not found in EHRbase'
      };
    }

  } catch (error) {
    console.error('❌ Error verifying EHRbase:', error.message);
    if (error.response) {
      console.error('EHRbase response:', error.response.status, error.response.data);
      testResults.ehrbaseEhr = {
        status: '❌',
        message: `EHRbase error: ${error.response.status} - ${JSON.stringify(error.response.data)}`
      };
    } else {
      testResults.ehrbaseEhr = {
        status: '❌',
        message: error.message
      };
    }
  }
}

async function verifyFirestoreDoc(firebaseUid) {
  console.log('\n📝 Verifying Firestore document...');

  try {
    const firestoreDoc = await admin.firestore().collection('users').doc(firebaseUid).get();

    if (!firestoreDoc.exists) {
      testResults.firestoreDoc = {
        status: '❌',
        message: 'Firestore document not found'
      };
      return;
    }

    const data = firestoreDoc.data();

    if (data.supabase_user_id && data.ehr_id) {
      testResults.firestoreDoc = {
        status: '✅',
        message: `Document complete with supabase_user_id: ${data.supabase_user_id}, ehr_id: ${data.ehr_id}`
      };
    } else if (data.supabase_user_id && !data.ehr_id) {
      testResults.firestoreDoc = {
        status: '⚠️',
        message: `Document has supabase_user_id but missing ehr_id (status: ${data.ehr_status || 'unknown'})`
      };
    } else {
      testResults.firestoreDoc = {
        status: '❌',
        message: 'Document incomplete'
      };
    }

  } catch (error) {
    console.error('❌ Error verifying Firestore:', error.message);
    testResults.firestoreDoc = { status: '❌', message: error.message };
  }
}

async function cleanup(firebaseUid) {
  console.log('\n🧹 Cleaning up test user...');

  try {
    // Delete Firebase Auth user (this will trigger onUserDeleted)
    await admin.auth().deleteUser(firebaseUid);
    console.log('✅ Deleted Firebase Auth user');

    // Delete Supabase user if exists
    if (createdUserId) {
      await supabase.auth.admin.deleteUser(createdUserId);
      console.log('✅ Deleted Supabase Auth user');

      // Delete from users table
      await supabase.from('users').delete().eq('id', createdUserId);
      console.log('✅ Deleted Supabase users table record');

      // Delete from electronic_health_records
      await supabase.from('electronic_health_records').delete().eq('patient_id', createdUserId);
      console.log('✅ Deleted electronic_health_records entry');
    }

    // Note: We don't delete from EHRbase as it maintains audit trail
    if (createdEhrId) {
      console.log(`ℹ️  EHR ${createdEhrId} kept in EHRbase for audit trail`);
    }

  } catch (error) {
    console.error('⚠️  Cleanup error:', error.message);
  }
}

async function runTest() {
  let firebaseUid = null;

  try {
    console.log('🚀 Starting User Creation Flow Test');
    console.log('='.repeat(80));

    // Step 1: Create Firebase Auth user
    console.log('\n📝 Step 1: Creating Firebase Auth user...');
    const testEmail = `test-user-${Date.now()}@medzentest.com`;
    const testPassword = 'TestPassword123!';

    const userRecord = await admin.auth().createUser({
      email: testEmail,
      password: testPassword,
      displayName: 'Test User',
    });

    firebaseUid = userRecord.uid;

    testResults.firebaseAuth = {
      status: '✅',
      message: `User created: ${testEmail} (${firebaseUid})`
    };

    console.log(`✅ Firebase Auth user created: ${testEmail}`);
    console.log(`   UID: ${firebaseUid}`);

    // Step 2: Wait for Cloud Function
    const cloudFunctionCompleted = await waitForCloudFunction(firebaseUid, 30);

    if (!cloudFunctionCompleted) {
      console.log('\n❌ Cloud Function did not complete in time');
      console.log('Check Firebase Functions logs:');
      console.log('   firebase functions:log --only onUserCreated --limit 50');

      printResults();

      // Cleanup and exit
      await cleanup(firebaseUid);
      process.exit(1);
    }

    // Step 3: Verify Supabase user
    await verifySupabaseUser(firebaseUid);

    // Step 4: Verify EHRbase
    await verifyEHRbase();

    // Step 5: Verify Firestore document
    await verifyFirestoreDoc(firebaseUid);

    // Print results
    printResults();

    // Cleanup
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    readline.question('\nCleanup test user? (y/n): ', async (answer) => {
      if (answer.toLowerCase() === 'y') {
        await cleanup(firebaseUid);
      } else {
        console.log('\nTest user kept:');
        console.log(`   Email: ${testEmail}`);
        console.log(`   Password: ${testPassword}`);
        console.log(`   Firebase UID: ${firebaseUid}`);
        if (createdUserId) console.log(`   Supabase ID: ${createdUserId}`);
        if (createdEhrId) console.log(`   EHR ID: ${createdEhrId}`);
      }

      readline.close();
      process.exit(0);
    });

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error('Stack trace:', error.stack);

    if (firebaseUid) {
      await cleanup(firebaseUid);
    }

    process.exit(1);
  }
}

// Run the test
runTest();
