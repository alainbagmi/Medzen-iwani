# PowerSync Quick Start (30 Minutes)

Get your true offline-first EHR system running in 30 minutes.

## Why This Matters

**❌ Old approach:** Writes to Supabase fail when offline
**✅ PowerSync:** Writes to local SQLite, syncs automatically when online

## Prerequisites

- [ ] PowerSync account created (you have this!)
- [ ] Supabase project
- [ ] EHRbase instance
- [ ] Flutter SDK
- [ ] 30 minutes

## Step 1: Get PowerSync Credentials (5 min)

1. Go to your [PowerSync Dashboard](https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898)
2. Navigate to **Settings** → **API Keys**
3. Click **Generate RSA Key Pair**
4. Save these values:
   - **Key ID**: `abc123...`
   - **Private Key**: Copy the entire key including headers

## Step 2: Configure PowerSync Sync Rules (5 min)

In PowerSync dashboard:

1. Go to **Sync Rules**
2. Paste this configuration:

```yaml
bucket_definitions:
  global:
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()
    data:
      - SELECT * FROM users WHERE id = bucket.user_id
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id
      - SELECT * FROM ehrbase_sync_queue WHERE record_id IN (
          SELECT id::text FROM users WHERE id = bucket.user_id
        )
```

3. Click **Save**

## Step 3: Deploy PowerSync Token Function (10 min)

```bash
# Set secrets
npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE.journeyapps.com
npx supabase secrets set POWERSYNC_KEY_ID=your-key-id-from-step-1
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
... paste your entire private key here ...
-----END PRIVATE KEY-----"

# Deploy function
npx supabase functions deploy powersync-token

# Test it
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer YOUR_USER_TOKEN"
```

Expected output:
```json
{
  "token": "eyJhbGc...",
  "powersync_url": "https://...",
  "expires_at": "2025-01-22T...",
  "user_id": "..."
}
```

## Step 4: Update Flutter App (5 min)

### 4a. Install Dependencies

```bash
flutter pub get
```

### 4b. Initialize PowerSync

**Update `lib/main.dart`:**

```dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';
import 'package:medzen_iwani/powersync/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await SupaFlow.initialize();

  // Initialize PowerSync (NEW!)
  await initializePowerSync();

  runApp(MyApp());
}
```

**OR in FlutterFlow:**
1. Open your main landing page
2. Add Custom Action on Page Load
3. Select `initializePowerSync`
4. Place it after Supabase initialization

### 4c. Use PowerSync in Your Code

**Before (❌ fails offline):**
```dart
await SupaFlow.client.from('vital_signs').insert({...});
```

**After (✅ works offline):**
```dart
import 'package:medzen_iwani/powersync/database.dart';

await db.execute('''
  INSERT INTO vital_signs (id, patient_id, systolic_bp, diastolic_bp, created_at)
  VALUES (?, ?, ?, ?, ?)
''', [uuid.v4(), userId, 120, 80, DateTime.now().toIso8601String()]);
```

## Step 5: Test Offline Functionality (5 min)

### Test 1: Offline Write

1. **Enable airplane mode** on device/emulator
2. **Create a vital signs record:**
   ```dart
   // Add this button to your UI for testing
   ElevatedButton(
     onPressed: () async {
       await db.execute('''
         INSERT INTO vital_signs (id, patient_id, systolic_bp, diastolic_bp, created_at)
         VALUES (?, ?, ?, ?, ?)
       ''', [
         Uuid().v4(),
         userId,
         120,
         80,
         DateTime.now().toIso8601String(),
       ]);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Vital signs saved offline!')),
       );
     },
     child: Text('Add Vital Signs (Offline Test)'),
   )
   ```
3. **Click the button** - Should succeed even offline!
4. **Disable airplane mode**
5. **Check PowerSync status:**
   ```dart
   print('Connected: ${isPowerSyncConnected()}');
   print('Last synced: ${getLastSyncedAt()}');
   ```
6. **Verify in Supabase:**
   ```sql
   SELECT * FROM vital_signs ORDER BY created_at DESC LIMIT 1;
   ```

✅ **Success:** Data saved offline, synced when online!

### Test 2: Real-time Updates

```dart
// Watch for changes
StreamBuilder(
  stream: watchQuery('SELECT * FROM vital_signs WHERE patient_id = ? ORDER BY created_at DESC', [userId]),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        final vital = snapshot.data![index];
        return ListTile(
          title: Text('BP: ${vital['systolic_bp']}/${vital['diastolic_bp']}'),
          subtitle: Text('Recorded: ${vital['created_at']}'),
        );
      },
    );
  },
)
```

Update a record in Supabase SQL Editor - UI updates automatically!

## Common Issues

### Issue: "PowerSync not configured"

**Fix:**
```bash
# Check secrets are set
npx supabase secrets list

# Should show:
# - POWERSYNC_URL
# - POWERSYNC_KEY_ID
# - POWERSYNC_PRIVATE_KEY
```

### Issue: Not syncing

**Debug:**
```dart
db.statusStream.listen((status) {
  print('PowerSync Status:');
  print('  Connected: ${status.connected}');
  print('  Downloading: ${status.downloading}');
  print('  Uploading: ${status.uploading}');
  print('  Last Synced: ${status.lastSyncedAt}');
});
```

### Issue: Sync rules not working

**Check in PowerSync dashboard:**
1. Go to **Sync Rules**
2. Click **Test** button
3. Enter a test user ID
4. Verify queries return expected data

## Migration Checklist

If migrating from old implementation:

- [ ] PowerSync credentials configured
- [ ] Sync rules saved in dashboard
- [ ] Token function deployed
- [ ] App initialization updated
- [ ] Existing code migrated to use `db` instead of `SupaFlow.client`
- [ ] Tested offline writes
- [ ] Tested bidirectional sync
- [ ] Monitored in PowerSync dashboard

## Next Steps

1. **Read full guide:** See [POWERSYNC_IMPLEMENTATION.md](./POWERSYNC_IMPLEMENTATION.md)
2. **Migrate all queries:** Replace SupaFlow.client with PowerSync db
3. **Monitor dashboard:** Watch sync metrics
4. **Test edge cases:** Conflict resolution, long offline periods
5. **Deploy to production:** Update production secrets

## Resources

- **Your Dashboard:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
- **PowerSync Docs:** https://docs.powersync.com/
- **Flutter SDK Docs:** https://docs.powersync.com/client-sdk-references/flutter
- **Supabase Integration:** https://docs.powersync.com/integration-guides/supabase

---

**Congratulations!** 🎉 You now have a **true offline-first** EHR system that works seamlessly online and offline!
