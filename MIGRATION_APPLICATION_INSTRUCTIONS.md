# Database Migration Application Instructions

**Status:** Ready to apply
**Migration File:** `supabase/migrations/20260122120000_create_facility_document_generation.sql`
**What It Does:** Creates the `facility_generated_documents` table for the facility document generation system

---

## Quick Apply (2 minutes)

### Step 1: Open Supabase SQL Editor

Navigate to your Supabase project SQL editor:
```
https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql/new
```

### Step 2: Copy the Migration SQL

Copy the entire SQL from below (or from the migration file):

```sql
-- Facility Document Generation System
-- Tracks AI-prefilled facility documents with versioning
CREATE TABLE IF NOT EXISTS facility_generated_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE NOT NULL,
  document_type VARCHAR(100) NOT NULL,
  template_path TEXT NOT NULL,
  title VARCHAR(255) NOT NULL,
  file_path TEXT,
  file_size BIGINT,
  version INTEGER DEFAULT 1 NOT NULL,
  status VARCHAR(50) DEFAULT 'draft',
  ai_prefill_data JSONB,
  ai_confidence_score DECIMAL(3,2),
  ai_flags JSONB,
  generated_by UUID REFERENCES users(id) NOT NULL,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_by UUID REFERENCES users(id),
  confirmed_at TIMESTAMPTZ,
  confirmation_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_facility
  ON facility_generated_documents(facility_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_status
  ON facility_generated_documents(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_facility_document_draft
  ON facility_generated_documents(facility_id, document_type, DATE(created_at))
  WHERE status IN ('draft', 'preview');

CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_type_date
  ON facility_generated_documents(document_type, created_at DESC)
  WHERE status != 'draft';

-- Enable RLS
ALTER TABLE facility_generated_documents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Facility admins view own documents" ON facility_generated_documents;
DROP POLICY IF EXISTS "Facility admins update own documents" ON facility_generated_documents;
DROP POLICY IF EXISTS "Service role can manage documents" ON facility_generated_documents;

CREATE POLICY "Facility admins view own documents"
ON facility_generated_documents FOR SELECT
TO authenticated
USING (
  facility_id IN (
    SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
    UNION
    SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Facility admins update own documents"
ON facility_generated_documents FOR UPDATE
TO authenticated
USING (
  facility_id IN (
    SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
    UNION
    SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Service role can manage documents"
ON facility_generated_documents FOR ALL
TO service_role
USING (true);

-- Create trigger for auto-update timestamp
DROP TRIGGER IF EXISTS update_facility_generated_documents_updated_at ON facility_generated_documents;
CREATE TRIGGER update_facility_generated_documents_updated_at
BEFORE UPDATE ON facility_generated_documents
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT SELECT ON facility_generated_documents TO authenticated;
GRANT UPDATE ON facility_generated_documents TO authenticated;
GRANT SELECT, INSERT, UPDATE ON facility_generated_documents TO service_role;
```

### Step 3: Paste into SQL Editor

1. In the SQL editor, click the text area
2. Paste the SQL code
3. The editor will format it automatically

### Step 4: Execute the Migration

Click the blue **Run** button (bottom-right corner), or press:
- **Mac:** `Cmd + Enter`
- **Windows/Linux:** `Ctrl + Enter`

You should see: ✅ **Query executed successfully**

---

## Verify Migration Applied

After running the SQL, verify it worked by running these checks:

### Quick Check (Run this first)
```sql
SELECT COUNT(*) as table_exists
FROM information_schema.tables
WHERE table_name = 'facility_generated_documents';
```

Expected result: `1` (table exists)

### Full Table Structure Check
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'facility_generated_documents'
ORDER BY ordinal_position;
```

Expected columns (19 total):
- id, facility_id, document_type, template_path, title
- file_path, file_size, version, status
- ai_prefill_data, ai_confidence_score, ai_flags
- generated_by, generated_at, confirmed_by, confirmed_at, confirmation_notes
- created_at, updated_at

### Check RLS Policies
```sql
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'facility_generated_documents'
ORDER BY policyname;
```

Expected result: 3 policies
- "Facility admins view own documents" (SELECT)
- "Facility admins update own documents" (UPDATE)
- "Service role can manage documents" (ALL)

### Check Indexes
```sql
SELECT indexname
FROM pg_indexes
WHERE tablename = 'facility_generated_documents'
ORDER BY indexname;
```

Expected result: 4 indexes
- idx_facility_generated_documents_facility
- idx_facility_generated_documents_status
- idx_facility_generated_documents_type_date
- idx_unique_facility_document_draft

### Check Trigger
```sql
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'facility_generated_documents';
```

Expected result: 1 trigger
- update_facility_generated_documents_updated_at (BEFORE UPDATE)

---

## Troubleshooting

### Error: "Table already exists"
**This is fine!** The migration uses `CREATE TABLE IF NOT EXISTS`, so running it again is safe. Just click Run again - it will complete successfully.

### Error: "Permission denied"
**Solution:** Make sure you're logged into Supabase as a project admin. Check the dashboard URL contains: `noaeltglphdlkbflipit`

### Error: "Relation 'facility_admin_profiles' does not exist"
**Solution:** This table should already exist from previous migrations. If not, the RLS policies will fail. Run the query anyway - the table creation will succeed, you may just need to adjust RLS policies later.

### Query seems to hang
**Solution:** Large migrations can take 10-30 seconds. Wait for the result. Don't close the window.

### Got "Query executed successfully" but table not found
**Solution:** Run the quick verification check above to confirm the table was created.

---

## Next Steps After Migration

✅ **Once migration is applied:**

1. **Verify** - Run one of the verification queries above
2. **Integrate UI** - Follow `FLUTTERFLOW_INTEGRATION_GUIDE.md`
3. **Test** - Generate a test document
4. **Deploy** - Push to ALINO branch

---

## Rollback (If Needed)

If something goes wrong, you can undo this migration:

```sql
DROP TABLE IF EXISTS facility_generated_documents CASCADE;
```

This will remove the table, all data, and all associated indexes and policies.

---

## Additional Resources

- **Full System Documentation:** `FACILITY_DOCUMENT_GENERATION.md`
- **UI Integration Guide:** `FLUTTERFLOW_INTEGRATION_GUIDE.md`
- **Deployment Checklist:** `DEPLOYMENT_SUMMARY.md`

---

**Questions?** Check the troubleshooting section above or review the migration SQL to understand what's being created.
