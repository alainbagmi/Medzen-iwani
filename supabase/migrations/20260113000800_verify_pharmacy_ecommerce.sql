-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 9: Verification
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Comprehensive verification of pharmacy e-commerce installation
--              Verifies:
--              - 12 tables exist
--              - 12 views exist
--              - 10 functions exist
--              - 10 triggers exist
--              - 50+ indexes exist
--              - RLS enabled on all tables
--              - 30+ RLS policies exist
--              - Seed data loaded
-- ============================================

-- ============================================
-- VERIFICATION 1: Tables
-- Expected: 12 tables
-- ============================================

DO $$
DECLARE
    table_count INTEGER;
    expected_tables TEXT[] := ARRAY[
        'product_categories',
        'product_subcategories',
        'pharmacy_products',
        'user_cart',
        'user_wishlist',
        'user_addresses',
        'pharmacy_orders',
        'pharmacy_order_items',
        'product_reviews',
        'order_tracking',
        'pharmacy_coupons',
        'coupon_usage'
    ];
    missing_tables TEXT[];
BEGIN
    -- Count tables
    SELECT COUNT(*)
    INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = ANY(expected_tables);

    -- Find missing tables
    SELECT ARRAY_AGG(table_name)
    INTO missing_tables
    FROM (
        SELECT unnest(expected_tables) AS table_name
        EXCEPT
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = ANY(expected_tables)
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: TABLES ===';
    RAISE NOTICE 'Expected: 12 tables';
    RAISE NOTICE 'Found: % tables', table_count;

    IF table_count = 12 THEN
        RAISE NOTICE '✓ All tables created successfully';
    ELSE
        RAISE WARNING '✗ Missing tables: %', missing_tables;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 2: Views
-- Expected: 12 views
-- ============================================

DO $$
DECLARE
    view_count INTEGER;
    expected_views TEXT[] := ARRAY[
        'v_pharmacy_products_full',
        'v_user_cart_details',
        'v_user_wishlist_details',
        'v_order_summary',
        'v_order_details_full',
        'v_product_with_reviews',
        'v_pharmacy_inventory',
        'v_pharmacy_dashboard_stats',
        'v_category_product_counts',
        'v_user_order_history',
        'v_pharmacy_inventory_dashboard',
        'v_pharmacy_inventory_full'
    ];
    missing_views TEXT[];
BEGIN
    -- Count views
    SELECT COUNT(*)
    INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public'
    AND table_name = ANY(expected_views);

    -- Find missing views
    SELECT ARRAY_AGG(view_name)
    INTO missing_views
    FROM (
        SELECT unnest(expected_views) AS view_name
        EXCEPT
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'public'
        AND table_name = ANY(expected_views)
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: VIEWS ===';
    RAISE NOTICE 'Expected: 12 views';
    RAISE NOTICE 'Found: % views', view_count;

    IF view_count = 12 THEN
        RAISE NOTICE '✓ All views created successfully';
    ELSE
        RAISE WARNING '✗ Missing views: %', missing_views;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 3: Functions
-- Expected: 10 functions
-- ============================================

DO $$
DECLARE
    function_count INTEGER;
    expected_functions TEXT[] := ARRAY[
        'update_product_search_vector',
        'update_cart_timestamp',
        'ensure_single_default_address',
        'generate_order_number',
        'update_order_status_timestamp',
        'calculate_line_total',
        'update_product_sold_count',
        'update_product_rating',
        'is_pharmacy_admin',
        'sync_pharmacy_inventory'
    ];
    missing_functions TEXT[];
BEGIN
    -- Count functions
    SELECT COUNT(*)
    INTO function_count
    FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND routine_name = ANY(expected_functions)
    AND routine_type = 'FUNCTION';

    -- Find missing functions
    SELECT ARRAY_AGG(func_name)
    INTO missing_functions
    FROM (
        SELECT unnest(expected_functions) AS func_name
        EXCEPT
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND routine_name = ANY(expected_functions)
        AND routine_type = 'FUNCTION'
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: FUNCTIONS ===';
    RAISE NOTICE 'Expected: 10 functions';
    RAISE NOTICE 'Found: % functions', function_count;

    IF function_count = 10 THEN
        RAISE NOTICE '✓ All functions created successfully';
    ELSE
        RAISE WARNING '✗ Missing functions: %', missing_functions;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 4: Triggers
-- Expected: 10 triggers
-- ============================================

DO $$
DECLARE
    trigger_count INTEGER;
    expected_triggers TEXT[] := ARRAY[
        'trigger_update_product_search',
        'trigger_update_cart_timestamp',
        'trigger_single_default_address',
        'trigger_generate_order_number',
        'trigger_update_order_status_timestamp',
        'trigger_calculate_line_total',
        'trigger_update_sold_count',
        'trigger_update_product_rating',
        'sync_to_inventory',
        'sync_from_inventory'
    ];
    missing_triggers TEXT[];
BEGIN
    -- Count triggers
    SELECT COUNT(*)
    INTO trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
    AND trigger_name = ANY(expected_triggers);

    -- Find missing triggers
    SELECT ARRAY_AGG(trigger_name)
    INTO missing_triggers
    FROM (
        SELECT unnest(expected_triggers) AS trigger_name
        EXCEPT
        SELECT trigger_name
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
        AND trigger_name = ANY(expected_triggers)
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: TRIGGERS ===';
    RAISE NOTICE 'Expected: 10 triggers';
    RAISE NOTICE 'Found: % triggers', trigger_count;

    IF trigger_count = 10 THEN
        RAISE NOTICE '✓ All triggers created successfully';
    ELSE
        RAISE WARNING '✗ Missing triggers: %', missing_triggers;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 5: Indexes
-- Expected: 50+ indexes
-- ============================================

DO $$
DECLARE
    index_count INTEGER;
    tables_with_indexes RECORD;
BEGIN
    -- Count all pharmacy e-commerce indexes
    SELECT COUNT(*)
    INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage', 'dispensed_medications'
    );

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: INDEXES ===';
    RAISE NOTICE 'Expected: 50+ indexes';
    RAISE NOTICE 'Found: % indexes', index_count;

    IF index_count >= 50 THEN
        RAISE NOTICE '✓ Sufficient indexes created';
    ELSE
        RAISE WARNING '✗ Only % indexes found (expected 50+)', index_count;
    END IF;

    -- Show index count per table
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes per table:';
    FOR tables_with_indexes IN (
        SELECT tablename, COUNT(*) as idx_count
        FROM pg_indexes
        WHERE schemaname = 'public'
        AND indexname LIKE 'idx_%'
        AND tablename IN (
            'product_categories', 'product_subcategories', 'pharmacy_products',
            'user_cart', 'user_wishlist', 'user_addresses',
            'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
            'order_tracking', 'pharmacy_coupons', 'coupon_usage'
        )
        GROUP BY tablename
        ORDER BY tablename
    ) LOOP
        RAISE NOTICE '  - %: % indexes', tables_with_indexes.tablename, tables_with_indexes.idx_count;
    END LOOP;
END $$;

-- ============================================
-- VERIFICATION 6: RLS Enabled
-- Expected: RLS enabled on all 12 tables
-- ============================================

DO $$
DECLARE
    rls_enabled_count INTEGER;
    tables_without_rls TEXT[];
BEGIN
    -- Count tables with RLS enabled
    SELECT COUNT(*)
    INTO rls_enabled_count
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage'
    )
    AND rowsecurity = true;

    -- Find tables without RLS
    SELECT ARRAY_AGG(tablename)
    INTO tables_without_rls
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage'
    )
    AND rowsecurity = false;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: RLS ENABLED ===';
    RAISE NOTICE 'Expected: 12 tables with RLS';
    RAISE NOTICE 'Found: % tables with RLS enabled', rls_enabled_count;

    IF rls_enabled_count = 12 THEN
        RAISE NOTICE '✓ RLS enabled on all tables';
    ELSE
        RAISE WARNING '✗ RLS not enabled on: %', tables_without_rls;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 7: RLS Policies
-- Expected: 30+ policies
-- ============================================

DO $$
DECLARE
    policy_count INTEGER;
    table_policies RECORD;
BEGIN
    -- Count all RLS policies
    SELECT COUNT(*)
    INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage'
    );

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: RLS POLICIES ===';
    RAISE NOTICE 'Expected: 30+ policies';
    RAISE NOTICE 'Found: % policies', policy_count;

    IF policy_count >= 30 THEN
        RAISE NOTICE '✓ Sufficient RLS policies created';
    ELSE
        RAISE WARNING '✗ Only % policies found (expected 30+)', policy_count;
    END IF;

    -- Show policy count per table
    RAISE NOTICE '';
    RAISE NOTICE 'Policies per table:';
    FOR table_policies IN (
        SELECT tablename, COUNT(*) as policy_count
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename IN (
            'product_categories', 'product_subcategories', 'pharmacy_products',
            'user_cart', 'user_wishlist', 'user_addresses',
            'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
            'order_tracking', 'pharmacy_coupons', 'coupon_usage'
        )
        GROUP BY tablename
        ORDER BY tablename
    ) LOOP
        RAISE NOTICE '  - %: % policies', table_policies.tablename, table_policies.policy_count;
    END LOOP;
