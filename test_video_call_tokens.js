#!/usr/bin/env node

/**
 * Test script for Agora video call token generation
 * Tests the generateVideoCallTokens Firebase function
 */

const https = require('https');

// Test data
const TEST_DATA = {
  providerUserId: 'test-provider-123',
  patientUserId: 'test-patient-456',
  channelName: 'test-channel-' + Date.now(),
  appointmentId: 'test-appt-' + Date.now()
};

console.log('🧪 Testing Agora Video Call Token Generation\n');
console.log('Test Data:', JSON.stringify(TEST_DATA, null, 2));
console.log('\n📞 Calling generateVideoCallTokens function...\n');

// Call Firebase function via HTTPS
const postData = JSON.stringify({ data: TEST_DATA });

const options = {
  hostname: 'us-central1-medzen-bf20e.cloudfunctions.net',
  port: 443,
  path: '/generateVideoCallTokens',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    try {
      const response = JSON.parse(data);

      if (res.statusCode === 200 && response.result) {
        console.log('✅ SUCCESS! Token generation working\n');
        console.log('Response:', JSON.stringify(response.result, null, 2));

        // Validate tokens
        const result = response.result;
        if (result.providerToken && result.patientToken) {
          console.log('\n🎉 Both tokens generated successfully:');
          console.log('   Provider Token:', result.providerToken.substring(0, 50) + '...');
          console.log('   Patient Token:', result.patientToken.substring(0, 50) + '...');
          console.log('   Channel:', result.channelName);
          console.log('   App ID:', result.appId);
          console.log('\n✅ All checks passed! Video calling is ready to use.');
        } else {
          console.log('❌ ERROR: Tokens missing in response');
        }
      } else {
        console.log('❌ ERROR: Function call failed\n');
        console.log('Status Code:', res.statusCode);
        console.log('Response:', JSON.stringify(response, null, 2));
      }
    } catch (error) {
      console.log('❌ ERROR: Failed to parse response\n');
      console.log('Raw response:', data);
      console.log('Error:', error.message);
    }
  });
});

req.on('error', (error) => {
  console.log('❌ ERROR: Request failed\n');
  console.log('Error:', error.message);
});

req.write(postData);
req.end();
