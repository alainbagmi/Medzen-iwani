-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 4: Functions & Triggers
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Creates database functions and triggers for automation
--              - Product search vector updates
--              - Cart timestamp updates
--              - Address default management
--              - Order number generation
--              - Order status timestamp updates
--              - Line total calculation
--              - Product sold count updates
--              - Product rating updates
--              - Pharmacy admin access check
--              - CRITICAL: Inventory sync between pharmacy_inventory and pharmacy_products
-- Total Functions: 10
-- Total Triggers: 10
-- ============================================

-- ============================================
-- FUNCTION 1: update_product_search_vector()
-- Purpose: Auto-populate full-text search vector for products
-- ============================================

CREATE OR REPLACE FUNCTION update_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english',
        COALESCE(NEW.name, '') || ' ' ||
        COALESCE(NEW.generic_name, '') || ' ' ||
        COALESCE(NEW.description, '') || ' ' ||
        COALESCE(NEW.manufacturer, '') || ' ' ||
        COALESCE(NEW.brand, '')
    );
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_product_search_vector() IS 'Auto-populate search_vector and updated_at for pharmacy_products';

-- Trigger
CREATE TRIGGER trigger_update_product_search
BEFORE INSERT OR UPDATE ON pharmacy_products
FOR EACH ROW EXECUTE FUNCTION update_product_search_vector();

COMMENT ON TRIGGER trigger_update_product_search ON pharmacy_products IS 'Update search vector before insert/update';

-- ============================================
-- FUNCTION 2: update_cart_timestamp()
-- Purpose: Auto-update cart item timestamp
-- ============================================

CREATE OR REPLACE FUNCTION update_cart_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_cart_timestamp() IS 'Auto-update updated_at timestamp for cart items';

-- Trigger
CREATE TRIGGER trigger_update_cart_timestamp
BEFORE UPDATE ON user_cart
FOR EACH ROW EXECUTE FUNCTION update_cart_timestamp();

COMMENT ON TRIGGER trigger_update_cart_timestamp ON user_cart IS 'Update timestamp before cart item update';

-- ============================================
-- FUNCTION 3: ensure_single_default_address()
-- Purpose: Only one default address per user
-- ============================================

CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        -- Unset all other default addresses for this user
        UPDATE user_addresses
        SET is_default = false
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION ensure_single_default_address() IS 'Ensure only one default address per user';

-- Trigger
CREATE TRIGGER trigger_single_default_address
BEFORE INSERT OR UPDATE ON user_addresses
FOR EACH ROW EXECUTE FUNCTION ensure_single_default_address();

COMMENT ON TRIGGER trigger_single_default_address ON user_addresses IS 'Enforce single default address constraint';

