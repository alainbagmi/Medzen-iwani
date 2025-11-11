-- Migration: Add consultation_fee to facilities table
-- Created: 2025-11-11
-- Purpose: Add consultation fee field to track facility consultation charges

-- Add consultation_fee column to facilities table
ALTER TABLE facilities
ADD COLUMN IF NOT EXISTS consultation_fee NUMERIC(10,2);

-- Add comment to explain the column
COMMENT ON COLUMN facilities.consultation_fee IS 'Standard consultation fee for this facility. Stored as decimal with 2 decimal places for currency precision. NULL indicates fee not set or varies by service.';

-- Create index for filtering facilities by fee range (useful for patient searches)
CREATE INDEX IF NOT EXISTS idx_facilities_consultation_fee ON facilities(consultation_fee) WHERE consultation_fee IS NOT NULL;
