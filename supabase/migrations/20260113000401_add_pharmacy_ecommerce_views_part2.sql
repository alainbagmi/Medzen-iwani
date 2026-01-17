-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 5: Views (Part 2 of 2)
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Creates database views for pharmacy e-commerce module
--              Views 7-12 of 12
-- MODIFICATIONS: All views use pharmacy_id and include medication joins
-- ============================================

-- ============================================
-- VIEW 7: v_pharmacy_inventory
-- Purpose: Inventory management view for pharmacy admins
-- ============================================

CREATE OR REPLACE VIEW v_pharmacy_inventory AS
SELECT
    p.id,
    p.pharmacy_id,
    p.medication_id,
    p.product_code,
    p.sku,
    p.name,
    p.generic_name,
    p.dosage_strength,
    p.dosage_form,
    p.manufacturer,
    p.batch_number,
    p.expiry_date,
    p.price,
    p.quantity_in_stock,
    p.reorder_level,
    p.max_stock_level,
    p.total_sold,
    p.is_active,

    -- Category
    c.name AS category_name,

    -- Stock Status
    CASE
        WHEN p.quantity_in_stock <= 0 THEN 'OUT_OF_STOCK'
        WHEN p.quantity_in_stock <= p.reorder_level THEN 'LOW_STOCK'
        WHEN p.quantity_in_stock >= p.max_stock_level THEN 'OVERSTOCKED'
        ELSE 'NORMAL'
    END AS stock_status,

    -- Expiry Status
    CASE
        WHEN p.expiry_date IS NULL THEN 'NO_EXPIRY'
        WHEN p.expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN p.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        WHEN p.expiry_date < CURRENT_DATE + INTERVAL '90 days' THEN 'EXPIRING_3_MONTHS'
        ELSE 'OK'
    END AS expiry_status,

    -- Days until expiry
    CASE
        WHEN p.expiry_date IS NOT NULL THEN p.expiry_date - CURRENT_DATE
        ELSE NULL
    END AS days_until_expiry,

    -- Stock value
    p.price * p.quantity_in_stock AS stock_value,

    p.created_at,
    p.updated_at

FROM pharmacy_products p
LEFT JOIN product_categories c ON p.category_id = c.id;

COMMENT ON VIEW v_pharmacy_inventory IS 'Inventory management view for pharmacy admins with stock and expiry status';

-- ============================================
-- VIEW 8: v_pharmacy_dashboard_stats
-- Purpose: Dashboard statistics per pharmacy
-- ============================================

CREATE OR REPLACE VIEW v_pharmacy_dashboard_stats AS
SELECT
    ph.id AS pharmacy_id,
    ph.name AS pharmacy_name,

    -- Product Stats
    (SELECT COUNT(*) FROM pharmacy_products WHERE pharmacy_id = ph.id AND is_active = true) AS total_products,
    (SELECT COUNT(*) FROM pharmacy_products WHERE pharmacy_id = ph.id AND is_active = true AND quantity_in_stock <= 0) AS out_of_stock_count,
    (SELECT COUNT(*) FROM pharmacy_products WHERE pharmacy_id = ph.id AND is_active = true AND quantity_in_stock <= reorder_level AND quantity_in_stock > 0) AS low_stock_count,
    (SELECT COUNT(*) FROM pharmacy_products WHERE pharmacy_id = ph.id AND is_active = true AND expiry_date < CURRENT_DATE) AS expired_count,
    (SELECT COUNT(*) FROM pharmacy_products WHERE pharmacy_id = ph.id AND is_active = true AND expiry_date < CURRENT_DATE + INTERVAL '30 days' AND expiry_date >= CURRENT_DATE) AS expiring_soon_count,

    -- Order Stats (Today)
    (SELECT COUNT(*) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND DATE(ordered_at) = CURRENT_DATE) AS orders_today,
    (SELECT COALESCE(SUM(total_amount), 0) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND DATE(ordered_at) = CURRENT_DATE AND payment_status = 'paid') AS revenue_today,

    -- Order Stats (This Month)
    (SELECT COUNT(*) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND DATE_TRUNC('month', ordered_at) = DATE_TRUNC('month', CURRENT_DATE)) AS orders_this_month,
    (SELECT COALESCE(SUM(total_amount), 0) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND DATE_TRUNC('month', ordered_at) = DATE_TRUNC('month', CURRENT_DATE) AND payment_status = 'paid') AS revenue_this_month,

    -- Pending Orders
    (SELECT COUNT(*) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND status = 'pending') AS pending_orders,
    (SELECT COUNT(*) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND status = 'processing') AS processing_orders,

    -- Total Stats
    (SELECT COUNT(*) FROM pharmacy_orders WHERE pharmacy_id = ph.id) AS total_orders,
    (SELECT COALESCE(SUM(total_amount), 0) FROM pharmacy_orders WHERE pharmacy_id = ph.id AND payment_status = 'paid') AS total_revenue,

    -- Inventory Value
    (SELECT COALESCE(SUM(price * quantity_in_stock), 0) FROM pharmacy_products WHERE pharmacy_id = ph.id AND is_active = true) AS total_inventory_value

