/**
 * Firebase JWT Signature Verification for Deno Runtime
 *
 * Cryptographically verifies Firebase JWT tokens using Firebase's public keys.
 * This prevents token forgery attacks by validating the RSA signature.
 */

interface FirebasePublicKeys {
  [kid: string]: string;
}

interface JWTHeader {
  alg: string;
  kid: string;
  typ: string;
}

interface FirebaseTokenPayload {
  aud: string;
  auth_time: number;
  user_id?: string;
  sub?: string;
  iat: number;
  exp: number;
  email?: string;
  email_verified?: boolean;
  firebase: {
    identities: Record<string, unknown>;
    sign_in_provider: string;
  };
  iss: string;
}

// Cache for Firebase public keys (refreshed when needed)
let publicKeysCache: FirebasePublicKeys | null = null;
let publicKeysCacheExpiry: number = 0;

/**
 * Fetches Firebase public keys from Google's endpoint
 */
async function fetchFirebasePublicKeys(): Promise<FirebasePublicKeys> {
  const now = Date.now();

  // Return cached keys if still valid
  if (publicKeysCache && publicKeysCacheExpiry > now) {
    return publicKeysCache;
  }

  const response = await fetch(
    "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
  );

  if (!response.ok) {
    throw new Error(`Failed to fetch Firebase public keys: ${response.statusText}`);
  }

  const keys = await response.json() as FirebasePublicKeys;

  // Cache for 1 hour (Firebase keys rotate daily but we refresh more frequently)
  publicKeysCache = keys;
  publicKeysCacheExpiry = now + (60 * 60 * 1000);

  return keys;
}

/**
 * Decodes base64url encoded string
 */
function base64UrlDecode(str: string): string {
  // Replace URL-safe characters with standard base64 characters
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');

  // Add padding if needed
  const pad = base64.length % 4;
  if (pad) {
    if (pad === 1) {
      throw new Error('Invalid base64url string');
    }
    base64 += new Array(5 - pad).join('=');
  }

  return atob(base64);
}

/**
 * Extracts SPKI (SubjectPublicKeyInfo) from X.509 certificate DER bytes
 *
 * X.509 certificate structure (ASN.1):
 * Certificate ::= SEQUENCE {
 *   tbsCertificate       TBSCertificate,
 *   signatureAlgorithm   AlgorithmIdentifier,
 *   signatureValue       BIT STRING
 * }
 *
 * TBSCertificate ::= SEQUENCE {
 *   version         [0]  EXPLICIT Version DEFAULT v1,
 *   serialNumber         CertificateSerialNumber,
 *   signature            AlgorithmIdentifier,
 *   issuer               Name,
 *   validity             Validity,
 *   subject              Name,
 *   subjectPublicKeyInfo SubjectPublicKeyInfo,  ← TARGET
 *   ...
 * }
 */
function extractSpkiFromX509(derBytes: Uint8Array): Uint8Array {
  let offset = 0;

  /**
   * Reads ASN.1 Tag-Length-Value (TLV) structure
   * Returns tag, length, value offset, and total length
   */
  function readTLV(startOffset: number): { tag: number; length: number; valueOffset: number; totalLength: number } {
    const tag = derBytes[startOffset];
    let lengthOffset = startOffset + 1;
    let length = derBytes[lengthOffset];
    let valueOffset = lengthOffset + 1;

    // Handle long form length (if bit 7 is set)
    if (length & 0x80) {
      const numLengthBytes = length & 0x7F;
      length = 0;
      for (let i = 0; i < numLengthBytes; i++) {
        length = (length << 8) | derBytes[lengthOffset + 1 + i];
      }
      valueOffset = lengthOffset + 1 + numLengthBytes;
    }

    return { tag, length, valueOffset, totalLength: valueOffset - startOffset + length };
  }

  /**
   * Skips over a complete TLV structure and returns the offset after it
   */
  function skipTLV(startOffset: number): number {
    const tlv = readTLV(startOffset);
    return startOffset + tlv.totalLength;
  }

  // Parse outer Certificate SEQUENCE
  const certTlv = readTLV(offset);
  if (certTlv.tag !== 0x30) {
    throw new Error(`Expected SEQUENCE tag (0x30) for Certificate, got 0x${certTlv.tag.toString(16)}`);
  }
  offset = certTlv.valueOffset;

  // Parse TBSCertificate SEQUENCE
  const tbsTlv = readTLV(offset);
  if (tbsTlv.tag !== 0x30) {
    throw new Error(`Expected SEQUENCE tag (0x30) for TBSCertificate, got 0x${tbsTlv.tag.toString(16)}`);
  }
  offset = tbsTlv.valueOffset;

  // Check for optional Version [0] EXPLICIT
  if (derBytes[offset] === 0xA0) {
    offset = skipTLV(offset);
  }

  // Skip SerialNumber INTEGER
  offset = skipTLV(offset);

  // Skip Signature AlgorithmIdentifier SEQUENCE
  offset = skipTLV(offset);

  // Skip Issuer Name SEQUENCE (variable length)
  offset = skipTLV(offset);

  // Skip Validity SEQUENCE
  offset = skipTLV(offset);

  // Skip Subject Name SEQUENCE (variable length)
  offset = skipTLV(offset);

  // Extract SubjectPublicKeyInfo SEQUENCE (TARGET)
  const spkiTlv = readTLV(offset);
  if (spkiTlv.tag !== 0x30) {
    throw new Error(`Expected SEQUENCE tag (0x30) for SubjectPublicKeyInfo, got 0x${spkiTlv.tag.toString(16)}`);
  }

  // Extract complete SPKI bytes (including tag and length)
  const spkiBytes = derBytes.slice(offset, offset + spkiTlv.totalLength);

  console.log(`[ASN.1 Parser] Successfully extracted SPKI (${spkiBytes.length} bytes) from X.509 certificate (${derBytes.length} bytes)`);

  return spkiBytes;
}

