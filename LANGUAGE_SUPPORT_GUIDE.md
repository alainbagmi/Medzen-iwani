# MedZen Language Support Guide

## Philosophy: "Not Everyone Speaks English"

MedZen is a healthcare platform serving Africa. Healthcare should be accessible in local languages, not just English. This guide explains our multilingual strategy and current implementation status.

---

## Current Status

### ✅ Natively Supported Languages (AWS Transcribe)

These languages have native AWS Transcribe support:

| Language | Region | Code | AWS Support | Medical Available |
|----------|--------|------|-------------|------------------|
| English (US) | Worldwide | en-US | Streaming + Batch | ✅ Yes (Medical) |
| English (UK) | UK | en-GB | Streaming + Batch | ❌ No |
| English (South Africa) | South Africa | en-ZA | Streaming + Batch | ❌ No |
| Afrikaans | South Africa | af-ZA | Streaming + Batch | ❌ No |
| Swahili (Kenya) | Kenya, East Africa | sw-KE | Batch only | ❌ No |
| Swahili (Tanzania) | Tanzania | sw-TZ | Batch only | ❌ No |
| Zulu | South Africa | zu-ZA | Streaming + Batch | ❌ No |
| French (France) | Francophone Africa | fr-FR | Streaming + Batch | ❌ No |
| French (Canada) | Canada | fr-CA | Streaming + Batch | ❌ No |
| Arabic (Gulf) | North Africa | ar-AE | Streaming + Batch | ❌ No |

**KEY LIMITATION**: **AWS Transcribe Medical ONLY supports en-US**. Medical specialties (CARDIOLOGY, NEUROLOGY, etc.) are only available when using English (US).

### ⚠️ Partially Supported (Fallback to English/French)

These languages are NOT natively supported by AWS but intelligently fall back to a related language:

| Language | Region | Code | Current Fallback | Status |
|----------|--------|------|------------------|--------|
| English (Nigeria) | Nigeria | en-NG | en-US | Works, but Nigerian accent not recognized |
| English (Kenya) | Kenya | en-KE | en-US | Works, but Kenyan accent not recognized |
| English (Cameroon) | Cameroon | en-CM | en-US | Works, uses Nigerian rules for French |
| French (Cameroon) | Cameroon | fr-CM | fr-FR | Works, but Cameroonian French not recognized |
| French (DRC) | DRC | fr-CD | fr-FR | Works, but Congolese French not recognized |
| French (Senegal) | Senegal | fr-SN | fr-FR | Works |

### ❌ NOT Supported - Scheduled for Q1 2026

These critical languages have no native AWS support and currently fall back to English. **This is our priority roadmap**:

#### Nigeria (Critical Priority 🔴)

| Language | Speakers | Current Status | Q1 2026 Plan |
|----------|----------|---|---|
| Yoruba (yo) | 45M | Falls back to en-US | Custom vocabulary + linguistic framework |
| Igbo (ig) | 30M | Falls back to en-US | Custom vocabulary + linguistic framework |
| Hausa (ha-NG) | 72M (incl. Niger) | AWS batch-only support | Enable streaming + medical terminology |
| Nigerian Pidgin (pcm) | 75M (lingua franca) | Falls back to en-US | Custom Pidgin vocabulary + medical terms |

**Why This Matters**: In Nigeria, English fluency varies widely. Rural healthcare workers and patients often rely on local languages. A Yoruba-speaking patient should be able to consult in Yoruba, not forced into English.

#### Cameroon (Critical Priority 🔴)

| Language | Speakers | Current Status | Q1 2026 Plan |
|----------|----------|---|---|
| Camfranglais (ff-CM) | 5M (urban) | Falls back to fr-FR | Custom vocabulary blending French + English medical terms |
| Pidgin (Cameroon) | 1M+ | Falls back to en-US | Custom vocabulary |

**Why This Matters**: Camfranglais is NOT an ISO-standard language, but it's the lingua franca of Douala and Yaoundé healthcare settings. Doctors and nurses use it daily.

#### Kenya & East Africa

