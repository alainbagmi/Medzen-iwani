# Permissions-Policy Headers Implementation Guide

**Status:** Optional Security Enhancement
**Effort:** 15 minutes
**Complexity:** Low
**Impact:** Restricts media device access to authorized context only
**Blocking:** No - Platform works without this

---

## What Are Permissions-Policy Headers?

Permissions-Policy (formerly Feature-Policy) headers tell the browser which features can be used in your page:
- Camera access (camera)
- Microphone access (microphone)
- Full screen (fullscreen)
- Payment API, geolocation, etc.

**Purpose:** Enhanced security by restricting which origins can use sensitive hardware.

---

## Why Implement This?

**Security Benefits:**
- ✅ Prevents unauthorized framing of your page
- ✅ Blocks nested iframes from accessing camera/mic
- ✅ Reduces XSS attack surface
- ✅ Browser reports violations (good for monitoring)

**When Not Necessary:**
- Your page is only accessed directly (not in iframes)
- You control all resources loaded on the page
- Security audit not required

---

## Three Implementation Options

### Option 1: Supabase Edge Function Response Headers (RECOMMENDED)

**File:** `supabase/functions/chime-meeting-token/index.ts`

**Why:** The edge function returns the video call setup, so it's the perfect place to add headers.

**Implementation:**

Find the response construction (around line 200-250), modify the response to include headers:

```typescript
// Find where the response is returned
// It should look something like:

return new Response(
  JSON.stringify({
    // response data
  }),
  {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      // ADD THESE LINES:
      'Permissions-Policy': 'camera=(self), microphone=(self), fullscreen=(self)',
    },
    status: 200,
  },
);
```

**Complete headers example:**

```typescript
return new Response(
  JSON.stringify(responseData),
  {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': corsOrigin,
      'Access-Control-Allow-Headers':
        'authorization, x-client-info, apikey, content-type, x-firebase-token',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',

      // Security headers
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'SAMEORIGIN',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',

      // Permissions-Policy (Feature-Policy)
      'Permissions-Policy': 'camera=(self), microphone=(self), fullscreen=(self)',
    },
    status: 200,
  },
);
```

**Testing the header:**

```bash
# Check if header is present
curl -I "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "apikey: YOUR_KEY" \
  -H "x-firebase-token: YOUR_TOKEN"

# Look for "Permissions-Policy" in the response headers
```

---

### Option 2: CloudFlare Pages Configuration

**Why:** If your web app is deployed on CloudFlare Pages

**Steps:**

1. **Create `_headers` file in your `build/web/` directory:**

```
/
  Permissions-Policy: camera=(self), microphone=(self), fullscreen=(self)
  X-Content-Type-Options: nosniff
  X-Frame-Options: SAMEORIGIN
```

2. **Or configure in CloudFlare Dashboard:**
   - Go to: https://dash.cloudflare.com
   - Select your domain (medzenhealth.app)
   - Rules → HTTP Request Header Modification
   - Add custom header:
     - **Name:** `Permissions-Policy`
     - **Value:** `camera=(self), microphone=(self), fullscreen=(self)`

3. **Deploy:**
```bash
wrangler pages deploy build/web/
```

---

### Option 3: HTML Template (If Self-Hosting)

**File:** `web/index.html` (if you have one)

```html
<head>
  <!-- Existing meta tags -->
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- ADD THIS LINE: -->
  <meta http-equiv="Permissions-Policy"
        content="camera=(self), microphone=(self), fullscreen=(self)">

  <!-- Rest of your head content -->
</head>
```

**Note:** Meta tags are less secure than HTTP headers. HTTP headers are preferred.

---

## Header Syntax Explained

**Format:** `Feature=(value1 value2 ...)`

**Common Values:**
- `*` - Allow all origins
- `self` - Allow same-origin only
- `none` - Disable completely
- `https://specific-domain.com` - Allow specific origin

**Example with multiple origins:**

```
Permissions-Policy:
  camera=(self "https://trusted-domain.com"),
  microphone=(self),
  fullscreen=(self)
```

---

## Recommended Header Values

### Minimal (Most Restrictive)
```
Permissions-Policy: camera=none, microphone=none
```

### Standard (Recommended for MedZen)
```
Permissions-Policy: camera=(self), microphone=(self), fullscreen=(self)
```

### Extended (If you need iframe support)
```
Permissions-Policy:
  camera=(self "https://trusted-domain.com"),
  microphone=(self "https://trusted-domain.com"),
  fullscreen=(self)
```

### Full Security Stack
```
Permissions-Policy: camera=(self), microphone=(self), fullscreen=(self)
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://du6iimxem4mh7.cloudfront.net; style-src 'self' 'unsafe-inline'
```

---

## Implementation for MedZen

### Step-by-Step (Option 1 - Recommended)

**File:** `supabase/functions/chime-meeting-token/index.ts`

1. **Find the response handler** (search for `new Response`)

2. **Locate the headers object:**
```typescript
headers: {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  // etc
}
```

3. **Add the Permissions-Policy line:**
```typescript
headers: {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '...',
  'Access-Control-Allow-Methods': '...',
  'Permissions-Policy': 'camera=(self), microphone=(self), fullscreen=(self)',
}
```

4. **Save the file**

5. **Deploy:**
```bash
npx supabase functions deploy chime-meeting-token
```

6. **Verify:**
```bash
# Call the function and check headers
curl -v "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -X POST \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' 2>&1 | grep -i "permissions-policy"
```

---

## Testing the Implementation

