-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 3: Indexes
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Creates indexes for all pharmacy e-commerce tables
--              Optimizes queries for:
--              - Product search and filtering
--              - Cart and wishlist operations
--              - Order management
--              - Reviews and ratings
--              - Tracking
-- Total Indexes: 50+
-- ============================================

-- ============================================
-- INDEXES: product_categories
-- ============================================

CREATE INDEX IF NOT EXISTS idx_product_categories_order
    ON product_categories(display_order);

CREATE INDEX IF NOT EXISTS idx_product_categories_active
    ON product_categories(is_active)
    WHERE is_active = true;

COMMENT ON INDEX idx_product_categories_order IS 'Optimize category sorting by display_order';
COMMENT ON INDEX idx_product_categories_active IS 'Optimize filtering of active categories';

-- ============================================
-- INDEXES: product_subcategories
-- ============================================

CREATE INDEX IF NOT EXISTS idx_product_subcategories_category
    ON product_subcategories(category_id);

CREATE INDEX IF NOT EXISTS idx_product_subcategories_active
    ON product_subcategories(is_active)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_product_subcategories_category_order
    ON product_subcategories(category_id, display_order);

COMMENT ON INDEX idx_product_subcategories_category IS 'Optimize subcategory lookup by parent category';
COMMENT ON INDEX idx_product_subcategories_active IS 'Optimize filtering of active subcategories';
COMMENT ON INDEX idx_product_subcategories_category_order IS 'Optimize subcategory sorting within category';

-- ============================================
-- INDEXES: pharmacy_products (MOST IMPORTANT - HEAVILY QUERIED)
-- ============================================