| Language | Region | Status | Q1 2026 Plan |
|----------|--------|--------|---|
| Kikuyu (ki) | Kenya | Falls back to en-US | Custom vocabulary |
| Luganda (lg) | Uganda | Falls back to en-US | Custom vocabulary |

#### DRC & Central Africa

| Language | Speakers | Status | Q1 2026 Plan |
|----------|----------|--------|---|
| Lingala (ln) | 5M+ | Falls back to fr-FR | Custom vocabulary |
| Kikongo (kg) | 3M+ | Falls back to fr-FR | Custom vocabulary |

#### South Africa

| Language | Speakers | AWS Support | Medical |
|----------|----------|---|---|
| Xhosa (xh) | 8M | Falls back to en-ZA | ❌ Not available |
| Sesotho (st) | 4M | Falls back to en-ZA | ❌ Not available |
| Setswana (tn) | 4M | Falls back to en-ZA | ❌ Not available |

---

## How Language Selection Works

### 1. Language Configuration

The system uses `LANGUAGE_CONFIG` in `start-medical-transcription/index.ts`:

```typescript
const LANGUAGE_CONFIG: Record<string, {
  engine: 'medical' | 'standard';
  awsCode: string;
  displayName: string;
  isNative: boolean;
  fallbackNote?: string;
}> = {
  'en-US': { engine: 'medical', awsCode: 'en-US', ... },
  'sw-KE': { engine: 'standard', awsCode: 'sw-KE', ... },
  'yo': { engine: 'standard', awsCode: 'en-US', isNative: false, fallbackNote: 'Using English' },
  // ... more languages
};
```

### 2. Engine Selection Logic

When a video call starts with transcription:

```typescript
// 1. Get language configuration
const languageConfig = getLanguageConfig(language);
const selectedEngine = languageConfig.engine;

// 2. If medical engine but NOT en-US, downgrade to standard
if (selectedEngine === 'medical' && language !== 'en-US') {
  finalEngine = 'standard';
  console.warn('Medical not available for this language, using standard');
}

// 3. Use appropriate AWS API
if (finalEngine === 'medical') {
  EngineTranscribeMedicalSettings: {
    LanguageCode: 'en-US', // ENFORCED
    Specialty: 'CARDIOLOGY', // Available
  }
} else {
  EngineTranscribeSettings: {
    LanguageCode: awsLanguageCode, // e.g., 'sw-KE', 'fr-FR', 'en-US'
    // No specialties available
  }
}
```

### 3. Regional Defaults

Use `regional-language-profiles.ts` to get recommended languages by country:

```typescript
import { getRecommendedLanguage, getRegionalProfile } from '../_shared/regional-language-profiles.ts';

// Nigeria defaults to English (Nigeria), fallback to Nigerian Pidgin
const lang = getRecommendedLanguage('NG'); // Returns 'en-NG'

// Kenya defaults to Swahili (Kenya)
const lang = getRecommendedLanguage('KE'); // Returns 'sw-KE'

// Get full regional profile with all supported languages
const profile = getRegionalProfile('NG');
console.log(profile.preferredTranscriptionLanguages);
```

---

## Deployment Checklist

### For Development

1. **Update Environment**:
   ```bash
   # Copy environment template
   cp supabase/.env.template supabase/.env

   # Set AWS credentials
   export AWS_REGION=eu-central-1
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   export DAILY_TRANSCRIPTION_BUDGET_USD=50
   ```

2. **Test Regional Language Support**:
   ```bash
   # Test Nigeria (English + Pidgin)
   curl -X POST "$URL/functions/v1/start-medical-transcription" \
     -H "Content-Type: application/json" \
     -d '{"meetingId":"test","sessionId":"test","action":"start","language":"en-NG"}'

   # Test Kenya (Swahili)
   curl -X POST "$URL/functions/v1/start-medical-transcription" \
     -H "Content-Type: application/json" \
     -d '{"meetingId":"test","sessionId":"test","action":"start","language":"sw-KE"}'
   ```

