-- =====================================================
-- CONSOLIDATED PHARMACY MIGRATIONS
-- =====================================================
-- This file combines all pharmacy e-commerce migrations
-- for manual application through Supabase Dashboard
-- =====================================================


-- =====================================================
-- SOURCE: 20260112140000_add_pharmacy_tables.sql
-- =====================================================

-- =====================================================
-- PHARMACY SYSTEM TABLES
-- =====================================================
-- This migration adds comprehensive pharmacy functionality
-- including pharmacies, medications, prescriptions, inventory,
-- and dispensing tracking.
-- =====================================================

-- =====================================================
-- PHARMACIES TABLE
-- =====================================================
-- Stores pharmacy locations and details
CREATE TABLE IF NOT EXISTS pharmacies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    license_number TEXT UNIQUE NOT NULL,
    phone_number TEXT,
    email TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Cameroon',
    location GEOGRAPHY(Point, 4326), -- PostGIS for location-based searches
    lat NUMERIC(10, 8),
    lng NUMERIC(11, 8),
    operating_hours JSONB, -- {"monday": "08:00-20:00", "tuesday": "08:00-20:00", ...}
    is_24_hours BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    facility_id UUID REFERENCES facilities(id) ON DELETE SET NULL, -- Link to existing facility if applicable
    manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- MEDICATIONS TABLE
-- =====================================================
-- Master list of medications/drugs
CREATE TABLE IF NOT EXISTS medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generic_name TEXT NOT NULL,
    brand_name TEXT,
    drug_class TEXT, -- e.g., "Antibiotic", "Analgesic", "Antihypertensive"
    active_ingredients TEXT[], -- Array of active ingredients
    strength TEXT, -- e.g., "500mg", "10mg/ml"
    dosage_form TEXT, -- e.g., "Tablet", "Capsule", "Syrup", "Injection"
    route_of_administration TEXT, -- e.g., "Oral", "IV", "Topical"
    manufacturer TEXT,
    description TEXT,
    indications TEXT, -- What it's used for
    contraindications TEXT, -- When not to use
    side_effects TEXT[],
    requires_prescription BOOLEAN DEFAULT true,
    is_controlled_substance BOOLEAN DEFAULT false,
    storage_requirements TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_medication UNIQUE(generic_name, brand_name, strength, dosage_form)
);

-- =====================================================
-- PRESCRIPTIONS TABLE
-- =====================================================
-- Medical prescriptions from providers
CREATE TABLE IF NOT EXISTS prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_number TEXT UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    clinical_note_id UUID REFERENCES clinical_notes(id) ON DELETE SET NULL,
    diagnosis TEXT,
    prescription_date TIMESTAMPTZ DEFAULT NOW(),
    expiry_date TIMESTAMPTZ, -- Prescriptions typically expire after 6-12 months
    status TEXT DEFAULT 'pending', -- pending, partially_filled, filled, expired, cancelled
    notes TEXT,
    is_refillable BOOLEAN DEFAULT false,
    refills_remaining INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'partially_filled', 'filled', 'expired', 'cancelled'))
);

-- =====================================================
-- PRESCRIPTION ITEMS TABLE
-- =====================================================
-- Individual medications on a prescription
CREATE TABLE IF NOT EXISTS prescription_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    dosage TEXT NOT NULL, -- e.g., "1 tablet", "5ml"
    frequency TEXT NOT NULL, -- e.g., "twice daily", "every 6 hours"
    duration TEXT, -- e.g., "7 days", "2 weeks"
    special_instructions TEXT,
    substitution_allowed BOOLEAN DEFAULT true,
    is_dispensed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- PHARMACY INVENTORY TABLE
-- =====================================================
-- Track medication stock at each pharmacy
CREATE TABLE IF NOT EXISTS pharmacy_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    batch_number TEXT,
    quantity_available INTEGER NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    reorder_level INTEGER DEFAULT 10, -- Alert when stock falls below this
    unit_price NUMERIC(10, 2),
    expiry_date DATE,
    date_received TIMESTAMPTZ,
    supplier TEXT,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_pharmacy_medication_batch UNIQUE(pharmacy_id, medication_id, batch_number)
);

-- =====================================================
-- DISPENSED MEDICATIONS TABLE
-- =====================================================
-- Track when medications are dispensed to patients
CREATE TABLE IF NOT EXISTS dispensed_medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    prescription_item_id UUID NOT NULL REFERENCES prescription_items(id) ON DELETE CASCADE,
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE RESTRICT,
    inventory_id UUID REFERENCES pharmacy_inventory(id) ON DELETE SET NULL,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pharmacist_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    quantity_dispensed INTEGER NOT NULL CHECK (quantity_dispensed > 0),
    unit_price NUMERIC(10, 2),
    total_price NUMERIC(10, 2),
    dispensed_at TIMESTAMPTZ DEFAULT NOW(),
    payment_status TEXT DEFAULT 'pending', -- pending, paid, insurance_pending
    payment_method TEXT, -- cash, insurance, mobile_money
    insurance_claim_number TEXT,
    patient_counseled BOOLEAN DEFAULT false,
    counseling_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_payment_status CHECK (payment_status IN ('pending', 'paid', 'insurance_pending', 'insurance_paid'))
);

