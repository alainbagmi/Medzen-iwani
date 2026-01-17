# Amazon Chime SDK Upgrade Issue - Critical Blocker

**Date:** December 16, 2025
**Status:** ❌ UPGRADE BLOCKED - Reverting to v3.19.0 Recommended

## Executive Summary

**Cannot upgrade to v3.29.0** because AWS no longer provides pre-built browser UMD bundles for the Chime SDK. The application requires a self-contained JavaScript bundle, but v3.29.0 only ships as modular ESM code.

## The Problem

### **What We Need:**
- **UMD Bundle:** Self-contained JavaScript file that works in browsers
- **Format:** `window.ChimeSDK = { ... }` global export
- **Size:** ~1.1 MB minified
- **Dependencies:** All bundled together (no external imports)

### **What v3.19.0 Provides:** ✅
```javascript
// UMD wrapper - works in all environments
!function(e,t){
  "object"==typeof exports && "object"==typeof module
    ? module.exports=t()
    : e.ChimeSDK=t()
}(this, ...)
```
- **Available at:** `https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js`
- **Size:** 1.16 MB
- **Format:** UMD (Universal Module Definition)
- **Works:** ✅ Android, ✅ iOS, ✅ Web

### **What v3.29.0 Provides:** ❌
```javascript
// ESM format - requires module loader
import e from"/npm/detect-browser@5.3.0/+esm";
import t from"/npm/ua-parser-js@1.0.41/+esm";
// ... many more external imports
```
- **Available at:** jsDelivr (ESM only, not UMD)
- **Size:** 858 KB
- **Format:** ESM with external dependencies
- **Works:** ❌ Cannot be used in WebView without module bundler

## Investigation Results

I attempted multiple sources to find v3.29.0 in UMD format:

### ❌ npm Registry
```bash
# Downloaded package
npm pack amazon-chime-sdk-js@3.29.0

# Result: Only modular source files in /build/ directory
# No pre-built UMD bundle included
```

### ❌ jsDelivr CDN
```bash
curl "https://cdn.jsdelivr.net/npm/amazon-chime-sdk-js@3.29.0/+esm"

# Result: ESM bundle with external imports (detect-browser, ua-parser-js, etc.)
# Cannot work in WebView without module resolution
```

### ❌ unpkg CDN
```bash
curl "https://unpkg.com/amazon-chime-sdk-js@3.29.0/build/amazon-chime-sdk.min.js"

# Result: 404 Not Found - no dist folder in package
```

### ❌ AWS Static Assets CDN
```bash
curl "https://static.sdkassets.chime.aws/amazon-chime-sdk-js/latest/amazon-chime-sdk.min.js"

# Result: 403 Forbidden - not publicly accessible
```

### ✅ Current v3.19.0 (Working)
```bash
curl "https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js"

# Result: 1.16 MB UMD bundle - works perfectly
```

## Why AWS Changed This

