# Firebase Functions Status Report

**Date:** December 16, 2025
**Project:** medzen-bf20e (current)

## 🚨 Critical Issue Found

**6 out of 11 deployed functions have no source code in the repository!**

## Deployed Functions (11 total)

| # | Function Name | Status | Location | Type | Notes |
|---|---------------|--------|----------|------|-------|
| 1 | **addFcmToken** | ❌ MISSING | Not in code | Callable | FCM token management |
| 2 | **beforeUserCreated** | ❌ MISSING | Not in code | Auth Blocking | Pre-signup validation |
| 3 | **beforeUserSignedIn** | ❌ MISSING | Not in code | Auth Blocking | Pre-signin validation |
| 4 | **createAiConversation** | ✅ Found | aiChatHandler.js | Callable | AI conversation setup |
| 5 | **generateVideoCallTokens** | ✅ Found | videoCallTokens.js | Callable | Video call token generation |
| 6 | **handleAiChatMessage** | ✅ Found | aiChatHandler.js | Callable | AI chat handler |
| 7 | **onUserCreated** | ❌ MISSING | Not in code | Auth Trigger | **CRITICAL** - User sync to Supabase/EHRbase |
| 8 | **onUserDeleted** | ✅ Found | index.js | Auth Trigger | User deletion cascade |
| 9 | **refreshVideoCallToken** | ✅ Found | videoCallTokens.js | Callable | Refresh video tokens |
| 10 | **sendPushNotificationsTrigger** | ❌ MISSING | Not in code | Firestore Trigger | Push notifications |
| 11 | **sendScheduledPushNotifications** | ❌ MISSING | Not in code | Scheduled | Scheduled push |

## Functions in Source Code (5 found)

### ✅ firebase/functions/index.js
- `onUserDeleted` - User deletion handler

### ✅ firebase/functions/aiChatHandler.js
- `handleAiChatMessage` - AI chat message handler
- `createAiConversation` - AI conversation creation

### ✅ firebase/functions/videoCallTokens.js
- `generateVideoCallTokens` - Video call token generation
- `refreshVideoCallToken` - Video call token refresh

## Missing Critical Functions ⚠️

### 1. **onUserCreated** (MOST CRITICAL)
**Purpose:** According to CLAUDE.md, this function:
- Creates Supabase Auth user via Admin API
- Inserts record in `users` table
- Creates EHR in EHRbase via REST API
- Inserts record in `electronic_health_records` table
- Total sync time: ~2.3s

**Impact:** Without this in source code:
- Cannot recreate the deployment
- Cannot modify or debug user creation flow
- Risk of losing critical business logic
- New deployments will break user signup

### 2. **addFcmToken**
**Purpose:** FCM token management for push notifications
**Impact:** Cannot manage device tokens for notifications

### 3. **beforeUserCreated** & **beforeUserSignedIn**
**Purpose:** Auth blocking functions for validation before signup/signin
**Impact:** Pre-auth validation logic not in source control

### 4. **sendPushNotificationsTrigger** & **sendScheduledPushNotifications**
**Purpose:** Push notification system
**Impact:** Cannot modify or debug notification system

## All Function Files in Repository

```
firebase/functions/
├── aiChatHandler.js (2 exports) ✅
├── api_manager.js (API helpers)
├── delete_test_user.js (test utility)
├── index.js (1 export) ✅
├── sync_current_user.js (utility)
├── videoCallTokens.js (2 exports) ✅
└── package.json
```

## Recommendations

### 🚨 URGENT - Recover Missing Functions

1. **Check Firebase Console Source Code View**
   - Firebase Console may have the deployed source code
   - Navigate to: Functions → [function name] → Source tab

2. **Check Git History**
   ```bash
   git log --all --full-history -- firebase/functions/
   ```

3. **Check Backups**
   - Look for any backup directories
   - Check for `.backup` or old deployment archives

4. **Extract from Production**
   - Use Firebase CLI to download deployed code:
   ```bash
   firebase functions:config:get > deployed-config.json
   ```

5. **Reconstruct from CLAUDE.md Documentation**
   - CLAUDE.md describes the onUserCreated logic
   - Reconstruct based on documentation and requirements

### 📋 Action Items

**Priority 1: Recover onUserCreated**
- [ ] Check Firebase Console for deployed source
- [ ] Search git history
- [ ] Reconstruct from documentation if needed
- [ ] Test thoroughly before deployment

**Priority 2: Recover Push Notification Functions**
- [ ] Recover sendPushNotificationsTrigger
- [ ] Recover sendScheduledPushNotifications
- [ ] Recover addFcmToken

**Priority 3: Recover Auth Blocking Functions**
- [ ] Recover beforeUserCreated
- [ ] Recover beforeUserSignedIn

**Priority 4: Documentation**
- [ ] Document all recovered functions
- [ ] Update CLAUDE.md if needed
- [ ] Create backup strategy to prevent future loss

## Risk Assessment

| Risk | Severity | Impact |
|------|----------|--------|
| Cannot redeploy user creation | 🔴 CRITICAL | New deployments will break signup |
| Lost business logic | 🔴 CRITICAL | Cannot maintain or debug |
| No source control | 🔴 CRITICAL | Cannot track changes |
| Push notifications at risk | 🟡 HIGH | Cannot modify notification system |
| Auth validation unknown | 🟡 HIGH | Security/validation logic unclear |

## Current Deployment Status

✅ **Production functions are working** (currently deployed and active)
❌ **Source code incomplete** (cannot safely redeploy or modify 6 functions)

## Next Steps

1. **DO NOT** run `firebase deploy --only functions` until source is recovered
2. Recover missing function source code ASAP
3. Test recovered functions in development environment
4. Document all functions properly
5. Set up proper source control practices