-- =====================================================
-- DRUG INTERACTIONS TABLE
-- =====================================================
-- Track known drug interactions for safety
CREATE TABLE IF NOT EXISTS drug_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medication_a_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    medication_b_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    severity TEXT NOT NULL, -- mild, moderate, severe
    interaction_type TEXT, -- e.g., "pharmacokinetic", "pharmacodynamic"
    description TEXT NOT NULL,
    clinical_management TEXT, -- How to manage this interaction
    reference_source TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_medications CHECK (medication_a_id != medication_b_id),
    CONSTRAINT unique_interaction UNIQUE(medication_a_id, medication_b_id),
    CONSTRAINT valid_severity CHECK (severity IN ('mild', 'moderate', 'severe'))
);

-- =====================================================
-- PHARMACY STAFF TABLE
-- =====================================================
-- Track pharmacy staff roles and credentials
CREATE TABLE IF NOT EXISTS pharmacy_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    role TEXT NOT NULL, -- pharmacist, pharmacy_technician, pharmacy_assistant
    license_number TEXT,
    license_expiry DATE,
    is_active BOOLEAN DEFAULT true,
    hire_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_pharmacy UNIQUE(user_id, pharmacy_id),
    CONSTRAINT valid_role CHECK (role IN ('pharmacist', 'pharmacy_technician', 'pharmacy_assistant'))
);

-- =====================================================
-- MEDICATION REFILL REQUESTS TABLE
-- =====================================================
-- Patients can request prescription refills
CREATE TABLE IF NOT EXISTS medication_refill_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pharmacy_id UUID REFERENCES pharmacies(id) ON DELETE SET NULL,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending', -- pending, approved, rejected, completed
    pharmacist_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_refill_status CHECK (status IN ('pending', 'approved', 'rejected', 'completed'))
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Pharmacies
CREATE INDEX idx_pharmacies_location ON pharmacies USING GIST(location);
CREATE INDEX idx_pharmacies_facility ON pharmacies(facility_id);
CREATE INDEX idx_pharmacies_active ON pharmacies(is_active);
CREATE INDEX idx_pharmacies_city ON pharmacies(city);

-- Medications
CREATE INDEX idx_medications_generic_name ON medications(generic_name);
CREATE INDEX idx_medications_brand_name ON medications(brand_name);
CREATE INDEX idx_medications_drug_class ON medications(drug_class);
CREATE INDEX idx_medications_active ON medications(is_active);

-- Prescriptions
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_provider ON prescriptions(provider_id);
CREATE INDEX idx_prescriptions_appointment ON prescriptions(appointment_id);
CREATE INDEX idx_prescriptions_status ON prescriptions(status);
CREATE INDEX idx_prescriptions_date ON prescriptions(prescription_date);
CREATE INDEX idx_prescriptions_number ON prescriptions(prescription_number);

-- Prescription Items
CREATE INDEX idx_prescription_items_prescription ON prescription_items(prescription_id);
CREATE INDEX idx_prescription_items_medication ON prescription_items(medication_id);
CREATE INDEX idx_prescription_items_dispensed ON prescription_items(is_dispensed);

-- Pharmacy Inventory
CREATE INDEX idx_inventory_pharmacy ON pharmacy_inventory(pharmacy_id);
CREATE INDEX idx_inventory_medication ON pharmacy_inventory(medication_id);
CREATE INDEX idx_inventory_expiry ON pharmacy_inventory(expiry_date);
CREATE INDEX idx_inventory_available ON pharmacy_inventory(is_available);

-- Dispensed Medications
CREATE INDEX idx_dispensed_prescription ON dispensed_medications(prescription_id);
CREATE INDEX idx_dispensed_patient ON dispensed_medications(patient_id);
CREATE INDEX idx_dispensed_pharmacy ON dispensed_medications(pharmacy_id);
CREATE INDEX idx_dispensed_pharmacist ON dispensed_medications(pharmacist_id);
CREATE INDEX idx_dispensed_date ON dispensed_medications(dispensed_at);

-- Pharmacy Staff
CREATE INDEX idx_pharmacy_staff_user ON pharmacy_staff(user_id);
CREATE INDEX idx_pharmacy_staff_pharmacy ON pharmacy_staff(pharmacy_id);
CREATE INDEX idx_pharmacy_staff_role ON pharmacy_staff(role);

-- Refill Requests
CREATE INDEX idx_refill_prescription ON medication_refill_requests(prescription_id);
CREATE INDEX idx_refill_patient ON medication_refill_requests(patient_id);
CREATE INDEX idx_refill_pharmacy ON medication_refill_requests(pharmacy_id);
CREATE INDEX idx_refill_status ON medication_refill_requests(status);

-- =====================================================
-- RLS POLICIES (Firebase Auth Pattern)
-- =====================================================
-- All policies allow auth.uid() IS NULL for Firebase Auth

ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispensed_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE drug_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_refill_requests ENABLE ROW LEVEL SECURITY;

-- Pharmacies: Public read, pharmacy staff can update their pharmacy
CREATE POLICY "Anyone can view active pharmacies"
    ON pharmacies FOR SELECT
    USING (is_active = true OR auth.uid() IS NULL);

CREATE POLICY "Pharmacy staff can update their pharmacy"
    ON pharmacies FOR UPDATE
    USING (
        auth.uid() IS NULL OR
        id IN (SELECT pharmacy_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()))
    );

-- Medications: Public read for reference
CREATE POLICY "Anyone can view active medications"
    ON medications FOR SELECT
    USING (is_active = true OR auth.uid() IS NULL);

-- Prescriptions: Patients and providers can view their own, pharmacies can view for dispensing
CREATE POLICY "Users can view their own prescriptions"
    ON prescriptions FOR SELECT
    USING (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()) OR
        provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
    );

