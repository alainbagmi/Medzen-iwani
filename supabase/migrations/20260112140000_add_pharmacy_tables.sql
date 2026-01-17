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

-- Add missing columns to medications table if it already exists
DO $$
BEGIN
    -- brand_name
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'brand_name') THEN
        ALTER TABLE medications ADD COLUMN brand_name TEXT;
    END IF;

    -- drug_class
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'drug_class') THEN
        ALTER TABLE medications ADD COLUMN drug_class TEXT;
    END IF;

    -- active_ingredients
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'active_ingredients') THEN
        ALTER TABLE medications ADD COLUMN active_ingredients TEXT[];
    END IF;

    -- strength
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'strength') THEN
        ALTER TABLE medications ADD COLUMN strength TEXT;
    END IF;

    -- dosage_form
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'dosage_form') THEN
        ALTER TABLE medications ADD COLUMN dosage_form TEXT;
    END IF;

    -- route_of_administration
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'route_of_administration') THEN
        ALTER TABLE medications ADD COLUMN route_of_administration TEXT;
    END IF;

    -- manufacturer
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'manufacturer') THEN
        ALTER TABLE medications ADD COLUMN manufacturer TEXT;
    END IF;

    -- description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'description') THEN
        ALTER TABLE medications ADD COLUMN description TEXT;
    END IF;

    -- indications
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'indications') THEN
        ALTER TABLE medications ADD COLUMN indications TEXT;
    END IF;

    -- contraindications
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'contraindications') THEN
        ALTER TABLE medications ADD COLUMN contraindications TEXT;
    END IF;

    -- side_effects
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'side_effects') THEN
        ALTER TABLE medications ADD COLUMN side_effects TEXT[];
    END IF;

    -- requires_prescription
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'requires_prescription') THEN
        ALTER TABLE medications ADD COLUMN requires_prescription BOOLEAN DEFAULT true;
    END IF;

    -- storage_requirements
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'storage_requirements') THEN
        ALTER TABLE medications ADD COLUMN storage_requirements TEXT;
    END IF;

    -- is_active
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'is_active') THEN
        ALTER TABLE medications ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;

    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'created_at') THEN
        ALTER TABLE medications ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;

    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'medications' AND column_name = 'updated_at') THEN
        ALTER TABLE medications ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

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

-- Add missing columns to prescriptions table if it already exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'prescription_number') THEN
        ALTER TABLE prescriptions ADD COLUMN prescription_number TEXT UNIQUE NOT NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'patient_id') THEN
        ALTER TABLE prescriptions ADD COLUMN patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'provider_id') THEN
        ALTER TABLE prescriptions ADD COLUMN provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'appointment_id') THEN
        ALTER TABLE prescriptions ADD COLUMN appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'clinical_note_id') THEN
        ALTER TABLE prescriptions ADD COLUMN clinical_note_id UUID REFERENCES clinical_notes(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'diagnosis') THEN
        ALTER TABLE prescriptions ADD COLUMN diagnosis TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'prescription_date') THEN
        ALTER TABLE prescriptions ADD COLUMN prescription_date TIMESTAMPTZ DEFAULT NOW();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'expiry_date') THEN
        ALTER TABLE prescriptions ADD COLUMN expiry_date TIMESTAMPTZ;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'status') THEN
        ALTER TABLE prescriptions ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'notes') THEN
        ALTER TABLE prescriptions ADD COLUMN notes TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'is_refillable') THEN
        ALTER TABLE prescriptions ADD COLUMN is_refillable BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'refills_remaining') THEN
        ALTER TABLE prescriptions ADD COLUMN refills_remaining INTEGER DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'created_at') THEN
        ALTER TABLE prescriptions ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prescriptions' AND column_name = 'updated_at') THEN
        ALTER TABLE prescriptions ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

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
CREATE INDEX IF NOT EXISTS idx_pharmacies_location ON pharmacies USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_pharmacies_facility ON pharmacies(facility_id);
CREATE INDEX IF NOT EXISTS idx_pharmacies_active ON pharmacies(is_active);
CREATE INDEX IF NOT EXISTS idx_pharmacies_city ON pharmacies(city);

-- Medications
CREATE INDEX IF NOT EXISTS idx_medications_generic_name ON medications(generic_name);
CREATE INDEX IF NOT EXISTS idx_medications_brand_name ON medications(brand_name);
CREATE INDEX IF NOT EXISTS idx_medications_drug_class ON medications(drug_class);
CREATE INDEX IF NOT EXISTS idx_medications_active ON medications(is_active);

