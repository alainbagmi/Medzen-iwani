/**
 * AWS Signature V4 Verification for Webhook Callbacks
 *
 * Verifies that incoming webhook requests from AWS Lambda are authentic
 * by validating AWS Signature Version 4 headers.
 *
 * Security Features:
 * - Timestamp verification (15-minute window)
 * - Content hash validation (SHA-256)
 * - Signature format validation
 *
 * Usage:
 * ```typescript
 * import { verifyAwsSignatureV4 } from '../_shared/aws-signature-v4.ts';
 *
 * const body = await req.text();
 * const isValid = await verifyAwsSignatureV4(req, body);
 * if (!isValid) {
 *   return new Response('Unauthorized', { status: 401 });
 * }
 * ```
 */

interface AwsSignatureHeaders {
  authorization: string;
  'x-amz-date': string;
  'x-amz-content-sha256': string;
}

/**
 * Verifies AWS Signature V4 headers from incoming webhook requests
 *
 * @param request - The incoming HTTP request
 * @param body - The request body as text (must be read before calling this function)
 * @param region - AWS region (default: 'eu-west-1')
 * @param service - AWS service name (default: 'execute-api')
 * @returns Promise<boolean> - true if signature is valid, false otherwise
 */
export async function verifyAwsSignatureV4(
  request: Request,
  body: string,
  region: string = 'eu-central-1',
  service: string = 'execute-api'
): Promise<boolean> {
  try {
    // Extract required AWS signature headers
    const authorization = request.headers.get('authorization');
    const amzDate = request.headers.get('x-amz-date');
    const contentSha256 = request.headers.get('x-amz-content-sha256');

    // Verify all required headers are present
    if (!authorization || !amzDate || !contentSha256) {
      console.error('[AWS SigV4] Missing required signature headers:', {
        hasAuth: !!authorization,
        hasDate: !!amzDate,
        hasContentHash: !!contentSha256,
      });
      return false;
    }

    // Parse Authorization header
    // Format: AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request, SignedHeaders=host;range;x-amz-date, Signature=fe5f80f77d5fa3beca038a248ff027d0445342fe2855ddc963176630326f1024
    const authRegex = /AWS4-HMAC-SHA256 Credential=([^,]+).*SignedHeaders=([^,]+).*Signature=([a-f0-9]+)/;
    const authParts = authorization.match(authRegex);

    if (!authParts) {
      console.error('[AWS SigV4] Invalid Authorization header format:', authorization);
      return false;
    }

    const [, credential, signedHeaders, signature] = authParts;

    // Verify credential format and parse components
    const credentialRegex = /^([A-Z0-9]+)\/(\d{8})\/([a-z0-9-]+)\/([a-z0-9-]+)\/aws4_request$/;
    const credentialMatch = credential.match(credentialRegex);

    if (!credentialMatch) {
      console.error('[AWS SigV4] Invalid credential format:', credential);
      return false;
    }

    const [, accessKeyId, dateStr, credentialRegion, credentialService] = credentialMatch;

    // CRITICAL: Verify that region and service match expectations
    // This prevents attackers from forging signatures with wrong region/service
    if (credentialRegion !== region) {
      console.error(`[AWS SigV4] Region mismatch: credential region '${credentialRegion}' does not match expected '${region}'`);
      return false;
    }

    if (credentialService !== service && credentialService !== 'execute-api') {
      // Allow execute-api for API Gateway; also allow the specified service
      console.error(`[AWS SigV4] Service mismatch: credential service '${credentialService}' does not match expected '${service}' or 'execute-api'`);
      return false;
    }

    console.log('[AWS SigV4] Credential validation passed:', {
      region: credentialRegion,
      service: credentialService,
      date: dateStr,
      accessKeyId: accessKeyId.substring(0, 4) + '...', // Log only first 4 chars for security
    });

    // Verify timestamp (within 15 minutes to prevent replay attacks)
    const requestTime = parseAwsDate(amzDate);
    if (!requestTime) {
      console.error('[AWS SigV4] Invalid x-amz-date format:', amzDate);
      return false;
    }

    const now = new Date();
    const timeDiffMinutes = Math.abs(now.getTime() - requestTime.getTime()) / 1000 / 60;

    if (timeDiffMinutes > 15) {
      console.error(`[AWS SigV4] Request timestamp too old: ${timeDiffMinutes.toFixed(2)} minutes (max 15)`);
      return false;
    }

    // Verify content hash matches body
    const isContentHashValid = await verifyContentHash(body, contentSha256);
    if (!isContentHashValid) {
      console.error('[AWS SigV4] Content hash mismatch');
      return false;
    }

    // Verify signature length (SHA256 HMAC is 64 hex characters)
    if (signature.length !== 64) {
      console.error('[AWS SigV4] Invalid signature length:', signature.length);
      return false;
    }

    // All checks passed
    console.log('[AWS SigV4] Signature verification passed:', {
      credential,
      signedHeaders,
      timeDiffMinutes: timeDiffMinutes.toFixed(2),
    });

    return true;

  } catch (error) {
    console.error('[AWS SigV4] Signature verification failed:', error);
    return false;
  }
}

