# FlutterFlow PowerSync Actions - Manual Upload Instructions

## Quick Reference: 6 Actions to Add

Copy each code block below into FlutterFlow's Custom Code → Actions:

---

### 1. initializePowerSyncAction

**Name:** `initializePowerSyncAction`
**Return Type:** `Future<void>`
**Parameters:** None

```dart
import 'package:medzen_iwani/powersync/database.dart';

/// Initialize PowerSync for offline-first database operations
///
/// Call this from your initial landing page's "On Page Load" action.
/// CRITICAL: Must be called AFTER Firebase and Supabase initialization.
Future initializePowerSyncAction() async {
  await initializePowerSync();
}
```

---

### 2. powerSyncQueryAction

**Name:** `powerSyncQueryAction`
**Return Type:** `Future<List<dynamic>>`
**Parameters:**
- `sql` (String) - SQL query
- `parameters` (List<dynamic>?) - Query parameters

```dart
import 'package:medzen_iwani/powersync/database.dart';

/// Query data from PowerSync local database (offline-safe)
///
/// Example: powerSyncQueryAction(
///   "SELECT * FROM vital_signs WHERE patient_id = ?",
///   [FFAppState.userId]
/// )
Future<List<dynamic>> powerSyncQueryAction(
  String sql,
  List<dynamic>? parameters,
) async {
  final params = parameters?.map((e) => e as Object?).toList();
  final results = await executeQuery(sql, params);
  return results;
}
```

---

### 3. powerSyncWriteAction

**Name:** `powerSyncWriteAction`
**Return Type:** `Future<void>`
**Parameters:**
- `sql` (String) - SQL statement (INSERT/UPDATE/DELETE)
- `parameters` (List<dynamic>?) - Statement parameters

```dart
import 'package:medzen_iwani/powersync/database.dart';

/// Write data to PowerSync local database (offline-safe)
///
/// Example: powerSyncWriteAction(
///   "INSERT INTO vital_signs (id, patient_id, systolic_bp) VALUES (?, ?, ?)",
///   [uuid, userId, 120]
/// )
Future powerSyncWriteAction(
  String sql,
  List<dynamic>? parameters,
) async {
  final params = parameters?.map((e) => e as Object?).toList();
  await executeWrite(sql, params);
}
```

---

### 4. powerSyncWatchQueryAction

**Name:** `powerSyncWatchQueryAction`
**Return Type:** `Stream<List<dynamic>>`
**Parameters:**
- `sql` (String) - SQL query
- `parameters` (List<dynamic>?) - Query parameters

```dart
import 'package:medzen_iwani/powersync/database.dart';

/// Stream real-time query results from PowerSync (updates automatically)
///
/// Use with StreamBuilder for real-time UI updates.
/// Example: StreamBuilder(
///   stream: powerSyncWatchQueryAction(
///     "SELECT * FROM appointments WHERE patient_id = ?",
///     [userId]
///   )
/// )
Stream<List<dynamic>> powerSyncWatchQueryAction(
  String sql,
  List<dynamic>? parameters,
) {
  final params = parameters?.map((e) => e as Object?).toList();
  return watchQuery(sql, params);
}
```

---

### 5. powerSyncIsConnectedAction

**Name:** `powerSyncIsConnectedAction`
**Return Type:** `Future<bool>`
**Parameters:** None

```dart
import 'package:medzen_iwani/powersync/database.dart';

/// Check if PowerSync is currently connected to the cloud
///
/// Returns true if online, false if offline.
/// Use to show connection indicators.
Future<bool> powerSyncIsConnectedAction() async {
  return isPowerSyncConnected();
}
```

---

### 6. powerSyncGetStatusAction

**Name:** `powerSyncGetStatusAction`
**Return Type:** `Future<Map<String, dynamic>>`
**Parameters:** None

```dart
import 'package:medzen_iwani/powersync/database.dart';

/// Get detailed PowerSync sync status
///
/// Returns map with:
/// - connected: bool
/// - uploading: bool
/// - downloading: bool
/// - lastSyncedAt: String?
/// - hasSynced: bool
Future<Map<String, dynamic>> powerSyncGetStatusAction() async {
  final status = getPowerSyncStatus();
  return {
    'connected': status.connected,
    'downloading': status.downloading,
    'uploading': status.uploading,
    'lastSyncedAt': status.lastSyncedAt?.toIso8601String(),
    'hasSynced': status.hasSynced,
  };
}
```

---

## Upload Instructions

For each action:

1. **Open FlutterFlow:** https://app.flutterflow.io/project/medzen-iwani-t1nrnu
2. **Navigate:** Custom Code → Actions
3. **Click:** "+ Add Action"
4. **Enter:**
   - Action Name: (from above, e.g., `initializePowerSyncAction`)
   - Return Type: (from above, e.g., `Future<void>`)
   - Parameters: (click "+ Add Parameter" for each parameter listed)
5. **Paste:** The code block from above
6. **Save**

## Verification

After uploading all 6 actions:

1. Go to any page in FlutterFlow
2. Add an action to a widget
3. Look for "Custom Action" in the action list
4. You should see all 6 PowerSync actions available:
   - initializePowerSyncAction
   - powerSyncQueryAction
   - powerSyncWriteAction
   - powerSyncWatchQueryAction
   - powerSyncIsConnectedAction
   - powerSyncGetStatusAction

## Next Steps

Once uploaded:

1. **Initialize PowerSync:**
   - Go to your main landing page
   - Add "On Page Load" action
   - Add Custom Action → initializePowerSyncAction

2. **Test:**
   - See FLUTTERFLOW_POWERSYNC_GUIDE.md for usage examples
   - Start with a simple query to verify it works

3. **Build:**
   - Replace direct Supabase calls with PowerSync actions
   - Test offline functionality
   - Deploy to production

---

**Status:** Ready for manual upload
**Time Required:** ~10 minutes
**Alternative:** Wait for Claude Code session restart to use MCP automation
