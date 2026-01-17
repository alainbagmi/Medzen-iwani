-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 1: Base Tables
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Creates base tables for pharmacy e-commerce module
--              - product_categories
--              - product_subcategories
--              - pharmacy_coupons (MODIFIED: uses pharmacy_id instead of facility_id)
--              - user_addresses
-- Dependencies: pharmacies table (from migration 20260112140000)
-- ============================================

-- ============================================
-- TABLE 1: product_categories
-- Purpose: Product categories for organizing pharmacy items
-- Columns: 8
-- Dependencies: None
-- ============================================

CREATE TABLE IF NOT EXISTS product_categories (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Category Information
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url TEXT,

    -- Display Settings
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table comment
COMMENT ON TABLE product_categories IS 'Product categories for pharmacy e-commerce';

-- Column comments
COMMENT ON COLUMN product_categories.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN product_categories.name IS 'Category name (required, max 100 chars)';
COMMENT ON COLUMN product_categories.description IS 'Category description';
COMMENT ON COLUMN product_categories.image_url IS 'URL to category image';
COMMENT ON COLUMN product_categories.display_order IS 'Sort order for display (lower = first)';
COMMENT ON COLUMN product_categories.is_active IS 'Whether category is active/visible';
COMMENT ON COLUMN product_categories.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN product_categories.updated_at IS 'Last update timestamp';

-- ============================================
-- TABLE 2: product_subcategories
-- Purpose: Subcategories within main categories
-- Columns: 9
-- Dependencies: product_categories
-- ============================================

CREATE TABLE IF NOT EXISTS product_subcategories (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Key to Parent Category
    category_id UUID NOT NULL REFERENCES product_categories(id) ON DELETE CASCADE,

    -- Subcategory Information
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url TEXT,

    -- Display Settings
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table comment
COMMENT ON TABLE product_subcategories IS 'Subcategories within main product categories';

-- Column comments
COMMENT ON COLUMN product_subcategories.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN product_subcategories.category_id IS 'Parent category reference (cascades on delete)';
COMMENT ON COLUMN product_subcategories.name IS 'Subcategory name';
COMMENT ON COLUMN product_subcategories.description IS 'Subcategory description';
COMMENT ON COLUMN product_subcategories.image_url IS 'URL to subcategory image';
COMMENT ON COLUMN product_subcategories.display_order IS 'Sort order within parent category';
COMMENT ON COLUMN product_subcategories.is_active IS 'Whether subcategory is active/visible';
COMMENT ON COLUMN product_subcategories.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN product_subcategories.updated_at IS 'Last update timestamp';

-- ============================================
-- TABLE 3: pharmacy_coupons
-- Purpose: Discount coupons for pharmacy orders
-- Columns: 19
-- Dependencies: pharmacies (from existing migration 20260112140000)
-- MODIFICATION: Uses pharmacy_id instead of facility_id
-- ============================================

CREATE TABLE IF NOT EXISTS pharmacy_coupons (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Pharmacy Reference (NULL = global coupon for all pharmacies)
    -- MODIFIED: pharmacy_id instead of facility_id
    pharmacy_id UUID REFERENCES pharmacies(id) ON DELETE CASCADE,

    -- Coupon Code
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,

    -- Discount Configuration
    discount_type VARCHAR(20) NOT NULL,  -- 'percentage' or 'fixed_amount'
    discount_value DECIMAL(10,2) NOT NULL,

    -- Order Requirements
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    max_discount_amount DECIMAL(10,2),

    -- Usage Limits
    usage_limit INTEGER,           -- NULL = unlimited total uses
    used_count INTEGER DEFAULT 0,
    per_user_limit INTEGER DEFAULT 1,

    -- Validity Period
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,

    -- Status Flags
    is_active BOOLEAN DEFAULT true,
    is_first_order_only BOOLEAN DEFAULT false,

    -- Applicability (NULL = all products/categories)
    applicable_category_ids UUID[],
    applicable_product_ids UUID[],

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_discount_type CHECK (discount_type IN ('percentage', 'fixed_amount')),
    CONSTRAINT positive_discount CHECK (discount_value > 0),
    CONSTRAINT valid_percentage CHECK (discount_type != 'percentage' OR discount_value <= 100)
);

-- Table comment
COMMENT ON TABLE pharmacy_coupons IS 'Discount coupons for pharmacy orders';

-- Column comments
COMMENT ON COLUMN pharmacy_coupons.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN pharmacy_coupons.pharmacy_id IS 'Pharmacy this coupon belongs to (NULL = global, references pharmacies.id)';
COMMENT ON COLUMN pharmacy_coupons.code IS 'Unique coupon code for user entry';
COMMENT ON COLUMN pharmacy_coupons.description IS 'Human-readable description of the coupon';
COMMENT ON COLUMN pharmacy_coupons.discount_type IS 'Type: percentage or fixed_amount';
COMMENT ON COLUMN pharmacy_coupons.discount_value IS 'Discount amount (percent or fixed value in XAF)';
COMMENT ON COLUMN pharmacy_coupons.min_order_amount IS 'Minimum order total required to use coupon';
COMMENT ON COLUMN pharmacy_coupons.max_discount_amount IS 'Maximum discount cap for percentage coupons';
COMMENT ON COLUMN pharmacy_coupons.usage_limit IS 'Total number of times coupon can be used (NULL = unlimited)';
COMMENT ON COLUMN pharmacy_coupons.used_count IS 'Number of times coupon has been used';
COMMENT ON COLUMN pharmacy_coupons.per_user_limit IS 'Max times each user can use this coupon';
COMMENT ON COLUMN pharmacy_coupons.valid_from IS 'Coupon activation date/time';
COMMENT ON COLUMN pharmacy_coupons.valid_until IS 'Coupon expiration date/time (NULL = no expiry)';
COMMENT ON COLUMN pharmacy_coupons.is_active IS 'Whether coupon is currently active';
COMMENT ON COLUMN pharmacy_coupons.is_first_order_only IS 'Only valid for users first order';
COMMENT ON COLUMN pharmacy_coupons.applicable_category_ids IS 'Limit to specific categories (NULL = all)';
COMMENT ON COLUMN pharmacy_coupons.applicable_product_ids IS 'Limit to specific products (NULL = all)';
COMMENT ON COLUMN pharmacy_coupons.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN pharmacy_coupons.updated_at IS 'Last update timestamp';

-- ============================================
-- TABLE 4: user_addresses
-- Purpose: User delivery addresses for pharmacy orders
-- Columns: 20
-- Dependencies: auth.users
-- ============================================

CREATE TABLE IF NOT EXISTS user_addresses (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- User Reference
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Address Label
    address_name VARCHAR(100),  -- "Home", "Work", "Mom's House", etc.

    -- Contact Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    phone_code VARCHAR(10) DEFAULT '+237',  -- Cameroon country code
    email VARCHAR(255),

    -- Address Details
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'Cameroon',

    -- Geolocation (Optional)
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    -- Status Flags
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table comment
COMMENT ON TABLE user_addresses IS 'User delivery addresses for pharmacy orders';

-- Column comments
COMMENT ON COLUMN user_addresses.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN user_addresses.user_id IS 'User who owns this address (Supabase Auth user)';
COMMENT ON COLUMN user_addresses.address_name IS 'User-friendly label for this address';
COMMENT ON COLUMN user_addresses.first_name IS 'Recipient first name';
COMMENT ON COLUMN user_addresses.last_name IS 'Recipient last name';
COMMENT ON COLUMN user_addresses.phone IS 'Recipient phone number';
COMMENT ON COLUMN user_addresses.phone_code IS 'Country dialing code (default: Cameroon +237)';
COMMENT ON COLUMN user_addresses.email IS 'Recipient email (optional)';
COMMENT ON COLUMN user_addresses.address_line1 IS 'Primary address line (street, number)';
COMMENT ON COLUMN user_addresses.address_line2 IS 'Secondary address line (apartment, suite, etc.)';
COMMENT ON COLUMN user_addresses.city IS 'City name';
COMMENT ON COLUMN user_addresses.state IS 'State/province/region';
COMMENT ON COLUMN user_addresses.postal_code IS 'Postal/ZIP code';
COMMENT ON COLUMN user_addresses.country IS 'Country name';
COMMENT ON COLUMN user_addresses.latitude IS 'GPS latitude for delivery';
COMMENT ON COLUMN user_addresses.longitude IS 'GPS longitude for delivery';
COMMENT ON COLUMN user_addresses.is_default IS 'Primary address for this user';
COMMENT ON COLUMN user_addresses.is_active IS 'Whether address is active';
COMMENT ON COLUMN user_addresses.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN user_addresses.updated_at IS 'Last update timestamp';

-- ============================================
-- END OF MIGRATION: Part 1 Base Tables
-- ============================================
