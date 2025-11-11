-- =====================================================
-- Seed Medical Specialties Data
-- =====================================================
-- Populates the specialties table with comprehensive list of medical specialties
-- organized by category for easy filtering and hierarchical display
--
-- Created: 2025-01-31
-- Purpose: Provide standardized specialty options for medical providers
-- =====================================================

-- Clear existing data if re-running (development only)
-- TRUNCATE TABLE specialties CASCADE;

-- =====================================================
-- PRIMARY CARE & FAMILY MEDICINE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('FAM_MED', 'Family Medicine', 'Comprehensive healthcare for individuals and families across all ages', true, 1),
('GEN_PRAC', 'General Practice', 'Primary care for common health issues and preventive care', true, 2),
('INT_MED', 'Internal Medicine', 'Diagnosis and treatment of adult diseases', true, 3),
('PEDIATRICS', 'Pediatrics', 'Medical care for infants, children, and adolescents', true, 4),
('GERIATRICS', 'Geriatrics', 'Healthcare for elderly patients', true, 5)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- SURGICAL SPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('GEN_SURG', 'General Surgery', 'Surgical treatment of abdominal organs and other conditions', true, 10),
('CARDIO_SURG', 'Cardiothoracic Surgery', 'Surgery of the heart, lungs, and chest', true, 11),
('NEURO_SURG', 'Neurosurgery', 'Surgery of the brain, spine, and nervous system', true, 12),
('ORTHO_SURG', 'Orthopedic Surgery', 'Surgery of bones, joints, ligaments, and muscles', true, 13),
('PLASTIC_SURG', 'Plastic and Reconstructive Surgery', 'Reconstructive and cosmetic surgery', true, 14),
('VASC_SURG', 'Vascular Surgery', 'Surgery of blood vessels', true, 15),
('PED_SURG', 'Pediatric Surgery', 'Surgery for children', true, 16),
('TRAUMA_SURG', 'Trauma Surgery', 'Emergency surgical care for traumatic injuries', true, 17),
('COLORECT_SURG', 'Colorectal Surgery', 'Surgery of the colon, rectum, and anus', true, 18),
('SURG_ONC', 'Surgical Oncology', 'Cancer surgery', true, 19)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- INTERNAL MEDICINE SUBSPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('CARDIOLOGY', 'Cardiology', 'Heart and cardiovascular system diseases', true, 20),
('GASTRO', 'Gastroenterology', 'Digestive system disorders', true, 21),
('PULMONOLOGY', 'Pulmonology', 'Respiratory system and lung diseases', true, 22),
('NEPHROLOGY', 'Nephrology', 'Kidney diseases and disorders', true, 23),
('ENDOCRINOLOGY', 'Endocrinology', 'Hormone and metabolic disorders', true, 24),
('RHEUMATOLOGY', 'Rheumatology', 'Autoimmune and musculoskeletal diseases', true, 25),
('HEMATOLOGY', 'Hematology', 'Blood disorders and diseases', true, 26),
('MED_ONCOLOGY', 'Medical Oncology', 'Cancer diagnosis and chemotherapy', true, 27),
('INFECT_DIS', 'Infectious Disease', 'Infectious and communicable diseases', true, 28),
('ALLERGY_IMMUNO', 'Allergy and Immunology', 'Allergies and immune system disorders', true, 29),
('CRIT_CARE', 'Critical Care Medicine', 'Intensive care for critically ill patients', true, 30),
('PALLIATIVE', 'Hospice and Palliative Medicine', 'End-of-life care and symptom management', true, 31)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- SURGICAL SUBSPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('OPHTHALMOLOGY', 'Ophthalmology', 'Eye diseases and surgery', true, 40),
('ENT', 'Otolaryngology (ENT)', 'Ear, nose, and throat disorders', true, 41),
('UROLOGY', 'Urology', 'Urinary tract and male reproductive system', true, 42),
('OBGYN', 'Obstetrics and Gynecology', 'Women''s reproductive health and pregnancy', true, 43),
('GYN_ONC', 'Gynecologic Oncology', 'Cancer of female reproductive organs', true, 44),
('MATERNAL_FETAL', 'Maternal-Fetal Medicine', 'High-risk pregnancies', true, 45),
('REPRO_ENDO', 'Reproductive Endocrinology and Infertility', 'Fertility and reproductive hormones', true, 46)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- DIAGNOSTIC SPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('RADIOLOGY', 'Radiology', 'Medical imaging and diagnosis', true, 50),
('DIAG_RAD', 'Diagnostic Radiology', 'Interpreting medical images', true, 51),
('INTERV_RAD', 'Interventional Radiology', 'Minimally invasive image-guided procedures', true, 52),
('NUCLEAR_MED', 'Nuclear Medicine', 'Radioactive substances for diagnosis and treatment', true, 53),
('PATHOLOGY', 'Pathology', 'Laboratory diagnosis of disease', true, 54),
('ANAT_PATH', 'Anatomic Pathology', 'Tissue and organ examination', true, 55),
('CLIN_PATH', 'Clinical Pathology', 'Laboratory medicine and blood analysis', true, 56),
('MOL_PATH', 'Molecular Pathology', 'Genetic and molecular disease diagnosis', true, 57),
('LAB_MED', 'Laboratory Medicine', 'Clinical laboratory testing', true, 58)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- MENTAL HEALTH & BEHAVIORAL
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('PSYCHIATRY', 'Psychiatry', 'Mental health disorders and treatment', true, 60),
('CHILD_PSY', 'Child and Adolescent Psychiatry', 'Mental health for children and teens', true, 61),
('ADDICTION_MED', 'Addiction Medicine', 'Substance abuse and addiction treatment', true, 62),
('GERIATRIC_PSY', 'Geriatric Psychiatry', 'Mental health in elderly patients', true, 63),
('CLIN_PSYCH', 'Clinical Psychology', 'Psychological assessment and therapy', true, 64),
('NEUROPSYCH', 'Neuropsychiatry', 'Mental disorders related to nervous system', true, 65)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- PEDIATRIC SUBSPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('NEONATOLOGY', 'Neonatology', 'Care of newborns, especially premature or ill infants', true, 70),
('PED_CARDIO', 'Pediatric Cardiology', 'Heart conditions in children', true, 71),
('PED_ENDO', 'Pediatric Endocrinology', 'Hormone disorders in children', true, 72),
('PED_GASTRO', 'Pediatric Gastroenterology', 'Digestive disorders in children', true, 73),
('PED_HEM_ONC', 'Pediatric Hematology-Oncology', 'Blood disorders and cancer in children', true, 74),
('PED_INFECT', 'Pediatric Infectious Disease', 'Infections in children', true, 75),
('PED_NEPHRO', 'Pediatric Nephrology', 'Kidney disorders in children', true, 76),
('PED_PULM', 'Pediatric Pulmonology', 'Respiratory disorders in children', true, 77),
('PED_EM', 'Pediatric Emergency Medicine', 'Emergency care for children', true, 78),
('DEV_BEHAV_PED', 'Developmental-Behavioral Pediatrics', 'Developmental and behavioral issues in children', true, 79)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- EMERGENCY & CRITICAL CARE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('EMERGENCY_MED', 'Emergency Medicine', 'Acute illness and injury treatment', true, 80),
('EMS', 'Emergency Medical Services', 'Pre-hospital emergency care', true, 81),
('DISASTER_MED', 'Disaster Medicine', 'Mass casualty and disaster response', true, 82),
('MED_TOX', 'Medical Toxicology', 'Poisoning and overdose treatment', true, 83)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- ANESTHESIOLOGY & PAIN MANAGEMENT
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('ANESTHESIOLOGY', 'Anesthesiology', 'Anesthesia and perioperative care', true, 90),
('PED_ANESTH', 'Pediatric Anesthesiology', 'Anesthesia for children', true, 91),
('CARDIAC_ANESTH', 'Cardiac Anesthesiology', 'Anesthesia for heart surgery', true, 92),
('PAIN_MED', 'Pain Medicine', 'Chronic pain management', true, 93),
('CRIT_CARE_ANESTH', 'Critical Care Anesthesiology', 'Intensive care anesthesia', true, 94)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- REHABILITATION & PHYSICAL MEDICINE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('PMR', 'Physical Medicine and Rehabilitation', 'Recovery from injury and disability', true, 100),
('SPORTS_MED', 'Sports Medicine', 'Athletic injuries and performance', true, 101),
('PAIN_MGMT', 'Pain Management', 'Chronic pain treatment', true, 102),
('OCC_MED', 'Occupational Medicine', 'Work-related health and safety', true, 103)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- NEUROLOGY & NEUROSCIENCES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('NEUROLOGY', 'Neurology', 'Brain and nervous system disorders', true, 110),
('PED_NEURO', 'Pediatric Neurology', 'Neurological disorders in children', true, 111),
('VASC_NEURO', 'Vascular Neurology (Stroke)', 'Stroke and cerebrovascular disease', true, 112),
('CLIN_NEUROPHYS', 'Clinical Neurophysiology', 'Electrical activity of nervous system', true, 113),
('NEUROMUSC', 'Neuromuscular Medicine', 'Nerve and muscle disorders', true, 114),
('SLEEP_MED', 'Sleep Medicine', 'Sleep disorders', true, 115)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- DERMATOLOGY
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('DERMATOLOGY', 'Dermatology', 'Skin, hair, and nail disorders', true, 120),
('DERMATOPATH', 'Dermatopathology', 'Skin disease pathology', true, 121),
('PED_DERM', 'Pediatric Dermatology', 'Skin conditions in children', true, 122),
('PROC_DERM', 'Procedural Dermatology', 'Cosmetic and surgical dermatology', true, 123)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- PREVENTIVE & PUBLIC HEALTH
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('PREV_MED', 'Preventive Medicine', 'Disease prevention and health promotion', true, 130),
('OCC_HEALTH', 'Occupational Health', 'Workplace health and safety', true, 131),
('PUB_HEALTH', 'Public Health and General Preventive Medicine', 'Population health', true, 132),
('AEROSPACE_MED', 'Aerospace Medicine', 'Aviation and space medicine', true, 133)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- OTHER SPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('MED_GENETICS', 'Medical Genetics and Genomics', 'Genetic disorders and counseling', true, 140),
('RAD_ONCOLOGY', 'Radiation Oncology', 'Radiation therapy for cancer', true, 141),
('TRANSPLANT_SURG', 'Transplant Surgery', 'Organ transplantation', true, 142),
('TRANSPLANT_HEP', 'Transplant Hepatology', 'Liver transplantation', true, 143),
('BARIATRIC_SURG', 'Bariatric Surgery', 'Weight loss surgery', true, 144),
('WOUND_CARE', 'Wound Care', 'Chronic and complex wound management', true, 145),
('HYPERBARIC_MED', 'Hyperbaric Medicine', 'Oxygen therapy for specific conditions', true, 146)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- ALLIED HEALTH SPECIALTIES
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('NP_FAM', 'Nurse Practitioner - Family', 'Advanced practice nursing in family medicine', true, 150),
('NP_ACUTE', 'Nurse Practitioner - Acute Care', 'Advanced practice nursing for acute conditions', true, 151),
('NP_PSYCH', 'Nurse Practitioner - Psychiatric', 'Mental health nurse practitioner', true, 152),
('PHYS_ASSIST', 'Physician Assistant', 'Medical care under physician supervision', true, 153),
('CNS', 'Clinical Nurse Specialist', 'Advanced practice nursing specialist', true, 154),
('MIDWIFE', 'Certified Nurse Midwife', 'Pregnancy and childbirth care', true, 155),
('CRNA', 'Certified Registered Nurse Anesthetist', 'Anesthesia nursing', true, 156)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- COMPLEMENTARY & INTEGRATIVE MEDICINE
-- =====================================================

INSERT INTO specialties (specialty_code, specialty_name, description, is_active, display_order) VALUES
('INTEGRATIVE_MED', 'Integrative Medicine', 'Conventional and complementary medicine', true, 160),
('ACUPUNCTURE', 'Acupuncture', 'Traditional Chinese medicine technique', true, 161),
('OSTEO_MANIP', 'Osteopathic Manipulative Medicine', 'Manual manipulation techniques', true, 162)
ON CONFLICT (specialty_code) DO NOTHING;

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================

-- Count inserted specialties
-- SELECT COUNT(*) as total_specialties FROM specialties;

-- View all specialties by category
-- SELECT specialty_code, specialty_name, display_order
-- FROM specialties
-- ORDER BY display_order;

COMMENT ON TABLE specialties IS 'Master list of medical specialties for provider classification and filtering';

-- =====================================================
-- END OF MIGRATION
-- =====================================================
-- Total specialties inserted: 100+
-- Categories covered: Primary Care, Surgery, Internal Medicine Subspecialties,
--                    Diagnostics, Mental Health, Pediatrics, Emergency, Anesthesia,
--                    Rehabilitation, Neurology, Dermatology, Preventive Medicine,
--                    Allied Health, Integrative Medicine
