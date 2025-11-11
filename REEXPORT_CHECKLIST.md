# FlutterFlow Re-Export Checklist

**Date Started:** ___________
**Completed By:** ___________

## Pre-Re-Export

- [ ] Read FLUTTERFLOW_REEXPORT_GUIDE.md
- [ ] Create backup of current project
  ```bash
  cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
  cp -r . ../medzen-iwani-backup-$(date +%Y%m%d)
  ```
- [ ] Verify backup created successfully
- [ ] Note current working state (all features functional)

## FlutterFlow Editor

- [ ] Open https://app.flutterflow.io
- [ ] Log in as alainbagmi@gmail.com
- [ ] Open medzen-iwani project (ID: medzen-iwani-t1nrnu)
- [ ] Wait for project to fully load (UI builder visible)
- [ ] Check Custom Code section for warnings
- [ ] Export code (Developer Menu → Export Code → Download ZIP)
- [ ] Verify ZIP downloaded (~4.6MB)

## File Replacement

- [ ] Extract downloaded ZIP to temporary location
- [ ] Copy ONLY FlutterFlow-managed files:
  - [ ] `lib/flutter_flow/` directory
  - [ ] `lib/backend/supabase/database/database.dart`
- [ ] VERIFY custom files NOT overwritten:
  - [ ] `lib/powersync/` unchanged
  - [ ] `lib/custom_code/` unchanged
  - [ ] `firebase/` unchanged
  - [ ] `supabase/` unchanged

## Verification

- [ ] Run `flutter pub get` - no errors
- [ ] Run `flutter analyze` - no new issues
- [ ] Run `flutter run -d chrome` - app launches
- [ ] Test Firebase Auth (login/signup)
- [ ] Test Supabase connection
- [ ] Test PowerSync sync (online mode)
- [ ] Test PowerSync offline mode (enable airplane mode)
- [ ] Navigate through all 4 user roles
- [ ] Test custom actions/widgets
- [ ] Test video call functionality

## Post-Re-Export Validation

- [ ] Navigate to /connectionTest in app
- [ ] Run Test 1: Signup Flow → ✅ Pass
- [ ] Run Test 2: Login Online → ✅ Pass
- [ ] Run Test 3: Login Offline → ✅ Pass
- [ ] Run Test 4: Data Ops Online → ✅ Pass
- [ ] Run Test 5: Data Ops Offline → ✅ Pass

## Final Checks

- [ ] No package version warnings in FlutterFlow
- [ ] No console errors in Flutter app
- [ ] All features functional
- [ ] Performance same or better
- [ ] Ready for production deployment

## If Issues Occur

- [ ] Restore from backup: `cp -r ../medzen-iwani-backup-* .`
- [ ] Check FLUTTERFLOW_REEXPORT_GUIDE.md troubleshooting section
- [ ] Verify only correct files were replaced
- [ ] Run `flutter clean && flutter pub get`
- [ ] Retry selective file update approach

---

## Success Criteria

✅ All checklist items completed
✅ No package warnings
✅ All tests pass
✅ App production-ready

## Notes

<!-- Add any notes or observations here -->

---

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete
