# Medical Vocabulary Creation Guide for AWS Transcribe

**Date**: January 15, 2026
**Purpose**: Create 50+ custom medical vocabulary files for AWS Transcribe
**Status**: Framework & Examples (Ready for Production Creation)

---

## Overview

AWS Transcribe Custom Vocabularies enhance speech recognition accuracy for domain-specific terms (medical terminology, medications, procedures, diagnoses, etc.).

For the Hybrid Medical Transcription system, we need custom vocabularies in 50+ languages to enable medical term recognition in all supported languages.

---

## Vocabulary File Format

### AWS Transcribe Vocabulary File Requirements

**File Format**: Plain text, one term per line

**Line Format**:
```
term
term, weight
```

**Weight/Boost Values**:
- Range: 0.0 to 1.0
- Default: 0.5 (if not specified, AWS uses default boost)
- Higher values = higher probability of matching
- Use 0.8-1.0 for critical medical terms
- Use 0.3-0.5 for common/obvious terms

**Example Medical Vocabulary File** (`medzen-medical-vocab-en.txt`):
```
diabetes
hypertension, 0.9
myocardial infarction, 0.95
pneumonia, 0.9
medication
pharmacology
diagnosis
cardiology
neurology
radiology
oncology
pathology
medications, 0.7
allergies, 0.8
symptoms
fever
cough
chest pain, 0.95
shortness of breath, 0.95
```

---

## Medical Terminology Categories

Each vocabulary should include terms from these categories:

### 1. **Diagnoses (ICD-10 Common)**
- Diabetes (Type 1, Type 2)
- Hypertension
- Myocardial infarction
- Pneumonia
- Asthma
- Chronic obstructive pulmonary disease (COPD)
- Heart failure
- Stroke
- Cancer types (melanoma, lung, breast, etc.)
- Depression, anxiety
- Arthritis
- Obesity

### 2. **Medications & Drugs**
- Antibiotics (amoxicillin, penicillin, metronidazole)
- Antihypertensives (lisinopril, atorvastatin, metoprolol)
- Diabetes medications (metformin, insulin, glipizide)
- Pain relievers (aspirin, ibuprofen, paracetamol)
- Antivirals (antiretrovirals for HIV)
- Corticosteroids
- Anticonvulsants

### 3. **Procedures & Treatments**
- Surgery
- Biopsy
- Angiography
- Dialysis
- Chemotherapy
- Radiotherapy
- Vaccination
- Cesarean section
- Appendectomy
- Bypass surgery

### 4. **Anatomical Terms**
- Heart
- Lungs
- Brain
- Liver
- Kidneys
- Blood vessels
- Arteries
- Veins
- Capillaries

### 5. **Symptoms & Signs**
- Fever
- Cough
- Chest pain
- Shortness of breath
- Headache
- Nausea
- Vomiting
- Diarrhea
- Rash
- Fatigue
- Dizziness

### 6. **Laboratory & Diagnostic Terms**
- Glucose
- Hemoglobin
- White blood cells
- Platelets
- Blood pressure
- ECG (electrocardiogram)
- X-ray
- CT scan
- MRI
- Ultrasound
- Biopsy

### 7. **Medical Specialties**
- Cardiology (cardiologist)
- Neurology (neurologist)
- Oncology (oncologist)
- Radiology (radiologist)
- Urology (urologist)
- Gastroenterology (gastroenterologist)
- Orthopedics (orthopedic surgeon)
- Psychiatry (psychiatrist)
- Dermatology (dermatologist)
- Pulmonology (pulmonologist)

### 8. **General Medical Terms**
- Patient
- Doctor
- Nurse
- Hospital
- Clinic
- Diagnosis
- Prognosis
- Treatment
- Therapy
- Rehabilitation

---

## Language-Specific Vocabulary Mapping

For each language, medical terms should be in **that language**, not English:

### **English** (`medzen-medical-vocab-en`)
English medical terms (see examples above)

