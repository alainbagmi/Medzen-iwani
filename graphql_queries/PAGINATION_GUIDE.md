# GraphQL Pagination Guide

## Problem: Not All Records Returned

Supabase GraphQL API has a **default limit** on the number of records returned (typically 50-100 records). Without specifying pagination parameters, you'll only get a partial result set.

## Solution: Use `first` Parameter

To retrieve all records, specify the `first` parameter with a value higher than your total record count:

```json
{
  "query": "query { specialtiesCollection(first: 200) { edges { node { specialty_name specialty_code } } } }"
}
```

## Total Records in Database

- **Specialties:** 103 records
- **Recommended `first` value:** 200 (provides buffer for future additions)

## Updated Query Files

All query files have been updated to include `first: 200`:

1. ✅ `get_all_specialties_name_code.json` - Basic query with limit
2. ✅ `get_all_specialties_name_code_sorted.json` - Sorted query with limit
3. ✅ `get_all_specialties_name_code_full.json` - Full query with limit

## Pagination Parameters

### Basic Pagination
```graphql
specialtiesCollection(first: 200) { ... }
```

### With Sorting
```graphql
specialtiesCollection(first: 200, orderBy: {specialty_name: AscNullsLast}) { ... }
```

### With Filtering
```graphql
specialtiesCollection(first: 200, filter: {is_active: {eq: true}}) { ... }
```

### Cursor-Based Pagination (for large datasets)
```graphql
# First page
specialtiesCollection(first: 50) {
  edges {
    node { specialty_name specialty_code }
    cursor
  }
  pageInfo {
    hasNextPage
    endCursor
  }
}

# Next page
specialtiesCollection(first: 50, after: "CURSOR_FROM_PREVIOUS_PAGE") {
  edges {
    node { specialty_name specialty_code }
    cursor
  }
  pageInfo {
    hasNextPage
    endCursor
  }
}
```

## Best Practices

1. **Small Datasets (<200 records):** Use `first: 200` to get all records in one query
2. **Large Datasets (>200 records):** Implement cursor-based pagination
3. **Always include `first`:** Even if you expect fewer results, always specify `first` to avoid confusion
4. **Monitor Performance:** If queries are slow, reduce `first` value and implement pagination
5. **Consider Caching:** For static data like specialties, cache results client-side

## Verification

To check how many records were returned:

```javascript
const response = await fetch('https://YOUR_PROJECT.supabase.co/graphql/v1', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'apikey': 'YOUR_ANON_KEY'
  },
  body: JSON.stringify({
    query: "query { specialtiesCollection(first: 200) { edges { node { specialty_name } } } }"
  })
});

const data = await response.json();
console.log(`Total records returned: ${data.data.specialtiesCollection.edges.length}`);
// Should show: Total records returned: 103
```

## Common Issues

### Issue: "Only getting first 50 records"
**Solution:** Add `first: 200` to your query

### Issue: "Query is slow with large `first` value"
**Solution:** Implement cursor-based pagination with smaller page sizes (e.g., `first: 50`)

### Issue: "Data changes between pages"
**Solution:** Use consistent sorting (`orderBy`) to ensure stable pagination

### Issue: "Don't know total count"
**Solution:** Use `totalCount` field:
```graphql
specialtiesCollection(first: 200) {
  edges { node { specialty_name } }
  totalCount
}
```

## Summary

**Always use `first: 200`** when querying the specialties table to ensure you get all 103 records!
