# ⚠️  CRITICAL DEPENDENCIES - DO NOT REMOVE ⚠️

## Protected Dependencies

The following dependencies in `package.json` are **CRITICAL** for production user lifecycle functions and are **PROTECTED** by git hooks:

### 1. @supabase/supabase-js (^2.39.0)

**Status:** 🔒 PROTECTED - Cannot be removed

**Required by:**
- `onUserCreated` - Creates users in Supabase Auth and database
- `onUserDeleted` - Deletes users from Supabase Auth and database

**Protection:**
- Pre-commit hook checks for this dependency
- Pre-push hook validates its presence
- Validation script monitors this dependency

**If removed, the following will FAIL:**
- User creation will fail completely
- User deletion will fail completely
- Pre-commit/pre-push hooks will BLOCK the commit/push
- Validation script will report CRITICAL ERROR

### Restoration

If this dependency is accidentally removed:

```bash
# Restore package.json from git
git checkout HEAD -- firebase/functions/package.json

# Or manually add it back
# Edit firebase/functions/package.json and add:
# "@supabase/supabase-js": "^2.39.0"

# Then reinstall
cd firebase/functions
npm install
```

### Verification

To verify all critical dependencies are present:

```bash
# From project root
./validate-critical-functions.sh
```

---

## Other Important Dependencies

These dependencies are also important but not currently protected by hooks:

- `firebase-admin` - Firebase Admin SDK (required for all Firebase operations)
- `firebase-functions` - Firebase Functions framework
- `axios` - HTTP client for API calls

---

## Protection Mechanisms

1. **Git Pre-commit Hook** (`.git/hooks/pre-commit`)
   - Checks for `@supabase/supabase-js` in package.json
   - Blocks commit if missing

2. **Git Pre-push Hook** (`.git/hooks/pre-push`)
   - Double-checks dependencies before push
   - Prevents pushing broken code

3. **Validation Script** (`validate-critical-functions.sh`)
   - Can be run anytime: `./validate-critical-functions.sh`
   - Comprehensive check of all protections

---

## DO NOT:

❌ Remove `@supabase/supabase-js` from package.json
❌ Downgrade `@supabase/supabase-js` below v2.0.0
❌ Delete or modify `.git/hooks/pre-commit`
❌ Delete or modify `.git/hooks/pre-push`
❌ Run `npm uninstall @supabase/supabase-js`

## DO:

✅ Keep `@supabase/supabase-js` at v2.39.0 or higher
✅ Run `./validate-critical-functions.sh` after any package changes
✅ Consult team before upgrading major versions
✅ Test thoroughly after any dependency changes

---

**Last Updated:** 2026-01-09
**Protection Level:** 🔒 MAXIMUM