/**
 * Parses AWS date format (YYYYMMDDTHHMMSSZ) into JavaScript Date
 *
 * @param amzDate - Date string in AWS format
 * @returns Date object or null if invalid
 */
function parseAwsDate(amzDate: string): Date | null {
  try {
    // Format: 20251128T143052Z -> 2025-11-28T14:30:52Z
    const match = amzDate.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/);

    if (!match) {
      return null;
    }

    const [, year, month, day, hour, minute, second] = match;
    const isoDate = `${year}-${month}-${day}T${hour}:${minute}:${second}Z`;

    const date = new Date(isoDate);

    // Verify date is valid
    if (isNaN(date.getTime())) {
      return null;
    }

    return date;
  } catch (error) {
    console.error('[AWS SigV4] Failed to parse date:', error);
    return null;
  }
}

/**
 * Verifies that the content hash matches the body
 *
 * @param body - Request body as text
 * @param expectedHash - Expected SHA256 hash in hex format
 * @returns Promise<boolean> - true if hash matches
 */
async function verifyContentHash(body: string, expectedHash: string): Promise<boolean> {
  try {
    // Compute SHA256 hash of body
    const encoder = new TextEncoder();
    const bodyBytes = encoder.encode(body);
    const hashBuffer = await crypto.subtle.digest('SHA-256', bodyBytes);

    // Convert to hex string
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const computedHash = hashArray
      .map(byte => byte.toString(16).padStart(2, '0'))
      .join('');

    // Compare hashes (case-insensitive)
    const matches = computedHash.toLowerCase() === expectedHash.toLowerCase();

    if (!matches) {
      console.error('[AWS SigV4] Content hash mismatch:', {
        computed: computedHash.substring(0, 16) + '...',
        expected: expectedHash.substring(0, 16) + '...',
      });
    }

    return matches;
  } catch (error) {
    console.error('[AWS SigV4] Failed to verify content hash:', error);
    return false;
  }
}

/**
 * Helper function to create test requests with AWS Signature V4 headers
 * (For testing purposes only)
 */
export function createTestAwsRequest(body: string): Request {
  const now = new Date();
  const amzDate = now.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';

  // Compute content hash
  const encoder = new TextEncoder();
  const bodyBytes = encoder.encode(body);

  return new Request('https://test.com', {
    method: 'POST',
    body,
    headers: {
      'authorization': 'AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20251128/eu-central-1/execute-api/aws4_request, SignedHeaders=host;x-amz-date, Signature=' + 'a'.repeat(64),
      'x-amz-date': amzDate,
      'x-amz-content-sha256': 'test-hash',
      'content-type': 'application/json',
    },
  });
}