CREATE POLICY "Providers can create prescriptions"
    ON prescriptions FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
    );

CREATE POLICY "Providers can update their prescriptions"
    ON prescriptions FOR UPDATE
    USING (
        auth.uid() IS NULL OR
        provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
    );

-- Prescription Items: Follow prescription access
CREATE POLICY "Users can view prescription items for their prescriptions"
    ON prescription_items FOR SELECT
    USING (
        auth.uid() IS NULL OR
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
                OR provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
        )
    );

CREATE POLICY "Providers can insert prescription items"
    ON prescription_items FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
        )
    );

-- Pharmacy Inventory: Pharmacy staff can manage, public can view availability
CREATE POLICY "Anyone can view available inventory"
    ON pharmacy_inventory FOR SELECT
    USING (is_available = true OR auth.uid() IS NULL);

CREATE POLICY "Pharmacy staff can manage inventory"
    ON pharmacy_inventory FOR ALL
    USING (
        auth.uid() IS NULL OR
        pharmacy_id IN (SELECT pharmacy_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()))
    );

-- Dispensed Medications: Patients, pharmacists, and prescribers can view
CREATE POLICY "Users can view their dispensed medications"
    ON dispensed_medications FOR SELECT
    USING (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()) OR
        pharmacist_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()) OR
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
        )
    );

CREATE POLICY "Pharmacists can dispense medications"
    ON dispensed_medications FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        pharmacist_id IN (SELECT user_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()))
    );

-- Drug Interactions: Public read for safety
CREATE POLICY "Anyone can view drug interactions"
    ON drug_interactions FOR SELECT
    USING (auth.uid() IS NULL OR true);

-- Pharmacy Staff: Staff can view their own records
CREATE POLICY "Users can view their pharmacy staff records"
    ON pharmacy_staff FOR SELECT
    USING (
        auth.uid() IS NULL OR
        user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
    );

-- Refill Requests: Patients create, pharmacists manage
CREATE POLICY "Patients can create refill requests"
    ON medication_refill_requests FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
    );

CREATE POLICY "Users can view their refill requests"
    ON medication_refill_requests FOR SELECT
    USING (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()) OR
        pharmacist_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid())
    );

CREATE POLICY "Pharmacists can update refill requests"
    ON medication_refill_requests FOR UPDATE
    USING (
        auth.uid() IS NULL OR
        pharmacy_id IN (SELECT pharmacy_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()))
    );

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pharmacies_updated_at BEFORE UPDATE ON pharmacies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prescriptions_updated_at BEFORE UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prescription_items_updated_at BEFORE UPDATE ON prescription_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pharmacy_inventory_updated_at BEFORE UPDATE ON pharmacy_inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drug_interactions_updated_at BEFORE UPDATE ON drug_interactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pharmacy_staff_updated_at BEFORE UPDATE ON pharmacy_staff
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_refill_requests_updated_at BEFORE UPDATE ON medication_refill_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get nearby pharmacies (similar to getNearbyFacilities)
CREATE OR REPLACE FUNCTION get_nearby_pharmacies(
    user_lat NUMERIC,
    user_lng NUMERIC,
    radius_km NUMERIC DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone_number TEXT,
    address TEXT,
    city TEXT,
    is_24_hours BOOLEAN,
    distance_km NUMERIC,
    lat NUMERIC,
    lng NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.phone_number,
        p.address,
        p.city,
        p.is_24_hours,
        ROUND(
            (6371 * acos(
                cos(radians(user_lat)) *
                cos(radians(p.lat)) *
                cos(radians(p.lng) - radians(user_lng)) +
                sin(radians(user_lat)) *
                sin(radians(p.lat))
            ))::numeric,
            2
        ) AS distance_km,
        p.lat,
        p.lng
    FROM pharmacies p
    WHERE
        p.is_active = true
        AND p.lat IS NOT NULL
        AND p.lng IS NOT NULL
        AND (
            6371 * acos(
                cos(radians(user_lat)) *
                cos(radians(p.lat)) *
                cos(radians(p.lng) - radians(user_lng)) +
                sin(radians(user_lat)) *
                sin(radians(p.lat))
            )
        ) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check medication stock across pharmacies
CREATE OR REPLACE FUNCTION check_medication_availability(
    medication_uuid UUID,
    user_lat NUMERIC DEFAULT NULL,
    user_lng NUMERIC DEFAULT NULL,
    radius_km NUMERIC DEFAULT 50
)
RETURNS TABLE (
    pharmacy_id UUID,
    pharmacy_name TEXT,
    quantity_available INTEGER,
    unit_price NUMERIC,
    distance_km NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        pi.quantity_available,
        pi.unit_price,
        CASE
            WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
                ROUND(
                    (6371 * acos(
                        cos(radians(user_lat)) *
                        cos(radians(p.lat)) *
                        cos(radians(p.lng) - radians(user_lng)) +
                        sin(radians(user_lat)) *
                        sin(radians(p.lat))
                    ))::numeric,
                    2
                )
            ELSE NULL
        END AS distance_km
    FROM pharmacy_inventory pi
    JOIN pharmacies p ON pi.pharmacy_id = p.id
    WHERE
        pi.medication_id = medication_uuid
        AND pi.is_available = true
        AND pi.quantity_available > 0
        AND p.is_active = true
        AND (
            user_lat IS NULL OR user_lng IS NULL OR
            (
                6371 * acos(
                    cos(radians(user_lat)) *
                    cos(radians(p.lat)) *
                    cos(radians(p.lng) - radians(user_lng)) +
                    sin(radians(user_lat)) *
                    sin(radians(p.lat))
                )
            ) <= radius_km
        )
    ORDER BY
        CASE
            WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN distance_km
            ELSE pi.quantity_available
        END DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE pharmacies IS 'Pharmacy locations and facilities';
COMMENT ON TABLE medications IS 'Master medication/drug database';
COMMENT ON TABLE prescriptions IS 'Medical prescriptions from providers';
COMMENT ON TABLE prescription_items IS 'Individual medications on prescriptions';
COMMENT ON TABLE pharmacy_inventory IS 'Medication stock levels at pharmacies';
COMMENT ON TABLE dispensed_medications IS 'Record of dispensed medications to patients';
COMMENT ON TABLE drug_interactions IS 'Known drug-drug interactions for safety';
COMMENT ON TABLE pharmacy_staff IS 'Pharmacy staff roles and credentials';
COMMENT ON TABLE medication_refill_requests IS 'Patient requests for prescription refills';

COMMENT ON FUNCTION get_nearby_pharmacies IS 'Find pharmacies within specified radius using Haversine formula';
COMMENT ON FUNCTION check_medication_availability IS 'Check medication stock availability across pharmacies';


-- =====================================================
-- SOURCE: 20260112141000_fix_pharmacy_schema.sql
-- =====================================================

-- =====================================================
-- FIX PHARMACY SCHEMA
-- =====================================================
-- This migration adds missing columns to existing
-- medications and prescriptions tables to match
-- the expected schema from 20260112140000
-- =====================================================

-- =====================================================
-- MEDICATIONS TABLE: Add missing columns
-- =====================================================

-- Add brand_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'brand_name'
    ) THEN
        ALTER TABLE medications ADD COLUMN brand_name TEXT;
        RAISE NOTICE 'Added brand_name column to medications table';
    ELSE
        RAISE NOTICE 'brand_name column already exists in medications table';
    END IF;
END $$;

-- Add drug_class column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'drug_class'
    ) THEN
        ALTER TABLE medications ADD COLUMN drug_class TEXT;
        RAISE NOTICE 'Added drug_class column to medications table';
    END IF;
