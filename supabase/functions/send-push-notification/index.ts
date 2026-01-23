// Supabase Edge Function: send-push-notification
// Sends FCM push notifications via Firebase Cloud Messaging HTTP v1 API
// Used for force logout and other server-initiated notifications

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';

interface PushNotificationRequest {
  fcm_token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

serve(async (req) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    const { fcm_token, title, body, data } = await req.json() as PushNotificationRequest;

    if (!fcm_token) {
      return new Response(
        JSON.stringify({ error: 'fcm_token is required' }),
        { status: 400, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get Firebase service account credentials from environment
    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'medzen-bf20e';
    const firebasePrivateKey = Deno.env.get('FIREBASE_PRIVATE_KEY');
    const firebaseClientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL');

    if (!firebasePrivateKey || !firebaseClientEmail) {
      console.error('Firebase credentials not configured');
      return new Response(
        JSON.stringify({ error: 'Firebase credentials not configured' }),
        { status: 500, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Generate OAuth2 access token for FCM
    const accessToken = await getFirebaseAccessToken(
      firebaseClientEmail,
      firebasePrivateKey.replace(/\\n/g, '\n'),
      firebaseProjectId
    );

    // Send FCM notification using HTTP v1 API
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: fcm_token,
            notification: {
              title,
              body,
            },
            data: data || {},
            android: {
              priority: 'high',
              notification: {
                channel_id: 'alerts',
                sound: 'default',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          },
        }),
      }
    );

    if (!fcmResponse.ok) {
      const errorText = await fcmResponse.text();
      console.error('FCM error:', errorText);

      // Check if token is invalid (user uninstalled app or token expired)
      if (errorText.includes('UNREGISTERED') || errorText.includes('INVALID_ARGUMENT')) {
        return new Response(
          JSON.stringify({ error: 'Invalid FCM token', details: errorText }),
          { status: 410, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({ error: 'Failed to send notification', details: errorText }),
        { status: fcmResponse.status, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const result = await fcmResponse.json();
    console.log('FCM notification sent:', result);

    return new Response(
      JSON.stringify({ success: true, messageId: result.name }),
      { status: 200, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending push notification:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

// Generate OAuth2 access token for Firebase
async function getFirebaseAccessToken(
  clientEmail: string,
  privateKey: string,
  projectId: string
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600; // 1 hour expiry

  // Create JWT header and payload
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp,
  };

  // Base64url encode
  const base64url = (obj: object) => {
    const json = JSON.stringify(obj);
    const base64 = btoa(json);
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  };

  const headerEncoded = base64url(header);
  const payloadEncoded = base64url(payload);
  const signatureInput = `${headerEncoded}.${payloadEncoded}`;

  // Import private key and sign
  const keyData = privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '');

  const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  );

  const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');

  const jwt = `${signatureInput}.${signatureBase64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text();
    throw new Error(`Failed to get access token: ${error}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}
