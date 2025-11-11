const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// Initialize Firebase Admin with project ID
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'medzen-bf20e'
  });
}

// Initialize Supabase
const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function runTest() {
  console.log('🚀 Testing onUserCreated Flow');
  console.log('================================================================================\n');

  // Generate unique test email
  const timestamp = Date.now();
  const testEmail = `test-user-${timestamp}@medzen-test.com`;
  const testPassword = 'TestPassword123!';

  let testUserId = null;
  let supabaseUserId = null;

  try {
    // Step 1: Create Firebase Auth user (this triggers onUserCreated)
    console.log('📝 Step 1: Creating Firebase Auth user...');
    console.log(`   Email: ${testEmail}`);

    const userRecord = await admin.auth().createUser({
      email: testEmail,
      password: testPassword,
      emailVerified: false,
    });

    testUserId = userRecord.uid;
    console.log(`✅ Firebase user created: ${testUserId}`);

    // Step 2: Wait for Cloud Function to complete
    console.log('\n⏳ Step 2: Waiting 10 seconds for Cloud Function to complete...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Step 3: Check Firestore for supabase_user_id
    console.log('\n📝 Step 3: Checking Firestore document...');
    const firestoreDoc = await admin.firestore().collection('users').doc(testUserId).get();

    if (!firestoreDoc.exists) {
      throw new Error('❌ Firestore document not found');
    }

    const firestoreData = firestoreDoc.data();
    supabaseUserId = firestoreData.supabase_user_id;

    if (!supabaseUserId) {
      throw new Error('❌ supabase_user_id not found in Firestore');
    }

    console.log(`✅ Firestore document found`);
    console.log(`   Firebase UID: ${firestoreData.uid}`);
    console.log(`   Email: ${firestoreData.email}`);
    console.log(`   Supabase ID: ${supabaseUserId}`);

    // Step 4: Check Supabase Auth
    console.log('\n📝 Step 4: Checking Supabase Auth...');
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();

    if (authError) {
      throw new Error(`❌ Supabase Auth error: ${authError.message}`);
    }

    const supabaseAuthUser = authUsers.users.find(u => u.id === supabaseUserId);

    if (!supabaseAuthUser) {
      throw new Error('❌ Supabase Auth user not found');
    }

    console.log(`✅ Supabase Auth user found`);
    console.log(`   ID: ${supabaseAuthUser.id}`);
    console.log(`   Email: ${supabaseAuthUser.email}`);
    console.log(`   Created: ${supabaseAuthUser.created_at}`);

    // Step 5: Check electronic_health_records
    console.log('\n📝 Step 5: Checking electronic_health_records table...');
    const { data: ehrRecord, error: ehrError } = await supabase
      .from('electronic_health_records')
      .select('*')
      .eq('patient_id', supabaseUserId)
      .maybeSingle();

    if (ehrError) {
      throw new Error(`❌ EHR query error: ${ehrError.message}`);
    }

    if (!ehrRecord) {
      throw new Error('❌ electronic_health_records entry not found');
    }

    console.log(`✅ electronic_health_records entry found`);
    console.log(`   ID: ${ehrRecord.id}`);
    console.log(`   Patient ID: ${ehrRecord.patient_id}`);
    console.log(`   EHR ID: ${ehrRecord.ehr_id || 'pending (null)'}`);
    console.log(`   EHR Status: ${ehrRecord.ehr_status}`);
    console.log(`   User Role: ${ehrRecord.user_role}`);
    console.log(`   Created: ${ehrRecord.created_at}`);

    // Success Summary
    console.log('\n🎉 SUCCESS! All steps completed successfully');
    console.log('================================================================================');
    console.log('✅ Firebase Auth user created');
    console.log('✅ Firestore document created with supabase_user_id');
    console.log('✅ Supabase Auth user created');
    console.log('✅ electronic_health_records entry created');
    console.log('');
    console.log('⚠️  Note: EHR ID is pending - will be filled by Edge Function later');
    console.log('');

    // Cleanup
    console.log('🧹 Cleaning up test user...');

    // Delete from Firebase Auth
    await admin.auth().deleteUser(testUserId);
    console.log('✅ Deleted from Firebase Auth');

    // Delete from Supabase Auth
    const { error: deleteAuthError } = await supabase.auth.admin.deleteUser(supabaseUserId);
    if (deleteAuthError) {
      console.log(`⚠️  Supabase Auth deletion warning: ${deleteAuthError.message}`);
    } else {
      console.log('✅ Deleted from Supabase Auth');
    }

    // Delete from Firestore
    await admin.firestore().collection('users').doc(testUserId).delete();
    console.log('✅ Deleted from Firestore');

    // Delete from electronic_health_records
    const { error: deleteEhrError } = await supabase
      .from('electronic_health_records')
      .delete()
      .eq('patient_id', supabaseUserId);

    if (deleteEhrError) {
      console.log(`⚠️  EHR deletion warning: ${deleteEhrError.message}`);
    } else {
      console.log('✅ Deleted from electronic_health_records');
    }

    console.log('\n✨ Test complete - all cleanup done!');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ TEST FAILED:', error.message);
    console.error('\nStack trace:', error.stack);

    // Attempt cleanup even on failure
    if (testUserId) {
      console.log('\n🧹 Attempting cleanup after failure...');
      try {
        await admin.auth().deleteUser(testUserId);
        console.log('✅ Cleaned up Firebase Auth user');
      } catch (cleanupError) {
        console.log('⚠️  Could not clean up Firebase user:', cleanupError.message);
      }

      try {
        await admin.firestore().collection('users').doc(testUserId).delete();
        console.log('✅ Cleaned up Firestore document');
      } catch (cleanupError) {
        console.log('⚠️  Could not clean up Firestore:', cleanupError.message);
      }
    }

    if (supabaseUserId) {
      try {
        await supabase.auth.admin.deleteUser(supabaseUserId);
        console.log('✅ Cleaned up Supabase Auth user');
      } catch (cleanupError) {
        console.log('⚠️  Could not clean up Supabase Auth:', cleanupError.message);
      }

      try {
        await supabase
          .from('electronic_health_records')
          .delete()
          .eq('patient_id', supabaseUserId);
        console.log('✅ Cleaned up electronic_health_records');
      } catch (cleanupError) {
        console.log('⚠️  Could not clean up EHR:', cleanupError.message);
      }
    }

    process.exit(1);
  }
}

runTest();