3. **Verify Fallback Handling**:
   ```bash
   # Test Yoruba (should fallback to en-US with warning)
   curl -X POST "$URL/functions/v1/start-medical-transcription" \
     -H "Content-Type: application/json" \
     -d '{"meetingId":"test","sessionId":"test","action":"start","language":"yo"}'
   ```

### For Production

1. **Set Secrets**:
   ```bash
   npx supabase link --project-ref noaeltglphdlkbflipit
   npx supabase secrets set AWS_REGION=eu-central-1
   npx supabase secrets set AWS_ACCESS_KEY_ID=<your-key>
   npx supabase secrets set AWS_SECRET_ACCESS_KEY=<your-secret>
   npx supabase secrets set DAILY_TRANSCRIPTION_BUDGET_USD=50
   npx supabase secrets set MEDICAL_VOCABULARY_NAME=medzen-medical-vocab
   npx supabase secrets set STANDARD_VOCABULARY_NAME=medzen-standard-vocab
   ```

2. **Deploy Edge Functions**:
   ```bash
   npx supabase functions deploy start-medical-transcription
   npx supabase functions deploy chime-transcription-callback
   ```

3. **Verify Deployment**:
   ```bash
   npx supabase functions list
   npx supabase secrets list
   ```

---

## Known Limitations & Workarounds

### 1. Medical Specialties Only for English (US)

**Problem**: AWS Transcribe Medical only supports en-US, so medical specialties (CARDIOLOGY, NEUROLOGY, ONCOLOGY, RADIOLOGY, UROLOGY) are unavailable in other languages.

**Workaround**: For non-US English regional variants:
- Use standard transcription engine instead
- Medical specialties field will be `null` in the response
- Application should handle this gracefully and not advertise medical specialties

**Code Change** (if needed):
```dart
// Only show medical specialties if language is en-US
if (transcriptionLanguage == 'en-US') {
  // Show specialty selector
} else {
  // Hide specialty selector, inform user
}
```

### 2. African Languages Lacking Native AWS Support

**Problem**: Yoruba, Igbo, Nigerian Pidgin, Lingala, Kikongo have no native AWS Transcribe support.

**Current Workaround**: Fall back to English
```typescript
'yo': {
  engine: 'standard',
  awsCode: 'en-US',
  isNative: false,
  fallbackNote: 'Using English (Yoruba not supported by AWS)'
}
```

**Q1 2026 Solution**: Custom vocabularies + linguistic frameworks
```typescript
// Future: enable these with AWS Transcribe custom vocabularies
'yo': {
  engine: 'standard',
  awsCode: 'en-US',
  vocabulary: 'medzen-yoruba-medical', // Custom vocabulary file
  isNative: false,
  fallbackNote: 'Using custom Yoruba medical vocabulary (beta)'
}
```

### 3. Camfranglais (French-English Creole in Cameroon)

**Problem**: Camfranglais is not an ISO-639 language code and AWS doesn't recognize it.

**Current Workaround**: Fall back to French
```typescript
'ff-CM': {
  engine: 'standard',
  awsCode: 'fr-FR',
  isNative: false,
  fallbackNote: 'Using French (Camfranglais not supported)'
}
```

**Q1 2026 Solution**: Blended custom vocabulary
```typescript
// Custom vocabulary with Camfranglais medical terms
// e.g., "le docteur" + medical Pidgin + French =  Camfranglais
'ff-CM': {
  engine: 'standard',
  awsCode: 'fr-FR',
  vocabulary: 'medzen-camfranglais-medical',
  isNative: false
}
```

---

## Implementation Guide for Developers

### Using Regional Profiles in Edge Functions

```typescript
import { getRegionalProfile, getRecommendedLanguage } from '../_shared/regional-language-profiles.ts';

// Example: Video call starting, user from Kenya
const userCountry = 'KE';
const profile = getRegionalProfile(userCountry);

if (profile) {
  console.log(`${profile.country} preferred languages:`);
  profile.preferredTranscriptionLanguages.forEach(lang => {
    console.log(`- ${lang.displayName} (${lang.code}): ${lang.nativeSupport}`);
  });
}

// Get default language for region
const defaultLang = getRecommendedLanguage(userCountry);
// Kenya returns: 'sw-KE'
```

