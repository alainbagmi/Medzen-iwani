-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 2: Dependent Tables
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Creates dependent tables for pharmacy e-commerce module
--              - pharmacy_products (MODIFIED: pharmacy_id, medication_id required, product_type added)
--              - user_cart
--              - user_wishlist
--              - pharmacy_orders (MODIFIED: added dispensed_medication_ids, ehrbase fields)
--              - pharmacy_order_items
--              - product_reviews
--              - order_tracking
--              - coupon_usage
-- Dependencies: Part 1 base tables, pharmacies, medications, prescriptions
-- ============================================

-- ============================================
-- TABLE 1: pharmacy_products
-- Purpose: Products for sale in pharmacies (UNIFIED INVENTORY)
-- Columns: 50 (including new fields: pharmacy_id, product_type)
-- Dependencies: pharmacies, medications, product_categories, product_subcategories
-- MODIFICATIONS:
--   - Uses pharmacy_id (not facility_id)
--   - medication_id REQUIRED for medication products
--   - Added product_type field
--   - Added medication_required_for_drugs constraint
-- ============================================

CREATE TABLE IF NOT EXISTS pharmacy_products (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ==========================================
    -- OWNERSHIP & REFERENCES (MODIFIED)
    -- ==========================================

    -- Pharmacy that owns this product (MODIFIED: pharmacy_id instead of facility_id)
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,

    -- Medication reference (REQUIRED for medication products)
    medication_id UUID REFERENCES medications(id) ON DELETE RESTRICT,

    -- Product type classification (NEW FIELD)
    product_type VARCHAR(50) NOT NULL DEFAULT 'medication',
    -- Options: 'medication', 'supplement', 'medical_device', 'personal_care', 'first_aid'

    -- ==========================================
    -- PRODUCT IDENTIFICATION
    -- ==========================================

    product_code VARCHAR(50),      -- Internal product code
    sku VARCHAR(100),              -- Stock Keeping Unit
    barcode VARCHAR(50),           -- EAN/UPC barcode

    -- ==========================================
    -- BASIC INFORMATION
    -- ==========================================

    name VARCHAR(255) NOT NULL,    -- Product display name
    generic_name VARCHAR(255),     -- Generic/scientific name
    description TEXT,              -- Short description
    information TEXT,              -- Detailed information/usage

    -- ==========================================
    -- PRICING (XAF - Central African Franc)
    -- ==========================================

    price DECIMAL(10,2) NOT NULL,  -- Regular price in XAF
    sale_price DECIMAL(10,2),      -- Sale price (when on sale)
    is_on_sale BOOLEAN DEFAULT false,
    sale_percent DECIMAL(5,2),     -- Discount percentage

    -- ==========================================
    -- CATEGORIZATION
    -- ==========================================

    category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
    subcategory_id UUID REFERENCES product_subcategories(id) ON DELETE SET NULL,

    -- ==========================================
    -- IMAGES
    -- ==========================================

    images TEXT[] DEFAULT '{}',    -- Array of image URLs
    thumbnail_url TEXT,            -- Primary thumbnail image

    -- ==========================================
    -- INVENTORY (UNIFIED: used by both clinical and e-commerce)
    -- ==========================================

    quantity_in_stock INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,     -- Alert when stock falls below
    max_stock_level INTEGER DEFAULT 1000, -- Maximum stock capacity

    -- ==========================================
    -- MEDICAL INFORMATION
    -- ==========================================

    dosage_strength VARCHAR(100),          -- e.g., "500mg", "10ml"
    dosage_form VARCHAR(50),               -- e.g., "Tablet", "Syrup", "Capsule"
    route_of_administration VARCHAR(50),   -- e.g., "Oral", "Topical"
    requires_prescription BOOLEAN DEFAULT false,
    controlled_substance BOOLEAN DEFAULT false,

    -- ==========================================
    -- MANUFACTURER INFORMATION
    -- ==========================================

    manufacturer VARCHAR(255),
    brand VARCHAR(255),
    batch_number VARCHAR(100),
    manufacturing_date DATE,
    expiry_date DATE,

    -- ==========================================
    -- STORAGE REQUIREMENTS
    -- ==========================================

    storage_conditions TEXT,               -- e.g., "Store in cool, dry place"
    temperature_requirement VARCHAR(50),   -- e.g., "2-8°C", "Room temperature"

    -- ==========================================
    -- DISPLAY FLAGS
    -- ==========================================

    is_active BOOLEAN DEFAULT true,        -- Show in catalog
    is_featured BOOLEAN DEFAULT false,     -- Featured products section
    is_trending BOOLEAN DEFAULT false,     -- Trending products section
    is_recommended BOOLEAN DEFAULT false,  -- Recommended products section
    is_big_saving BOOLEAN DEFAULT false,   -- Big savings section
    is_new_arrival BOOLEAN DEFAULT false,  -- New arrivals section

    -- ==========================================
    -- STATISTICS (Updated by triggers/functions)
    -- ==========================================

    average_rating DECIMAL(3,2) DEFAULT 0.00,  -- 0.00 to 5.00
    total_reviews INTEGER DEFAULT 0,
    total_sold INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,

    -- ==========================================
    -- RELATED PRODUCTS
    -- ==========================================

    related_product_ids UUID[] DEFAULT '{}',

    -- ==========================================
    -- SEARCH
    -- ==========================================

    search_vector TSVECTOR,  -- Full-text search vector

    -- ==========================================
    -- METADATA
    -- ==========================================

    metadata JSONB DEFAULT '{}',  -- Flexible additional data

    -- ==========================================
    -- TIMESTAMPS
    -- ==========================================

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- ==========================================
    -- CONSTRAINTS
    -- ==========================================

    CONSTRAINT price_positive CHECK (price >= 0),
    CONSTRAINT sale_price_valid CHECK (sale_price IS NULL OR sale_price >= 0),
    CONSTRAINT quantity_non_negative CHECK (quantity_in_stock >= 0),
    CONSTRAINT rating_range CHECK (average_rating >= 0 AND average_rating <= 5),

    -- NEW CONSTRAINT: medication_id required for medication products
    CONSTRAINT medication_required_for_drugs CHECK (
        (product_type = 'medication' AND medication_id IS NOT NULL) OR
        (product_type != 'medication')
    )
);

