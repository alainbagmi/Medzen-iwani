-- =====================================================
-- Cameroon-Focused Medical Specialties
-- =====================================================
-- Replaces comprehensive specialty list with specialties
-- relevant to Cameroon's healthcare system
--
-- Created: 2025-01-31
-- Purpose: Provide practical specialty options for Cameroon healthcare providers
-- =====================================================

-- =====================================================
-- 1. CLEAR EXISTING SPECIALTY DATA
-- =====================================================

-- Clear all existing specialties and related data
TRUNCATE TABLE specialties CASCADE;

-- This will also clear provider_specialties due to CASCADE
-- Specialty counts in specialties table will be reset automatically by triggers

-- =====================================================
-- 2. PRIMARY CARE & GENERAL MEDICINE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('FAM_MED', 'Médecine Familiale / Family Medicine', 'Soins de santé complets pour tous les âges / Comprehensive healthcare for all ages', true, 1),
('GEN_PRAC', 'Médecine Générale / General Practice', 'Soins primaires et prévention / Primary care and prevention', true, 2),
('INT_MED', 'Médecine Interne / Internal Medicine', 'Diagnostic et traitement des maladies adultes / Diagnosis and treatment of adult diseases', true, 3),
('PEDIATRICS', 'Pédiatrie / Pediatrics', 'Soins médicaux pour enfants / Medical care for children', true, 4)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 3. SURGERY
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('GEN_SURG', 'Chirurgie Générale / General Surgery', 'Chirurgie abdominale et trauma / Abdominal and trauma surgery', true, 10),
('ORTHO_SURG', 'Chirurgie Orthopédique / Orthopedic Surgery', 'Chirurgie des os et articulations / Bone and joint surgery', true, 11),
('OBGYN', 'Obstétrique et Gynécologie / Obstetrics & Gynecology', 'Santé reproductive et accouchement / Reproductive health and childbirth', true, 12),
('NEUROSURG', 'Neurochirurgie / Neurosurgery', 'Chirurgie du cerveau et colonne vertébrale / Brain and spine surgery', true, 13),
('ENT', 'ORL (Oto-Rhino-Laryngologie) / ENT', 'Oreille, nez et gorge / Ear, nose and throat', true, 14),
('OPHTHALMOLOGY', 'Ophtalmologie / Ophthalmology', 'Maladies des yeux / Eye diseases and surgery', true, 15),
('UROLOGY', 'Urologie / Urology', 'Voies urinaires et système reproducteur masculin / Urinary tract and male reproductive system', true, 16)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 4. INTERNAL MEDICINE SUBSPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('CARDIOLOGY', 'Cardiologie / Cardiology', 'Maladies du cœur et système cardiovasculaire / Heart and cardiovascular diseases', true, 20),
('GASTRO', 'Gastro-entérologie / Gastroenterology', 'Maladies digestives / Digestive system disorders', true, 21),
('ENDOCRINOLOGY', 'Endocrinologie / Endocrinology', 'Diabète et troubles hormonaux / Diabetes and hormonal disorders', true, 22),
('NEPHROLOGY', 'Néphrologie / Nephrology', 'Maladies rénales / Kidney diseases', true, 23),
('PULMONOLOGY', 'Pneumologie / Pulmonology', 'Maladies respiratoires / Respiratory diseases', true, 24),
('RHEUMATOLOGY', 'Rhumatologie / Rheumatology', 'Maladies articulaires et auto-immunes / Joint and autoimmune diseases', true, 25),
('HEMATOLOGY', 'Hématologie / Hematology', 'Maladies du sang / Blood disorders', true, 26),
('ONCOLOGY', 'Oncologie / Oncology', 'Cancer et chimiothérapie / Cancer diagnosis and chemotherapy', true, 27),
('INFECT_DIS', 'Maladies Infectieuses / Infectious Disease', 'Paludisme, VIH, tuberculose, maladies tropicales / Malaria, HIV, TB, tropical diseases', true, 28)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 5. DIAGNOSTIC SPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('RADIOLOGY', 'Radiologie / Radiology', 'Imagerie médicale (rayons X, échographie, scanner) / Medical imaging', true, 30),
('LAB_MED', 'Médecine de Laboratoire / Laboratory Medicine', 'Analyses biologiques et tests cliniques / Laboratory testing', true, 31),
('PATHOLOGY', 'Anatomopathologie / Pathology', 'Diagnostic tissulaire et biopsies / Tissue diagnosis', true, 32)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 6. EMERGENCY & CRITICAL CARE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('EMERGENCY_MED', 'Médecine d''Urgence / Emergency Medicine', 'Soins d''urgence et trauma / Emergency and trauma care', true, 40),
('ANESTHESIOLOGY', 'Anesthésie-Réanimation / Anesthesiology', 'Anesthésie et soins intensifs / Anesthesia and intensive care', true, 41),
('CRIT_CARE', 'Réanimation / Critical Care Medicine', 'Soins intensifs pour patients critiques / Intensive care for critically ill patients', true, 42)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 7. MENTAL HEALTH
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('PSYCHIATRY', 'Psychiatrie / Psychiatry', 'Santé mentale et troubles psychiatriques / Mental health disorders', true, 50),
('NEUROLOGY', 'Neurologie / Neurology', 'Maladies du système nerveux / Nervous system disorders', true, 51)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 8. DERMATOLOGY
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('DERMATOLOGY', 'Dermatologie / Dermatology', 'Maladies de la peau et infections tropicales / Skin diseases and tropical infections', true, 60)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 9. GERIATRICS & PALLIATIVE CARE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('GERIATRICS', 'Gériatrie / Geriatrics', 'Soins pour personnes âgées / Healthcare for elderly patients', true, 70),
('PALLIATIVE', 'Soins Palliatifs / Palliative Care', 'Soins de fin de vie / End-of-life care', true, 71)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 10. MATERNAL & CHILD HEALTH
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('NEONATOLOGY', 'Néonatologie / Neonatology', 'Soins des nouveau-nés / Newborn care', true, 80),
('MATERNAL_FETAL', 'Médecine Materno-Fœtale / Maternal-Fetal Medicine', 'Grossesses à haut risque / High-risk pregnancies', true, 81)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 11. PUBLIC HEALTH & PREVENTION
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('PUB_HEALTH', 'Santé Publique / Public Health', 'Santé communautaire et prévention / Community health and prevention', true, 90),
('TROPICAL_MED', 'Médecine Tropicale / Tropical Medicine', 'Maladies tropicales et parasitaires / Tropical and parasitic diseases', true, 91)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 12. ALLIED HEALTH PROFESSIONALS
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('NURSING', 'Infirmier(ère) / Nursing', 'Soins infirmiers généraux / General nursing care', true, 100),
('MIDWIFE', 'Sage-Femme / Midwife', 'Soins de grossesse et accouchement / Pregnancy and childbirth care', true, 101),
('PHARMACY', 'Pharmacie / Pharmacy', 'Médicaments et conseil pharmaceutique / Medication and pharmaceutical counseling', true, 102),
('LAB_TECH', 'Technicien de Laboratoire / Laboratory Technician', 'Analyses de laboratoire / Laboratory analysis', true, 103),
('RADIOLOGY_TECH', 'Technicien en Radiologie / Radiology Technician', 'Imagerie médicale technique / Medical imaging technician', true, 104),
('PHYSIOTHERAPY', 'Kinésithérapie / Physiotherapy', 'Rééducation fonctionnelle / Physical rehabilitation', true, 105),
('NUTRITION', 'Nutrition / Nutrition', 'Diététique et nutrition / Dietetics and nutrition', true, 106)
ON CONFLICT (specialty_code) DO UPDATE SET
  specialty_name = EXCLUDED.specialty_name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;

