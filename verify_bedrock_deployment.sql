-- Bedrock Models Deployment Verification Script
-- Run this after deploying to verify everything is set up correctly

-- 1. Check if bedrock_models table exists and has data
SELECT 'bedrock_models table' as check_name,
       CASE
         WHEN COUNT(*) > 0 THEN '✅ PASS'
         ELSE '❌ FAIL'
       END as status,
       COUNT(*) as model_count
FROM bedrock_models;

-- 2. Check available models
SELECT 'Available models' as check_name,
       CASE
         WHEN COUNT(*) >= 3 THEN '✅ PASS'
         ELSE '❌ FAIL'
       END as status,
       COUNT(*) as count
FROM bedrock_models
WHERE is_available = TRUE;

-- 3. Check default model is set
SELECT 'Default model' as check_name,
       CASE
         WHEN COUNT(*) = 1 THEN '✅ PASS'
         ELSE '❌ FAIL'
       END as status,
       COALESCE(model_id, 'NONE SET') as model
FROM bedrock_models
WHERE is_default = TRUE
GROUP BY model_id;

-- 4. Check all models have proper configuration
SELECT 'Model configuration' as check_name,
       CASE
         WHEN COUNT(*) = 0 THEN '✅ PASS'
         ELSE '❌ FAIL'
       END as status,
       COUNT(*) as incomplete_count
FROM bedrock_models
WHERE model_id IS NULL
   OR model_name IS NULL
   OR provider IS NULL
   OR format IS NULL
   OR max_tokens IS NULL;

-- 5. Check model format is valid
SELECT 'Valid formats' as check_name,
       CASE
         WHEN COUNT(DISTINCT format) > 0 AND SUM(CASE WHEN format NOT IN ('nova', 'claude') THEN 1 ELSE 0 END) = 0
         THEN '✅ PASS'
         ELSE '❌ FAIL'
       END as status,
       COUNT(DISTINCT format) as format_count,
       STRING_AGG(DISTINCT format, ', ') as formats
FROM bedrock_models;

-- 6. Check RLS policies are enabled
SELECT 'RLS policies' as check_name,
       CASE
         WHEN row_security_active = TRUE THEN '✅ PASS'
         ELSE '❌ FAIL'
       END as status
FROM information_schema.tables
WHERE table_name = 'bedrock_models' AND table_schema = 'public';

-- 7. List all available models
SELECT '--- Available Models ---' as separator;
SELECT model_id, model_name, provider, format, use_case, is_default
FROM bedrock_models
WHERE is_available = TRUE
ORDER BY priority ASC;

-- 8. List any disabled models
SELECT '--- Disabled Models ---' as separator;
SELECT model_id, model_name, provider
FROM bedrock_models
WHERE is_available = FALSE
ORDER BY model_id;

-- 9. Check functions exist
SELECT '--- Helper Functions ---' as separator,
       routine_name,
       routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_best_bedrock_model', 'list_available_bedrock_models');

-- 10. Summary
SELECT '--- Deployment Summary ---' as summary,
       'Models seeded: ' || (SELECT COUNT(*) FROM bedrock_models)::TEXT as detail
UNION ALL
SELECT '',
       'Models enabled: ' || (SELECT COUNT(*) FROM bedrock_models WHERE is_available = TRUE)::TEXT
UNION ALL
SELECT '',
       'Default model: ' || COALESCE((SELECT model_name FROM bedrock_models WHERE is_default = TRUE LIMIT 1), 'NOT SET')
UNION ALL
SELECT '',
       'Next step: Deploy edge functions and Lambda'