-- Table comment
COMMENT ON TABLE pharmacy_products IS 'Products available for sale in pharmacy facilities (unified inventory for clinical and e-commerce)';

-- Key column comments
COMMENT ON COLUMN pharmacy_products.pharmacy_id IS 'Pharmacy that owns this product (references pharmacies.id)';
COMMENT ON COLUMN pharmacy_products.medication_id IS 'Medication reference (required for medication products, references medications.id)';
COMMENT ON COLUMN pharmacy_products.product_type IS 'Product type: medication, supplement, medical_device, personal_care, first_aid';
COMMENT ON COLUMN pharmacy_products.price IS 'Regular price in XAF (Central African Franc)';
COMMENT ON COLUMN pharmacy_products.images IS 'Array of product image URLs';
COMMENT ON COLUMN pharmacy_products.quantity_in_stock IS 'Current inventory count (unified for clinical and e-commerce)';
COMMENT ON COLUMN pharmacy_products.reorder_level IS 'Stock level that triggers reorder alert';
COMMENT ON COLUMN pharmacy_products.requires_prescription IS 'Whether prescription is required to purchase';
COMMENT ON COLUMN pharmacy_products.expiry_date IS 'Product expiration date';
COMMENT ON COLUMN pharmacy_products.search_vector IS 'Full-text search index (auto-populated by trigger)';

-- ============================================
-- TABLE 2: user_cart
-- Purpose: Shopping cart for users
-- Columns: 6
-- Dependencies: auth.users, pharmacy_products
-- ============================================