END $$;

-- Add active_ingredients column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'active_ingredients'
    ) THEN
        ALTER TABLE medications ADD COLUMN active_ingredients TEXT[];
        RAISE NOTICE 'Added active_ingredients column to medications table';
    END IF;
END $$;

-- Add strength column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'strength'
    ) THEN
        ALTER TABLE medications ADD COLUMN strength TEXT;
        RAISE NOTICE 'Added strength column to medications table';
    END IF;
END $$;

-- Add dosage_form column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'dosage_form'
    ) THEN
        ALTER TABLE medications ADD COLUMN dosage_form TEXT;
        RAISE NOTICE 'Added dosage_form column to medications table';
    END IF;
END $$;

-- Add route_of_administration column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'route_of_administration'
    ) THEN
        ALTER TABLE medications ADD COLUMN route_of_administration TEXT;
        RAISE NOTICE 'Added route_of_administration column to medications table';
    END IF;
END $$;

-- Add manufacturer column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'manufacturer'
    ) THEN
        ALTER TABLE medications ADD COLUMN manufacturer TEXT;
        RAISE NOTICE 'Added manufacturer column to medications table';
    END IF;
END $$;

-- Add description column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'description'
    ) THEN
        ALTER TABLE medications ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to medications table';
    END IF;
END $$;

-- Add side_effects column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'side_effects'
    ) THEN
        ALTER TABLE medications ADD COLUMN side_effects TEXT;
        RAISE NOTICE 'Added side_effects column to medications table';
    END IF;
END $$;

-- Add warnings column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'warnings'
    ) THEN
        ALTER TABLE medications ADD COLUMN warnings TEXT;
        RAISE NOTICE 'Added warnings column to medications table';
    END IF;
END $$;

-- Add requires_prescription column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'requires_prescription'
    ) THEN
        ALTER TABLE medications ADD COLUMN requires_prescription BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added requires_prescription column to medications table';
    END IF;
END $$;

-- Add is_generic column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'is_generic'
    ) THEN
        ALTER TABLE medications ADD COLUMN is_generic BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added is_generic column to medications table';
    END IF;
END $$;

-- Add ndc_code column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'ndc_code'
    ) THEN
        ALTER TABLE medications ADD COLUMN ndc_code TEXT;
        RAISE NOTICE 'Added ndc_code column to medications table';
    END IF;
END $$;

-- Add storage_conditions column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'storage_conditions'
    ) THEN
        ALTER TABLE medications ADD COLUMN storage_conditions TEXT;
        RAISE NOTICE 'Added storage_conditions column to medications table';
    END IF;
END $$;

-- Add is_active column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE medications ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added is_active column to medications table';
    END IF;
END $$;

-- Add timestamps if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE medications ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to medications table';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE medications ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to medications table';
    END IF;
END $$;

-- =====================================================
-- PRESCRIPTIONS TABLE: Add missing columns if needed
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'prescriptions' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE prescriptions ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to prescriptions table';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'prescriptions' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE prescriptions ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to prescriptions table';
    END IF;
END $$;

RAISE NOTICE 'Schema fix migration completed successfully';


