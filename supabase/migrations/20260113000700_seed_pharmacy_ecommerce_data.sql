-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 8: Seed Data
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Seed initial data for pharmacy e-commerce
--              - 15 product categories
--              - 16+ product subcategories
--              - 3 test coupons
-- ============================================

-- ============================================
-- SEED: Product Categories (15 categories)
-- ============================================

INSERT INTO product_categories (name, description, image_url, display_order, is_active) VALUES
('Antibiotics', 'Medications that fight bacterial infections', 'https://placehold.co/200x200?text=Antibiotics', 1, true),
('Pain Relief', 'Pain relievers and anti-inflammatory medications', 'https://placehold.co/200x200?text=Pain+Relief', 2, true),
('Vitamins & Supplements', 'Vitamins, minerals, and dietary supplements', 'https://placehold.co/200x200?text=Vitamins', 3, true),
('Cardiovascular', 'Heart and blood pressure medications', 'https://placehold.co/200x200?text=Cardiovascular', 4, true),
('Diabetes', 'Diabetes management medications', 'https://placehold.co/200x200?text=Diabetes', 5, true),
('Skin Care', 'Dermatological products and skin treatments', 'https://placehold.co/200x200?text=Skin+Care', 6, true),
('First Aid', 'First aid supplies and wound care', 'https://placehold.co/200x200?text=First+Aid', 7, true),
('Baby & Child Care', 'Products for infants and children', 'https://placehold.co/200x200?text=Baby+Care', 8, true),
('Personal Care', 'Personal hygiene and care products', 'https://placehold.co/200x200?text=Personal+Care', 9, true),
('Respiratory', 'Cough, cold, and respiratory medications', 'https://placehold.co/200x200?text=Respiratory', 10, true),
('Digestive Health', 'Antacids, laxatives, and digestive aids', 'https://placehold.co/200x200?text=Digestive', 11, true),
('Eye & Ear Care', 'Eye drops, ear drops, and related products', 'https://placehold.co/200x200?text=Eye+Ear', 12, true),
('Women''s Health', 'Women''s health and feminine care products', 'https://placehold.co/200x200?text=Womens+Health', 13, true),
('Men''s Health', 'Men''s health products', 'https://placehold.co/200x200?text=Mens+Health', 14, true),
('Detox & Cleanse', 'Detoxification and cleansing products', 'https://placehold.co/200x200?text=Detox', 15, true)
ON CONFLICT DO NOTHING;

-- Log result
DO $$
DECLARE
    category_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO category_count FROM product_categories;
    RAISE NOTICE '✓ Seeded product categories. Total categories: %', category_count;
END $$;

-- ============================================
-- SEED: Product Subcategories (16+ subcategories)
-- ============================================

WITH categories AS (
    SELECT id, name FROM product_categories
)
INSERT INTO product_subcategories (category_id, name, description, display_order, is_active)
SELECT c.id, sub.name, sub.description, sub.display_order, true
FROM categories c
CROSS JOIN LATERAL (
    VALUES
    -- Antibiotics subcategories
    ('Antibiotics', 'Penicillins', 'Penicillin-based antibiotics', 1),
    ('Antibiotics', 'Cephalosporins', 'Cephalosporin antibiotics', 2),
    ('Antibiotics', 'Macrolides', 'Macrolide antibiotics', 3),
    ('Antibiotics', 'Fluoroquinolones', 'Fluoroquinolone antibiotics', 4),

    -- Pain Relief subcategories
    ('Pain Relief', 'Analgesics', 'Pain relievers', 1),
    ('Pain Relief', 'Anti-inflammatory', 'NSAIDs and anti-inflammatory drugs', 2),
    ('Pain Relief', 'Muscle Relaxants', 'Muscle relaxant medications', 3),

    -- Vitamins & Supplements subcategories
    ('Vitamins & Supplements', 'Multivitamins', 'Complete vitamin formulations', 1),
    ('Vitamins & Supplements', 'Vitamin C', 'Vitamin C supplements', 2),
    ('Vitamins & Supplements', 'Vitamin D', 'Vitamin D supplements', 3),
    ('Vitamins & Supplements', 'Iron Supplements', 'Iron and ferrous supplements', 4),
    ('Vitamins & Supplements', 'Calcium', 'Calcium supplements', 5),

    -- Respiratory subcategories
    ('Respiratory', 'Cough Syrups', 'Cough relief medications', 1),
    ('Respiratory', 'Decongestants', 'Nasal and sinus decongestants', 2),
    ('Respiratory', 'Antihistamines', 'Allergy relief medications', 3),
    ('Respiratory', 'Inhalers', 'Respiratory inhalers', 4)
) AS sub(category_name, name, description, display_order)
WHERE c.name = sub.category_name
ON CONFLICT DO NOTHING;

-- Log result
DO $$
DECLARE
    subcategory_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO subcategory_count FROM product_subcategories;
    RAISE NOTICE '✓ Seeded product subcategories. Total subcategories: %', subcategory_count;
END $$;

-- ============================================
-- SEED: Test Coupons (3 global coupons)
-- Note: pharmacy_id is NULL for global coupons
-- ============================================

INSERT INTO pharmacy_coupons (
    pharmacy_id,  -- NULL = global coupon for all pharmacies
    code,
    description,
    discount_type,
    discount_value,
    min_order_amount,
    max_discount_amount,
    usage_limit,
    per_user_limit,
    valid_from,
    valid_until,
    is_active,
    is_first_order_only
) VALUES
(
    NULL,  -- Global coupon
    'WELCOME10',
    'Welcome discount - 10% off your first order',
    'percentage',
    10,
    5000,
    2000,
    NULL,  -- Unlimited total uses
    1,     -- Once per user
    NOW(),
    NOW() + INTERVAL '1 year',
    true,
    true   -- First order only
),
(
    NULL,  -- Global coupon
    'SAVE500',
    'Flat 500 XAF off orders above 3000 XAF',
    'fixed_amount',
    500,
    3000,
    NULL,
    1000,  -- Limited to 1000 total uses
    3,     -- Up to 3 times per user
    NOW(),
    NOW() + INTERVAL '6 months',
    true,
    false
),
(
    NULL,  -- Global coupon
    'MEDZEN20',
    'Special 20% discount for MedZen users',
    'percentage',
    20,
    10000,
    5000,
    500,   -- Limited to 500 total uses
    1,     -- Once per user
    NOW(),
    NOW() + INTERVAL '3 months',
    true,
    false
)
ON CONFLICT (code) DO NOTHING;

-- Log result
DO $$
DECLARE
    coupon_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO coupon_count FROM pharmacy_coupons;
    RAISE NOTICE '✓ Seeded test coupons. Total coupons: %', coupon_count;
END $$;

-- ============================================
-- VERIFICATION: Show Seeded Data Summary
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
    RAISE NOTICE '=== SEED DATA SUMMARY ===';
    RAISE NOTICE 'Product Categories: %', category_count;
    RAISE NOTICE 'Product Subcategories: %', subcategory_count;
    RAISE NOTICE 'Pharmacy Coupons: %', coupon_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Available coupons:';
    RAISE NOTICE '  - WELCOME10: 10%% off first order (min 5000 XAF)';
    RAISE NOTICE '  - SAVE500: 500 XAF off (min 3000 XAF)';
    RAISE NOTICE '  - MEDZEN20: 20%% off (min 10000 XAF, max 5000 XAF discount)';
END $$;

-- ============================================
-- END OF MIGRATION: Part 8 Seed Data
-- ============================================