### **French** (`medzen-medical-vocab-fr`)
- Diabète (Diabetes)
- Hypertension artérielle (Hypertension)
- Infarctus du myocarde (Myocardial infarction)
- Pneumonie (Pneumonia)
- Asthme (Asthma)
- Insuffisance cardiaque (Heart failure)
- Accident vasculaire cérébral (Stroke)
- Cancer (Cancer)
- Dépression (Depression)
- Arthrite (Arthritis)
- Obésité (Obesity)
- Médicament (Medication)
- Antibiotique (Antibiotic)
- Chirurgie (Surgery)
- Cœur (Heart)
- Poumon (Lungs)
- Cerveau (Brain)
- Foie (Liver)
- Rein (Kidneys)
- Fièvre (Fever)
- Toux (Cough)
- Douleur thoracique (Chest pain)
- Essoufflement (Shortness of breath)
- Diagnostic (Diagnosis)
- Traitement (Treatment)
- Thérapie (Therapy)

### **Swahili (sw-KE)** (`medzen-medical-vocab-sw`)
- Diabetes (Diabetes)
- Uponyaji wa damu ya juu (Hypertension)
- Kifo cha moyo (Myocardial infarction / Heart attack)
- Ugonjwa wa mapafu (Pneumonia)
- Asthma (Asthma)
- Magonjwa ya moyo (Heart disease)
- Ajali ya ubongo (Stroke)
- Saratani (Cancer)
- Maadhimisho ya akili (Depression)
- Matatizo ya mifupa (Arthritis)
- Uzani zaidi (Obesity)
- Dawa (Medication)
- Antibiotiki (Antibiotic)
- Upasuaji (Surgery)
- Moyo (Heart)
- Mapafu (Lungs)
- Ubongo (Brain)
- Ini (Liver)
- Kiju (Kidneys)
- Homa (Fever)
- Kikohozi (Cough)
- Maumivu ya kimo (Chest pain)
- Upungufu wa pumzi (Shortness of breath)
- Tukio (Diagnosis)
- Matibabu (Treatment)

### **Zulu (zu-ZA)** (`medzen-medical-vocab-zu`)
- Ishugela siwangu (Diabetes)
- Isifo somilingo (Hypertension)
- Isifo senhhliziyo (Heart attack)
- Isifo samafuba (Pneumonia)
- Asthma (Asthma)
- Isifo senhhliziyo (Heart disease)
- Umlilo womzwandlele (Stroke)
- Umkhuhlane (Cancer)
- Inkinga yengqondo (Depression)
- Isifo samabona (Arthritis)
- Kuziswa okwebesele (Obesity)
- Umuthi (Medication)
- Umuthi we-antibiotic (Antibiotic)
- Ukulwa (Surgery)
- Umhliziyo (Heart)
- Amafuba (Lungs)
- Ubuchopho (Brain)
- Iso (Liver)
- Okusha (Kidneys)
- Isifo samakhaza (Fever)
- Ukufakela (Cough)
- Izinzwa zenhliziyo (Chest pain)
- Umkhuhlane wespasmo (Shortness of breath)
- Isazwa (Diagnosis)
- Ukunakekeleza (Treatment)

### **Hausa (ha-NG)** (`medzen-medical-vocab-ha`)
- Diabitis (Diabetes)
- Bugi-bugi (Hypertension)
- Jĩyar zuciya (Heart attack)
- Sankarau na huhu (Pneumonia)
- Tashin numfashi (Asthma)
- Ciwon zuciya (Heart disease)
- Jĩyar jiki (Stroke)
- Karadenta/Ciwon kankara (Cancer)
- Bakin ciki (Depression)
- Ciwon haƙoli (Arthritis)
- Jajjara (Obesity)
- Maganin (Medication)
- Maganin kamatakare (Antibiotic)
- Gargajiya (Surgery)
- Zuciya (Heart)
- Huhu (Lungs)
- Kai (Brain)
- Hanta (Liver)
- Koda (Kidneys)
- Zafi (Fever)
- Tudu (Cough)
- Banshen zuciya (Chest pain)
- Takaitawa na numfashi (Shortness of breath)
- Sanin ciwon (Diagnosis)
- Jiya (Treatment)

