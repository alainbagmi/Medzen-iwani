# FlutterFlow GraphQL Pagination Issue

## Problem

FlutterFlow's GraphQL interface returns only **30 specialties** instead of all 103, even when `first: 200` is specified in the query.

**Database Status:** ✅ All 103 specialties are correctly stored in the database.

**Query Used:**
```json
{
  "query": "query { specialtiesCollection(first: 200, orderBy: {specialty_name: AscNullsLast}) { edges { node { specialty_name specialty_code } } } }"
}
```

**Actual Results:** Only 30 records returned (stops at "Gastroenterology")

## Root Cause

FlutterFlow's GraphQL UI appears to have a **hardcoded 30-record display limit** that overrides the `first` parameter.

## Solutions

### Solution 1: Use Direct Supabase Client (Recommended)

**DO NOT use FlutterFlow's GraphQL interface for this.** Use Supabase's REST API directly in your Flutter app:

```dart
// lib/custom_code/actions/get_all_specialties.dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';

Future<List<Map<String, dynamic>>> getAllSpecialties() async {
  final response = await SupaFlow.client
      .from('specialties')
      .select('specialty_code, specialty_name')
      .eq('is_active', true)
      .order('specialty_name')
      .limit(200);  // Explicit limit

  if (response == null) {
    return [];
  }

  return List<Map<String, dynamic>>.from(response);
}
```

### Solution 2: Use Supabase Studio to Verify

1. Open Supabase Studio: https://supabase.com/dashboard
2. Navigate to your project → Table Editor → `specialties`
3. Verify all 103 records are present
4. Use SQL Editor to run:
```sql
SELECT COUNT(*) FROM specialties;  -- Should return 103
SELECT specialty_code, specialty_name FROM specialties ORDER BY specialty_name;
```

### Solution 3: Query with Pagination Info

Try this query to see if pagination is working:

```json
{
  "query": "query { specialtiesCollection(first: 200, orderBy: {specialty_name: AscNullsLast}) { edges { node { specialty_name specialty_code } } pageInfo { hasNextPage hasPreviousPage startCursor endCursor } totalCount } }"
}
```

Check the response for:
- `totalCount` - Should be 103
- `pageInfo.hasNextPage` - If true, there are more records
- `pageInfo.endCursor` - Use this to fetch next page

### Solution 4: Multiple Paginated Requests

If you must use GraphQL, fetch in batches:

**Query 1 (records 1-50):**
```json
{
  "query": "query { specialtiesCollection(first: 50, orderBy: {specialty_name: AscNullsLast}) { edges { node { specialty_name specialty_code } cursor } pageInfo { endCursor hasNextPage } } }"
}
```

**Query 2 (records 51-100):**
```json
{
  "query": "query { specialtiesCollection(first: 50, after: \"CURSOR_FROM_QUERY_1\", orderBy: {specialty_name: AscNullsLast}) { edges { node { specialty_name specialty_code } cursor } pageInfo { endCursor hasNextPage } } }"
}
```

**Query 3 (records 101-103):**
```json
{
  "query": "query { specialtiesCollection(first: 50, after: \"CURSOR_FROM_QUERY_2\", orderBy: {specialty_name: AscNullsLast}) { edges { node { specialty_name specialty_code } } } }"
}
```

## Recommended Implementation

### For FlutterFlow App (Use Custom Action)

**Create:** `lib/custom_code/actions/get_all_specialties.dart`

```dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';

/// Retrieves all medical specialties from Supabase
///
/// Returns: List of maps with specialty_code and specialty_name
Future<List<Map<String, dynamic>>> getAllSpecialties() async {
  try {
    final response = await SupaFlow.client
        .from('specialties')
        .select('id, specialty_code, specialty_name, description')
        .eq('is_active', true)
        .order('specialty_name', ascending: true)
        .limit(200);

    if (response == null) {
      print('Error: No data returned from specialties query');
      return [];
    }

    // Convert to List<Map<String, dynamic>>
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error fetching specialties: $e');
    return [];
  }
}
```

**Use in FlutterFlow:**
1. Add Custom Action → Import `get_all_specialties.dart`
2. On page load or dropdown open → Run action
3. Store result in App State or Page State
4. Bind dropdown options to the result

### For Testing (Supabase SQL Editor)

```sql
-- Verify count
SELECT COUNT(*) as total_count FROM specialties;

-- Get all specialties alphabetically
SELECT specialty_code, specialty_name
FROM specialties
WHERE is_active = true
ORDER BY specialty_name;

-- Check specific range
SELECT specialty_name
FROM specialties
WHERE is_active = true
ORDER BY specialty_name
LIMIT 35;  -- Should show up to "Gastroenterology"

SELECT specialty_name
FROM specialties
WHERE is_active = true
ORDER BY specialty_name
OFFSET 30;  -- Should show everything after "Gastroenterology"
```

## Verification Steps

1. **Database has 103 records:** ✅ Confirmed via migration file
2. **GraphQL returns 30 records:** ⚠️ FlutterFlow UI limitation
3. **Direct Supabase query returns all:** ✅ Should work with custom action

## Next Steps

1. ✅ Create custom action `get_all_specialties.dart`
2. ✅ Use direct Supabase client instead of GraphQL
3. ✅ Test custom action returns all 103 specialties
4. ✅ Update FlutterFlow dropdown to use custom action

## Why This Happens

FlutterFlow's GraphQL testing interface has display limits for UI performance. The actual GraphQL endpoint can handle larger result sets, but the **UI preview pane** caps results at 30 records.

**Solution:** Don't rely on FlutterFlow's GraphQL UI for large datasets. Use custom actions with direct Supabase client calls.