FROM pharmacies ph;

COMMENT ON VIEW v_pharmacy_dashboard_stats IS 'Dashboard statistics for pharmacy admins including sales, inventory, and orders';

-- ============================================
-- VIEW 9: v_category_product_counts
-- Purpose: Categories with product counts per pharmacy
-- ============================================

CREATE OR REPLACE VIEW v_category_product_counts AS
SELECT
    c.id AS category_id,
    c.name AS category_name,
    c.image_url AS category_image,
    c.display_order,
    c.is_active,
    p.pharmacy_id,
    COUNT(p.id) AS product_count,
    COUNT(p.id) FILTER (WHERE p.quantity_in_stock > 0) AS in_stock_count

FROM product_categories c
LEFT JOIN pharmacy_products p ON p.category_id = c.id AND p.is_active = true
WHERE c.is_active = true
GROUP BY c.id, c.name, c.image_url, c.display_order, c.is_active, p.pharmacy_id
ORDER BY c.display_order;

COMMENT ON VIEW v_category_product_counts IS 'Categories with product counts per pharmacy';

-- ============================================
-- VIEW 10: v_user_order_history
-- Purpose: User order history with summary
-- ============================================

CREATE OR REPLACE VIEW v_user_order_history AS
SELECT
    o.id,
    o.order_number,
    o.user_id,
    o.status,
    o.payment_status,
    o.total_amount,
    o.currency,
    o.ordered_at,
    o.delivered_at,

    -- Pharmacy
    ph.name AS pharmacy_name,
    ph.city AS pharmacy_city,

    -- Item summary
    (SELECT COUNT(*) FROM pharmacy_order_items WHERE order_id = o.id) AS item_count,
    (SELECT SUM(quantity) FROM pharmacy_order_items WHERE order_id = o.id) AS total_quantity,

    -- First few product images
    (
        SELECT ARRAY_AGG(product_image)
        FROM (
            SELECT product_image FROM pharmacy_order_items
            WHERE order_id = o.id AND product_image IS NOT NULL
            LIMIT 3
        ) images
    ) AS preview_images,

    -- Can be reviewed (delivered and not yet reviewed all items)
    CASE
        WHEN o.status = 'delivered' THEN true
        ELSE false
    END AS can_review,

    -- Can be cancelled
    CASE
        WHEN o.status IN ('pending', 'confirmed') THEN true
        ELSE false
    END AS can_cancel,

    -- Can be reordered
    true AS can_reorder

FROM pharmacy_orders o
LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.id
ORDER BY o.ordered_at DESC;

COMMENT ON VIEW v_user_order_history IS 'User order history with summary and action flags';