-- =====================================================
-- 13. DEACTIVATE OLD SPECIALTIES (NOT IN NEW LIST)
-- =====================================================

-- Mark any specialties not in the above list as inactive
UPDATE specialties
SET is_active = false, updated_at = NOW()
WHERE specialty_code NOT IN (
  -- Primary Care
  'FAM_MED', 'GEN_PRAC', 'INT_MED', 'PEDIATRICS',
  -- Surgery
  'GEN_SURG', 'ORTHO_SURG', 'OBGYN', 'NEUROSURG', 'ENT', 'OPHTHALMOLOGY', 'UROLOGY',
  -- Internal Medicine Subspecialties
  'CARDIOLOGY', 'GASTRO', 'ENDOCRINOLOGY', 'NEPHROLOGY', 'PULMONOLOGY', 'RHEUMATOLOGY',
  'HEMATOLOGY', 'ONCOLOGY', 'INFECT_DIS',
  -- Diagnostic
  'RADIOLOGY', 'LAB_MED', 'PATHOLOGY',
  -- Emergency & Critical Care
  'EMERGENCY_MED', 'ANESTHESIOLOGY', 'CRIT_CARE',
  -- Mental Health
  'PSYCHIATRY', 'NEUROLOGY',
  -- Dermatology
  'DERMATOLOGY',
  -- Geriatrics & Palliative
  'GERIATRICS', 'PALLIATIVE',
  -- Maternal & Child Health
  'NEONATOLOGY', 'MATERNAL_FETAL',
  -- Public Health
  'PUB_HEALTH', 'TROPICAL_MED',
  -- Allied Health
  'NURSING', 'MIDWIFE', 'PHARMACY', 'LAB_TECH', 'RADIOLOGY_TECH', 'PHYSIOTHERAPY', 'NUTRITION'
);

-- =====================================================
-- 14. UPDATE SPECIALTY CATEGORIES (METADATA)
-- =====================================================

