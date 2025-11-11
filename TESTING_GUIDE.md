# Testing Guide - Connection & Integration Tests

## Overview

This guide explains how to use the comprehensive testing infrastructure for the medzen-iwani 4-system architecture. The testing suite validates that all systems (Firebase Auth, Supabase, PowerSync, EHRbase) are properly integrated and communicating.

**Last Updated**: January 2025
**Status**: Production Ready

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Test Suite Overview](#test-suite-overview)
3. [Accessing the Test Page](#accessing-the-test-page)
4. [Available Tests](#available-tests)
5. [Understanding Test Results](#understanding-test-results)
6. [Common Test Scenarios](#common-test-scenarios)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Quick Start

### Method 1: Navigate in App

```dart
// From any page in the app
context.pushNamed('ConnectionTestPage');
```

### Method 2: Direct URL

Navigate to: `https://your-app-url.com/connectionTest`

### Method 3: Add Navigation Button

Add a button to your settings or admin page:

```dart
FFButtonWidget(
  onPressed: () async {
    context.pushNamed('ConnectionTestPage');
  },
  text: 'Run System Tests',
  icon: Icon(Icons.bug_report),
  options: FFButtonOptions(
    // ... button styling
  ),
)
```

---

## Test Suite Overview

The testing infrastructure consists of:

### 1. **Test Actions** (Backend Logic)
Located in `lib/custom_code/actions/`:
- `test_signup_flow.dart` - Complete signup validation across all 4 systems
- `test_login_flow.dart` - Login validation for online/offline modes
- `test_data_operations.dart` - CRUD operations testing in both modes

### 2. **Visual Test Interface** (UI)
Located in `lib/test_page/`:
- `connection_test_page_widget.dart` - Interactive test interface
- `connection_test_page_model.dart` - Page state management

### 3. **System Status Monitor**
Located in `lib/components/system_status_debug/`:
- Real-time status of all 4 systems
- Network connectivity indicator
- Color-coded health indicators

---

## Accessing the Test Page

### Prerequisites

**For Development:**
- Flutter development environment set up
- App running on device/simulator
- Network connectivity (for online tests)

**For Production:**
- App deployed and accessible
- Admin/tester credentials
- Access to test page route

### Navigation Code Examples

**From a Button:**
```dart
onPressed: () async {
  context.pushNamed('ConnectionTestPage');
}
```

**From Drawer Menu:**
```dart
ListTile(
  leading: Icon(Icons.science),
  title: Text('System Tests'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    context.pushNamed('ConnectionTestPage');
  },
)
```

---

## Available Tests

### 1. Test Signup Flow (All 4 Systems)

**What it tests:**
- ✅ System initialization status
- ✅ Firebase Auth user creation
- ✅ Supabase user record creation (via Cloud Function)
- ✅ EHR creation in EHRbase (via Cloud Function)
- ✅ PowerSync initialization
- ✅ Test medical record creation
- ✅ EHRbase sync queue functionality
- ✅ Automatic cleanup

**When to use:**
- Testing complete signup flow
- Validating Firebase Cloud Function (`onUserCreated`)
- Verifying EHRbase integration
- Checking sync queue triggers

**Steps executed:**
1. Check all systems are initialized
2. Create test Firebase user (auto-generated email)
3. Wait for Cloud Function to process (5 seconds)
4. Verify Supabase user record exists
5. Verify EHR record in `electronic_health_records` table
6. Check PowerSync initialization
7. Create test vital signs record
8. Verify sync queue entry created
9. Clean up all test data

**Expected duration:** 10-15 seconds

**⚠️ Note:** Creates and deletes a real user. Use only in development/staging.

---

### 2. Test Login (Online Mode)

**What it tests:**
- ✅ Network connectivity
- ✅ System initialization
- ✅ Firebase Auth login
- ✅ Supabase user verification
- ✅ PowerSync connection status
- ✅ Data access from Supabase
- ✅ Session persistence

**When to use:**
- Validating login flow with network
- Testing data synchronization
- Verifying PowerSync connectivity

**Prerequisites:**
- Valid email and password entered
- Device has network connectivity
- User exists in the system

**Steps executed:**
1. Check network connectivity (must be online)
2. Verify system initialization
3. Sign in with Firebase Auth
4. Verify Supabase user record
5. Check PowerSync connection
6. Query user's medical records
7. Verify session persistence

**Expected duration:** 5-8 seconds

---

### 3. Test Login (Offline Mode)

**What it tests:**
- ✅ Offline login capability
- ✅ Local data access via PowerSync
- ✅ Cached authentication
- ✅ Offline data operations

**When to use:**
- Testing offline-first functionality
- Validating PowerSync local database
- Verifying cached credentials work

**Prerequisites:**
- Valid email and password entered
- User previously logged in (credentials cached)
- PowerSync has synced data

**Steps executed:**
1. Check system initialization
2. Attempt Firebase Auth login (may use cache)
3. Check PowerSync status (offline mode)
4. Query local PowerSync database
5. Verify data accessible offline

**Expected duration:** 3-5 seconds

**⚠️ Note:** To truly test offline, enable airplane mode. Otherwise, it simulates offline behavior.

---

### 4. Test Data Operations (Online)

**What it tests:**
- ✅ CREATE - Insert medical record to Supabase
- ✅ READ - Query record from Supabase
- ✅ UPDATE - Modify record in Supabase
- ✅ Sync queue entry creation
- ✅ DELETE - Cleanup test record

**When to use:**
- Testing CRUD operations
- Validating database triggers
- Checking EHRbase sync queue

**Prerequisites:**
- User logged in
- Device has network connectivity

**Steps executed:**
1. Check prerequisites (user logged in, online)
2. Get user's Supabase ID
3. CREATE: Insert vital signs record to Supabase
4. READ: Query the created record
5. UPDATE: Modify heart rate value
6. Verify sync queue entry (for EHRbase)
7. DELETE: Remove test record

**Expected duration:** 5-8 seconds

---

### 5. Test Data Operations (Offline)

**What it tests:**
- ✅ CREATE - Insert to PowerSync local DB
- ✅ READ - Query from local DB
- ✅ UPDATE - Modify in local DB
- ✅ DELETE - Remove from local DB
- ✅ Sync queue preparation (will sync when online)

**When to use:**
- Testing offline data creation
- Validating PowerSync local storage
- Verifying sync queue works offline

**Prerequisites:**
- User logged in
- PowerSync initialized

**Steps executed:**
1. Check prerequisites (user logged in)
2. Get user's Supabase ID
3. CREATE: Insert vital signs to PowerSync local DB
4. READ: Query from local DB
5. UPDATE: Modify record in local DB
6. DELETE: Remove from local DB

**Expected duration:** 3-5 seconds

**⚠️ Note:** Records are queued for sync and will upload when device comes online.

---

## Understanding Test Results

### Result Format

Each test returns:
```dart
{
  'overall_success': bool,           // Overall pass/fail
  'test_type': string,               // Type of test run
  'summary': '6/7 steps passed',     // Quick summary
  'timestamp': ISO8601 string,       // When test was run
  'steps': [                         // Detailed step results
    {
      'name': string,                // Step name
      'status': string,              // passed, failed, warning, testing, skipped
      'message': string,             // Detailed message
      'timestamp': ISO8601 string,   // Step start time
      'completed_at': ISO8601 string // Step completion time
    },
    ...
  ],
  // Test-specific fields
  'firebase_uid': string?,           // Created Firebase UID
  'supabase_user_id': int?,          // Supabase user ID
  'ehr_id': string?,                 // EHRbase EHR ID
  'is_online': bool?,                // Network status
  'error': string?                   // If test crashed
}
```

### Status Indicators

**🟢 Passed (Green)**
- Step completed successfully
- All assertions met
- No errors encountered

**🔴 Failed (Red)**
- Step failed critical assertion
- Error prevented completion
- Test cannot continue

**🟠 Warning (Orange)**
- Step completed with minor issues
- Non-critical error occurred
- Test can continue but review needed

**🔵 Testing (Blue)**
- Step currently in progress
- Waiting for operation to complete

**⚪ Skipped (Gray)**
- Step skipped (e.g., offline check when online)
- Not applicable to current test mode

### Color-Coded Results Display

The test page shows results with:
- **Border color** indicating overall status
- **Icon** showing status type (checkmark, error, warning)
- **Step-by-step breakdown** with individual status indicators
- **Detailed messages** explaining each step result

### Success Criteria

A test is considered **successful** if:
- `overall_success: true`
- At least `(total_steps - 2)` steps passed
- No critical failures
- Warnings are acceptable for non-critical systems

---

## Common Test Scenarios

### Scenario 1: First-Time System Validation

**Goal:** Verify all 4 systems are properly integrated

**Steps:**
1. Navigate to test page
2. Check System Status section (all should be green)
3. Run "Test Signup Flow"
4. Verify all steps pass
5. Check logs for any warnings

**Expected Result:**
- All 4 systems show "Initialized" (green)
- Signup test completes with 8/9 or 9/9 steps passed
- User created in Firebase, Supabase, and EHRbase
- Test data cleaned up automatically

---

### Scenario 2: Testing Offline Functionality

**Goal:** Validate offline-first architecture works

**Steps:**
1. Ensure user is logged in with cached credentials
2. Enable airplane mode on device
3. Navigate to test page
4. Check System Status (PowerSync should show offline)
5. Run "Test Data Operations (Offline)"
6. Verify local DB operations work
7. Disable airplane mode
8. Observe automatic sync

**Expected Result:**
- PowerSync shows "Offline" status but initialized
- Offline data operations test passes
- Records saved to local SQLite DB
- When online, PowerSync syncs to Supabase
- Sync queue processes EHRbase sync

---

### Scenario 3: Login Flow Validation

**Goal:** Test login in both online and offline modes

**Steps:**
1. Enter valid test credentials in form
2. Run "Test Login (Online Mode)"
3. Verify all steps pass
4. Log out
5. Enable airplane mode
6. Run "Test Login (Offline Mode)"
7. Compare results

**Expected Result:**
- Online login: All systems accessible, data from Supabase
- Offline login: PowerSync provides local data access
- Session persists in both modes

---

### Scenario 4: Continuous Integration Testing

**Goal:** Automated testing in CI/CD pipeline

**Approach:**
```dart
// In your test file
testWidgets('System integration test', (WidgetTester tester) async {
  // Run signup test
  final signupResults = await testSignupFlow();
  expect(signupResults['overall_success'], true);

  // Run data operations test
  final dataResults = await testDataOperations(testOfflineMode: false);
  expect(dataResults['overall_success'], true);

  // Check specific steps
  final steps = signupResults['steps'] as List;
  expect(steps.where((s) => s['status'] == 'failed').length, 0);
});
```

---

## Troubleshooting

### Problem: System Status shows systems not initialized

**Symptoms:**
- Red status indicators
- "Failed" or "Offline" status
- Cannot run tests

**Solutions:**

1. **Check network connectivity:**
   ```dart
   // The app monitors this automatically
   FFAppState().isOnline
   ```

2. **Retry initialization:**
   - Use "Retry Failed Systems" button in System Status
   - Or restart the app

3. **Check Firebase/Supabase config:**
   - Verify `google-services.json` (Android)
   - Verify `GoogleService-Info.plist` (iOS)
   - Check Supabase credentials in `lib/backend/supabase/supabase.dart`

4. **PowerSync not connecting:**
   - Check PowerSync credentials in Supabase secrets
   - Verify PowerSync instance is running
   - Check `powersync-token` Edge Function is deployed

---

### Problem: Signup test fails at "Verify EHR Record" step

**Symptoms:**
- Firebase user created
- Supabase user found
- EHR record not found

**Solutions:**

1. **Check Firebase Cloud Function:**
   ```bash
   firebase functions:log --only onUserCreated
   ```

2. **Verify Cloud Function config:**
   ```bash
   firebase functions:config:get
   ```
   Should show:
   - `supabase.url`
   - `supabase.service_key`
   - `ehrbase.url`
   - `ehrbase.username`
   - `ehrbase.password`

3. **Check EHRbase accessibility:**
   - Verify EHRbase URL is correct
   - Test credentials with curl:
     ```bash
     curl -u username:password https://ehrbase-url/rest/openehr/v1/
     ```

4. **Increase wait time:**
   - Cloud Function may need more than 5 seconds
   - Modify `test_signup_flow.dart` line 63:
     ```dart
     await Future.delayed(const Duration(seconds: 10));
     ```

---

### Problem: Login test shows "User not logged in"

**Symptoms:**
- Test immediately fails
- "Please login first" message

**Solutions:**

1. **Log in first:**
   - Navigate to login page
   - Sign in with valid credentials
   - Then run test

2. **Check Firebase Auth state:**
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   print('Logged in: ${user != null}');
   print('UID: ${user?.uid}');
   ```

3. **Session expired:**
   - Log out and log back in
   - Firebase tokens may have expired

---

### Problem: Offline test doesn't work

**Symptoms:**
- "Device is online but testing offline mode" warning
- Results don't reflect offline behavior

**Solutions:**

1. **Enable airplane mode:**
   - Truly test offline by disabling network
   - Or turn off WiFi/cellular

2. **PowerSync not initialized:**
   - Check PowerSync status in System Status section
   - Retry initialization if needed

3. **No local data:**
   - Offline tests need previously synced data
   - Run online data test first
   - Let PowerSync sync
   - Then test offline

---

### Problem: Data operations test fails at sync queue

**Symptoms:**
- Data created successfully
- Sync queue entry not found
- "Database trigger may not be configured" warning

**Solutions:**

1. **Check database triggers:**
   ```sql
   -- In Supabase SQL Editor
   SELECT * FROM pg_trigger WHERE tgname LIKE '%ehrbase%';
   ```

2. **Apply migrations:**
   ```bash
   npx supabase db push
   ```

3. **Verify trigger function:**
   ```sql
   SELECT proname FROM pg_proc WHERE proname LIKE '%ehrbase%';
   ```

4. **Check trigger is enabled:**
   ```sql
   -- Should show triggers on vital_signs, lab_results, etc.
   SELECT tgname, tgenabled FROM pg_trigger
   WHERE tgname = 'trigger_queue_for_ehrbase';
   ```

---

### Problem: Test results not showing

**Symptoms:**
- Test runs but no results display
- Blank results section

**Solutions:**

1. **Check console for errors:**
   - Open browser DevTools (Web)
   - Check Xcode console (iOS)
   - Check Logcat (Android)

2. **Test crashed:**
   - Look for exception in logs
   - Check `testResults['error']` field

3. **State update issue:**
   - Force refresh:
     ```dart
     setState(() {});
     ```

---

## Best Practices

### 1. Test in Development First

Always run tests in development environment before production:
- Use development Firebase project
- Use staging Supabase instance
- Point to test EHRbase server
- Use test PowerSync instance

### 2. Clean Up Test Data

The tests include automatic cleanup, but verify:
- Test users are deleted
- Test medical records removed
- Sync queue entries processed

**Manual cleanup:**
```sql
-- Supabase SQL Editor
DELETE FROM users WHERE email LIKE 'test+%@medzen.test';
DELETE FROM vital_signs WHERE patient_id NOT IN (SELECT id FROM users);
DELETE FROM ehrbase_sync_queue WHERE created_at < NOW() - INTERVAL '1 day';
```

### 3. Monitor Test Frequency

Don't run tests too frequently to avoid:
- Rate limiting (Firebase Auth)
- Database bloat (Supabase)
- Unnecessary EHRbase load

**Recommended frequency:**
- Development: As needed during debugging
- Staging: Before each deployment
- Production: Weekly scheduled tests

### 4. Document Test Results

Keep a log of test runs:
```
Date: 2025-01-20
Environment: Staging
Signup Test: ✅ 9/9 passed
Online Login: ✅ 7/7 passed
Offline Login: ✅ 6/7 passed (1 warning: no local data)
Online Data Ops: ✅ 6/7 passed (sync queue: 2s delay)
Offline Data Ops: ✅ 5/5 passed

Notes: All critical systems working. Sync queue may need optimization.
```

### 5. Use Copy Results Feature

The test page includes a "Copy Results" button:
- Tap button after test completes
- Paste into documentation
- Share with team
- Include in bug reports

**Exported format:**
```
=== TEST RESULTS ===
Test Type: online_login
Overall Success: true
Summary: 7/7 steps passed
Timestamp: 2025-01-20T10:30:00Z

STEPS:
Step 1: Network Connectivity Check
  Status: passed
  Message: Network status: Online
  Time: 2025-01-20T10:30:00Z

Step 2: System Initialization Check
  Status: passed
  Message: Critical systems ready (Firebase + Supabase)
  Time: 2025-01-20T10:30:01Z
...
```

### 6. Test Before Major Changes

Run full test suite before:
- Deploying to production
- Database schema changes
- Backend function updates
- PowerSync sync rules changes
- EHRbase template updates

### 7. Combine with System Status Monitor

Use System Status Debug Widget alongside tests:
```dart
// Show both in a comprehensive testing dashboard
Column(
  children: [
    SystemStatusDebugWidget(),
    Divider(),
    ConnectionTestButtons(),
  ],
)
```

### 8. Automate Where Possible

For CI/CD pipelines, create automated tests:
```dart
// integration_test/system_test.dart
void main() {
  testWidgets('Full system integration', (tester) async {
    await tester.pumpWidget(MyApp());

    // Wait for initialization
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Navigate to test page
    await tester.tap(find.text('System Tests'));
    await tester.pumpAndSettle();

    // Run signup test
    await tester.tap(find.text('Test Signup Flow'));
    await tester.pump(Duration(seconds: 15));

    // Verify success
    expect(find.text('9/9 steps passed'), findsOneWidget);
  });
}
```

---

## Accessing Test Results Programmatically

For advanced use cases, access test results directly:

```dart
// Run test and process results
final results = await testSignupFlow();

if (results['overall_success'] == true) {
  print('✅ All systems working');
} else {
  print('❌ System integration issues');

  // Check which steps failed
  final steps = results['steps'] as List;
  final failedSteps = steps.where((s) => s['status'] == 'failed');

  for (var step in failedSteps) {
    print('Failed: ${step['name']}');
    print('Error: ${step['message']}');

    // Send to error tracking
    // Sentry.captureMessage('Test failed: ${step['name']}');
  }
}
```

---

## Integration with Monitoring

Send test results to monitoring services:

```dart
// After test completion
final results = await testSignupFlow();

// Log to Firebase Analytics
FirebaseAnalytics.instance.logEvent(
  name: 'system_test_completed',
  parameters: {
    'test_type': 'signup_flow',
    'success': results['overall_success'],
    'steps_passed': (results['summary'] as String).split('/')[0],
    'timestamp': results['timestamp'],
  },
);

// Log to custom monitoring
await logToMonitoring({
  'event': 'system_test',
  'environment': 'production',
  'results': results,
});
```

---

## Support & Feedback

If you encounter issues not covered in this guide:

1. **Check logs:**
   - Firebase Console → Functions → Logs
   - Supabase Dashboard → Logs
   - PowerSync Dashboard → Logs
   - Flutter console output

2. **Review documentation:**
   - [SYSTEM_INTEGRATION_STATUS.md](./SYSTEM_INTEGRATION_STATUS.md)
   - [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md)
   - [POWERSYNC_QUICK_START.md](./POWERSYNC_QUICK_START.md)

3. **Contact support:**
   - File an issue in your project repository
   - Contact your development team
   - Review code in `lib/custom_code/actions/test_*.dart`

---

**Remember:** These tests validate the integration of 4 complex systems. Some warnings are normal, especially during initial setup. Focus on ensuring critical flows (signup, login, data sync) work reliably.

**Happy Testing! 🧪**