CREATE TABLE IF NOT EXISTS user_cart (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- User Reference (Supabase Auth)
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Product Reference
    product_id UUID NOT NULL REFERENCES pharmacy_products(id) ON DELETE CASCADE,

    -- Quantity
    quantity INTEGER NOT NULL DEFAULT 1,

    -- Timestamps
    added_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT quantity_positive CHECK (quantity > 0),
    CONSTRAINT unique_user_product UNIQUE (user_id, product_id)
);

-- Table comment
COMMENT ON TABLE user_cart IS 'User shopping cart for pharmacy products';

-- Column comments
COMMENT ON COLUMN user_cart.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN user_cart.user_id IS 'User who owns this cart item (Supabase Auth user)';
COMMENT ON COLUMN user_cart.product_id IS 'Product in cart (references pharmacy_products.id)';
COMMENT ON COLUMN user_cart.quantity IS 'Quantity of product (must be > 0)';
COMMENT ON COLUMN user_cart.added_at IS 'When item was first added to cart';
COMMENT ON COLUMN user_cart.updated_at IS 'When quantity was last updated';

-- ============================================
-- TABLE 3: user_wishlist
-- Purpose: User's saved/favorite products
-- Columns: 4
-- Dependencies: auth.users, pharmacy_products
-- ============================================

CREATE TABLE IF NOT EXISTS user_wishlist (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- User Reference
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Product Reference
    product_id UUID NOT NULL REFERENCES pharmacy_products(id) ON DELETE CASCADE,

    -- Timestamp
    added_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_wishlist_item UNIQUE (user_id, product_id)
);

-- Table comment
COMMENT ON TABLE user_wishlist IS 'User wishlist/favorites for pharmacy products';

-- Column comments
COMMENT ON COLUMN user_wishlist.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN user_wishlist.user_id IS 'User who saved this product';
COMMENT ON COLUMN user_wishlist.product_id IS 'Saved product reference';
COMMENT ON COLUMN user_wishlist.added_at IS 'When product was added to wishlist';

-- ============================================
-- TABLE 4: pharmacy_orders
-- Purpose: Customer orders from pharmacies
-- Columns: 43 (including new fields: dispensed_medication_ids, ehrbase_synced, ehrbase_sync_id)
-- Dependencies: auth.users, pharmacies, user_addresses, pharmacy_coupons, prescriptions
-- MODIFICATIONS:
--   - Uses pharmacy_id (via pharmacies table)
--   - Added dispensed_medication_ids array
--   - Added ehrbase_synced and ehrbase_sync_id fields
-- ============================================