### **Yoruba (yo)** (`medzen-medical-vocab-yo-fallback-en`)
- Ṣugbẹ (Diabetes)
- Inu-ẹni-giga (Hypertension)
- Arun ọkan (Heart attack)
- Oku ifẹ (Pneumonia)
- Ẹṣu-inu (Asthma)
- Arun ọkan (Heart disease)
- Ibadandun inu (Stroke)
- Ojo patapata (Cancer)
- Arun ẹkan-ọkan (Depression)
- Arun egungun (Arthritis)
- Ẹjẹbọ (Obesity)
- Ilẹ-oogun (Medication)
- Oogun ti oṣe ararẹ (Antibiotic)
- Ikawe (Surgery)
- Ọkan (Heart)
- Oku (Lungs)
- Ọpọlọ (Brain)
- Ẹbẹ (Liver)
- Apata (Kidneys)
- Ooru (Fever)
- Ikọ (Cough)
- Ibadandun ẹkan (Chest pain)
- Iṣẹ okoko (Shortness of breath)
- Ijẹrisi (Diagnosis)
- Orun (Treatment)

### **Lingala (ln)** (`medzen-medical-vocab-ln-fallback-fr`)
- Madiarite (Diabetes)
- Motema na motema (Hypertension)
- Motema ya moele (Heart attack)
- Koloboto (Pneumonia)
- Asthme (Asthma)
- Motema ya lobi (Heart disease)
- Moto ya molili (Stroke)
- Ebola te (Cancer)
- Kelele ya motema (Depression)
- Mabele (Arthritis)
- Motema na moi (Obesity)
- Eloko ya lokola (Medication)
- Lokoli ya koloka (Antibiotic)
- Lokolo (Surgery)
- Motema (Heart)
- Koloboto (Lungs)
- Molili (Brain)
- Ini (Liver)
- Inge (Kidneys)
- Motema na molɔngɔ (Fever)
- Kolelo (Cough)
- Motema ni (Chest pain)
- Pɔmbɔ ya motema (Shortness of breath)
- Motema ya koloba (Diagnosis)
- Lokolo (Treatment)

---

## File Naming Convention

All vocabulary files follow this naming convention:

```
medzen-medical-vocab-{language-code}.txt
```

**Examples**:
- `medzen-medical-vocab-en.txt` (English)
- `medzen-medical-vocab-fr.txt` (French - France)
- `medzen-medical-vocab-fr-cm.txt` (French - Cameroon)
- `medzen-medical-vocab-fr-cd.txt` (French - DRC)
- `medzen-medical-vocab-sw.txt` (Swahili)
- `medzen-medical-vocab-zu.txt` (Zulu)
- `medzen-medical-vocab-af.txt` (Afrikaans)
- `medzen-medical-vocab-ha.txt` (Hausa)
- `medzen-medical-vocab-yo-fallback-en.txt` (Yoruba with fallback to English)
- `medzen-medical-vocab-ig-fallback-en.txt` (Igbo with fallback to English)
- `medzen-medical-vocab-ln-fallback-fr.txt` (Lingala with fallback to French)
- `medzen-medical-vocab-pcm-fallback-en.txt` (Nigerian Pidgin)

---

## Directory Structure

Create vocabularies in this structure:

```
medical-vocabularies/
├── english/
│   └── medzen-medical-vocab-en.txt
├── french/
│   ├── medzen-medical-vocab-fr.txt
│   ├── medzen-medical-vocab-fr-cm.txt
│   ├── medzen-medical-vocab-fr-sn.txt
│   ├── medzen-medical-vocab-fr-cd.txt
│   └── medzen-medical-vocab-fr-ci.txt
├── west-africa/
│   ├── medzen-medical-vocab-ha.txt
│   ├── medzen-medical-vocab-yo-fallback-en.txt
│   ├── medzen-medical-vocab-ig-fallback-en.txt
│   ├── medzen-medical-vocab-pcm-fallback-en.txt
│   └── medzen-medical-vocab-ee.txt
├── east-africa/
│   ├── medzen-medical-vocab-sw.txt
│   ├── medzen-medical-vocab-lg-fallback-en.txt
│   └── medzen-medical-vocab-rw.txt
├── central-africa/
│   ├── medzen-medical-vocab-ln-fallback-fr.txt
│   ├── medzen-medical-vocab-kg-fallback-fr.txt
│   └── medzen-medical-vocab-sg.txt
├── southern-africa/
│   ├── medzen-medical-vocab-zu.txt
│   ├── medzen-medical-vocab-af.txt
│   ├── medzen-medical-vocab-xh.txt
│   └── medzen-medical-vocab-st.txt
└── north-africa/
    └── medzen-medical-vocab-ar.txt
```

---

## Creating Vocabulary Files

### Step 1: Gather Medical Terminology

Sources:
1. **Standard medical dictionaries** (English, French, etc.)
2. **WHO multilingual medical terminology databases**
3. **Regional medical boards** (Nigeria Medical Board, Kenya Medical Board, etc.)
4. **OpenMRS medical vocabulary system**
5. **SNOMED CT multilingual translations** (where available)

### Step 2: Create Base Vocabulary

Create a file with medical terms, one per line:

```bash
# Example: creating medzen-medical-vocab-en.txt
cat > medical-vocabularies/english/medzen-medical-vocab-en.txt << 'EOF'
diabetes
hypertension, 0.9
myocardial infarction, 0.95
pneumonia, 0.9
asthma, 0.85
heart failure, 0.95
stroke, 0.95
cancer, 0.9
depression, 0.8
arthritis, 0.85
obesity, 0.8
medication, 0.7
antibiotic, 0.9
surgery, 0.85
biopsy, 0.9
angiography, 0.9
dialysis, 0.9
chemotherapy, 0.95
radiotherapy, 0.9
vaccination, 0.85
cesarean section, 0.9
# ... add more terms
EOF
```

### Step 3: Add Language-Specific Terms

For each language, include:
- Native language medical terms
- Common abbreviations (if applicable)
- Regional terminology variations

**Example for Swahili**:
```
diabetes
uponyaji wa damu ya juu, 0.9
kifo cha moyo, 0.95
ugonjwa wa mapafu, 0.9
asthma, 0.85
# ... more Swahili terms
```

### Step 4: Optimize Boost Values

Adjust weights based on:
- **Critical terms** (ICD-10 diagnoses, common medications): 0.8-1.0
- **Important terms** (procedures, symptoms): 0.6-0.8
- **General terms** (anatomy, basic concepts): 0.3-0.6

---

## AWS Transcribe Upload Process

### Prerequisites

```bash
# Ensure AWS CLI is installed and configured
aws --version
aws configure  # Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, region: eu-central-1
```

### Option 1: Upload via AWS CLI

```bash
# Create vocabulary for English medical terms
aws transcribe create-vocabulary \
  --vocabulary-name medzen-medical-vocab-en \
  --language-code en-US \
  --vocabulary-entries file://medical-vocabularies/english/medzen-medical-vocab-en.txt \
  --region eu-central-1

# Create vocabulary for French
aws transcribe create-vocabulary \
  --vocabulary-name medzen-medical-vocab-fr \
  --language-code fr-FR \
  --vocabulary-entries file://medical-vocabularies/french/medzen-medical-vocab-fr.txt \
  --region eu-central-1

# Create vocabulary for Swahili
aws transcribe create-vocabulary \
  --vocabulary-name medzen-medical-vocab-sw \
  --language-code sw-KE \
  --vocabulary-entries file://medical-vocabularies/east-africa/medzen-medical-vocab-sw.txt \
  --region eu-central-1

# ... repeat for all 50+ languages
```

### Option 2: Upload via AWS Console

1. Navigate to **AWS Transcribe → Custom vocabularies**
2. Click **Create vocabulary**
3. Enter vocabulary name (e.g., `medzen-medical-vocab-en`)
4. Select language code
5. Upload vocabulary file
6. Click **Create**