END $$;

-- ============================================
-- VERIFICATION 8: Seed Data
-- ============================================

DO $$
DECLARE
    category_count INTEGER;
    subcategory_count INTEGER;
    coupon_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO category_count FROM product_categories;
    SELECT COUNT(*) INTO subcategory_count FROM product_subcategories;
    SELECT COUNT(*) INTO coupon_count FROM pharmacy_coupons;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: SEED DATA ===';
    RAISE NOTICE 'Product Categories: %', category_count;
    RAISE NOTICE 'Product Subcategories: %', subcategory_count;
    RAISE NOTICE 'Pharmacy Coupons: %', coupon_count;

    IF category_count >= 15 AND subcategory_count >= 16 AND coupon_count >= 3 THEN
        RAISE NOTICE '✓ Seed data loaded successfully';
    ELSE
        RAISE WARNING '✗ Seed data incomplete (expected: 15+ categories, 16+ subcategories, 3+ coupons)';
    END IF;
END $$;

-- ============================================
-- VERIFICATION 9: Inventory Sync
-- ============================================

DO $$
DECLARE
    inventory_count INTEGER;
    product_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO inventory_count FROM pharmacy_inventory;
    SELECT COUNT(*) INTO product_count FROM pharmacy_products WHERE product_type = 'medication';

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: INVENTORY SYNC ===';
    RAISE NOTICE 'pharmacy_inventory records: %', inventory_count;
    RAISE NOTICE 'pharmacy_products (medication): %', product_count;

    IF product_count >= inventory_count THEN
        RAISE NOTICE '✓ Inventory migrated successfully';
    ELSE
        RAISE WARNING '✗ Inventory migration incomplete (products: %, inventory: %)', product_count, inventory_count;
    END IF;
END $$;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '   PHARMACY E-COMMERCE VERIFICATION COMPLETE';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Review the output above to ensure all components are installed correctly.';
    RAISE NOTICE '';
    RAISE NOTICE 'Expected Results:';
    RAISE NOTICE '  ✓ 12 tables';
    RAISE NOTICE '  ✓ 12 views';
    RAISE NOTICE '  ✓ 10 functions';
    RAISE NOTICE '  ✓ 10 triggers';
    RAISE NOTICE '  ✓ 50+ indexes';
    RAISE NOTICE '  ✓ RLS enabled on 12 tables';
    RAISE NOTICE '  ✓ 30+ RLS policies';
    RAISE NOTICE '  ✓ Seed data loaded';
    RAISE NOTICE '  ✓ Inventory synced';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Review verification output for any warnings';
    RAISE NOTICE '  2. Test RLS policies with different user roles';
    RAISE NOTICE '  3. Verify inventory sync triggers are working';
    RAISE NOTICE '  4. Create test products and orders';
    RAISE NOTICE '  5. Update CLAUDE.md with new tables';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF MIGRATION: Part 9 Verification
-- ============================================