### Browser DevTools
1. Open your video call page
2. Press `F12` (Developer Tools)
3. Go to Network tab
4. Reload the page
5. Click on the API request to `chime-meeting-token`
6. Look at Response Headers
7. Should see: `Permissions-Policy: camera=(self), microphone=(self), fullscreen=(self)`

### Command Line
```bash
# Check response headers
curl -v "https://001e077e.medzen-dev.pages.dev" 2>&1 | grep -i "permissions-policy"

# Should output something like:
# < Permissions-Policy: camera=(self), microphone=(self), fullscreen=(self)
```

### Browser Console
```javascript
// If header is properly set, this should show the policy
fetch('/api/chime-meeting-token')
  .then(r => r.headers.get('Permissions-Policy'))
  .then(p => console.log('Policy:', p))
```

---

## Verification Checklist

After implementation:

- [ ] Edited the correct file
- [ ] Added `Permissions-Policy` header
- [ ] Syntax is correct (colons and commas)
- [ ] Deployed changes
- [ ] Checked with curl/DevTools
- [ ] Header appears in response
- [ ] Video call still works (no regressions)
- [ ] Mobile devices work (Android & iOS)
- [ ] Web browsers work (Chrome, Firefox, Safari)

---

## Potential Issues & Troubleshooting

### Issue: Header not appearing in response

**Cause:** Changes not deployed yet

**Fix:**
```bash
npx supabase functions deploy chime-meeting-token --force
```

### Issue: Video call stops working

**Cause:** Header is too restrictive

**Fix:** Change `none` to `(self)` or remove the header to test

```typescript
// Change from:
'Permissions-Policy': 'camera=none, microphone=none',

// To:
'Permissions-Policy': 'camera=(self), microphone=(self), fullscreen=(self)',
```

### Issue: Iframe doesn't work

**Cause:** Header doesn't include the iframe origin

**Fix:** Add the origin:
```typescript
'Permissions-Policy': 'camera=(self "https://your-iframe-domain.com"), microphone=(self "https://your-iframe-domain.com")'
```

---

## Browser Support

| Browser | Support | Notes |
|---------|---------|-------|
| Chrome | ✅ | Full support |
| Firefox | ✅ | Full support |
| Safari | ⚠️ | Limited support |
| Edge | ✅ | Full support |
| Mobile Chrome | ✅ | Full support |
| Mobile Safari | ⚠️ | Partial support |

**Note:** Older browsers ignore the header but don't break. No risk to add it.

---

## Documentation & References

**Official Specs:**
- https://www.w3.org/TR/permissions-policy/
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy

**Related Headers:**
- `X-Frame-Options` - Prevent clickjacking
- `X-Content-Type-Options: nosniff` - Prevent MIME type sniffing
- `Content-Security-Policy` - Control resource loading

---

## Deployment Options

### Option A: Deploy to Edge Function Only (Recommended)
**Time:** 2 minutes
**Scope:** Protects the API response
**Risk:** Minimal

```bash
npx supabase functions deploy chime-meeting-token
```

### Option B: Deploy via CloudFlare Pages
**Time:** 5 minutes
**Scope:** Protects entire site
**Risk:** Low

See "Option 2: CloudFlare Pages Configuration" above

### Option C: Deploy to Multiple Functions
**Time:** 10 minutes
**Scope:** All API responses protected
**Risk:** Medium (more coordination needed)

```bash
# Add to these functions:
npx supabase functions deploy \
  chime-meeting-token \
  chime-messaging \
  bedrock-ai-chat \
  start-medical-transcription
```

---

## Implementation Checklist

- [ ] **Choose approach** (Option 1 recommended)
- [ ] **Modify file** (chime-meeting-token/index.ts)
- [ ] **Test locally** (dev environment)
- [ ] **Deploy** (npx supabase functions deploy)
- [ ] **Verify** (curl or browser DevTools)
- [ ] **Test functionality** (video call still works)
- [ ] **Test all platforms** (web, Android, iOS)
- [ ] **Document changes** (in PR description)
- [ ] **Get code review** (before production)
- [ ] **Deploy to production**

---

## Risk Assessment

**Risk Level:** 🟢 **LOW**

- No breaking changes
- Headers are advisory (browsers can ignore)
- Can be removed without impact if issues occur
- Easy to rollback

**Performance Impact:** 🟢 **None**
- Adds ~80 bytes to response header
- Negligible network impact

**Security Improvement:** 🟢 **Good**
- Restricts attack surface
- Prevents unauthorized access
- Industry best practice

---

## Timeline

| Task | Time | Notes |
|------|------|-------|
| Edit file | 2 min | Copy-paste header line |
| Test locally | 3 min | Verify no errors |
| Deploy | 1 min | npx command |
| Verify | 2 min | curl or DevTools |
| **Total** | **8 minutes** | Could be done in parallel |

---

## When to Implement

### High Priority:
- ✅ Security audit required
- ✅ HIPAA compliance needed
- ✅ Enterprise deployment

### Low Priority (Nice to have):
- ✅ Additional security hardening
- ✅ Industry best practices
- ✅ Defense in depth

### Not Necessary:
- ❌ Page is never in iframe
- ❌ All content is first-party
- ❌ Development environment only

---

## Next Steps

1. **Decide:** Implement now or later?
2. **Choose:** Which option (Option 1 recommended)
3. **Edit:** Modify the file with header line
4. **Test:** Verify in dev environment
5. **Deploy:** Push to production
6. **Monitor:** Check CloudWatch logs for any issues

---

**Questions?**
- See COMPREHENSIVE_CHECKLIST_VERIFICATION_JAN12.md
- Check CLAUDE.md for architecture
- Review git history: `git log --oneline -20`

