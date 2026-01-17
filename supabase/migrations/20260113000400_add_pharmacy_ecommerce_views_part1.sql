-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 5: Views (Part 1 of 2)
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Creates database views for pharmacy e-commerce module
--              Views 1-6 of 12
-- MODIFICATIONS: All views use pharmacy_id and include medication joins
-- ============================================

-- ============================================
-- VIEW 1: v_pharmacy_products_full
-- Purpose: Product details with category, pharmacy, and medication info
-- ============================================

CREATE OR REPLACE VIEW v_pharmacy_products_full AS
SELECT
    p.id,
    p.pharmacy_id,
    p.medication_id,
    p.product_type,
    p.product_code,
    p.sku,
    p.name,
    p.generic_name,
    p.description,
    p.information,
    p.price,
    p.sale_price,
    p.is_on_sale,
    p.sale_percent,
    p.images,
    p.thumbnail_url,
    p.quantity_in_stock,
    p.reorder_level,
    p.dosage_strength,
    p.dosage_form,
    p.requires_prescription,
    p.manufacturer,
    p.brand,
    p.expiry_date,
    p.is_active,
    p.is_featured,
    p.is_trending,
    p.is_recommended,
    p.is_big_saving,
    p.is_new_arrival,
    p.average_rating,
    p.total_reviews,
    p.total_sold,
    p.created_at,
    p.updated_at,

    -- Category Info
    c.id AS category_id,
    c.name AS category_name,
    c.image_url AS category_image,

    -- Subcategory Info
    sc.id AS subcategory_id,
    sc.name AS subcategory_name,

    -- Pharmacy Info (MODIFIED: uses pharmacies table)
    ph.name AS pharmacy_name,
    ph.license_number AS pharmacy_license,
    ph.phone_number AS pharmacy_phone,
    ph.email AS pharmacy_email,
    ph.address AS pharmacy_address,
    ph.city AS pharmacy_city,
    ph.lat AS pharmacy_latitude,
    ph.lng AS pharmacy_longitude,
    ph.is_24_hours AS pharmacy_is_24_hours,

    -- Medication Info (NEW: join with medications table)
    m.generic_name AS medication_generic_name,
    m.brand_name AS medication_brand_name,
    m.drug_class AS medication_drug_class,
    m.requires_prescription AS medication_requires_prescription,

    -- Calculated fields
    CASE
        WHEN p.is_on_sale AND p.sale_price IS NOT NULL THEN p.sale_price
        ELSE p.price
    END AS effective_price,

    CASE
        WHEN p.quantity_in_stock <= 0 THEN 'out_of_stock'
        WHEN p.quantity_in_stock <= p.reorder_level THEN 'low_stock'
        ELSE 'in_stock'
    END AS stock_status

FROM pharmacy_products p
LEFT JOIN product_categories c ON p.category_id = c.id
LEFT JOIN product_subcategories sc ON p.subcategory_id = sc.id
LEFT JOIN pharmacies ph ON p.pharmacy_id = ph.id
LEFT JOIN medications m ON p.medication_id = m.id
WHERE p.is_active = true;

COMMENT ON VIEW v_pharmacy_products_full IS 'Full product details with category, pharmacy, and medication information';

-- ============================================
-- VIEW 2: v_user_cart_details
-- Purpose: Cart items with full product details
-- ============================================

CREATE OR REPLACE VIEW v_user_cart_details AS
SELECT
    uc.id AS cart_item_id,
    uc.user_id,
    uc.product_id,
    uc.quantity,
    uc.added_at,
    uc.updated_at,

    -- Product Info
    p.name AS product_name,
    p.generic_name,
    p.description,
    p.price AS unit_price,
    p.sale_price,
    p.is_on_sale,
    p.sale_percent,
    p.images,
    p.thumbnail_url,
    p.sku,
    p.requires_prescription,
    p.quantity_in_stock,

    -- Pharmacy Info
    p.pharmacy_id,
    ph.name AS pharmacy_name,
    ph.city AS pharmacy_city,

    -- Category
    c.name AS category_name,

    -- Calculated fields
    CASE
        WHEN p.is_on_sale AND p.sale_price IS NOT NULL THEN p.sale_price
        ELSE p.price
    END AS effective_unit_price,

    CASE
        WHEN p.is_on_sale AND p.sale_price IS NOT NULL THEN p.sale_price * uc.quantity
        ELSE p.price * uc.quantity
    END AS line_total,

    -- Stock status
    CASE
        WHEN p.quantity_in_stock <= 0 THEN 'out_of_stock'
        WHEN p.quantity_in_stock < uc.quantity THEN 'insufficient_stock'
        ELSE 'available'
    END AS availability_status

FROM user_cart uc
JOIN pharmacy_products p ON uc.product_id = p.id
LEFT JOIN pharmacies ph ON p.pharmacy_id = ph.id
LEFT JOIN product_categories c ON p.category_id = c.id
WHERE p.is_active = true;

COMMENT ON VIEW v_user_cart_details IS 'User cart items with full product details and availability status';

-- ============================================
-- VIEW 3: v_user_wishlist_details
-- Purpose: Wishlist items with product details
-- ============================================

CREATE OR REPLACE VIEW v_user_wishlist_details AS
SELECT
    uw.id AS wishlist_item_id,
    uw.user_id,
    uw.product_id,
    uw.added_at,

    -- Product Info
    p.name AS product_name,
    p.generic_name,
    p.description,
    p.price,
    p.sale_price,
    p.is_on_sale,
    p.sale_percent,
    p.images,
    p.thumbnail_url,
    p.average_rating,
    p.total_reviews,
    p.requires_prescription,
    p.quantity_in_stock,

    -- Pharmacy Info
    p.pharmacy_id,
    ph.name AS pharmacy_name,

    -- Category
    c.name AS category_name,

    -- Calculated
    CASE
        WHEN p.is_on_sale AND p.sale_price IS NOT NULL THEN p.sale_price
        ELSE p.price
    END AS effective_price,

    p.quantity_in_stock > 0 AS is_in_stock

