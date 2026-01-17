-- Verify pharmacy e-commerce tables exist
SELECT
    table_name,
    CASE
        WHEN table_name IN (
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
        ) THEN '✓ Found'
        ELSE 'Extra table'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name LIKE '%product%'
    OR table_name LIKE '%cart%'
    OR table_name LIKE '%wishlist%'
    OR table_name LIKE '%coupon%'
    OR table_name = 'user_addresses'
    OR table_name = 'pharmacy_orders'
    OR table_name = 'pharmacy_order_items'
    OR table_name = 'order_tracking'
ORDER BY table_name;