According to the [GitHub repository](https://github.com/aws/amazon-chime-sdk-js):

> "To add the Amazon Chime SDK for JavaScript into an existing application, install the package directly from npm"

AWS now expects developers to:
1. Install via npm: `npm install amazon-chime-sdk-js`
2. Bundle with their own build tools (webpack, Rollup, etc.)
3. Create their own UMD/browser bundle if needed

**AWS no longer provides ready-to-use browser bundles.**

## Options Going Forward

### **Option 1: Stay on v3.19.0** ⭐ **RECOMMENDED**

**Pros:**
- ✅ Works perfectly right now
- ✅ No code changes needed
- ✅ No infrastructure changes needed
- ✅ Zero risk
- ✅ Saves development time

**Cons:**
- ❌ Misses 10 minor releases of bug fixes/features
- ❌ Will eventually need to upgrade

**Effort:** None
**Risk:** None
**Timeline:** Immediate

---

### **Option 2: Build Custom UMD Bundle**

Create a webpack/Rollup configuration to build v3.29.0 as UMD.

**Steps:**
1. Create build project with webpack
2. Configure UMD output format
3. Bundle all dependencies
4. Minify and optimize
5. Upload to CloudFront
6. Test on all platforms

**Pros:**
- ✅ Get latest v3.29.0 features
- ✅ Control over bundle size/optimization
- ✅ Can customize exports

**Cons:**
- ❌ Complex setup (webpack config, dependencies, etc.)
- ❌ Requires maintenance for future updates
- ❌ 8-16 hours of development work
- ❌ Risk of bundle issues

**Effort:** 8-16 hours
**Risk:** Medium
**Timeline:** 2-3 days

---

### **Option 3: Rewrite to Use ESM Modules**

Completely restructure the video call widget to use modern ESM imports.

**Changes Needed:**
- Rewrite `ChimeMeetingWebview` to load ESM modules
- Add module loader to WebView
- Handle dynamic imports
- Update CDN strategy

**Pros:**
- ✅ Modern architecture
- ✅ Smaller initial bundle (code splitting)
- ✅ Future-proof

**Cons:**
- ❌ Major refactoring required
- ❌ 16-24 hours of work
- ❌ High risk of breaking changes
- ❌ May not work on older Android WebViews
- ❌ Significant testing needed

**Effort:** 16-24 hours
**Risk:** High
**Timeline:** 1-2 weeks (including testing)

---

### **Option 4: Wait for AWS to Provide Browser Bundles**

Monitor AWS Chime SDK releases for official browser bundles.

**Pros:**
- ✅ No work required
- ✅ Official support

**Cons:**
- ❌ May never happen
- ❌ Stuck on v3.19.0 indefinitely

**Effort:** None
**Risk:** None
**Timeline:** Unknown (likely never)

## Recommendation

### **Stay on v3.19.0** for now

**Reasoning:**
1. **v3.19.0 is stable** - works perfectly in production
2. **Low priority** - bug fixes in v3.20-v3.29 are minor, not critical
3. **High cost** - 8-24 hours of development for minimal benefit
4. **Risk/reward** - upgrading provides little value vs. effort required

### **When to Revisit:**

Upgrade should be reconsidered if:
- Critical security vulnerability found in v3.19.0
- Major feature needed that only exists in v3.29.0+
- AWS provides official browser bundles again
- Major refactoring planned (good time to modernize)

## What I've Done

### ✅ Fixed Documentation
- **Corrected CLAUDE.md** - Updated to accurately reflect CDN loading (v3.19.0)
- **Removed misleading claims** - No longer says "offline capable" or "self-contained"

### ⚠️ Code Changes Made (Need Reversion)
The widget code was updated to reference v3.29.0, but this needs to be reverted:

**Files to revert:**
```bash
# Revert widget code
git checkout HEAD -- lib/custom_code/widgets/chime_meeting_webview.dart

# Revert deployment script
git checkout HEAD -- aws-deployment/scripts/deploy-chime-sdk-cdn.sh
```

## Testing Recommendation

Before making any changes, validate that v3.19.0 works correctly:

```bash
# Test video call on all platforms
./test_chime_video_complete.sh

# Check SDK loads correctly
curl -I https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js
# Should return: HTTP/2 200
```

## Cost Analysis

| Option | Dev Time | Cost | Risk | Benefit |
|--------|----------|------|------|---------|
| **Stay on v3.19.0** | 0 hours | $0 | None | Status quo |
| **Custom UMD Build** | 8-16 hours | $800-1,600 | Medium | Bug fixes, optimizations |
| **ESM Rewrite** | 16-24 hours | $1,600-2,400 | High | Modern architecture |

**Recommendation:** Stay on v3.19.0 unless critical need arises.

## References

- **npm Package:** https://www.npmjs.com/package/amazon-chime-sdk-js
- **GitHub Repository:** https://github.com/aws/amazon-chime-sdk-js
- **AWS Documentation:** https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html
- **Latest Release:** https://github.com/aws/amazon-chime-sdk-js/releases/tag/amazon-chime-sdk-js%403.29.0

---

## Decision

**Status:** ❌ DO NOT UPGRADE TO V3.29.0
**Action:** Revert code changes, stay on v3.19.0
**Priority:** Low (revisit in 6 months or when critical need arises)