CREATE TABLE IF NOT EXISTS pharmacy_orders (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ==========================================
    -- ORDER IDENTIFICATION
    -- ==========================================

    order_number VARCHAR(50) UNIQUE NOT NULL,  -- Human-readable: ORD-YYYYMMDD-XXXXX

    -- ==========================================
    -- USER & PHARMACY
    -- ==========================================

    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE RESTRICT,

    -- ==========================================
    -- SHIPPING ADDRESS
    -- ==========================================

    shipping_address_id UUID REFERENCES user_addresses(id) ON DELETE SET NULL,
    shipping_address_snapshot JSONB,  -- Copy of address at order time

    -- ==========================================
    -- PRICING (XAF - Central African Franc)
    -- ==========================================

    subtotal DECIMAL(10,2) NOT NULL,          -- Sum of line items
    discount_amount DECIMAL(10,2) DEFAULT 0,   -- Total discounts
    shipping_fee DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,       -- Final amount to pay
    currency VARCHAR(3) DEFAULT 'XAF',         -- ISO currency code

    -- ==========================================
    -- COUPON
    -- ==========================================

    coupon_id UUID REFERENCES pharmacy_coupons(id) ON DELETE SET NULL,
    coupon_code VARCHAR(50),
    coupon_discount DECIMAL(10,2) DEFAULT 0,

    -- ==========================================
    -- PAYMENT
    -- ==========================================

    payment_method VARCHAR(50),      -- 'mobile_money', 'card', 'cash_on_delivery'
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_reference VARCHAR(100),  -- External payment reference
    payment_id UUID,                 -- Reference to payments table

    -- ==========================================
    -- ORDER STATUS
    -- ==========================================

    status VARCHAR(30) DEFAULT 'pending',
    -- Status flow: pending → confirmed → processing → shipped → delivered
    -- Alternative: pending → cancelled

    -- ==========================================
    -- PRESCRIPTION
    -- ==========================================

    requires_prescription BOOLEAN DEFAULT false,
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE SET NULL,  -- Link to prescriptions table
    prescription_verified BOOLEAN DEFAULT false,
    prescription_image_url TEXT,     -- User-uploaded prescription image

    -- ==========================================
    -- DELIVERY
    -- ==========================================

    delivery_method VARCHAR(50) DEFAULT 'delivery',  -- 'delivery' or 'pickup'
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    delivery_notes TEXT,

    -- ==========================================
    -- NOTES
    -- ==========================================

    customer_notes TEXT,        -- Notes from customer
    internal_notes TEXT,        -- Internal pharmacy notes
    cancellation_reason TEXT,   -- Reason if cancelled

    -- ==========================================
    -- DISPENSING INTEGRATION (NEW FIELDS)
    -- ==========================================

    dispensed_medication_ids UUID[],  -- Track which dispensed_medications records were created

    -- ==========================================
    -- EHRBASE INTEGRATION (NEW FIELDS)
    -- ==========================================

    ehrbase_synced BOOLEAN DEFAULT false,
    ehrbase_sync_id UUID,  -- Reference to ehrbase_sync_queue (no FK to avoid circular dependency)

    -- ==========================================
    -- STATUS TIMESTAMPS
    -- ==========================================

    ordered_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    processing_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,

    -- ==========================================
    -- RECORD TIMESTAMPS
    -- ==========================================

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- ==========================================
    -- CONSTRAINTS
    -- ==========================================

    CONSTRAINT positive_amounts CHECK (
        subtotal >= 0 AND
        total_amount >= 0 AND
        discount_amount >= 0 AND
        shipping_fee >= 0
    ),
    CONSTRAINT valid_status CHECK (
        status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')
    ),
    CONSTRAINT valid_payment_status CHECK (
        payment_status IN ('pending', 'paid', 'failed', 'refunded', 'partially_refunded')
    )
);

-- Table comment
COMMENT ON TABLE pharmacy_orders IS 'Customer orders from pharmacy facilities';

-- Key column comments
COMMENT ON COLUMN pharmacy_orders.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN pharmacy_orders.order_number IS 'Human-readable order number (format: ORD-YYYYMMDD-XXXXX)';
COMMENT ON COLUMN pharmacy_orders.pharmacy_id IS 'Pharmacy fulfilling this order (references pharmacies.id)';
COMMENT ON COLUMN pharmacy_orders.shipping_address_snapshot IS 'JSON copy of shipping address at order time (for historical reference)';
COMMENT ON COLUMN pharmacy_orders.status IS 'Order status: pending, confirmed, processing, shipped, delivered, cancelled, refunded';
COMMENT ON COLUMN pharmacy_orders.payment_status IS 'Payment status: pending, paid, failed, refunded, partially_refunded';
COMMENT ON COLUMN pharmacy_orders.prescription_id IS 'Link to prescriptions table for prescription validation';
COMMENT ON COLUMN pharmacy_orders.dispensed_medication_ids IS 'Array of dispensed_medications IDs created when order is fulfilled';
COMMENT ON COLUMN pharmacy_orders.ehrbase_synced IS 'Whether order has been synced to EHRbase';
COMMENT ON COLUMN pharmacy_orders.ehrbase_sync_id IS 'Reference to ehrbase_sync_queue record';