-- Prescriptions
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_provider ON prescriptions(provider_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_appointment ON prescriptions(appointment_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_status ON prescriptions(status);
CREATE INDEX IF NOT EXISTS idx_prescriptions_date ON prescriptions(prescription_date);
CREATE INDEX IF NOT EXISTS idx_prescriptions_number ON prescriptions(prescription_number);

-- Prescription Items
CREATE INDEX IF NOT EXISTS idx_prescription_items_prescription ON prescription_items(prescription_id);
CREATE INDEX IF NOT EXISTS idx_prescription_items_medication ON prescription_items(medication_id);
CREATE INDEX IF NOT EXISTS idx_prescription_items_dispensed ON prescription_items(is_dispensed);

-- Pharmacy Inventory
CREATE INDEX IF NOT EXISTS idx_inventory_pharmacy ON pharmacy_inventory(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_inventory_medication ON pharmacy_inventory(medication_id);
CREATE INDEX IF NOT EXISTS idx_inventory_expiry ON pharmacy_inventory(expiry_date);
CREATE INDEX IF NOT EXISTS idx_inventory_available ON pharmacy_inventory(is_available);

-- Dispensed Medications
CREATE INDEX IF NOT EXISTS idx_dispensed_prescription ON dispensed_medications(prescription_id);
CREATE INDEX IF NOT EXISTS idx_dispensed_patient ON dispensed_medications(patient_id);
CREATE INDEX IF NOT EXISTS idx_dispensed_pharmacy ON dispensed_medications(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_dispensed_pharmacist ON dispensed_medications(pharmacist_id);
CREATE INDEX IF NOT EXISTS idx_dispensed_date ON dispensed_medications(dispensed_at);

-- Pharmacy Staff
CREATE INDEX IF NOT EXISTS idx_pharmacy_staff_user ON pharmacy_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_pharmacy_staff_pharmacy ON pharmacy_staff(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_pharmacy_staff_role ON pharmacy_staff(role);

-- Refill Requests
CREATE INDEX IF NOT EXISTS idx_refill_prescription ON medication_refill_requests(prescription_id);
CREATE INDEX IF NOT EXISTS idx_refill_patient ON medication_refill_requests(patient_id);
CREATE INDEX IF NOT EXISTS idx_refill_pharmacy ON medication_refill_requests(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_refill_status ON medication_refill_requests(status);

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
        id IN (SELECT pharmacy_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT))
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
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT) OR
        provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
    );

CREATE POLICY "Providers can create prescriptions"
    ON prescriptions FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
    );

CREATE POLICY "Providers can update their prescriptions"
    ON prescriptions FOR UPDATE
    USING (
        auth.uid() IS NULL OR
        provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
    );

-- Prescription Items: Follow prescription access
CREATE POLICY "Users can view prescription items for their prescriptions"
    ON prescription_items FOR SELECT
    USING (
        auth.uid() IS NULL OR
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
                OR provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
        )
    );

CREATE POLICY "Providers can insert prescription items"
    ON prescription_items FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
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
        pharmacy_id IN (SELECT pharmacy_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT))
    );

-- Dispensed Medications: Patients, pharmacists, and prescribers can view
CREATE POLICY "Users can view their dispensed medications"
    ON dispensed_medications FOR SELECT
    USING (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT) OR
        pharmacist_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT) OR
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
        )
    );

CREATE POLICY "Pharmacists can dispense medications"
    ON dispensed_medications FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        pharmacist_id IN (SELECT user_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT))
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
        user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
    );

-- Refill Requests: Patients create, pharmacists manage
CREATE POLICY "Patients can create refill requests"
    ON medication_refill_requests FOR INSERT
    WITH CHECK (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
    );

CREATE POLICY "Users can view their refill requests"
    ON medication_refill_requests FOR SELECT
    USING (
        auth.uid() IS NULL OR
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT) OR
        pharmacist_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT)
    );

CREATE POLICY "Pharmacists can update refill requests"
    ON medication_refill_requests FOR UPDATE
    USING (
        auth.uid() IS NULL OR
        pharmacy_id IN (SELECT pharmacy_id FROM pharmacy_staff WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::TEXT))
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
