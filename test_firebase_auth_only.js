/**
 * Test Firebase Auth Account Creation (No Backend Integration)
 * Tests ONLY Firebase Auth to isolate the signup issue
 */

const axios = require('axios');

const FIREBASE_API_KEY = 'AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ';
const TEST_EMAIL = `test-auth-${Date.now()}@medzentest.com`;
const TEST_PASSWORD = 'TestPassword123!';

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testFirebaseAuthOnly() {
  log('\n========================================', 'cyan');
  log('    Firebase Auth Test (Isolated)', 'cyan');
  log('========================================\n', 'cyan');

  log(`Test Email: ${TEST_EMAIL}`, 'cyan');
  log(`Password: ${TEST_PASSWORD}`, 'cyan');
  log(`API Key: ${FIREBASE_API_KEY}\n`, 'cyan');

  try {
    // Test 1: Create Firebase user via REST API
    log('[1/3] Creating Firebase user via REST API...', 'cyan');

    const signUpResponse = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`,
      {
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        returnSecureToken: true
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const firebaseUid = signUpResponse.data.localId;
    const idToken = signUpResponse.data.idToken;

    log(`✅ Firebase user created successfully!`, 'green');
    log(`   UID: ${firebaseUid}`, 'green');
    log(`   Email: ${signUpResponse.data.email}`, 'green');
    log(`   ID Token: ${idToken.substring(0, 50)}...`, 'green');

    // Test 2: Verify the user exists by getting account info
    log('\n[2/3] Verifying user exists in Firebase...', 'cyan');

    const getUserResponse = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${FIREBASE_API_KEY}`,
      {
        idToken: idToken
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const userInfo = getUserResponse.data.users[0];
    log(`✅ User verified in Firebase!`, 'green');
    log(`   UID: ${userInfo.localId}`, 'green');
    log(`   Email: ${userInfo.email}`, 'green');
    log(`   Email Verified: ${userInfo.emailVerified}`, 'green');
    log(`   Created At: ${new Date(parseInt(userInfo.createdAt)).toISOString()}`, 'green');

    // Test 3: Try to sign in with the created account
    log('\n[3/3] Testing sign-in with created account...', 'cyan');

    const signInResponse = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
      {
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        returnSecureToken: true
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    log(`✅ Sign-in successful!`, 'green');
    log(`   UID: ${signInResponse.data.localId}`, 'green');
    log(`   ID Token obtained: ${signInResponse.data.idToken.substring(0, 50)}...`, 'green');

    // Summary
    log('\n========================================', 'cyan');
    log('           TEST RESULTS', 'cyan');
    log('========================================', 'cyan');
    log('✅ Firebase Auth signup: WORKING', 'green');
    log('✅ User verification: WORKING', 'green');
    log('✅ Sign-in: WORKING', 'green');
    log('\n🎉 Firebase Auth is functioning correctly!', 'green');
    log('\nThe 400 error you saw is likely from:', 'yellow');
    log('  1. Twilio phone verification (404 error)', 'yellow');
    log('  2. Some additional validation in your app', 'yellow');
    log('  3. Not from Firebase Auth itself\n', 'yellow');

    log('Test User Created:', 'cyan');
    log(`  Email: ${TEST_EMAIL}`, 'cyan');
    log(`  UID: ${firebaseUid}`, 'cyan');
    log(`  Password: ${TEST_PASSWORD}\n`, 'cyan');

  } catch (error) {
    log(`\n❌ Error: ${error.message}`, 'red');

    if (error.response) {
      log(`\nResponse Status: ${error.response.status}`, 'red');
      log(`Response Data:`, 'red');
      console.log(JSON.stringify(error.response.data, null, 2));

      if (error.response.data.error) {
        log(`\nError Code: ${error.response.data.error.code}`, 'red');
        log(`Error Message: ${error.response.data.error.message}`, 'red');
      }
    }

    process.exit(1);
  }
}

// Run the test
testFirebaseAuthOnly().catch(error => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});
