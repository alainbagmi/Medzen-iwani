#!/usr/bin/env node

/**
 * Verify FCM Token Setup
 * This script checks if a user has FCM tokens and displays their details
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-adminsdk-key.json'); // You'll need to download this

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function verifyFcmTokens(userId) {
  console.log('🔍 Checking FCM tokens for user:', userId);
  console.log('================================\n');

  try {
    // Get user's FCM tokens
    const tokensSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('fcm_tokens')
      .get();

    if (tokensSnapshot.empty) {
      console.log('⚠️  No FCM tokens found for this user');
      console.log('   This could mean:');
      console.log('   1. User has never logged in on a mobile device');
      console.log('   2. FCM token stream is not initialized');
      console.log('   3. App doesn\'t have notification permissions');
      return;
    }

    console.log(`✅ Found ${tokensSnapshot.size} FCM token(s)\n`);

    tokensSnapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`Token ID: ${doc.id}`);
      console.log(`  Device Type: ${data.device_type}`);
      console.log(`  Token (first 30 chars): ${data.fcm_token?.substring(0, 30)}...`);
      console.log(`  Created: ${data.created_at?.toDate() || 'N/A'}`);
      console.log(`  Last Updated: ${data.last_updated?.toDate() || 'N/A'}`);

      // Check if token is recent (within last 7 days)
      const lastUpdated = data.last_updated?.toDate() || data.created_at?.toDate();
      if (lastUpdated) {
        const daysSinceUpdate = Math.floor((Date.now() - lastUpdated.getTime()) / (1000 * 60 * 60 * 24));
        if (daysSinceUpdate > 7) {
          console.log(`  ⚠️  Token is ${daysSinceUpdate} days old - may be stale`);
        } else {
          console.log(`  ✅ Token is fresh (${daysSinceUpdate} days old)`);
        }
      }
      console.log('');
    });

    // Check for duplicate tokens across users
    const allTokens = tokensSnapshot.docs.map(doc => doc.data().fcm_token);
    for (const token of allTokens) {
      const duplicates = await db
        .collectionGroup('fcm_tokens')
        .where('fcm_token', '==', token)
        .get();

      if (duplicates.size > 1) {
        console.log(`⚠️  Warning: Token found in ${duplicates.size} user accounts (should be cleaned up)`);
      }
    }

  } catch (error) {
    console.error('❌ Error checking FCM tokens:', error.message);
    throw error;
  }
}

// Get userId from command line or use default
const userId = process.argv[2];

if (!userId) {
  console.error('❌ Usage: node verify_fcm_token_setup.js <firebase_user_id>');
  console.error('   Example: node verify_fcm_token_setup.js abc123def456');
  process.exit(1);
}

verifyFcmTokens(userId)
  .then(() => {
    console.log('================================');
    console.log('✅ Verification complete');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Verification failed:', error);
    process.exit(1);
  });