-- =====================================================
-- SOURCE: 20260113000000_add_pharmacy_ecommerce_part1_base_tables.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000100_add_pharmacy_ecommerce_part2_dependent_tables.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000200_add_pharmacy_ecommerce_indexes.sql
-- =====================================================

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
    ON pharmacy_products(pharmacy_id, expiry_date)
    WHERE expiry_date < CURRENT_DATE;

CREATE INDEX IF NOT EXISTS idx_pharmacy_products_expiring_soon
    ON pharmacy_products(pharmacy_id, expiry_date)
    WHERE expiry_date >= CURRENT_DATE AND expiry_date < CURRENT_DATE + INTERVAL '30 days';

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
    ON pharmacy_coupons(code)
    WHERE is_active = true
      AND (valid_from IS NULL OR valid_from <= NOW())
      AND (valid_until IS NULL OR valid_until >= NOW());

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


-- =====================================================
-- SOURCE: 20260113000300_add_pharmacy_ecommerce_functions_triggers.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000400_add_pharmacy_ecommerce_views_part1.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000401_add_pharmacy_ecommerce_views_part2.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000500_add_pharmacy_ecommerce_rls_policies_part1.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000501_add_pharmacy_ecommerce_rls_policies_part2.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000600_migrate_pharmacy_inventory_data.sql
-- =====================================================

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


-- =====================================================
-- SOURCE: 20260113000700_seed_pharmacy_ecommerce_data.sql
-- =====================================================

-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 8: Seed Data
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Seed initial data for pharmacy e-commerce
--              - 15 product categories
--              - 16+ product subcategories
--              - 3 test coupons
-- ============================================

-- ============================================
-- SEED: Product Categories (15 categories)
-- ============================================

INSERT INTO product_categories (name, description, image_url, display_order, is_active) VALUES
('Antibiotics', 'Medications that fight bacterial infections', 'https://placehold.co/200x200?text=Antibiotics', 1, true),
('Pain Relief', 'Pain relievers and anti-inflammatory medications', 'https://placehold.co/200x200?text=Pain+Relief', 2, true),
('Vitamins & Supplements', 'Vitamins, minerals, and dietary supplements', 'https://placehold.co/200x200?text=Vitamins', 3, true),
('Cardiovascular', 'Heart and blood pressure medications', 'https://placehold.co/200x200?text=Cardiovascular', 4, true),
('Diabetes', 'Diabetes management medications', 'https://placehold.co/200x200?text=Diabetes', 5, true),
('Skin Care', 'Dermatological products and skin treatments', 'https://placehold.co/200x200?text=Skin+Care', 6, true),
('First Aid', 'First aid supplies and wound care', 'https://placehold.co/200x200?text=First+Aid', 7, true),
('Baby & Child Care', 'Products for infants and children', 'https://placehold.co/200x200?text=Baby+Care', 8, true),
('Personal Care', 'Personal hygiene and care products', 'https://placehold.co/200x200?text=Personal+Care', 9, true),
('Respiratory', 'Cough, cold, and respiratory medications', 'https://placehold.co/200x200?text=Respiratory', 10, true),
('Digestive Health', 'Antacids, laxatives, and digestive aids', 'https://placehold.co/200x200?text=Digestive', 11, true),
('Eye & Ear Care', 'Eye drops, ear drops, and related products', 'https://placehold.co/200x200?text=Eye+Ear', 12, true),
('Women''s Health', 'Women''s health and feminine care products', 'https://placehold.co/200x200?text=Womens+Health', 13, true),
('Men''s Health', 'Men''s health products', 'https://placehold.co/200x200?text=Mens+Health', 14, true),
('Detox & Cleanse', 'Detoxification and cleansing products', 'https://placehold.co/200x200?text=Detox', 15, true)
ON CONFLICT DO NOTHING;

-- Log result
DO $$
DECLARE
    category_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO category_count FROM product_categories;
    RAISE NOTICE '✓ Seeded product categories. Total categories: %', category_count;
END $$;

-- ============================================
-- SEED: Product Subcategories (16+ subcategories)
-- ============================================

WITH categories AS (
    SELECT id, name FROM product_categories
)
INSERT INTO product_subcategories (category_id, name, description, display_order, is_active)
SELECT c.id, sub.name, sub.description, sub.display_order, true
FROM categories c
CROSS JOIN LATERAL (
    VALUES
    -- Antibiotics subcategories
    ('Antibiotics', 'Penicillins', 'Penicillin-based antibiotics', 1),
    ('Antibiotics', 'Cephalosporins', 'Cephalosporin antibiotics', 2),
    ('Antibiotics', 'Macrolides', 'Macrolide antibiotics', 3),
    ('Antibiotics', 'Fluoroquinolones', 'Fluoroquinolone antibiotics', 4),

    -- Pain Relief subcategories
    ('Pain Relief', 'Analgesics', 'Pain relievers', 1),
    ('Pain Relief', 'Anti-inflammatory', 'NSAIDs and anti-inflammatory drugs', 2),
    ('Pain Relief', 'Muscle Relaxants', 'Muscle relaxant medications', 3),

    -- Vitamins & Supplements subcategories
    ('Vitamins & Supplements', 'Multivitamins', 'Complete vitamin formulations', 1),
    ('Vitamins & Supplements', 'Vitamin C', 'Vitamin C supplements', 2),
    ('Vitamins & Supplements', 'Vitamin D', 'Vitamin D supplements', 3),
    ('Vitamins & Supplements', 'Iron Supplements', 'Iron and ferrous supplements', 4),
    ('Vitamins & Supplements', 'Calcium', 'Calcium supplements', 5),

    -- Respiratory subcategories
    ('Respiratory', 'Cough Syrups', 'Cough relief medications', 1),
    ('Respiratory', 'Decongestants', 'Nasal and sinus decongestants', 2),
    ('Respiratory', 'Antihistamines', 'Allergy relief medications', 3),
    ('Respiratory', 'Inhalers', 'Respiratory inhalers', 4)
) AS sub(category_name, name, description, display_order)
WHERE c.name = sub.category_name
ON CONFLICT DO NOTHING;