-- Foreign keys
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_pharmacy
    ON pharmacy_products(pharmacy_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_medication
    ON pharmacy_products(medication_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_category
    ON pharmacy_products(category_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_subcategory
    ON pharmacy_products(subcategory_id);

-- Status and display flags
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_active
    ON pharmacy_products(is_active)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_featured
    ON pharmacy_products(is_featured)
    WHERE is_featured = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_trending
    ON pharmacy_products(is_trending)
    WHERE is_trending = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_recommended
    ON pharmacy_products(is_recommended)
    WHERE is_recommended = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_big_saving
    ON pharmacy_products(is_big_saving)
    WHERE is_big_saving = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_new_arrival
    ON pharmacy_products(is_new_arrival)
    WHERE is_new_arrival = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_on_sale
    ON pharmacy_products(is_on_sale)
    WHERE is_on_sale = true;

-- Product type
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_type
    ON pharmacy_products(product_type);

-- Pricing
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_price
    ON pharmacy_products(price);

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_effective_price
    ON pharmacy_products((CASE WHEN is_on_sale AND sale_price IS NOT NULL THEN sale_price ELSE price END));

-- Name (for sorting)
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_name
    ON pharmacy_products(name);

-- Stock
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_in_stock
    ON pharmacy_products(quantity_in_stock)
    WHERE quantity_in_stock > 0;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_low_stock
    ON pharmacy_products(pharmacy_id, reorder_level, quantity_in_stock)
    WHERE quantity_in_stock > 0 AND quantity_in_stock <= reorder_level;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_out_of_stock
    ON pharmacy_products(pharmacy_id)
    WHERE quantity_in_stock <= 0;

-- Expiry
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_expiry
    ON pharmacy_products(expiry_date)
    WHERE expiry_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_expired
    ON pharmacy_products(pharmacy_id, expiry_date);

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_expiring_soon
    ON pharmacy_products(pharmacy_id, expiry_date);

-- Full-text search
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_search
    ON pharmacy_products USING GIN(search_vector);

-- Unique product code per pharmacy
CREATE UNIQUE INDEX IF NOT EXISTS idx_pharmacy_products_code_pharmacy
    ON pharmacy_products(pharmacy_id, product_code)
    WHERE product_code IS NOT NULL;

-- Compound indexes for common queries
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_pharmacy_active_category
    ON pharmacy_products(pharmacy_id, is_active, category_id)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_pharmacy_active_price
    ON pharmacy_products(pharmacy_id, is_active, price)
    WHERE is_active = true;

-- Ratings
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_rating
    ON pharmacy_products(average_rating DESC, total_reviews DESC);

-- Popularity
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_popular
    ON pharmacy_products(total_sold DESC, view_count DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_pharmacy_products_created
    ON pharmacy_products(created_at DESC);

COMMENT ON INDEX idx_pharmacy_products_pharmacy IS 'Optimize product lookup by pharmacy';
COMMENT ON INDEX idx_pharmacy_products_medication IS 'Optimize product-medication link queries';
COMMENT ON INDEX idx_pharmacy_products_search IS 'Full-text search on product names, descriptions, etc.';
COMMENT ON INDEX idx_pharmacy_products_low_stock IS 'Optimize low stock alerts per pharmacy';
COMMENT ON INDEX idx_pharmacy_products_expiring_soon IS 'Optimize expiry alerts (next 30 days)';

-- ============================================
-- INDEXES: user_cart
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_cart_user
    ON user_cart(user_id);

CREATE INDEX IF NOT EXISTS idx_user_cart_product
    ON user_cart(product_id);

CREATE INDEX IF NOT EXISTS idx_user_cart_user_added
    ON user_cart(user_id, added_at DESC);

COMMENT ON INDEX idx_user_cart_user IS 'Optimize cart lookup by user';
COMMENT ON INDEX idx_user_cart_product IS 'Optimize cart item deletion when product is deleted';

-- ============================================
-- INDEXES: user_wishlist
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_wishlist_user
    ON user_wishlist(user_id);

CREATE INDEX IF NOT EXISTS idx_user_wishlist_product
    ON user_wishlist(product_id);

CREATE INDEX IF NOT EXISTS idx_user_wishlist_user_added
    ON user_wishlist(user_id, added_at DESC);

COMMENT ON INDEX idx_user_wishlist_user IS 'Optimize wishlist lookup by user';
COMMENT ON INDEX idx_user_wishlist_product IS 'Optimize wishlist item deletion when product is deleted';

-- ============================================
-- INDEXES: user_addresses
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_addresses_user
    ON user_addresses(user_id);

CREATE INDEX IF NOT EXISTS idx_user_addresses_default
    ON user_addresses(user_id, is_default)
    WHERE is_default = true;

CREATE INDEX IF NOT EXISTS idx_user_addresses_active
    ON user_addresses(user_id, is_active)
    WHERE is_active = true;

COMMENT ON INDEX idx_user_addresses_user IS 'Optimize address lookup by user';
COMMENT ON INDEX idx_user_addresses_default IS 'Optimize default address lookup';

-- ============================================
-- INDEXES: pharmacy_orders
-- ============================================

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_user
    ON pharmacy_orders(user_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_pharmacy
    ON pharmacy_orders(pharmacy_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_status
    ON pharmacy_orders(status);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_payment_status
    ON pharmacy_orders(payment_status);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_ordered_at
    ON pharmacy_orders(ordered_at DESC);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_number
    ON pharmacy_orders(order_number);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_prescription
    ON pharmacy_orders(prescription_id)
    WHERE prescription_id IS NOT NULL;

-- Compound indexes for common queries
CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_user_status
    ON pharmacy_orders(user_id, status, ordered_at DESC);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_pharmacy_status
    ON pharmacy_orders(pharmacy_id, status, ordered_at DESC);

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_pharmacy_pending
    ON pharmacy_orders(pharmacy_id, ordered_at DESC)
    WHERE status IN ('pending', 'confirmed', 'processing');

-- EHRbase sync
CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_ehrbase_pending
    ON pharmacy_orders(pharmacy_id)
    WHERE ehrbase_synced = false AND status = 'delivered';

COMMENT ON INDEX idx_pharmacy_orders_user IS 'Optimize order lookup by user';
COMMENT ON INDEX idx_pharmacy_orders_pharmacy IS 'Optimize order lookup by pharmacy';
COMMENT ON INDEX idx_pharmacy_orders_status IS 'Optimize order filtering by status';
COMMENT ON INDEX idx_pharmacy_orders_pharmacy_pending IS 'Optimize pending orders dashboard for pharmacies';
COMMENT ON INDEX idx_pharmacy_orders_ehrbase_pending IS 'Optimize EHRbase sync queue processing';

-- ============================================
-- INDEXES: pharmacy_order_items
-- ============================================

CREATE INDEX IF NOT EXISTS idx_order_items_order
    ON pharmacy_order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product
    ON pharmacy_order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_prescription_required
    ON pharmacy_order_items(order_id)
    WHERE requires_prescription = true;

COMMENT ON INDEX idx_order_items_order IS 'Optimize order items lookup by order';
COMMENT ON INDEX idx_order_items_product IS 'Optimize sales analytics by product';
COMMENT ON INDEX idx_order_items_prescription_required IS 'Optimize prescription validation queries';

-- ============================================
-- INDEXES: product_reviews
-- ============================================

CREATE INDEX IF NOT EXISTS idx_product_reviews_product
    ON product_reviews(product_id);

CREATE INDEX IF NOT EXISTS idx_product_reviews_user
    ON product_reviews(user_id);

CREATE INDEX IF NOT EXISTS idx_product_reviews_rating
    ON product_reviews(rating);

CREATE INDEX IF NOT EXISTS idx_product_reviews_approved
    ON product_reviews(is_approved, product_id, created_at DESC)
    WHERE is_approved = true;

CREATE INDEX IF NOT EXISTS idx_product_reviews_featured
    ON product_reviews(product_id, is_featured)
    WHERE is_featured = true;

CREATE INDEX IF NOT EXISTS idx_product_reviews_verified
    ON product_reviews(product_id, is_verified_purchase)
    WHERE is_verified_purchase = true;

-- Compound index for review sorting
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_approved_created
    ON product_reviews(product_id, is_approved, created_at DESC);

COMMENT ON INDEX idx_product_reviews_product IS 'Optimize reviews lookup by product';
COMMENT ON INDEX idx_product_reviews_approved IS 'Optimize approved reviews queries';
COMMENT ON INDEX idx_product_reviews_verified IS 'Optimize verified purchase badge queries';

-- ============================================
-- INDEXES: order_tracking
-- ============================================

CREATE INDEX IF NOT EXISTS idx_order_tracking_order
    ON order_tracking(order_id);

CREATE INDEX IF NOT EXISTS idx_order_tracking_time
    ON order_tracking(tracked_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_tracking_order_time
    ON order_tracking(order_id, tracked_at DESC);

COMMENT ON INDEX idx_order_tracking_order IS 'Optimize tracking history lookup by order';
COMMENT ON INDEX idx_order_tracking_time IS 'Optimize recent tracking events queries';

-- ============================================
-- INDEXES: pharmacy_coupons
-- ============================================

CREATE INDEX IF NOT EXISTS idx_pharmacy_coupons_pharmacy
    ON pharmacy_coupons(pharmacy_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_coupons_code
    ON pharmacy_coupons(code);

CREATE INDEX IF NOT EXISTS idx_pharmacy_coupons_active
    ON pharmacy_coupons(is_active, valid_from, valid_until)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_pharmacy_coupons_validity
    ON pharmacy_coupons(valid_from, valid_until);

CREATE INDEX IF NOT EXISTS idx_pharmacy_coupons_active_valid
    ON pharmacy_coupons(code);

COMMENT ON INDEX idx_pharmacy_coupons_pharmacy IS 'Optimize coupon lookup by pharmacy';
COMMENT ON INDEX idx_pharmacy_coupons_code IS 'Optimize coupon code validation';
COMMENT ON INDEX idx_pharmacy_coupons_active_valid IS 'Optimize active coupon validation';

-- ============================================
-- INDEXES: coupon_usage
-- ============================================

CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon
    ON coupon_usage(coupon_id);

CREATE INDEX IF NOT EXISTS idx_coupon_usage_user
    ON coupon_usage(user_id);

CREATE INDEX IF NOT EXISTS idx_coupon_usage_order
    ON coupon_usage(order_id);

CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon_user
    ON coupon_usage(coupon_id, user_id);

COMMENT ON INDEX idx_coupon_usage_coupon IS 'Optimize usage tracking by coupon';
COMMENT ON INDEX idx_coupon_usage_user IS 'Optimize user coupon history';
COMMENT ON INDEX idx_coupon_usage_coupon_user IS 'Optimize per-user limit checks';

-- ============================================
-- INDEXES: dispensed_medications (NEW INDEX FOR E-COMMERCE LINK)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_dispensed_medications_order
    ON dispensed_medications(order_id)
    WHERE order_id IS NOT NULL;

COMMENT ON INDEX idx_dispensed_medications_order IS 'Optimize dispensed_medications lookup by e-commerce order';

-- ============================================
-- END OF MIGRATION: Part 3 Indexes
-- Total Indexes Created: 50+
-- ============================================
