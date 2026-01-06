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

  // Extract SPKI from X.509 certificate using ASN.1 parser
  const spkiBytes = extractSpkiFromX509(x509Der);

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
  // Split token into parts
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('Invalid JWT format: must have 3 parts');
  }

  const [headerB64, payloadB64, signatureB64] = parts;

  // Decode header
  let header: JWTHeader;
  try {
    header = JSON.parse(base64UrlDecode(headerB64));
  } catch (error) {
    throw new Error(`Invalid JWT header: ${(error as Error).message}`);
  }

  // Verify algorithm
  if (header.alg !== 'RS256') {
    throw new Error(`Unsupported algorithm: ${header.alg}`);
  }

  // Decode payload
  let payload: FirebaseTokenPayload;
  try {
    payload = JSON.parse(base64UrlDecode(payloadB64));
  } catch (error) {
    throw new Error(`Invalid JWT payload: ${(error as Error).message}`);
  }

  // Validate expiration
  const now = Math.floor(Date.now() / 1000);
  if (payload.exp <= now) {
    throw new Error('Token expired');
  }

  // Validate issued-at time
  if (payload.iat > now) {
    throw new Error('Token used before issued');
  }

  // Validate issuer
  const expectedIssuer = `https://securetoken.google.com/${projectId}`;
  if (payload.iss !== expectedIssuer) {
    throw new Error(`Invalid issuer: expected ${expectedIssuer}, got ${payload.iss}`);
  }

  // Validate audience (must match Firebase project ID)
  if (payload.aud !== projectId) {
    throw new Error(`Invalid audience: expected ${projectId}, got ${payload.aud}`);
  }

  // Get Firebase public keys
  const publicKeys = await fetchFirebasePublicKeys();

  // Get the public key for this token
  const publicKeyPem = publicKeys[header.kid];
  if (!publicKeyPem) {
    throw new Error(`Public key not found for kid: ${header.kid}`);
  }

  // Import the public key
  const publicKey = await importPublicKey(publicKeyPem);

  // Verify signature
  const signatureData = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signatureBytes = Uint8Array.from(
    atob(signatureB64.replace(/-/g, '+').replace(/_/g, '/')),
    c => c.charCodeAt(0)
  );

  const isValid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    publicKey,
    signatureBytes,
    signatureData
  );

  if (!isValid) {
    throw new Error('Invalid token signature');
  }

  // Extract Firebase UID
  const firebaseUid = payload.user_id || payload.sub;
  if (!firebaseUid) {
    throw new Error('No user ID in token');
  }

  return payload;
}
