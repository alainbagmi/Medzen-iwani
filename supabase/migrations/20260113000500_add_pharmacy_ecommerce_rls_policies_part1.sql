-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 6: RLS Policies (Part 1 of 2)
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Enable RLS and create policies for pharmacy e-commerce tables
--              All policies converted to MedZen Firebase Auth pattern
--              Part 1: Tables 1-6 of 12
-- CRITICAL: Firebase Auth pattern requires auth.uid() IS NULL checks
-- ============================================

-- ============================================
-- ENABLE RLS ON ALL PHARMACY E-COMMERCE TABLES
-- ============================================

ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usage ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TABLE 1: product_categories
-- Public read, admin manage
-- ============================================

-- Anyone can view active categories
CREATE POLICY "product_categories_select_active"
ON product_categories FOR SELECT
USING (is_active = true);

-- Facility admins can manage all categories
CREATE POLICY "product_categories_admin_all"
ON product_categories FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM facility_admin_profiles fap
        WHERE fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM facility_admin_profiles fap
        WHERE fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- ============================================
-- TABLE 2: product_subcategories
-- Public read, admin manage
-- ============================================

-- Anyone can view active subcategories
CREATE POLICY "product_subcategories_select_active"
ON product_subcategories FOR SELECT
USING (is_active = true);

-- Facility admins can manage all subcategories
CREATE POLICY "product_subcategories_admin_all"
ON product_subcategories FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM facility_admin_profiles fap
        WHERE fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM facility_admin_profiles fap
        WHERE fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- ============================================
-- TABLE 3: pharmacy_products
-- Public read active products, pharmacy admin full access to their products
-- ============================================

-- Anyone can view active products
CREATE POLICY "pharmacy_products_select_active"
ON pharmacy_products FOR SELECT
USING (is_active = true);

-- Pharmacy admins can view all their products (including inactive)
CREATE POLICY "pharmacy_products_select_pharmacy_admin"
ON pharmacy_products FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_products.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_products.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Pharmacy admins can insert products for their pharmacy
CREATE POLICY "pharmacy_products_insert_pharmacy_admin"
ON pharmacy_products FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_products.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_products.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Pharmacy admins can update their products
CREATE POLICY "pharmacy_products_update_pharmacy_admin"
ON pharmacy_products FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_products.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_products.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Pharmacy admins can delete their products
CREATE POLICY "pharmacy_products_delete_pharmacy_admin"
ON pharmacy_products FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_products.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_products.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- ============================================
-- TABLE 4: user_cart
-- Users can only access their own cart
-- ============================================

-- Users can view own cart
CREATE POLICY "user_cart_select_own"
ON user_cart FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can add to own cart
CREATE POLICY "user_cart_insert_own"
ON user_cart FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can update own cart
CREATE POLICY "user_cart_update_own"
ON user_cart FOR UPDATE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can delete from own cart
CREATE POLICY "user_cart_delete_own"
ON user_cart FOR DELETE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- ============================================
-- TABLE 5: user_wishlist
-- Users can only access their own wishlist
-- ============================================

-- Users can view own wishlist
CREATE POLICY "user_wishlist_select_own"
ON user_wishlist FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can add to own wishlist
CREATE POLICY "user_wishlist_insert_own"
ON user_wishlist FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can delete from own wishlist
CREATE POLICY "user_wishlist_delete_own"
ON user_wishlist FOR DELETE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- ============================================
-- TABLE 6: user_addresses
-- Users can only access their own addresses
-- ============================================

-- Users can view own addresses
CREATE POLICY "user_addresses_select_own"
ON user_addresses FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can add own addresses
CREATE POLICY "user_addresses_insert_own"
ON user_addresses FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can update own addresses
CREATE POLICY "user_addresses_update_own"
ON user_addresses FOR UPDATE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can delete own addresses
CREATE POLICY "user_addresses_delete_own"
ON user_addresses FOR DELETE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- ============================================
-- END OF MIGRATION: Part 6 RLS Policies (Part 1 of 2)
-- Tables 1-6 of 12
-- ============================================
