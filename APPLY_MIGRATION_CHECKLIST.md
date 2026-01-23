# Migration Application Checklist

## ✅ Status: Ready to Apply

**Date:** January 22, 2026
**System:** Facility Document Generation System
**Action:** Apply database migration

---

## 📋 Manual Application Steps (2 minutes)

### Step 1: Open Supabase SQL Editor
```
👉 Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql/new
```

### Step 2: Click "New Query"
- Look for the blue "+ New Query" button
- Or click the "SQL" tab on the left sidebar

### Step 3: Copy the SQL Below

```sql
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

CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_facility ON facility_generated_documents(facility_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_status ON facility_generated_documents(status);
CREATE INDEX IF NOT EXISTS idx_facility_generated_documents_type_date ON facility_generated_documents(document_type, created_at DESC) WHERE status != 'draft';
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_facility_document_draft ON facility_generated_documents(facility_id, document_type, DATE(created_at)) WHERE status IN ('draft', 'preview');

ALTER TABLE facility_generated_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Facility admins view own documents" ON facility_generated_documents;
DROP POLICY IF EXISTS "Facility admins update own documents" ON facility_generated_documents;
DROP POLICY IF EXISTS "Service role can manage documents" ON facility_generated_documents;

CREATE POLICY "Facility admins view own documents" ON facility_generated_documents FOR SELECT TO authenticated USING (
  facility_id IN (
    SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
    UNION
    SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Facility admins update own documents" ON facility_generated_documents FOR UPDATE TO authenticated USING (
  facility_id IN (
    SELECT primary_facility_id FROM facility_admin_profiles WHERE user_id = auth.uid()
    UNION
    SELECT unnest(managed_facilities) FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Service role can manage documents" ON facility_generated_documents FOR ALL TO service_role USING (true);

DROP TRIGGER IF EXISTS update_facility_generated_documents_updated_at ON facility_generated_documents;
CREATE TRIGGER update_facility_generated_documents_updated_at BEFORE UPDATE ON facility_generated_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT SELECT ON facility_generated_documents TO authenticated;
GRANT UPDATE ON facility_generated_documents TO authenticated;
GRANT SELECT, INSERT, UPDATE ON facility_generated_documents TO service_role;
```

### Step 4: Click Run Button
- Look for the green **Run** button at the bottom right
- Or press `Cmd+Enter` (Mac) / `Ctrl+Enter` (Windows/Linux)

### Step 5: Verify Success
You should see a message like:
```
Query executed successfully
```

---

## ✅ Verification Steps

### Quick Verification (Run in New Query)
```sql
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_name = 'facility_generated_documents';
```

Expected result: `1` (table exists)

### Full Verification
```sql
-- Check table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'facility_generated_documents'
ORDER BY ordinal_position;
```

Expected result: 19 columns including:
- id (UUID)
- facility_id (UUID)
- document_type (VARCHAR)
- template_path (TEXT)
- ai_confidence_score (NUMERIC)
- status (VARCHAR)
- etc.

### Check RLS Policies
```sql
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'facility_generated_documents';
```

Expected result: 3 policies
- "Facility admins view own documents" (SELECT)
- "Facility admins update own documents" (UPDATE)
- "Service role can manage documents" (ALL)

### Check Indexes
```sql
SELECT indexname
FROM pg_indexes
WHERE tablename = 'facility_generated_documents';
```

Expected result: 4 indexes
- idx_facility_generated_documents_facility
- idx_facility_generated_documents_status
- idx_facility_generated_documents_type_date
- idx_unique_facility_document_draft

---

## 🚀 Next Steps After Migration

1. ✅ **Migration Applied**
   - Table created
   - RLS policies active
   - Indexes created

2. **Test Edge Function**
   - Check logs: `npx supabase functions logs generate-facility-document --tail`
   - Verify Bedrock integration working

3. **Integrate Flutter UI**
   - Follow: `FLUTTERFLOW_INTEGRATION_GUIDE.md`
   - Add "Generate Document" button
   - Connect custom actions
   - Add preview dialog

4. **Test End-to-End**
   - Generate test document
   - Review preview
   - Confirm and print
   - Check database

5. **Deploy to Production**
   - Push to ALINO branch
   - Merge and deploy

---

## ⚠️ Troubleshooting

### "Table already exists" error
- This is normal if you've run this before
- The `CREATE TABLE IF NOT EXISTS` prevents errors
- Just run the query again - it will complete successfully

### "Permission denied" error
- You may need to be logged in as a Supabase admin
- Check you're using the correct Supabase project
- Verify URL contains: `noaeltglphdlkbflipit`

### RLS Policy errors
- Make sure `facility_admin_profiles` table exists
- Check `auth.uid()` context is available
- Verify roles are set correctly

### Index creation timeout
- Indexes on larger tables can take a few seconds
- Just wait for the query to complete
- Check the "Query executed successfully" message

---

## 📞 Support

If you encounter any issues:

1. **Check Supabase Logs**
   - Dashboard → Logs → PostgreSQL
   - Look for error messages

2. **Verify Table Permissions**
   - Run: `SHOW CURRENT_USER;`
   - Should be: `postgres`

3. **Check Migration File**
   - Location: `supabase/migrations/20260122120000_create_facility_document_generation.sql`
   - Content length: ~3.5 KB

4. **Read Documentation**
   - `FACILITY_DOCUMENT_GENERATION.md` - System overview
   - `FLUTTERFLOW_INTEGRATION_GUIDE.md` - UI integration
   - `DEPLOYMENT_SUMMARY.md` - Deployment guide

---

## ✨ You're Almost Done!

Once you apply this migration, your system is fully functional and ready for:
- ✅ AI-prefilled document generation
- ✅ User preview and confirmation workflow
- ✅ Confidence scoring and AI flags
- ✅ Document versioning
- ✅ Audit trails and RLS security
- ✅ Print integration

**Estimated Time to Complete:** 2 minutes
**Estimated Time to First Document:** 5 minutes after applying

Let's go! 🚀