-- Log result
DO $$
DECLARE
    subcategory_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO subcategory_count FROM product_subcategories;
    RAISE NOTICE '✓ Seeded product subcategories. Total subcategories: %', subcategory_count;
END $$;

-- ============================================
-- SEED: Test Coupons (3 global coupons)
-- Note: pharmacy_id is NULL for global coupons
-- ============================================

INSERT INTO pharmacy_coupons (
    pharmacy_id,  -- NULL = global coupon for all pharmacies
    code,
    description,
    discount_type,
    discount_value,
    min_order_amount,
    max_discount_amount,
    usage_limit,
    per_user_limit,
    valid_from,
    valid_until,
    is_active,
    is_first_order_only
) VALUES
(
    NULL,  -- Global coupon
    'WELCOME10',
    'Welcome discount - 10% off your first order',
    'percentage',
    10,
    5000,
    2000,
    NULL,  -- Unlimited total uses
    1,     -- Once per user
    NOW(),
    NOW() + INTERVAL '1 year',
    true,
    true   -- First order only
),
(
    NULL,  -- Global coupon
    'SAVE500',
    'Flat 500 XAF off orders above 3000 XAF',
    'fixed_amount',
    500,
    3000,
    NULL,
    1000,  -- Limited to 1000 total uses
    3,     -- Up to 3 times per user
    NOW(),
    NOW() + INTERVAL '6 months',
    true,
    false
),
(
    NULL,  -- Global coupon
    'MEDZEN20',
    'Special 20% discount for MedZen users',
    'percentage',
    20,
    10000,
    5000,
    500,   -- Limited to 500 total uses
    1,     -- Once per user
    NOW(),
    NOW() + INTERVAL '3 months',
    true,
    false
)
ON CONFLICT (code) DO NOTHING;

-- Log result
DO $$
DECLARE
    coupon_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO coupon_count FROM pharmacy_coupons;
    RAISE NOTICE '✓ Seeded test coupons. Total coupons: %', coupon_count;
END $$;

-- ============================================
-- VERIFICATION: Show Seeded Data Summary
-- ============================================

DO $$
DECLARE
    category_count INTEGER;
    subcategory_count INTEGER;
    coupon_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO category_count FROM product_categories;
    SELECT COUNT(*) INTO subcategory_count FROM product_subcategories;
    SELECT COUNT(*) INTO coupon_count FROM pharmacy_coupons;

    RAISE NOTICE '';
    RAISE NOTICE '=== SEED DATA SUMMARY ===';
    RAISE NOTICE 'Product Categories: %', category_count;
    RAISE NOTICE 'Product Subcategories: %', subcategory_count;
    RAISE NOTICE 'Pharmacy Coupons: %', coupon_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Available coupons:';
    RAISE NOTICE '  - WELCOME10: 10%% off first order (min 5000 XAF)';
    RAISE NOTICE '  - SAVE500: 500 XAF off (min 3000 XAF)';
    RAISE NOTICE '  - MEDZEN20: 20%% off (min 10000 XAF, max 5000 XAF discount)';
END $$;

-- ============================================
-- END OF MIGRATION: Part 8 Seed Data
-- ============================================


-- =====================================================
-- SOURCE: 20260113000800_verify_pharmacy_ecommerce.sql
-- =====================================================

-- ============================================
-- MIGRATION: Pharmacy E-Commerce - Part 9: Verification
-- Author: MedZen Development Team
-- Date: January 13, 2026
-- Description: Comprehensive verification of pharmacy e-commerce installation
--              Verifies:
--              - 12 tables exist
--              - 12 views exist
--              - 10 functions exist
--              - 10 triggers exist
--              - 50+ indexes exist
--              - RLS enabled on all tables
--              - 30+ RLS policies exist
--              - Seed data loaded
-- ============================================

-- ============================================
-- VERIFICATION 1: Tables
-- Expected: 12 tables
-- ============================================

DO $$
DECLARE
    table_count INTEGER;
    expected_tables TEXT[] := ARRAY[
        'product_categories',
        'product_subcategories',
        'pharmacy_products',
        'user_cart',
        'user_wishlist',
        'user_addresses',
        'pharmacy_orders',
        'pharmacy_order_items',
        'product_reviews',
        'order_tracking',
        'pharmacy_coupons',
        'coupon_usage'
    ];
    missing_tables TEXT[];