-- ============================================
-- FUNCTION 4: generate_order_number()
-- Purpose: Auto-generate human-readable order number
-- Format: ORD-YYYYMMDD-XXXXX
-- ============================================

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    seq_num INTEGER;
BEGIN
    -- Get next sequence number for today
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(order_number FROM 'ORD-[0-9]{8}-([0-9]+)') AS INTEGER)
    ), 0) + 1 INTO seq_num
    FROM pharmacy_orders
    WHERE order_number LIKE 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-%';

    NEW.order_number := 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(seq_num::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_order_number() IS 'Auto-generate order number in format ORD-YYYYMMDD-XXXXX';

-- Trigger (only when order_number is NULL)
CREATE TRIGGER trigger_generate_order_number
BEFORE INSERT ON pharmacy_orders
FOR EACH ROW
WHEN (NEW.order_number IS NULL)
EXECUTE FUNCTION generate_order_number();

COMMENT ON TRIGGER trigger_generate_order_number ON pharmacy_orders IS 'Generate order number if not provided';

-- ============================================
-- FUNCTION 5: update_order_status_timestamp()
-- Purpose: Auto-update status timestamps when order status changes
-- ============================================

CREATE OR REPLACE FUNCTION update_order_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();

    IF NEW.status != OLD.status THEN
        CASE NEW.status
            WHEN 'confirmed' THEN NEW.confirmed_at := NOW();
            WHEN 'processing' THEN NEW.processing_at := NOW();
            WHEN 'shipped' THEN NEW.shipped_at := NOW();
            WHEN 'delivered' THEN
                NEW.delivered_at := NOW();
                NEW.actual_delivery_date := CURRENT_DATE;
            WHEN 'cancelled' THEN NEW.cancelled_at := NOW();
        END CASE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_order_status_timestamp() IS 'Auto-update status-specific timestamps when order status changes';

-- Trigger
CREATE TRIGGER trigger_update_order_status_timestamp
BEFORE UPDATE ON pharmacy_orders
FOR EACH ROW EXECUTE FUNCTION update_order_status_timestamp();

COMMENT ON TRIGGER trigger_update_order_status_timestamp ON pharmacy_orders IS 'Update status timestamps on order status change';

-- ============================================
-- FUNCTION 6: calculate_line_total()
-- Purpose: Auto-calculate order item line total
-- ============================================

CREATE OR REPLACE FUNCTION calculate_line_total()
RETURNS TRIGGER AS $$
BEGIN
    NEW.line_total := NEW.unit_price * NEW.quantity * (1 - COALESCE(NEW.discount_percent, 0) / 100) - COALESCE(NEW.discount_amount, 0);

    -- Ensure line_total is not negative
    IF NEW.line_total < 0 THEN
        NEW.line_total := 0;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_line_total() IS 'Auto-calculate line_total for order items';

-- Trigger
CREATE TRIGGER trigger_calculate_line_total
BEFORE INSERT OR UPDATE ON pharmacy_order_items
FOR EACH ROW EXECUTE FUNCTION calculate_line_total();

COMMENT ON TRIGGER trigger_calculate_line_total ON pharmacy_order_items IS 'Calculate line total before insert/update';

-- ============================================
-- FUNCTION 7: update_product_sold_count()
-- Purpose: Increment product sold count when order item is created
-- ============================================

CREATE OR REPLACE FUNCTION update_product_sold_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE pharmacy_products
        SET total_sold = total_sold + NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_product_sold_count() IS 'Increment product total_sold count when order item is created';

-- Trigger
CREATE TRIGGER trigger_update_sold_count
AFTER INSERT ON pharmacy_order_items
FOR EACH ROW EXECUTE FUNCTION update_product_sold_count();

COMMENT ON TRIGGER trigger_update_sold_count ON pharmacy_order_items IS 'Update product sold count after order item insert';

-- ============================================
-- FUNCTION 8: update_product_rating()
-- Purpose: Recalculate product average rating when reviews change
-- ============================================

CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pharmacy_products
    SET
        average_rating = (
            SELECT ROUND(AVG(rating)::numeric, 2)
            FROM product_reviews
            WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
            AND is_approved = true
        ),
        total_reviews = (
            SELECT COUNT(*)
            FROM product_reviews
            WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
            AND is_approved = true
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_product_rating() IS 'Recalculate product average_rating and total_reviews when reviews change';

-- Trigger
CREATE TRIGGER trigger_update_product_rating
AFTER INSERT OR UPDATE OR DELETE ON product_reviews
FOR EACH ROW EXECUTE FUNCTION update_product_rating();

COMMENT ON TRIGGER trigger_update_product_rating ON product_reviews IS 'Update product rating after review insert/update/delete';

-- ============================================
-- FUNCTION 9: is_pharmacy_admin()
-- Purpose: Check if current user is admin of a pharmacy (for RLS policies)
-- Returns: TRUE if user is approved admin of the specified pharmacy
-- ============================================

CREATE OR REPLACE FUNCTION is_pharmacy_admin(pharmacy_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM pharmacies p
        WHERE p.id = pharmacy_uuid
        AND p.manager_id IN (
            SELECT user_id FROM facility_admin_profiles
            WHERE user_id IN (
                SELECT id FROM users WHERE firebase_uid::TEXT = auth.uid()::TEXT
            )
            AND application_status = 'approved'
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION is_pharmacy_admin(UUID) IS 'Check if current user is approved admin of specified pharmacy (for RLS policies)';

-- ============================================
-- FUNCTION 10: sync_pharmacy_inventory()
-- Purpose: Bidirectional sync between pharmacy_inventory and pharmacy_products
--          This keeps the legacy clinical inventory in sync with e-commerce inventory
-- Trigger: AFTER INSERT OR UPDATE on both tables
-- CRITICAL: Enables unified inventory management
-- ============================================

CREATE OR REPLACE FUNCTION sync_pharmacy_inventory()
RETURNS TRIGGER AS $$
BEGIN
    -- When pharmacy_products stock changes, update pharmacy_inventory
    IF (TG_TABLE_NAME = 'pharmacy_products') THEN
        -- Only sync if this is a medication product
        IF NEW.medication_id IS NOT NULL THEN
            -- Try to update existing inventory record
            UPDATE pharmacy_inventory
            SET quantity_available = NEW.quantity_in_stock,
                unit_price = NEW.price,
                is_available = (NEW.quantity_in_stock > 0),
                updated_at = NOW()
            WHERE pharmacy_id = NEW.pharmacy_id
              AND medication_id = NEW.medication_id
              AND (batch_number = NEW.batch_number OR (batch_number IS NULL AND NEW.batch_number IS NULL));

            -- Create if doesn't exist
            IF NOT FOUND THEN
                INSERT INTO pharmacy_inventory (
                    pharmacy_id,
                    medication_id,
                    quantity_available,
                    reorder_level,
                    unit_price,
                    expiry_date,
                    batch_number,
                    is_available,
                    date_received,
                    created_at,
                    updated_at
                ) VALUES (
                    NEW.pharmacy_id,
                    NEW.medication_id,
                    NEW.quantity_in_stock,
                    NEW.reorder_level,
                    NEW.price,
                    NEW.expiry_date,
                    NEW.batch_number,
                    (NEW.quantity_in_stock > 0),
                    NEW.created_at,
                    NOW(),
                    NOW()
                )
                ON CONFLICT DO NOTHING;  -- Prevent duplicates if concurrent inserts
            END IF;
        END IF;
    END IF;

    -- When pharmacy_inventory changes, update pharmacy_products
    IF (TG_TABLE_NAME = 'pharmacy_inventory') THEN
        -- Try to update existing product record
        UPDATE pharmacy_products
        SET quantity_in_stock = NEW.quantity_available,
            price = NEW.unit_price,
            is_active = NEW.is_available,
            updated_at = NOW()
        WHERE pharmacy_id = NEW.pharmacy_id
          AND medication_id = NEW.medication_id
          AND product_type = 'medication'
          AND (batch_number = NEW.batch_number OR (batch_number IS NULL AND NEW.batch_number IS NULL));

        -- Create if doesn't exist
        IF NOT FOUND AND NEW.medication_id IS NOT NULL THEN
            -- Get medication details
            INSERT INTO pharmacy_products (
                pharmacy_id,
                medication_id,
                product_type,
                name,
                generic_name,
                sku,
                price,
                quantity_in_stock,
                reorder_level,
                dosage_strength,
                dosage_form,
                route_of_administration,
                requires_prescription,
                controlled_substance,
                manufacturer,
                batch_number,
                expiry_date,
                is_active,
                created_at,
                updated_at
            )
            SELECT
                NEW.pharmacy_id,
                NEW.medication_id,
                'medication',
                COALESCE(m.brand_name, m.generic_name),
                m.generic_name,
                NEW.batch_number,
                NEW.unit_price,
                NEW.quantity_available,
                NEW.reorder_level,
                m.strength,
                m.dosage_form,
                m.route_of_administration,
                m.requires_prescription,
                m.is_controlled_substance,
                m.manufacturer,
                NEW.batch_number,
                NEW.expiry_date,
                NEW.is_available,
                NEW.date_received,
                NOW()
            FROM medications m
            WHERE m.id = NEW.medication_id
            ON CONFLICT DO NOTHING;  -- Prevent duplicates if concurrent inserts
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sync_pharmacy_inventory() IS 'Bidirectional sync between pharmacy_inventory (clinical) and pharmacy_products (e-commerce) for unified inventory management';

-- Triggers for bidirectional sync
CREATE TRIGGER sync_to_inventory
  AFTER INSERT OR UPDATE ON pharmacy_products
  FOR EACH ROW
  WHEN (NEW.medication_id IS NOT NULL)
  EXECUTE FUNCTION sync_pharmacy_inventory();

COMMENT ON TRIGGER sync_to_inventory ON pharmacy_products IS 'Sync changes from pharmacy_products to pharmacy_inventory';

CREATE TRIGGER sync_from_inventory
  AFTER INSERT OR UPDATE ON pharmacy_inventory
  FOR EACH ROW
  EXECUTE FUNCTION sync_pharmacy_inventory();

COMMENT ON TRIGGER sync_from_inventory ON pharmacy_inventory IS 'Sync changes from pharmacy_inventory to pharmacy_products';

-- ============================================
-- END OF MIGRATION: Part 4 Functions & Triggers
-- Total Functions: 10
-- Total Triggers: 10
-- ============================================