-- ============================================
-- VIEW 11: v_pharmacy_inventory_dashboard
-- Purpose: SINGLE VIEW with both stats AND drug details for inventory page
-- Use: One query for entire inventory page
-- ============================================

CREATE OR REPLACE VIEW v_pharmacy_inventory_dashboard AS
SELECT
    -- FACILITY INFO
    ph.id AS pharmacy_id,
    ph.name AS pharmacy_name,
    ph.license_number AS pharmacy_license,
    ph.email AS pharmacy_email,
    ph.phone_number AS pharmacy_phone,
    ph.address AS pharmacy_address,
    ph.city AS pharmacy_city,
    ph.lat AS pharmacy_latitude,
    ph.lng AS pharmacy_longitude,

    -- DASHBOARD STATS (same value on every row per pharmacy)
    (SELECT COUNT(*) FROM pharmacy_products pp WHERE pp.pharmacy_id = ph.id AND pp.is_active = true) AS stat_total_drugs,
    (SELECT COUNT(*) FROM pharmacy_products pp WHERE pp.pharmacy_id = ph.id AND pp.is_active = true AND pp.quantity_in_stock > 0 AND pp.quantity_in_stock <= pp.reorder_level) AS stat_low_stock,
    (SELECT COUNT(*) FROM pharmacy_products pp WHERE pp.pharmacy_id = ph.id AND pp.is_active = true AND pp.quantity_in_stock <= 0) AS stat_out_of_stock,
    (SELECT COUNT(*) FROM pharmacy_products pp WHERE pp.pharmacy_id = ph.id AND pp.is_active = true AND pp.expiry_date IS NOT NULL AND pp.expiry_date >= CURRENT_DATE AND pp.expiry_date <= CURRENT_DATE + INTERVAL '30 days') AS stat_expiring,
    (SELECT COUNT(*) FROM pharmacy_products pp WHERE pp.pharmacy_id = ph.id AND pp.is_active = true AND pp.expiry_date IS NOT NULL AND pp.expiry_date < CURRENT_DATE) AS stat_expired,
    (SELECT COALESCE(SUM(pp.price * pp.quantity_in_stock), 0) FROM pharmacy_products pp WHERE pp.pharmacy_id = ph.id AND pp.is_active = true) AS stat_inventory_value,

    -- DRUG INFO
    p.id AS product_id,
    p.product_code,
    p.sku,
    p.barcode,
    p.name,
    p.generic_name,
    p.description,
    p.images,
    p.thumbnail_url,
    CASE WHEN p.images IS NOT NULL AND array_length(p.images, 1) > 0 THEN p.images[1] ELSE p.thumbnail_url END AS primary_image,
    p.dosage_strength,
    p.dosage_form,
    TRIM(CONCAT(COALESCE(p.dosage_strength, ''), CASE WHEN p.dosage_strength IS NOT NULL AND p.dosage_form IS NOT NULL THEN ' ' ELSE '' END, COALESCE(p.dosage_form, ''))) AS dosage_display,

    -- CATEGORY
    p.category_id,
    c.name AS category_name,
    c.image_url AS category_image,

    -- SUBCATEGORY
    p.subcategory_id,
    sc.name AS subcategory_name,

    -- PRICING
    p.price,
    p.sale_price,
    p.is_on_sale,
    p.sale_percent,
    CASE WHEN p.is_on_sale AND p.sale_price IS NOT NULL THEN p.sale_price ELSE p.price END AS effective_price,

    -- STOCK
    p.quantity_in_stock,
    p.reorder_level,
    p.max_stock_level,
    CASE WHEN p.quantity_in_stock <= 0 THEN 'OUT_OF_STOCK' WHEN p.quantity_in_stock <= p.reorder_level THEN 'LOW_STOCK' ELSE 'IN_STOCK' END AS stock_status,
    CASE WHEN p.quantity_in_stock <= 0 THEN 'Out of Stock' WHEN p.quantity_in_stock <= p.reorder_level THEN 'Low Stock' ELSE 'In Stock' END AS stock_status_display,
    CASE WHEN p.quantity_in_stock <= 0 THEN 'red' WHEN p.quantity_in_stock <= p.reorder_level THEN 'orange' ELSE 'green' END AS stock_status_color,

    -- EXPIRY
    p.expiry_date,
    p.manufacturing_date,
    p.batch_number,
    CASE WHEN p.expiry_date IS NOT NULL THEN TO_CHAR(p.expiry_date, 'MM/YYYY') ELSE NULL END AS expiry_display,
    CASE WHEN p.expiry_date IS NOT NULL THEN (p.expiry_date - CURRENT_DATE) ELSE NULL END AS days_until_expiry,
    CASE WHEN p.expiry_date IS NULL THEN 'NO_EXPIRY' WHEN p.expiry_date < CURRENT_DATE THEN 'EXPIRED' WHEN p.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON' ELSE 'OK' END AS expiry_status,
    CASE WHEN p.expiry_date IS NULL THEN 'N/A' WHEN p.expiry_date < CURRENT_DATE THEN 'Expired' WHEN p.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'Expiring Soon' ELSE 'Valid' END AS expiry_status_display,
    CASE WHEN p.expiry_date IS NULL THEN 'gray' WHEN p.expiry_date < CURRENT_DATE THEN 'red' WHEN p.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'orange' ELSE 'green' END AS expiry_status_color,

    -- OTHER
    p.manufacturer,
    p.brand,
    p.requires_prescription,
    p.controlled_substance,
    p.is_active,
    p.is_featured,
    p.is_trending,
    p.is_new_arrival,
    p.total_sold,
    p.view_count,
    p.average_rating,
    p.total_reviews,
    (p.price * p.quantity_in_stock) AS drug_stock_value,
    p.created_at,
    p.updated_at