FROM user_wishlist uw
JOIN pharmacy_products p ON uw.product_id = p.id
LEFT JOIN pharmacies ph ON p.pharmacy_id = ph.id
LEFT JOIN product_categories c ON p.category_id = c.id
WHERE p.is_active = true;

COMMENT ON VIEW v_user_wishlist_details IS 'User wishlist with full product details and stock status';

-- ============================================
-- VIEW 4: v_order_summary
-- Purpose: Order summary with item counts and pharmacy info
-- ============================================

CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.id,
    o.order_number,
    o.user_id,
    o.pharmacy_id,
    o.status,
    o.payment_status,
    o.payment_method,
    o.subtotal,
    o.discount_amount,
    o.shipping_fee,
    o.total_amount,
    o.currency,
    o.coupon_code,
    o.requires_prescription,
    o.delivery_method,
    o.customer_notes,
    o.ordered_at,
    o.confirmed_at,
    o.shipped_at,
    o.delivered_at,
    o.cancelled_at,

    -- Pharmacy Info
    ph.name AS pharmacy_name,
    ph.phone_number AS pharmacy_phone,
    ph.address AS pharmacy_address,
    ph.city AS pharmacy_city,

    -- Shipping Address
    o.shipping_address_snapshot,

    -- Item counts
    (SELECT COUNT(*) FROM pharmacy_order_items WHERE order_id = o.id) AS total_items,
    (SELECT SUM(quantity) FROM pharmacy_order_items WHERE order_id = o.id) AS total_quantity,

    -- First product image for display
    (SELECT product_image FROM pharmacy_order_items WHERE order_id = o.id LIMIT 1) AS preview_image

FROM pharmacy_orders o
LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.id;

COMMENT ON VIEW v_order_summary IS 'Order summary with item counts and pharmacy information';

-- ============================================
-- VIEW 5: v_order_details_full
-- Purpose: Complete order with all items and tracking as JSON
-- ============================================

CREATE OR REPLACE VIEW v_order_details_full AS
SELECT
    o.id AS order_id,
    o.order_number,
    o.user_id,
    o.status,
    o.payment_status,
    o.payment_method,
    o.subtotal,
    o.discount_amount,
    o.shipping_fee,
    o.total_amount,
    o.ordered_at,
    o.shipping_address_snapshot,

    -- Pharmacy
    o.pharmacy_id,
    ph.name AS pharmacy_name,
    ph.phone_number AS pharmacy_phone,
    ph.address AS pharmacy_address,

    -- Order Items (as JSON array)
    (
        SELECT json_agg(json_build_object(
            'id', oi.id,
            'product_id', oi.product_id,
            'product_name', oi.product_name,
            'product_image', oi.product_image,
            'unit_price', oi.unit_price,
            'quantity', oi.quantity,
            'line_total', oi.line_total,
            'requires_prescription', oi.requires_prescription
        ))
        FROM pharmacy_order_items oi
        WHERE oi.order_id = o.id
    ) AS items,

    -- Tracking (as JSON array)
    (
        SELECT json_agg(json_build_object(
            'status', t.status,
            'title', t.title,
            'description', t.description,
            'location', t.location,
            'tracked_at', t.tracked_at
        ) ORDER BY t.tracked_at DESC)
        FROM order_tracking t
        WHERE t.order_id = o.id
    ) AS tracking_history

FROM pharmacy_orders o
LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.id;

COMMENT ON VIEW v_order_details_full IS 'Complete order details with items and tracking as JSON';

-- ============================================
-- VIEW 6: v_product_with_reviews
-- Purpose: Product details with recent reviews
-- ============================================

CREATE OR REPLACE VIEW v_product_with_reviews AS
SELECT
    p.id,
    p.name,
    p.description,
    p.price,
    p.sale_price,
    p.is_on_sale,
    p.images,
    p.average_rating,
    p.total_reviews,
    p.pharmacy_id,

    -- Latest reviews (as JSON array)
    (
        SELECT json_agg(json_build_object(
            'id', r.id,
            'rating', r.rating,
            'title', r.title,
            'review_text', r.review_text,
            'reviewer_name', r.reviewer_name,
            'reviewer_image', r.reviewer_image,
            'is_verified_purchase', r.is_verified_purchase,
            'created_at', r.created_at
        ) ORDER BY r.created_at DESC)
        FROM (
            SELECT * FROM product_reviews
            WHERE product_id = p.id AND is_approved = true
            LIMIT 10
        ) r
    ) AS recent_reviews,

    -- Rating distribution
    (
        SELECT json_build_object(
            '5', COUNT(*) FILTER (WHERE rating = 5),
            '4', COUNT(*) FILTER (WHERE rating = 4),
            '3', COUNT(*) FILTER (WHERE rating = 3),
            '2', COUNT(*) FILTER (WHERE rating = 2),
            '1', COUNT(*) FILTER (WHERE rating = 1)
        )
        FROM product_reviews
        WHERE product_id = p.id AND is_approved = true
    ) AS rating_distribution

FROM pharmacy_products p
WHERE p.is_active = true;

COMMENT ON VIEW v_product_with_reviews IS 'Product details with recent reviews and rating distribution';

-- ============================================
-- END OF MIGRATION: Part 5 Views (Part 1 of 2)
-- Views 1-6 of 12
-- ============================================
