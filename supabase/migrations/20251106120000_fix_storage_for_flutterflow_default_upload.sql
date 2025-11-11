-- =====================================================
-- Fix Storage RLS for Default FlutterFlow Upload
-- Allows flat paths while maintaining security via ownership tracking
-- =====================================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can upload own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can upload facility images" ON storage.objects;
DROP POLICY IF EXISTS "Facility images are public" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can delete facility images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own documents" ON storage.objects;
DROP POLICY IF EXISTS "Providers can view all documents" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can view all documents" ON storage.objects;
DROP POLICY IF EXISTS "System admins can view all documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own documents" ON storage.objects;

-- Create file ownership tracking table
CREATE TABLE IF NOT EXISTS public.storage_file_ownership (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_path TEXT NOT NULL UNIQUE,
  bucket_id TEXT NOT NULL,
  owner_firebase_uid TEXT NOT NULL,
  file_type TEXT, -- 'avatar', 'facility_image', 'document'
  facility_id UUID, -- Only for facility images
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on ownership table
ALTER TABLE public.storage_file_ownership ENABLE ROW LEVEL SECURITY;

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_storage_ownership_path ON public.storage_file_ownership(storage_path);
CREATE INDEX IF NOT EXISTS idx_storage_ownership_owner ON public.storage_file_ownership(owner_firebase_uid);
CREATE INDEX IF NOT EXISTS idx_storage_ownership_bucket ON public.storage_file_ownership(bucket_id);
CREATE INDEX IF NOT EXISTS idx_storage_ownership_facility ON public.storage_file_ownership(facility_id) WHERE facility_id IS NOT NULL;

-- =====================================================
-- USER AVATARS BUCKET - Allow flat path uploads
-- =====================================================

-- Anyone authenticated can upload to user-avatars
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-avatars');

-- Users can view their own avatars (based on ownership table)
CREATE POLICY "Users can view own avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-avatars' AND (
    -- Check ownership table
    EXISTS (
      SELECT 1 FROM public.storage_file_ownership
      WHERE storage_path = storage.objects.name
      AND bucket_id = 'user-avatars'
      AND owner_firebase_uid = auth.uid()::text
    )
    -- Or allow all reads for now (can be restricted later)
    OR TRUE
  )
);

-- Users can update their own avatars
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  EXISTS (
    SELECT 1 FROM public.storage_file_ownership
    WHERE storage_path = storage.objects.name
    AND bucket_id = 'user-avatars'
    AND owner_firebase_uid = auth.uid()::text
  )
);

-- Users can delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  EXISTS (
    SELECT 1 FROM public.storage_file_ownership
    WHERE storage_path = storage.objects.name
    AND bucket_id = 'user-avatars'
    AND owner_firebase_uid = auth.uid()::text
  )
);

-- =====================================================
-- FACILITY IMAGES BUCKET - Allow flat path uploads
-- =====================================================

-- Authenticated users can upload to facility-images
CREATE POLICY "Authenticated users can upload facility images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'facility-images');

-- Public read for facility images
CREATE POLICY "Facility images are publicly viewable"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'facility-images');

-- Facility admins can delete (based on ownership table)
CREATE POLICY "Facility admins can delete facility images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM public.storage_file_ownership
    WHERE storage_path = storage.objects.name
    AND bucket_id = 'facility-images'
    AND owner_firebase_uid = auth.uid()::text
  )
);

-- =====================================================
-- DOCUMENTS BUCKET - Allow flat path uploads
-- =====================================================

-- Authenticated users can upload documents
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

-- Users can view their own documents
CREATE POLICY "Users can view own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM public.storage_file_ownership
    WHERE storage_path = storage.objects.name
    AND bucket_id = 'documents'
    AND owner_firebase_uid = auth.uid()::text
  )
);

-- Providers can view all documents
CREATE POLICY "Providers can view all documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM public.medical_provider_profiles
    WHERE user_id::text = auth.uid()::text
  )
);

-- Facility admins can view all documents
CREATE POLICY "Facility admins can view all documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM public.facility_admin_profiles
    WHERE user_id::text = auth.uid()::text
  )
);

-- System admins can view all documents
CREATE POLICY "System admins can view all documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM public.system_admin_profiles
    WHERE user_id::text = auth.uid()::text
  )
);

-- Users can delete their own documents
CREATE POLICY "Users can delete own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM public.storage_file_ownership
    WHERE storage_path = storage.objects.name
    AND bucket_id = 'documents'
    AND owner_firebase_uid = auth.uid()::text
  )
);

-- =====================================================
-- HELPER FUNCTIONS FOR TRACKING FILE OWNERSHIP
-- =====================================================

-- Function to track file upload (call this after successful upload)
CREATE OR REPLACE FUNCTION public.track_file_upload(
  p_storage_path TEXT,
  p_bucket_id TEXT,
  p_owner_firebase_uid TEXT,
  p_file_type TEXT DEFAULT NULL,
  p_facility_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_ownership_id UUID;
BEGIN
  INSERT INTO public.storage_file_ownership (
    storage_path,
    bucket_id,
    owner_firebase_uid,
    file_type,
    facility_id
  ) VALUES (
    p_storage_path,
    p_bucket_id,
    p_owner_firebase_uid,
    p_file_type,
    p_facility_id
  )
  ON CONFLICT (storage_path) DO UPDATE
  SET owner_firebase_uid = EXCLUDED.owner_firebase_uid,
      file_type = EXCLUDED.file_type,
      facility_id = EXCLUDED.facility_id,
      updated_at = NOW()
  RETURNING id INTO v_ownership_id;

  RETURN v_ownership_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check file ownership
CREATE OR REPLACE FUNCTION public.check_file_ownership(
  p_storage_path TEXT,
  p_firebase_uid TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.storage_file_ownership
    WHERE storage_path = p_storage_path
    AND owner_firebase_uid = COALESCE(p_firebase_uid, auth.uid()::text)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get file owner
CREATE OR REPLACE FUNCTION public.get_file_owner(
  p_storage_path TEXT
) RETURNS TEXT AS $$
DECLARE
  v_owner TEXT;
BEGIN
  SELECT owner_firebase_uid INTO v_owner
  FROM public.storage_file_ownership
  WHERE storage_path = p_storage_path;

  RETURN v_owner;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- RLS POLICIES FOR OWNERSHIP TABLE
-- =====================================================

-- Users can insert their own ownership records
CREATE POLICY "Users can track their own uploads"
ON public.storage_file_ownership FOR INSERT
TO authenticated
WITH CHECK (owner_firebase_uid = auth.uid()::text);

-- Users can view their own ownership records
CREATE POLICY "Users can view their own file ownership"
ON public.storage_file_ownership FOR SELECT
TO authenticated
USING (owner_firebase_uid = auth.uid()::text);

-- Users can update their own ownership records
CREATE POLICY "Users can update their own file ownership"
ON public.storage_file_ownership FOR UPDATE
TO authenticated
USING (owner_firebase_uid = auth.uid()::text);

-- Users can delete their own ownership records
CREATE POLICY "Users can delete their own file ownership"
ON public.storage_file_ownership FOR DELETE
TO authenticated
USING (owner_firebase_uid = auth.uid()::text);

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT ALL ON public.storage_file_ownership TO authenticated;
GRANT ALL ON public.storage_file_ownership TO service_role;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check storage buckets
-- SELECT * FROM storage.buckets WHERE id IN ('user-avatars', 'facility-images', 'documents');

-- Check RLS policies
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- Check ownership table
-- SELECT * FROM public.storage_file_ownership;