/**
 * Imports an RSA public key from X.509 certificate (PEM format)
 *
 * This function:
 * 1. Decodes PEM to DER (binary X.509 certificate)
 * 2. Uses ASN.1 parser to extract SPKI from X.509 certificate
 * 3. Imports SPKI using Web Crypto API with valid 'spki' KeyFormat
 *
 * Note: Web Crypto API only supports KeyFormat values: "raw", "pkcs8", "spki", "jwk"
 * The value "x509" is NOT valid and causes runtime TypeError in Deno 2.1.4+
 */
async function importPublicKey(pem: string): Promise<CryptoKey> {
  // Remove PEM header/footer and decode base64
  const pemContents = pem
    .replace(/-----BEGIN CERTIFICATE-----/g, '')
    .replace(/-----END CERTIFICATE-----/g, '')
    .replace(/\s/g, '');

  const x509Der = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));

  console.log(`[Key Import] Parsing X.509 certificate (${x509Der.length} bytes)`);

  // Extract SPKI from X.509 certificate using ASN.1 parser
  const spkiBytes = extractSpkiFromX509(x509Der);

  console.log(`[Key Import] Importing SPKI as RSA public key`);

  // Import the extracted SPKI using the correct 'spki' KeyFormat
  return await crypto.subtle.importKey(
    'spki', // Valid KeyFormat value (not 'x509')
    spkiBytes,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['verify']
  );
}

/**
 * Verifies Firebase JWT token signature and returns the decoded payload
 *
 * @param token - The Firebase JWT token to verify
 * @param projectId - Firebase project ID (for audience validation)
 * @returns Verified token payload
 * @throws Error if token is invalid or verification fails
 */
