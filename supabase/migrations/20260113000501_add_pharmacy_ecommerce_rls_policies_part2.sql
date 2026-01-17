-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 6: RLS Policies (Part 2 of 2)
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: RLS policies for pharmacy e-commerce tables
--              Part 2: Tables 7-12 of 12
-- CRITICAL: Firebase Auth pattern with auth.uid() checks
-- ============================================

-- ============================================
-- TABLE 7: pharmacy_orders
-- Users can view own orders, pharmacy admins can view/manage their pharmacy's orders
-- ============================================

-- Users can see their own orders
CREATE POLICY "pharmacy_orders_select_own"
ON pharmacy_orders FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Pharmacy admins can see orders for their pharmacy
CREATE POLICY "pharmacy_orders_select_pharmacy_admin"
ON pharmacy_orders FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_orders.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_orders.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Users can create orders (for themselves)
CREATE POLICY "pharmacy_orders_insert_own"
ON pharmacy_orders FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can update their own pending orders (cancel)
CREATE POLICY "pharmacy_orders_update_own_pending"
ON pharmacy_orders FOR UPDATE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
    AND status IN ('pending', 'confirmed')
);

-- Pharmacy admins can update order status
CREATE POLICY "pharmacy_orders_update_pharmacy_admin"
ON pharmacy_orders FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_orders.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_orders.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- ============================================
-- TABLE 8: pharmacy_order_items
-- Users can view items of their own orders, pharmacy admins can view their pharmacy's order items
-- ============================================

-- Users can see items of their own orders
CREATE POLICY "pharmacy_order_items_select_own"
ON pharmacy_order_items FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM pharmacy_orders o
        WHERE o.id = pharmacy_order_items.order_id
        AND o.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
    )
);

-- Pharmacy admins can see items of their pharmacy's orders
CREATE POLICY "pharmacy_order_items_select_pharmacy_admin"
ON pharmacy_order_items FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM pharmacy_orders o
        JOIN pharmacies p ON o.pharmacy_id = p.id
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR o.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE o.id = pharmacy_order_items.order_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Users can insert order items (via order creation)
CREATE POLICY "pharmacy_order_items_insert_own"
ON pharmacy_order_items FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM pharmacy_orders o
        WHERE o.id = pharmacy_order_items.order_id
        AND o.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
    )
);

-- ============================================
-- TABLE 9: product_reviews
-- Anyone can see approved reviews, users can manage their own reviews
-- ============================================

-- Anyone can see approved reviews
CREATE POLICY "product_reviews_select_approved"
ON product_reviews FOR SELECT
USING (is_approved = true);

-- Users can see their own reviews (even unapproved)
CREATE POLICY "product_reviews_select_own"
ON product_reviews FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Authenticated users can add reviews
CREATE POLICY "product_reviews_insert_authenticated"
ON product_reviews FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can update their own reviews
CREATE POLICY "product_reviews_update_own"
ON product_reviews FOR UPDATE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- Users can delete their own reviews
CREATE POLICY "product_reviews_delete_own"
ON product_reviews FOR DELETE
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- ============================================
-- TABLE 10: order_tracking
-- Users can view tracking for their orders, pharmacy admins can manage tracking
-- ============================================

-- Users can see tracking for their orders
CREATE POLICY "order_tracking_select_own_orders"
ON order_tracking FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM pharmacy_orders o
        WHERE o.id = order_tracking.order_id
        AND o.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
    )
);

-- Pharmacy admins can see and add tracking for their pharmacy's orders
CREATE POLICY "order_tracking_pharmacy_admin_all"
ON order_tracking FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM pharmacy_orders o
        JOIN pharmacies p ON o.pharmacy_id = p.id
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR o.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE o.id = order_tracking.order_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM pharmacy_orders o
        JOIN pharmacies p ON o.pharmacy_id = p.id
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR o.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE o.id = order_tracking.order_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- ============================================
-- TABLE 11: pharmacy_coupons
-- Anyone can see active coupons, pharmacy admins can manage their coupons
-- ============================================

-- Anyone can see active coupons (for validation)
CREATE POLICY "pharmacy_coupons_select_active"
ON pharmacy_coupons FOR SELECT
USING (
    is_active = true
    AND (valid_from IS NULL OR valid_from <= NOW())
    AND (valid_until IS NULL OR valid_until >= NOW())
);

-- Pharmacy admins can view all their coupons
CREATE POLICY "pharmacy_coupons_select_pharmacy_admin"
ON pharmacy_coupons FOR SELECT
USING (
    pharmacy_id IS NULL  -- Global coupons
    OR
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_coupons.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_coupons.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Pharmacy admins can create coupons for their pharmacy
CREATE POLICY "pharmacy_coupons_insert_pharmacy_admin"
ON pharmacy_coupons FOR INSERT
WITH CHECK (
    pharmacy_id IS NULL  -- System admins can create global coupons
    OR
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_coupons.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_coupons.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Pharmacy admins can update their coupons
CREATE POLICY "pharmacy_coupons_update_pharmacy_admin"
ON pharmacy_coupons FOR UPDATE
USING (
    pharmacy_id IS NULL
    OR
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_coupons.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_coupons.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- Pharmacy admins can delete their coupons
CREATE POLICY "pharmacy_coupons_delete_pharmacy_admin"
ON pharmacy_coupons FOR DELETE
USING (
    pharmacy_id IS NULL
    OR
    EXISTS (
        SELECT 1 FROM pharmacies p
        JOIN facility_admin_profiles fap ON (
            p.manager_id = fap.user_id
            OR pharmacy_coupons.pharmacy_id = ANY(fap.managed_facilities)
        )
        WHERE p.id = pharmacy_coupons.pharmacy_id
        AND fap.user_id IN (
            SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
        )
        AND fap.application_status = 'approved'
    )
);

-- ============================================
-- TABLE 12: coupon_usage
-- Users can view their own coupon usage, system can track usage
-- ============================================

-- Users can see their own coupon usage
CREATE POLICY "coupon_usage_select_own"
ON coupon_usage FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- System can insert coupon usage records
CREATE POLICY "coupon_usage_insert_authenticated"
ON coupon_usage FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
    )
);

-- ============================================
-- GRANT PERMISSIONS TO SERVICE ROLE
-- Service role needs full access for backend operations
-- ============================================

GRANT ALL ON product_categories TO service_role;
GRANT ALL ON product_subcategories TO service_role;
GRANT ALL ON pharmacy_products TO service_role;
GRANT ALL ON user_cart TO service_role;
GRANT ALL ON user_wishlist TO service_role;
GRANT ALL ON user_addresses TO service_role;
GRANT ALL ON pharmacy_orders TO service_role;
GRANT ALL ON pharmacy_order_items TO service_role;
GRANT ALL ON product_reviews TO service_role;
GRANT ALL ON order_tracking TO service_role;
GRANT ALL ON pharmacy_coupons TO service_role;
GRANT ALL ON coupon_usage TO service_role;

-- ============================================
-- END OF MIGRATION: Part 6 RLS Policies (Part 2 of 2)
-- Tables 7-12 of 12
-- Total RLS Policies Created: 30+
-- ============================================
