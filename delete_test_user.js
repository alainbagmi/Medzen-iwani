const admin = require('firebase-admin');

// Initialize Firebase Admin (uses GOOGLE_APPLICATION_CREDENTIALS env var)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'medzen-bf20e'
  });
}

const uid = process.argv[2];

if (!uid) {
  console.error('Usage: node delete_test_user.js <firebase-uid>');
  process.exit(1);
}

async function deleteUser() {
  try {
    console.log(`Deleting user: ${uid}`);
    await admin.auth().deleteUser(uid);
    console.log('✅ User deleted successfully');
  } catch (error) {
    console.error('❌ Error deleting user:', error.message);
    process.exit(1);
  }
}

deleteUser();
