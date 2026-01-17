-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 7: Data Migration
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Migrate existing pharmacy_inventory data to pharmacy_products
--              This enables unified inventory management
-- CRITICAL: Run this after tables, functions, and triggers are in place
-- ============================================

-- ============================================
-- MIGRATE EXISTING PHARMACY_INVENTORY TO PHARMACY_PRODUCTS
-- ============================================

DO $$
DECLARE
    migrated_count INTEGER;
    skipped_count INTEGER;
    total_count INTEGER;
BEGIN
    -- Count total inventory records
    SELECT COUNT(*) INTO total_count FROM pharmacy_inventory;

    RAISE NOTICE 'Starting migration of % pharmacy_inventory records to pharmacy_products...', total_count;

    -- Insert existing medications as products
    WITH inserted AS (
        INSERT INTO pharmacy_products (
            pharmacy_id,
            medication_id,
            product_type,
            name,
            generic_name,
            product_code,
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
            manufacturing_date,
            is_active,
            created_at,
            updated_at
        )
        SELECT
            pi.pharmacy_id,
            pi.medication_id,
            'medication' as product_type,
            COALESCE(m.brand_name, m.generic_name) as name,
            m.generic_name,
            NULL as product_code,
            pi.batch_number as sku,
            pi.unit_price as price,
            pi.quantity_available as quantity_in_stock,
            pi.reorder_level,
            m.strength as dosage_strength,
            m.dosage_form,
            m.route_of_administration,
            m.requires_prescription,
            m.is_controlled_substance,
            m.manufacturer,
            pi.batch_number,
            pi.expiry_date,
            NULL as manufacturing_date,  -- Not in pharmacy_inventory
            pi.is_available as is_active,
            pi.date_received as created_at,
            NOW() as updated_at
        FROM pharmacy_inventory pi
        JOIN medications m ON pi.medication_id = m.id
        WHERE NOT EXISTS (
            -- Skip if already migrated (same pharmacy, medication, and batch)
            SELECT 1 FROM pharmacy_products pp
            WHERE pp.pharmacy_id = pi.pharmacy_id
            AND pp.medication_id = pi.medication_id
            AND (pp.batch_number = pi.batch_number OR (pp.batch_number IS NULL AND pi.batch_number IS NULL))
        )
        ON CONFLICT DO NOTHING
        RETURNING id
    )
    SELECT COUNT(*) INTO migrated_count FROM inserted;

    -- Count skipped records
    SELECT total_count - migrated_count INTO skipped_count;

    RAISE NOTICE 'Migration completed:';
    RAISE NOTICE '  - Total inventory records: %', total_count;
    RAISE NOTICE '  - Migrated to pharmacy_products: %', migrated_count;
    RAISE NOTICE '  - Skipped (already exist): %', skipped_count;

    -- Verify sync triggers are working
    RAISE NOTICE 'Verifying bidirectional sync triggers...';

    -- Check if triggers exist
    IF EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'sync_to_inventory'
        AND tgrelid = 'pharmacy_products'::regclass
    ) THEN
        RAISE NOTICE '  ✓ Trigger sync_to_inventory exists';
    ELSE
        RAISE WARNING '  ✗ Trigger sync_to_inventory NOT FOUND - inventory sync may not work!';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'sync_from_inventory'
        AND tgrelid = 'pharmacy_inventory'::regclass
    ) THEN
        RAISE NOTICE '  ✓ Trigger sync_from_inventory exists';
    ELSE
        RAISE WARNING '  ✗ Trigger sync_from_inventory NOT FOUND - inventory sync may not work!';
    END IF;

    RAISE NOTICE 'Data migration completed successfully!';
END $$;

-- ============================================
-- VERIFY MIGRATION
-- ============================================

DO $$
DECLARE
    inventory_count INTEGER;
    products_count INTEGER;
    medication_products_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO inventory_count FROM pharmacy_inventory;
    SELECT COUNT(*) INTO products_count FROM pharmacy_products;
    SELECT COUNT(*) INTO medication_products_count FROM pharmacy_products WHERE product_type = 'medication';

    RAISE NOTICE '';
    RAISE NOTICE '=== POST-MIGRATION VERIFICATION ===';
    RAISE NOTICE 'pharmacy_inventory records: %', inventory_count;
    RAISE NOTICE 'pharmacy_products records: %', products_count;
    RAISE NOTICE 'medication-type products: %', medication_products_count;

    IF medication_products_count >= inventory_count THEN
        RAISE NOTICE '✓ Migration verification PASSED - medication products >= inventory records';
    ELSE
        RAISE WARNING '✗ Migration verification FAILED - medication products (%) < inventory records (%)', medication_products_count, inventory_count;
    END IF;
END $$;

-- ============================================
-- OPTIONAL: QUERY TO CHECK FOR ANY UNMIGRATED RECORDS
-- This helps identify any records that couldn't be migrated
-- ============================================

DO $$
DECLARE
    unmigrated_count INTEGER;
    rec RECORD;
BEGIN
    SELECT COUNT(*) INTO unmigrated_count
    FROM pharmacy_inventory pi
    WHERE NOT EXISTS (
        SELECT 1 FROM pharmacy_products pp
        WHERE pp.pharmacy_id = pi.pharmacy_id
        AND pp.medication_id = pi.medication_id
        AND (pp.batch_number = pi.batch_number OR (pp.batch_number IS NULL AND pi.batch_number IS NULL))
    );

    IF unmigrated_count > 0 THEN
        RAISE WARNING 'Found % unmigrated inventory records. Check for missing medication references.', unmigrated_count;

        -- Show details of unmigrated records
        RAISE NOTICE '';
        RAISE NOTICE 'Unmigrated records (medication_id, pharmacy_id, batch_number):';
        FOR rec IN (
            SELECT pi.medication_id, pi.pharmacy_id, pi.batch_number
            FROM pharmacy_inventory pi
            WHERE NOT EXISTS (
                SELECT 1 FROM pharmacy_products pp
                WHERE pp.pharmacy_id = pi.pharmacy_id
                AND pp.medication_id = pi.medication_id
                AND (pp.batch_number = pi.batch_number OR (pp.batch_number IS NULL AND pi.batch_number IS NULL))
            )
            LIMIT 10
        ) LOOP
            RAISE NOTICE '  - medication_id: %, pharmacy_id: %, batch: %',
                rec.medication_id, rec.pharmacy_id, COALESCE(rec.batch_number, 'NULL');
        END LOOP;

        IF unmigrated_count > 10 THEN
            RAISE NOTICE '  ... and % more', unmigrated_count - 10;
        END IF;
    ELSE
        RAISE NOTICE '✓ All inventory records migrated successfully';
    END IF;
END $$;

-- ============================================
-- END OF MIGRATION: Part 7 Data Migration
-- ============================================