-- ============================================
-- TABLE 5: pharmacy_order_items
-- Purpose: Individual items within an order
-- Columns: 14
-- Dependencies: pharmacy_orders, pharmacy_products
-- ============================================

CREATE TABLE IF NOT EXISTS pharmacy_order_items (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Order Reference
    order_id UUID NOT NULL REFERENCES pharmacy_orders(id) ON DELETE CASCADE,

    -- Product Reference
    product_id UUID NOT NULL REFERENCES pharmacy_products(id) ON DELETE RESTRICT,

    -- Product Snapshot (Preserved from order time)
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100),
    product_image TEXT,
    product_description TEXT,

    -- Pricing
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    line_total DECIMAL(10,2) NOT NULL,  -- Calculated: unit_price * quantity - discounts

    -- Prescription Flag
    requires_prescription BOOLEAN DEFAULT false,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT positive_quantity CHECK (quantity > 0),
    CONSTRAINT positive_price CHECK (unit_price >= 0),
    CONSTRAINT positive_total CHECK (line_total >= 0)
);

-- Table comment
COMMENT ON TABLE pharmacy_order_items IS 'Individual items within pharmacy orders';

-- Key column comments
COMMENT ON COLUMN pharmacy_order_items.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN pharmacy_order_items.order_id IS 'Parent order reference';
COMMENT ON COLUMN pharmacy_order_items.product_id IS 'Product reference (at order time)';
COMMENT ON COLUMN pharmacy_order_items.product_name IS 'Product name at time of order (snapshot)';
COMMENT ON COLUMN pharmacy_order_items.unit_price IS 'Price per unit at time of order';
COMMENT ON COLUMN pharmacy_order_items.quantity IS 'Quantity ordered';
COMMENT ON COLUMN pharmacy_order_items.line_total IS 'Total for this line item (auto-calculated by trigger)';
COMMENT ON COLUMN pharmacy_order_items.requires_prescription IS 'Whether this product required prescription at order time';

-- ============================================
-- TABLE 6: product_reviews
-- Purpose: Product reviews and ratings
-- Columns: 15
-- Dependencies: pharmacy_products, auth.users, pharmacy_orders
-- ============================================

CREATE TABLE IF NOT EXISTS product_reviews (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Product & User
    product_id UUID NOT NULL REFERENCES pharmacy_products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Order Reference (for verified purchase badge)
    order_id UUID REFERENCES pharmacy_orders(id) ON DELETE SET NULL,

    -- Review Content
    rating INTEGER NOT NULL,
    title VARCHAR(255),
    review_text TEXT,

    -- Reviewer Info Snapshot
    reviewer_name VARCHAR(100),
    reviewer_image TEXT,

    -- Status Flags
    is_verified_purchase BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,

    -- Engagement
    helpful_count INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT unique_user_product_review UNIQUE (product_id, user_id)
);

-- Table comment
COMMENT ON TABLE product_reviews IS 'Customer reviews and ratings for pharmacy products';

-- Key column comments
COMMENT ON COLUMN product_reviews.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN product_reviews.product_id IS 'Product being reviewed';
COMMENT ON COLUMN product_reviews.user_id IS 'User who wrote the review';
COMMENT ON COLUMN product_reviews.order_id IS 'Order where product was purchased (for verified purchase badge)';
COMMENT ON COLUMN product_reviews.rating IS 'Star rating from 1 to 5';
COMMENT ON COLUMN product_reviews.is_verified_purchase IS 'User actually purchased this product';
COMMENT ON COLUMN product_reviews.is_approved IS 'Review passed moderation';
COMMENT ON COLUMN product_reviews.is_featured IS 'Review is featured/highlighted';
COMMENT ON COLUMN product_reviews.helpful_count IS 'Number of users who found review helpful';

