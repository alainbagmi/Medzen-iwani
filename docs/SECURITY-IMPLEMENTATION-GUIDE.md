# MedZen Security Implementation Guide for Developers

**For:** Flutter developers, Edge Function developers, DevOps engineers
**Status:** ✅ Phase 1 Complete
**Last Updated:** 2026-01-23

---

## Quick Start

### For Edge Function Developers

#### 1. Import Security Modules
```typescript
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";
import { validateInput, sanitizeString, createValidationErrorResponse } from "../_shared/input-validator.ts";
```

#### 2. Add Rate Limiting
```typescript
serve(async (req) => {
  // Get request context
  const userId = auth.userId;
  const endpoint = 'your-function-name';

  // Check rate limit
  const rateLimitConfig = getRateLimitConfig(endpoint, userId);
  const rateLimit = await checkRateLimit(rateLimitConfig);

  if (!rateLimit.allowed) {
    return createRateLimitErrorResponse(rateLimit);
  }

  // Continue with function logic...
  return new Response(JSON.stringify({ success: true }), {
    headers: {
      ...getCorsHeaders(req.headers.get('origin') || ''),
      ...securityHeaders,
    },
  });
});
```

#### 3. Add Input Validation
```typescript
import { validateClinicalNote, createValidationErrorResponse } from "../_shared/input-validator.ts";

const validation = validateClinicalNote(requestBody);
if (!validation.valid) {
  return createValidationErrorResponse(validation.errors);
}

// Safe to use requestBody now
const clinicalNote = validation.data;
```

#### 4. Security Headers Template
```typescript
// Use in all functions
const response = new Response(JSON.stringify(result), {
  status: 200,
  headers: {
    'Content-Type': 'application/json',
    ...getCorsHeaders(req.headers.get('origin') || ''),
    ...securityHeaders,
  },
});
```

---

## CORS Policy (CRITICAL)

### ✅ CORRECT - Production
```typescript
'Access-Control-Allow-Origin': 'https://medzenhealth.app'
```

### ❌ WRONG - Wildcard (DO NOT USE)
```typescript
'Access-Control-Allow-Origin': '*'  // BLOCKED - HIPAA violation!
```

### Testing CORS

```bash
# Test authorized origin (should succeed)
curl -i -H "Origin: https://medzenhealth.app" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/your-function

# Test unauthorized origin (should fail)
curl -i -H "Origin: https://evil-site.com" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/your-function
```

---

## Rate Limiting

### Rate Limits by Endpoint

| Endpoint | Limit | Window |
|----------|-------|--------|
| `chime-meeting-token` | 10 requests | 60 seconds |
| `generate-soap-draft-v2` | 20 requests | 60 seconds |
| `bedrock-ai-chat` | 30 requests | 60 seconds |
| `upload-profile-picture` | 5 requests | 60 seconds |
| `start-medical-transcription` | 5 requests | 60 seconds |
| `sync-to-ehrbase` | 10 requests | 60 seconds |
| (default) | 100 requests | 60 seconds |

### Adding Rate Limiting to Your Function

```typescript
import { checkRateLimit, getRateLimitConfig } from "../_shared/rate-limiter.ts";

serve(async (req) => {
  // ... auth verification ...

  // Rate limiting (prevents API abuse)
  const identifier = userId; // or firebase_uid
  const config = getRateLimitConfig('your-function-name', identifier);
  const rateLimit = await checkRateLimit(config);

  if (!rateLimit.allowed) {
    return new Response(
      JSON.stringify({
        error: 'Rate limit exceeded',
        retryAfter: rateLimit.retryAfter,
        resetAt: rateLimit.resetAt.toISOString(),
      }),
      {
        status: 429,
        headers: {
          'Retry-After': rateLimit.retryAfter?.toString() || '60',
          'X-RateLimit-Remaining': rateLimit.remainingRequests.toString(),
        },
      }
    );
  }

  // Continue with function logic...
});
```

---

## Input Validation

### Validation Patterns Available

```typescript
import { ValidationPatterns } from "../_shared/input-validator.ts";

// Available patterns:
ValidationPatterns.uuid         // UUID format
ValidationPatterns.email        // Email format
ValidationPatterns.phone        // Phone number (E.164)
ValidationPatterns.firebaseUid  // Firebase UID
ValidationPatterns.userRole     // Enum: patient, medical_provider, etc.
```

### Using Built-in Validators

```typescript
import {
  validateUUID,
  validateEmail,
  validatePhone,
  validateClinicalNote,
  validateVideoCallRequest,
} from "../_shared/input-validator.ts";

// Validate individual fields
if (!validateUUID(appointmentId)) {
  return createValidationErrorResponse(['Invalid appointment ID']);
}

if (!validateEmail(userEmail)) {
  return createValidationErrorResponse(['Invalid email format']);
}

// Validate complex objects
const clinicalNoteValidation = validateClinicalNote(requestBody);
if (!clinicalNoteValidation.valid) {
  return createValidationErrorResponse(clinicalNoteValidation.errors);
}
```