### Using Regional Profiles in Flutter App

```dart
// Create a helper to get language options for user's region
Future<List<LanguageOption>> getLanguageOptionsForRegion(String countryCode) async {
  // Call edge function to get regional profile
  final response = await supabase.functions.invoke(
    'get-language-options',
    body: { 'countryCode': countryCode }
  );

  return (response['languages'] as List)
    .map((l) => LanguageOption.fromJson(l))
    .toList();
}

// In video call setup
final languages = await getLanguageOptionsForRegion(userCountry);
showLanguageDropdown(languages); // Show region-specific languages
```

---

## Roadmap: Q1 2026 Improvements

| Priority | Task | Target Languages | Implementation |
|----------|------|---|---|
| 🔴 Critical | Custom vocabularies for major African languages | Yoruba, Igbo, Hausa, Lingala | AWS Transcribe Custom Vocabulary API |
| 🔴 Critical | Medical terminology in local languages | Nigerian Pidgin, Camfranglais | Build term databases + vocabulary files |
| 🟠 High | Linguistic framework for fallback languages | All unsupported languages | Automatic diacritics + phonetic mapping |
| 🟠 High | Streaming transcription for Swahili (Kenya) | sw-KE | Enable streaming in AWS config |
| 🟡 Medium | UI language selector with regional defaults | All languages | Update Flutter UI pages |
| 🟡 Medium | CloudWatch metrics by language | All languages | Add language dimension to metrics |

---

## Testing Language Support

### Local Testing

```bash
# Start local Supabase
npx supabase start

# Test Nigeria English fallback
curl -X POST "http://localhost:54321/functions/v1/start-medical-transcription" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "meetingId": "test-001",
    "sessionId": "session-001",
    "action": "start",
    "language": "en-NG"
  }'

# Expected Response:
# {
#   "success": true,
#   "message": "Standard transcription started",
#   "config": {
#     "requestedLanguage": "en-NG",
#     "languageDisplayName": "English (Nigeria)",
#     "selectedEngine": "standard",
#     "fallbackNote": "Using US English"
#   }
# }
```

### Production Verification

```bash
# Check which languages are actually being used in production
SELECT
  live_transcription_language,
  live_transcription_engine,
  COUNT(*) as count
FROM video_call_sessions
WHERE created_at > now() - interval '7 days'
GROUP BY live_transcription_language, live_transcription_engine
ORDER BY count DESC;

# Check for fallback usage
SELECT
  live_transcription_language,
  COUNT(*) as fallback_count
FROM video_call_sessions
WHERE live_transcription_engine = 'standard'
  AND live_transcription_language != 'en-US'
  AND created_at > now() - interval '7 days'
GROUP BY live_transcription_language;
```

---

## FAQ

**Q: Why does medical transcription only work with English (US)?**
A: AWS Transcribe Medical is a specialized engine that only supports en-US. Medical specialties like CARDIOLOGY require this engine. For other languages, we use standard transcription without specialties.

**Q: What happens if someone selects Yoruba?**
A: Currently, the system falls back to English (US) automatically. Q1 2026, we'll add custom Yoruba medical vocabularies so the system can better handle Yoruba speech.

**Q: Can we support Camfranglais?**
A: Not natively from AWS, but Q1 2026 we'll create a custom vocabulary that blends French + English medical terms to approximate Camfranglais.

**Q: Does transcription work offline?**
A: No, AWS Transcribe requires internet. For offline scenarios, see PowerSync + local transcription module (scheduled for Q2 2026).

**Q: What about other African countries?**
A: The guide covers the primary target regions (Nigeria, Cameroon, Kenya, DRC, South Africa, Uganda). We'll expand to other countries based on deployment needs.

---

## Contact & Support

For language-specific issues or to request new language support:
- Report issue: https://github.com/yourusername/medzen/issues
- Tag: `language-support` + country code (e.g., `language-support/ng-yoruba`)
- Include: Language code, region, use case, sample audio if possible