-- Add category information to metadata for filtering/grouping
UPDATE specialties SET metadata = jsonb_build_object('category', 'Primary Care', 'priority', 'high')
WHERE specialty_code IN ('FAM_MED', 'GEN_PRAC', 'INT_MED', 'PEDIATRICS');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Surgery', 'priority', 'high')
WHERE specialty_code IN ('GEN_SURG', 'ORTHO_SURG', 'OBGYN', 'NEUROSURG', 'ENT', 'OPHTHALMOLOGY', 'UROLOGY');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Internal Medicine', 'priority', 'medium')
WHERE specialty_code IN ('CARDIOLOGY', 'GASTRO', 'ENDOCRINOLOGY', 'NEPHROLOGY', 'PULMONOLOGY', 'RHEUMATOLOGY', 'HEMATOLOGY', 'ONCOLOGY', 'INFECT_DIS');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Diagnostic', 'priority', 'medium')
WHERE specialty_code IN ('RADIOLOGY', 'LAB_MED', 'PATHOLOGY');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Emergency & Critical Care', 'priority', 'high')
WHERE specialty_code IN ('EMERGENCY_MED', 'ANESTHESIOLOGY', 'CRIT_CARE');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Mental Health', 'priority', 'medium')
WHERE specialty_code IN ('PSYCHIATRY', 'NEUROLOGY');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Dermatology', 'priority', 'medium')
WHERE specialty_code = 'DERMATOLOGY';

UPDATE specialties SET metadata = jsonb_build_object('category', 'Geriatrics & Palliative', 'priority', 'low')
WHERE specialty_code IN ('GERIATRICS', 'PALLIATIVE');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Maternal & Child Health', 'priority', 'high')
WHERE specialty_code IN ('NEONATOLOGY', 'MATERNAL_FETAL');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Public Health', 'priority', 'medium')
WHERE specialty_code IN ('PUB_HEALTH', 'TROPICAL_MED');

UPDATE specialties SET metadata = jsonb_build_object('category', 'Allied Health', 'priority', 'medium')
WHERE specialty_code IN ('NURSING', 'MIDWIFE', 'PHARMACY', 'LAB_TECH', 'RADIOLOGY_TECH', 'PHYSIOTHERAPY', 'NUTRITION');

-- =====================================================
-- 15. CREATE VIEW FOR SPECIALTY CATEGORIES
-- =====================================================

CREATE OR REPLACE VIEW v_specialties_by_category AS
SELECT
  metadata->>'category' as category,
  metadata->>'priority' as priority,
  COUNT(*) as specialty_count,
  jsonb_agg(
    jsonb_build_object(
      'id', id,
      'specialty_code', specialty_code,
      'specialty_name', specialty_name,
      'description', description,
      'display_order', display_order,
      'provider_count', total_provider_count
    ) ORDER BY display_order
  ) as specialties
FROM specialties
WHERE is_active = true
GROUP BY metadata->>'category', metadata->>'priority'
ORDER BY
  CASE metadata->>'priority'
    WHEN 'high' THEN 1
    WHEN 'medium' THEN 2
    WHEN 'low' THEN 3
    ELSE 4
  END,
  metadata->>'category';

COMMENT ON VIEW v_specialties_by_category IS
'Specialties grouped by category and priority for UI display (Cameroon healthcare focus)';

GRANT SELECT ON v_specialties_by_category TO authenticated;
GRANT SELECT ON v_specialties_by_category TO postgres;

-- =====================================================
-- 16. VERIFICATION QUERIES
-- =====================================================

-- Count active specialties
-- SELECT COUNT(*) as active_specialties FROM specialties WHERE is_active = true;

-- View by category
-- SELECT * FROM v_specialties_by_category;

-- List all active specialties
-- SELECT specialty_code, specialty_name, metadata->>'category' as category
-- FROM specialties
-- WHERE is_active = true
-- ORDER BY display_order;

-- =====================================================
-- 17. DOCUMENTATION
-- =====================================================

COMMENT ON TABLE specialties IS
'Medical specialties relevant to Cameroon healthcare system.

FEATURES:
- Bilingual (French/English) for Cameroon context
- Focused on commonly available specialties
- Excludes highly specialized subspecialties not widely available
- Includes tropical medicine and infectious diseases
- Allied health professionals included
- Categorized by priority (high/medium/low)

CATEGORIES:
- Primary Care (4 specialties)
- Surgery (7 specialties)
- Internal Medicine (9 subspecialties)
- Diagnostic (3 specialties)
- Emergency & Critical Care (3 specialties)
- Mental Health (2 specialties)
- Dermatology (1 specialty)
- Geriatrics & Palliative (2 specialties)
- Maternal & Child Health (2 specialties)
- Public Health (2 specialties)
- Allied Health (7 specialties)

TOTAL: ~42 active specialties (reduced from 100+)';

-- =====================================================
-- END OF MIGRATION
-- =====================================================

-- Summary:
-- - Reduced from 100+ specialties to ~42 focused specialties
-- - All names in French/English for Cameroon
-- - Removed highly specialized subspecialties
-- - Added tropical medicine focus
-- - Included allied health professionals
-- - Categorized by priority and type
-- - Created view for category-based display