### Custom Validation Example

```typescript
const validatePhoneNumber = (phone: unknown): boolean => {
  return validatePhone(phone);
};

const validateAppointmentRequest = (data: unknown): {
  valid: boolean;
  errors: string[];
} => {
  const errors: string[] = [];

  if (!data || typeof data !== 'object') {
    return { valid: false, errors: ['Must be an object'] };
  }

  const req = data as any;

  if (!validateUUID(req.appointmentId)) {
    errors.push('Invalid appointmentId');
  }

  if (!validatePhone(req.patientPhone)) {
    errors.push('Invalid patient phone number');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};
```

---

## PHI Access Audit Logging

### Automatic Logging (Database Triggers)

The following tables are automatically logged:
- `clinical_notes` - SOAP notes and assessments
- `patient_profiles` - Patient demographics
- `appointments` - Appointment details
- `video_call_sessions` - Video call records

**No code changes needed** - triggers log automatically.

### Viewing Audit Logs (Admin Only)

```sql
-- View recent access logs
SELECT * FROM phi_access_audit_log
ORDER BY created_at DESC
LIMIT 100;

-- View access by user
SELECT * FROM phi_access_audit_log
WHERE user_id = '<user-id>'
ORDER BY created_at DESC;

-- View access by patient
SELECT * FROM phi_access_audit_log
WHERE patient_id = '<patient-id>'
ORDER BY created_at DESC;

-- Monthly summary
SELECT * FROM monthly_phi_access_summary;
```

### Logging in Edge Functions (Manual)

```typescript
// Insert custom audit log entry (if needed)
const { data, error } = await supabase
  .from('phi_access_audit_log')
  .insert({
    user_id: userId,
    patient_id: patientId,
    access_type: 'export',
    table_name: 'clinical_notes',
    record_id: noteId,
    reason: 'PDF export for patient',
    ip_address: req.headers.get('x-forwarded-for'),
    user_agent: req.headers.get('user-agent'),
  });
```

---

## Session Timeout (Flutter)

### For Flutter Developers

The app automatically implements:
- **15-minute idle timeout** - Auto-logout after 15 minutes without activity
- **8-hour max session** - Auto-logout after 8 hours regardless of activity

**No code changes needed in most cases** - app handles automatically.

### Manual Session Management (if needed)

```dart
// Update activity timestamp (called on any user interaction)
SessionManager.resetIdleTimer();

// Check if session expired
if (SessionManager.isSessionExpired()) {
  await SessionManager.signOut();
  GoRouter.of(context).go('/login?reason=session_expired');
}

// Manual logout
await SessionManager.signOut();
```

### Testing Session Timeout

1. Login to app
2. Don't interact for 15 minutes
3. Verify auto-logout occurs
4. Check that session is marked as "timeout_idle" in database

---

## MFA Enrollment (Flutter)

### For Flutter Developers

MFA requirements (Phase 2 - not yet deployed):
- **Providers** - MFA required (7-day grace period)
- **Facility Admins** - MFA required (7-day grace period)
- **System Admins** - MFA required (immediate)
- **Patients** - MFA optional

### Checking MFA Status

```dart
// Get user's MFA compliance status
final mfaStatus = await supabase
  .from('mfa_compliance_status')
  .select()
  .eq('id', userId)
  .single();

print('MFA Status: ${mfaStatus['mfa_status']}');
// Returns: 'compliant', 'grace_period', 'non_compliant'

if (mfaStatus['mfa_status'] == 'non_compliant') {
  // Redirect to MFA enrollment
  GoRouter.of(context).go('/auth/enroll-mfa');
}
```

---

## Security Best Practices

### ✅ DO

1. **Always validate inputs** - Use input-validator.ts for all user data
2. **Always check rate limits** - Use rate-limiter.ts on all APIs
3. **Always use CORS headers** - Use getCorsHeaders() for origin validation
4. **Always use security headers** - Include securityHeaders in responses
5. **Always authenticate** - Verify Firebase token before processing
6. **Always log PHI access** - Database triggers handle automatically
7. **Always use HTTPS** - All APIs use TLS 1.2+
8. **Always sanitize output** - Use sanitizeString() for user-displayed content

### ❌ DON'T

1. **Don't use CORS wildcard** - `Access-Control-Allow-Origin: *` is blocked
2. **Don't hardcode secrets** - Use environment variables only
3. **Don't trust user input** - Always validate and sanitize
4. **Don't disable rate limiting** - Even admins are rate limited
5. **Don't log passwords** - Audit logs exclude sensitive data
6. **Don't comment out validation** - Never bypass security checks
7. **Don't use HTTP** - All traffic must use TLS 1.2+
8. **Don't expose error details** - Return generic errors to clients