BEGIN
    -- Count tables
    SELECT COUNT(*)
    INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = ANY(expected_tables);

    -- Find missing tables
    SELECT ARRAY_AGG(table_name)
    INTO missing_tables
    FROM (
        SELECT unnest(expected_tables) AS table_name
        EXCEPT
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = ANY(expected_tables)
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: TABLES ===';
    RAISE NOTICE 'Expected: 12 tables';
    RAISE NOTICE 'Found: % tables', table_count;

    IF table_count = 12 THEN
        RAISE NOTICE '✓ All tables created successfully';
    ELSE
        RAISE WARNING '✗ Missing tables: %', missing_tables;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 2: Views
-- Expected: 12 views
-- ============================================

DO $$
DECLARE
    view_count INTEGER;
    expected_views TEXT[] := ARRAY[
        'v_pharmacy_products_full',
        'v_user_cart_details',
        'v_user_wishlist_details',
        'v_order_summary',
        'v_order_details_full',
        'v_product_with_reviews',
        'v_pharmacy_inventory',
        'v_pharmacy_dashboard_stats',
        'v_category_product_counts',
        'v_user_order_history',
        'v_pharmacy_inventory_dashboard',
        'v_pharmacy_inventory_full'
    ];
    missing_views TEXT[];
BEGIN
    -- Count views
    SELECT COUNT(*)
    INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public'
    AND table_name = ANY(expected_views);

    -- Find missing views
    SELECT ARRAY_AGG(view_name)
    INTO missing_views
    FROM (
        SELECT unnest(expected_views) AS view_name
        EXCEPT
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'public'
        AND table_name = ANY(expected_views)
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: VIEWS ===';
    RAISE NOTICE 'Expected: 12 views';
    RAISE NOTICE 'Found: % views', view_count;

    IF view_count = 12 THEN
        RAISE NOTICE '✓ All views created successfully';
    ELSE
        RAISE WARNING '✗ Missing views: %', missing_views;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 3: Functions
-- Expected: 10 functions
-- ============================================

DO $$
DECLARE
    function_count INTEGER;
    expected_functions TEXT[] := ARRAY[
        'update_product_search_vector',
        'update_cart_timestamp',
        'ensure_single_default_address',
        'generate_order_number',
        'update_order_status_timestamp',
        'calculate_line_total',
        'update_product_sold_count',
        'update_product_rating',
        'is_pharmacy_admin',
        'sync_pharmacy_inventory'
    ];
    missing_functions TEXT[];
BEGIN
    -- Count functions
    SELECT COUNT(*)
    INTO function_count
    FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND routine_name = ANY(expected_functions)
    AND routine_type = 'FUNCTION';

    -- Find missing functions
    SELECT ARRAY_AGG(func_name)
    INTO missing_functions
    FROM (
        SELECT unnest(expected_functions) AS func_name
        EXCEPT
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND routine_name = ANY(expected_functions)
        AND routine_type = 'FUNCTION'
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: FUNCTIONS ===';
    RAISE NOTICE 'Expected: 10 functions';
    RAISE NOTICE 'Found: % functions', function_count;

    IF function_count = 10 THEN
        RAISE NOTICE '✓ All functions created successfully';
    ELSE
        RAISE WARNING '✗ Missing functions: %', missing_functions;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 4: Triggers
-- Expected: 10 triggers
-- ============================================

DO $$
DECLARE
    trigger_count INTEGER;
    expected_triggers TEXT[] := ARRAY[
        'trigger_update_product_search',
        'trigger_update_cart_timestamp',
        'trigger_single_default_address',
        'trigger_generate_order_number',
        'trigger_update_order_status_timestamp',
        'trigger_calculate_line_total',
        'trigger_update_sold_count',
        'trigger_update_product_rating',
        'sync_to_inventory',
        'sync_from_inventory'
    ];
    missing_triggers TEXT[];
BEGIN
    -- Count triggers
    SELECT COUNT(*)
    INTO trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
    AND trigger_name = ANY(expected_triggers);

    -- Find missing triggers
    SELECT ARRAY_AGG(trigger_name)
    INTO missing_triggers
    FROM (
        SELECT unnest(expected_triggers) AS trigger_name
        EXCEPT
        SELECT trigger_name
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
        AND trigger_name = ANY(expected_triggers)
    ) AS missing;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: TRIGGERS ===';
    RAISE NOTICE 'Expected: 10 triggers';
    RAISE NOTICE 'Found: % triggers', trigger_count;

    IF trigger_count = 10 THEN
        RAISE NOTICE '✓ All triggers created successfully';
    ELSE
        RAISE WARNING '✗ Missing triggers: %', missing_triggers;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 5: Indexes
-- Expected: 50+ indexes
-- ============================================

DO $$
DECLARE
    index_count INTEGER;
    tables_with_indexes RECORD;
BEGIN
    -- Count all pharmacy e-commerce indexes
    SELECT COUNT(*)
    INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage', 'dispensed_medications'
    );

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: INDEXES ===';
    RAISE NOTICE 'Expected: 50+ indexes';
    RAISE NOTICE 'Found: % indexes', index_count;

    IF index_count >= 50 THEN
        RAISE NOTICE '✓ Sufficient indexes created';
    ELSE
        RAISE WARNING '✗ Only % indexes found (expected 50+)', index_count;
    END IF;

    -- Show index count per table
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes per table:';
    FOR tables_with_indexes IN (
        SELECT tablename, COUNT(*) as idx_count
        FROM pg_indexes
        WHERE schemaname = 'public'
        AND indexname LIKE 'idx_%'
        AND tablename IN (
            'product_categories', 'product_subcategories', 'pharmacy_products',
            'user_cart', 'user_wishlist', 'user_addresses',
            'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
            'order_tracking', 'pharmacy_coupons', 'coupon_usage'
        )
        GROUP BY tablename
        ORDER BY tablename
    ) LOOP
        RAISE NOTICE '  - %: % indexes', tables_with_indexes.tablename, tables_with_indexes.idx_count;
    END LOOP;
END $$;

-- ============================================
-- VERIFICATION 6: RLS Enabled
-- Expected: RLS enabled on all 12 tables
-- ============================================

DO $$
DECLARE
    rls_enabled_count INTEGER;
    tables_without_rls TEXT[];
BEGIN
    -- Count tables with RLS enabled
    SELECT COUNT(*)
    INTO rls_enabled_count
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage'
    )
    AND rowsecurity = true;

    -- Find tables without RLS
    SELECT ARRAY_AGG(tablename)
    INTO tables_without_rls
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage'
    )
    AND rowsecurity = false;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: RLS ENABLED ===';
    RAISE NOTICE 'Expected: 12 tables with RLS';
    RAISE NOTICE 'Found: % tables with RLS enabled', rls_enabled_count;

    IF rls_enabled_count = 12 THEN
        RAISE NOTICE '✓ RLS enabled on all tables';
    ELSE
        RAISE WARNING '✗ RLS not enabled on: %', tables_without_rls;
    END IF;