FROM pharmacies ph
INNER JOIN pharmacy_products p ON p.pharmacy_id = ph.id
LEFT JOIN product_categories c ON p.category_id = c.id
LEFT JOIN product_subcategories sc ON p.subcategory_id = sc.id
WHERE p.is_active = true
ORDER BY p.created_at DESC;

COMMENT ON VIEW v_pharmacy_inventory_dashboard IS 'Combined view with pharmacy info, dashboard stats, AND drug details for inventory page';

-- ============================================
-- VIEW 12: v_pharmacy_inventory_full
-- Purpose: Full inventory view with all relationships
-- ============================================

CREATE OR REPLACE VIEW v_pharmacy_inventory_full AS
SELECT
    p.*,

    -- Category
    c.name AS category_name,
    c.image_url AS category_image,

    -- Subcategory
    sc.name AS subcategory_name,

    -- Pharmacy
    ph.name AS pharmacy_name,
    ph.license_number AS pharmacy_license,
    ph.address AS pharmacy_address,
    ph.city AS pharmacy_city,

    -- Calculated
    CASE
        WHEN p.quantity_in_stock <= 0 THEN 'OUT_OF_STOCK'
        WHEN p.quantity_in_stock <= p.reorder_level THEN 'LOW_STOCK'
        ELSE 'IN_STOCK'
    END AS stock_status,

    CASE
        WHEN p.expiry_date IS NULL THEN 'NO_EXPIRY'
        WHEN p.expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN p.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        ELSE 'OK'
    END AS expiry_status,

    (p.price * p.quantity_in_stock) AS stock_value

FROM pharmacy_products p
LEFT JOIN product_categories c ON p.category_id = c.id
LEFT JOIN product_subcategories sc ON p.subcategory_id = sc.id
LEFT JOIN pharmacies ph ON p.pharmacy_id = ph.id;

COMMENT ON VIEW v_pharmacy_inventory_full IS 'Full inventory view with all relationships and calculated fields';

-- ============================================
-- END OF MIGRATION: Part 5 Views (Part 2 of 2)
-- Views 7-12 of 12
-- Total Views Created: 12
-- ============================================
