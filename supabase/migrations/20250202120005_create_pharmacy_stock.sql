-- Create pharmacy_stock table for inventory management
-- Template: medzen-pharmacy-stock-management.v1

CREATE TABLE pharmacy_stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    updated_by_id UUID REFERENCES medical_provider_profiles(id),

    medication_name VARCHAR(255) NOT NULL,
    medication_code VARCHAR(50),
    strength VARCHAR(100),
    dosage_form VARCHAR(100),

    -- Stock Levels
    current_quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
    unit VARCHAR(50) NOT NULL,
    reorder_level DECIMAL(10,2),
    maximum_stock_level DECIMAL(10,2),

    -- Batch Information
    batch_number VARCHAR(100),
    manufacturer VARCHAR(255),
    manufacturing_date DATE,
    expiry_date DATE,

    -- Location
    storage_location VARCHAR(255),
    temperature_requirement VARCHAR(100),

    -- Cost
    unit_cost DECIMAL(10,2),
    total_value DECIMAL(10,2),

    -- Status
    stock_status VARCHAR(50) DEFAULT 'in_stock', -- 'in_stock', 'low_stock', 'out_of_stock', 'expired'
    last_stock_check_date DATE,

    notes TEXT,

    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_quantity CHECK (current_quantity >= 0)
);

CREATE INDEX idx_pharmacy_stock_facility ON pharmacy_stock(facility_id);
CREATE INDEX idx_pharmacy_stock_medication ON pharmacy_stock(medication_name);
CREATE INDEX idx_pharmacy_stock_status ON pharmacy_stock(stock_status);
CREATE INDEX idx_pharmacy_stock_expiry ON pharmacy_stock(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_pharmacy_stock_ehrbase ON pharmacy_stock(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE pharmacy_stock ENABLE ROW LEVEL SECURITY;

CREATE POLICY "provider_pharmacy_stock_select" ON pharmacy_stock FOR SELECT TO authenticated USING (TRUE); -- All providers can view stock
CREATE POLICY "facility_admin_pharmacy_stock_all" ON pharmacy_stock FOR ALL TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_pharmacy_stock_all" ON pharmacy_stock FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_pharmacy_stock_for_sync() RETURNS TRIGGER AS $$ BEGIN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('pharmacy_stock', NEW.id::TEXT, 'medzen.pharmacy_stock_management.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_pharmacy_stock_sync ON pharmacy_stock;
CREATE TRIGGER trigger_queue_pharmacy_stock_sync AFTER INSERT OR UPDATE ON pharmacy_stock FOR EACH ROW EXECUTE FUNCTION queue_pharmacy_stock_for_sync();
CREATE TRIGGER set_pharmacy_stock_updated_at BEFORE UPDATE ON pharmacy_stock FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
