const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'medzen-bf20e'
  });
}

const testEmail = process.argv[2];
const testPassword = 'TestPassword123!';

if (!testEmail) {
  console.error('Usage: node create_test_user.js <email>');
  process.exit(1);
}

async function createTestUser() {
  try {
    console.log(`\n🚀 Creating test user: ${testEmail}`);

    // Create user
    const userRecord = await admin.auth().createUser({
      email: testEmail,
      password: testPassword,
      emailVerified: true,
    });

    console.log(`✅ User created successfully!`);
    console.log(`   Firebase UID: ${userRecord.uid}`);
    console.log(`   Email: ${userRecord.email}`);
    console.log(`   Password: ${testPassword}`);
    console.log(`\n⏳ Waiting 8 seconds for onUserCreated Cloud Function to complete...`);

    // Wait for Cloud Function to process
    await new Promise(resolve => setTimeout(resolve, 8000));

    console.log(`\n✅ Ready for verification!`);
    console.log(`\nRun this to verify:`);
    console.log(`./test_production_user.sh ${testEmail}\n`);

  } catch (error) {
    console.error(`❌ Error creating user: ${error.message}`);
    if (error.code === 'auth/email-already-exists') {
      console.log(`\n⚠️  User already exists. You can still verify:`);
      console.log(`./test_production_user.sh ${testEmail}\n`);
    }
    process.exit(1);
  }
}

createTestUser();