### Verify Vocabulary Created

```bash
# List all custom vocabularies
aws transcribe list-vocabularies --region eu-central-1

# Get details of specific vocabulary
aws transcribe get-vocabulary \
  --vocabulary-name medzen-medical-vocab-en \
  --region eu-central-1
```

---

## Vocabulary Status Monitoring

After creating a vocabulary, it goes through these states:

| Status | Meaning |
|--------|---------|
| PENDING | Vocabulary is being processed |
| READY | Vocabulary is ready to use |
| FAILED | Vocabulary creation failed (check CloudWatch logs) |

Wait for status `READY` before using in production:

```bash
# Check vocabulary status
aws transcribe get-vocabulary \
  --vocabulary-name medzen-medical-vocab-en \
  --region eu-central-1 \
  --query 'VocabularyState'
```

---

## Testing Vocabularies

### 1. Local Testing

Test vocabulary effectiveness before production:

```bash
# Upload test audio file
aws s3 cp test-medical-audio.wav s3://medzen-transcription-test/

# Start transcription with vocabulary
aws transcribe start-transcription-job \
  --transcription-job-name test-medical-vocab-en \
  --media-format-container wav \
  --media-file-uri s3://medzen-transcription-test/test-medical-audio.wav \
  --output-bucket-name medzen-transcription-test \
  --output-key test-results/ \
  --language-code en-US \
  --transcription-configuration VocabularyName=medzen-medical-vocab-en
```

### 2. Production Testing

Run test calls through the Chime integration:

```bash
# Test medical transcription with French vocabulary
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/start-medical-transcription" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "meetingId": "test-fr-vocab",
    "sessionId": "test-fr-001",
    "action": "start",
    "language": "fr-FR"
  }'

# Test with Swahili
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/start-medical-transcription" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "meetingId": "test-sw-vocab",
    "sessionId": "test-sw-001",
    "action": "start",
    "language": "sw-KE"
  }'
```

Check transcription results:

```sql
SELECT
  id,
  live_transcription_language,
  live_transcription_medical_vocabulary,
  transcript,
  created_at
FROM video_call_sessions
WHERE live_transcription_language IN ('fr-FR', 'sw-KE')
AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

---

## Validation Checklist

Before deploying to production:

- [ ] All 50+ vocabulary files created
- [ ] Each file includes 150+ medical terms
- [ ] Boost values assigned appropriately
- [ ] Files uploaded to AWS Transcribe
- [ ] All vocabularies show status `READY`
- [ ] Test transcriptions run successfully with each vocabulary
- [ ] Medical terms are correctly recognized in test audio
- [ ] Fallback languages configured correctly (Yoruba→en-US, Lingala→fr-FR)
- [ ] Database migration applied
- [ ] Edge function deployed with vocabulary support
- [ ] Production deployment verified

---

## Rollback Plan

If vocabularies cause issues in production:

1. **Disable specific vocabulary**:
   ```bash
   aws transcribe delete-vocabulary \
     --vocabulary-name medzen-medical-vocab-{language} \
     --region eu-central-1
   ```

2. **Fall back to standard transcription** (no vocabulary):
   - System will use AWS Transcribe without custom vocabulary
   - Medical term recognition will be reduced but basic transcription works
   - Update `LANGUAGE_CONFIG` to set `medicalVocabulary: null` for affected language

3. **Monitor via logs**:
   ```bash
   npx supabase functions logs start-medical-transcription --tail
   ```

---

## Summary

This guide provides the framework for creating medical vocabulary files for all 50+ languages supported by the hybrid medical transcription system.

**Next Steps**:
1. Create vocabulary files using the provided categories and language examples
2. Upload to AWS Transcribe
3. Test with actual video calls
4. Monitor adoption via `medical_transcription_usage` view
5. Iterate and improve based on real-world usage

Once vocabularies are created and uploaded, the system will be fully production-ready for multilingual medical transcription across Africa.