END $$;

-- ============================================
-- VERIFICATION 7: RLS Policies
-- Expected: 30+ policies
-- ============================================

DO $$
DECLARE
    policy_count INTEGER;
    table_policies RECORD;
BEGIN
    -- Count all RLS policies
    SELECT COUNT(*)
    INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN (
        'product_categories', 'product_subcategories', 'pharmacy_products',
        'user_cart', 'user_wishlist', 'user_addresses',
        'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
        'order_tracking', 'pharmacy_coupons', 'coupon_usage'
    );

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: RLS POLICIES ===';
    RAISE NOTICE 'Expected: 30+ policies';
    RAISE NOTICE 'Found: % policies', policy_count;

    IF policy_count >= 30 THEN
        RAISE NOTICE '✓ Sufficient RLS policies created';
    ELSE
        RAISE WARNING '✗ Only % policies found (expected 30+)', policy_count;
    END IF;

    -- Show policy count per table
    RAISE NOTICE '';
    RAISE NOTICE 'Policies per table:';
    FOR table_policies IN (
        SELECT tablename, COUNT(*) as policy_count
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename IN (
            'product_categories', 'product_subcategories', 'pharmacy_products',
            'user_cart', 'user_wishlist', 'user_addresses',
            'pharmacy_orders', 'pharmacy_order_items', 'product_reviews',
            'order_tracking', 'pharmacy_coupons', 'coupon_usage'
        )
        GROUP BY tablename
        ORDER BY tablename
    ) LOOP
        RAISE NOTICE '  - %: % policies', table_policies.tablename, table_policies.policy_count;
    END LOOP;
END $$;

-- ============================================
-- VERIFICATION 8: Seed Data
-- ============================================

DO $$
DECLARE
    category_count INTEGER;
    subcategory_count INTEGER;
    coupon_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO category_count FROM product_categories;
    SELECT COUNT(*) INTO subcategory_count FROM product_subcategories;
    SELECT COUNT(*) INTO coupon_count FROM pharmacy_coupons;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: SEED DATA ===';
    RAISE NOTICE 'Product Categories: %', category_count;
    RAISE NOTICE 'Product Subcategories: %', subcategory_count;
    RAISE NOTICE 'Pharmacy Coupons: %', coupon_count;

    IF category_count >= 15 AND subcategory_count >= 16 AND coupon_count >= 3 THEN
        RAISE NOTICE '✓ Seed data loaded successfully';
    ELSE
        RAISE WARNING '✗ Seed data incomplete (expected: 15+ categories, 16+ subcategories, 3+ coupons)';
    END IF;
END $$;

-- ============================================
-- VERIFICATION 9: Inventory Sync
-- ============================================

DO $$
DECLARE
    inventory_count INTEGER;
    product_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO inventory_count FROM pharmacy_inventory;
    SELECT COUNT(*) INTO product_count FROM pharmacy_products WHERE product_type = 'medication';

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION: INVENTORY SYNC ===';
    RAISE NOTICE 'pharmacy_inventory records: %', inventory_count;
    RAISE NOTICE 'pharmacy_products (medication): %', product_count;

    IF product_count >= inventory_count THEN
        RAISE NOTICE '✓ Inventory migrated successfully';
    ELSE
        RAISE WARNING '✗ Inventory migration incomplete (products: %, inventory: %)', product_count, inventory_count;
    END IF;
END $$;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '   PHARMACY E-COMMERCE VERIFICATION COMPLETE';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Review the output above to ensure all components are installed correctly.';
    RAISE NOTICE '';
    RAISE NOTICE 'Expected Results:';
    RAISE NOTICE '  ✓ 12 tables';
    RAISE NOTICE '  ✓ 12 views';
    RAISE NOTICE '  ✓ 10 functions';
    RAISE NOTICE '  ✓ 10 triggers';
    RAISE NOTICE '  ✓ 50+ indexes';
    RAISE NOTICE '  ✓ RLS enabled on 12 tables';
    RAISE NOTICE '  ✓ 30+ RLS policies';
    RAISE NOTICE '  ✓ Seed data loaded';
    RAISE NOTICE '  ✓ Inventory synced';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Review verification output for any warnings';
    RAISE NOTICE '  2. Test RLS policies with different user roles';
    RAISE NOTICE '  3. Verify inventory sync triggers are working';
    RAISE NOTICE '  4. Create test products and orders';
    RAISE NOTICE '  5. Update CLAUDE.md with new tables';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF MIGRATION: Part 9 Verification
-- ============================================