export async function verifyFirebaseToken(
  token: string,
  projectId: string
): Promise<FirebaseTokenPayload> {
  console.log('=== JWT Verification START ===');
  console.log('Token length:', token.length);
  console.log('Token prefix (first 50 chars):', token.substring(0, 50));
  console.log('Project ID:', projectId);

  // Split token into parts
  console.log('[STEP 1] Splitting token into parts...');
  const parts = token.split('.');
  if (parts.length !== 3) {
    console.error('❌ Token format error: got', parts.length, 'parts, expected 3');
    throw new Error('Invalid JWT format: must have 3 parts');
  }
  console.log('✓ Token has 3 parts');

  const [headerB64, payloadB64, signatureB64] = parts;

  // Decode header
  console.log('[STEP 2] Decoding JWT header...');
  let header: JWTHeader;
  try {
    header = JSON.parse(base64UrlDecode(headerB64));
    console.log('✓ Header decoded:', JSON.stringify(header));
  } catch (error) {
    console.error('❌ Header decode error:', error);
    throw new Error(`Invalid JWT header: ${(error as Error).message}`);
  }

  // Verify algorithm
  console.log('[STEP 3] Verifying algorithm...');
  console.log('Algorithm in token:', header.alg);
  if (header.alg !== 'RS256') {
    console.error('❌ Algorithm mismatch: expected RS256, got', header.alg);
    throw new Error(`Unsupported algorithm: ${header.alg}`);
  }
  console.log('✓ Algorithm is RS256');

  // Decode payload
  console.log('[STEP 4] Decoding JWT payload...');
  let payload: FirebaseTokenPayload;
  try {
    payload = JSON.parse(base64UrlDecode(payloadB64));
    console.log('✓ Payload decoded');
    console.log('Payload issuer:', payload.iss);
    console.log('Payload audience:', payload.aud);
    console.log('Payload exp:', payload.exp, '(' + new Date(payload.exp * 1000).toISOString() + ')');
    console.log('Payload iat:', payload.iat, '(' + new Date(payload.iat * 1000).toISOString() + ')');
    console.log('Payload user_id:', payload.user_id);
    console.log('Payload sub:', payload.sub);
  } catch (error) {
    console.error('❌ Payload decode error:', error);
    throw new Error(`Invalid JWT payload: ${(error as Error).message}`);
  }

  // Validate expiration
  console.log('[STEP 5] Validating expiration...');
  const now = Math.floor(Date.now() / 1000);
  console.log('Current time (unix):', now, '(' + new Date(now * 1000).toISOString() + ')');
  console.log('Token exp:', payload.exp, '(' + new Date(payload.exp * 1000).toISOString() + ')');
  console.log('Time until expiry (seconds):', payload.exp - now);
  if (payload.exp <= now) {
    console.error('❌ Token expired');
    throw new Error('Token expired');
  }
  console.log('✓ Token not expired');

  // Validate issued-at time
  console.log('[STEP 6] Validating issued-at time...');
  console.log('Token iat:', payload.iat, '(' + new Date(payload.iat * 1000).toISOString() + ')');
  console.log('Time since issued (seconds):', now - payload.iat);
  if (payload.iat > now) {
    console.error('❌ Token used before issued');
    throw new Error('Token used before issued');
  }
  console.log('✓ Token iat valid');

  // Validate issuer
  console.log('[STEP 7] Validating issuer...');
  const expectedIssuer = `https://securetoken.google.com/${projectId}`;
  console.log('Expected issuer:', expectedIssuer);
  console.log('Actual issuer:', payload.iss);
  console.log('Issuer match:', payload.iss === expectedIssuer);
  if (payload.iss !== expectedIssuer) {
    console.error('❌ Issuer mismatch');
    console.error('Expected:', expectedIssuer);
    console.error('Got:', payload.iss);
    throw new Error(`Invalid issuer: expected ${expectedIssuer}, got ${payload.iss}`);
  }
  console.log('✓ Issuer valid');

  // Validate audience (must match Firebase project ID)
  console.log('[STEP 8] Validating audience...');
  console.log('Expected audience:', projectId);
  console.log('Actual audience:', payload.aud);
  console.log('Audience match:', payload.aud === projectId);
  if (payload.aud !== projectId) {
    console.error('❌ Audience mismatch');
    console.error('Expected:', projectId);
    console.error('Got:', payload.aud);
    throw new Error(`Invalid audience: expected ${projectId}, got ${payload.aud}`);
  }
  console.log('✓ Audience valid');

  // Get Firebase public keys
  console.log('[STEP 9] Fetching Firebase public keys...');
  const publicKeys = await fetchFirebasePublicKeys();
  const availableKids = Object.keys(publicKeys);
  console.log('✓ Public keys fetched');
  console.log('Available kids:', availableKids);
  console.log('Number of available keys:', availableKids.length);

  // Get the public key for this token
  console.log('[STEP 10] Matching public key for token kid...');
  console.log('Token kid:', header.kid);
  console.log('Kid exists in available keys:', availableKids.includes(header.kid));
  const publicKeyPem = publicKeys[header.kid];
  if (!publicKeyPem) {
    console.error('❌ Public key not found for kid:', header.kid);
    console.error('Available kids:', availableKids);
    throw new Error(`Public key not found for kid: ${header.kid}`);
  }
  console.log('✓ Public key found for kid:', header.kid);
  console.log('Public key PEM length:', publicKeyPem.length);

  // Import the public key
  console.log('[STEP 11] Importing public key...');
  const publicKey = await importPublicKey(publicKeyPem);
  console.log('✓ Public key imported');

  // Verify signature
  console.log('[STEP 12] Verifying signature...');
  const signatureData = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  console.log('Signature data length:', signatureData.length);
  const signatureBytes = Uint8Array.from(
    atob(signatureB64.replace(/-/g, '+').replace(/_/g, '/')),
    c => c.charCodeAt(0)
  );
  console.log('Signature bytes length:', signatureBytes.length);

  const isValid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    publicKey,
    signatureBytes,
    signatureData
  );
  console.log('Signature verification result:', isValid);

  if (!isValid) {
    console.error('❌ Invalid token signature');
    throw new Error('Invalid token signature');
  }
  console.log('✓ Signature valid');

  // Extract Firebase UID
  const firebaseUid = payload.user_id || payload.sub;
  if (!firebaseUid) {
    console.error('❌ No user ID in token');
    throw new Error('No user ID in token');
  }

  console.log('=== Firebase JWT Verified Successfully ===');
  console.log('User ID (uid):', firebaseUid);
  console.log('Email:', payload.email);
  console.log('Token expiry:', new Date(payload.exp * 1000).toISOString());
  console.log('==========================================');

  return payload;
}
