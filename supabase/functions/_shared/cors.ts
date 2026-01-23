// HIPAA/GDPR Compliant CORS Headers
// Only allow production domain for PHI access
const ALLOWED_ORIGINS = [
  'https://medzenhealth.app',
  'https://www.medzenhealth.app',
  // Development/staging origins
  ...(Deno.env.get('ENVIRONMENT') === 'development'
    ? ['http://localhost:3000', 'http://localhost:5173']
    : []),
];

export const getCorsHeaders = (origin?: string) => {
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin || '') ? origin : undefined;

  return {
    'Access-Control-Allow-Origin': allowedOrigin || 'https://medzenhealth.app',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-firebase-token',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Max-Age': '86400',
  };
};

// Security headers for HIPAA/GDPR compliance
export const securityHeaders = {
  'Content-Security-Policy': "default-src 'self'; script-src 'self' https://du6iimxem4mh7.cloudfront.net; connect-src 'self' https://*.supabase.co https://*.firebaseapp.com; frame-ancestors 'none';",
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(self), microphone=(self), camera=(self)',
};

// Legacy export for backward compatibility
export const corsHeaders = getCorsHeaders();