---

## Common Patterns

### Pattern 1: Complete Edge Function (Secure)

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";
import { validateInput, ValidationSchemas, createValidationErrorResponse } from "../_shared/input-validator.ts";
import { verifyFirebaseToken } from "../_shared/verify-firebase-jwt.ts";

interface RequestBody {
  patientId: string;
  data: string;
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        ...getCorsHeaders(req.headers.get('origin') || ''),
        ...securityHeaders,
      },
    });
  }

  try {
    // 1. Authenticate
    const token = req.headers.get('x-firebase-token');
    const auth = await verifyFirebaseToken(token);
    if (!auth.valid) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: securityHeaders,
      });
    }

    // 2. Rate limiting
    const rateLimitConfig = getRateLimitConfig('your-function', auth.userId);
    const rateLimit = await checkRateLimit(rateLimitConfig);
    if (!rateLimit.allowed) {
      return createRateLimitErrorResponse(rateLimit);
    }

    // 3. Parse request
    const body: RequestBody = await req.json();

    // 4. Input validation
    if (!body.patientId || typeof body.patientId !== 'string') {
      return createValidationErrorResponse(['Invalid patientId']);
    }

    // 5. Business logic
    const result = await processData(body.patientId, body.data);

    // 6. Return success
    return new Response(JSON.stringify({ success: true, data: result }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...getCorsHeaders(req.headers.get('origin') || ''),
        ...securityHeaders,
      },
    });
  } catch (error) {
    console.error('Function error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: securityHeaders,
    });
  }
});

async function processData(patientId: string, data: string): Promise<any> {
  // Your business logic here
  return { processed: true };
}
```

### Pattern 2: Flutter Session Management

```dart
// In main.dart or initialization file
void setupSecurityControls() {
  // Initialize session manager
  SessionManager.initSession();

  // Track all user interactions
  GestureDetector(
    onTap: () => SessionManager.resetIdleTimer(),
    onPanDown: (_) => SessionManager.resetIdleTimer(),
    child: MaterialApp(
      // ... app configuration
    ),
  );

  // Periodic check for expired sessions
  Timer.periodic(Duration(minutes: 1), (_) {
    if (SessionManager.isSessionExpired()) {
      SessionManager.signOut();
      // Navigate to login
    }
  });
}
```

---

## Troubleshooting

### Problem: "Rate limit exceeded" error
**Solution:**
1. Check rate limit config for endpoint
2. Verify identifier is consistent (user_id)
3. Wait for window to reset (usually 60 seconds)
4. Contact ops if legitimate need for higher limit

### Problem: CORS error in browser
**Solution:**
1. Verify origin matches `https://medzenhealth.app`
2. Check cors.ts is deployed
3. Check edge function returns proper CORS headers
4. Test with: `curl -H "Origin: https://medzenhealth.app" ...`

### Problem: Input validation failing unexpectedly
**Solution:**
1. Check validation function for your data type
2. Use `sanitizeString()` if data is user-generated
3. Add console.log to debug validation
4. Check regex patterns match your data

### Problem: Audit logging not working
**Solution:**
1. Check table triggers are enabled: `SELECT * FROM pg_trigger WHERE tgname LIKE 'audit%'`
2. Verify phi_access_audit_log has data: `SELECT COUNT(*) FROM phi_access_audit_log`
3. Check user is authenticated (audit needs user_id)
4. Verify table is one of: clinical_notes, patient_profiles, appointments, video_call_sessions

---

## Contact & Support

**Issues with security implementation?**
1. Check this guide first
2. Review PHASE-1-DEPLOYMENT-CHECKLIST.md
3. Contact Security Officer: [email]
4. Escalate to CTO if critical

**Security vulnerabilities found?**
1. Do NOT commit to main branch
2. Document in private security thread
3. Contact CTO immediately
4. Follow incident response procedures

---

## Compliance References

**HIPAA Requirements Implemented:**
- 164.308(a)(1)(ii)(D) - Incident response
- 164.312(a)(2)(i) - Authentication (MFA)
- 164.312(a)(2)(ii) - User identification (Firebase UID)
- 164.312(a)(2)(iii) - Session timeout (15-min idle)
- 164.312(b) - Audit logging (PHI access log)
- 164.312(a)(2)(iv) - Encryption (TLS 1.2+, KMS)

**GDPR Requirements Implemented:**
- Article 32 - Security (encryption, access controls, audit logging)
- Article 33 - Breach notification (incident playbook)
- Article 35 - Data protection impact assessment (security assessment)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-23
**Status:** ✅ Active
**Next Review:** 2026-02-23