-- ============================================
-- TABLE 7: order_tracking
-- Purpose: Order delivery tracking history
-- Columns: 8
-- Dependencies: pharmacy_orders
-- ============================================

CREATE TABLE IF NOT EXISTS order_tracking (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Order Reference
    order_id UUID NOT NULL REFERENCES pharmacy_orders(id) ON DELETE CASCADE,

    -- Tracking Information
    status VARCHAR(50) NOT NULL,    -- e.g., 'picked_up', 'in_transit', 'out_for_delivery'
    title VARCHAR(255),             -- Display title
    description TEXT,               -- Detailed description
    location VARCHAR(255),          -- Current location

    -- Timestamps
    tracked_at TIMESTAMPTZ DEFAULT NOW(),  -- When this event occurred
    created_at TIMESTAMPTZ DEFAULT NOW()   -- When record was created
);

-- Table comment
COMMENT ON TABLE order_tracking IS 'Delivery tracking history for pharmacy orders';

-- Column comments
COMMENT ON COLUMN order_tracking.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN order_tracking.order_id IS 'Order being tracked';
COMMENT ON COLUMN order_tracking.status IS 'Tracking status code';
COMMENT ON COLUMN order_tracking.title IS 'Display-friendly title for this tracking event';
COMMENT ON COLUMN order_tracking.description IS 'Detailed description of tracking event';
COMMENT ON COLUMN order_tracking.location IS 'Current location of shipment';
COMMENT ON COLUMN order_tracking.tracked_at IS 'Actual time of tracking event';
COMMENT ON COLUMN order_tracking.created_at IS 'When tracking record was created in database';

-- ============================================
-- TABLE 8: coupon_usage
-- Purpose: Track coupon usage per user
-- Columns: 5
-- Dependencies: pharmacy_coupons, auth.users, pharmacy_orders
-- ============================================

CREATE TABLE IF NOT EXISTS coupon_usage (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    coupon_id UUID NOT NULL REFERENCES pharmacy_coupons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES pharmacy_orders(id) ON DELETE SET NULL,

    -- Timestamp
    used_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_coupon_user_order UNIQUE (coupon_id, user_id, order_id)
);

-- Table comment
COMMENT ON TABLE coupon_usage IS 'Track coupon usage per user';

-- Column comments
COMMENT ON COLUMN coupon_usage.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN coupon_usage.coupon_id IS 'Coupon that was used';
COMMENT ON COLUMN coupon_usage.user_id IS 'User who used the coupon';
COMMENT ON COLUMN coupon_usage.order_id IS 'Order where coupon was applied';
COMMENT ON COLUMN coupon_usage.used_at IS 'When coupon was used';

-- ============================================
-- EXTENSION TO EXISTING TABLE: dispensed_medications
-- Purpose: Add order_id column to link e-commerce orders
-- This allows unified tracking of all medication sales
-- ============================================

-- Add order_id column (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dispensed_medications' AND column_name = 'order_id'
    ) THEN
        ALTER TABLE dispensed_medications
        ADD COLUMN order_id UUID REFERENCES pharmacy_orders(id) ON DELETE SET NULL;

        COMMENT ON COLUMN dispensed_medications.order_id IS 'E-commerce order reference (for non-prescription sales)';
    END IF;
END $$;

-- Make prescription_id nullable (allow e-commerce orders without prescription)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dispensed_medications'
        AND column_name = 'prescription_id'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE dispensed_medications
        ALTER COLUMN prescription_id DROP NOT NULL;
    END IF;
END $$;

-- Add constraint: must have either prescription_id OR order_id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'has_prescription_or_order'
    ) THEN
        ALTER TABLE dispensed_medications
        ADD CONSTRAINT has_prescription_or_order CHECK (
            prescription_id IS NOT NULL OR order_id IS NOT NULL
        );
    END IF;
END $$;

-- ============================================
-- END OF MIGRATION: Part 2 Dependent Tables
-- ============================================
