# African Languages Medical Transcription Support

This document outlines the African language support for MedZen's real-time medical transcription feature powered by AWS Transcribe.

## Overview

MedZen supports 50+ languages for medical transcription during video calls. This includes:
- **14 natively supported languages** (highest quality transcription)
- **20+ African languages with intelligent fallback** (uses the closest language for transcription)

## Natively Supported African Languages

These languages are directly supported by AWS Transcribe with optimal transcription quality:

| Language | Code | Region | Streaming Support |
|----------|------|--------|-------------------|
| **Afrikaans** | `af-ZA` | South Africa | Yes |
| **Swahili** | `sw-KE` | Kenya | Batch only |
| **Swahili** | `sw-TZ` | Tanzania | Batch only |
| **Swahili** | `sw-UG` | Uganda | Batch only |
| **Swahili** | `sw-RW` | Rwanda | Batch only |
| **Swahili** | `sw-BI` | Burundi | Batch only |
| **Zulu** | `zu-ZA` | South Africa | Yes |
| **Somali** | `so-SO` | Somalia | Yes |
| **Hausa** | `ha-NG` | Nigeria | Batch only |
| **Wolof** | `wo-SN` | Senegal | Batch only |
| **Kinyarwanda** | `rw-RW` | Rwanda | Batch only |

## African Languages with Fallback

These languages are not directly supported by AWS Transcribe but will use intelligent fallback to the most appropriate language:

### West African Languages

| Language | Code | Fallback | Reason |
|----------|------|----------|--------|
| **Sango** | `sg` | French | Lingua franca in Central African Republic |
| **Fulfulde/Fula** | `ff` | French | Common second language in Francophone West Africa |
| **Yoruba** | `yo` | English | Common in Nigeria |
| **Igbo** | `ig` | English | Common in Nigeria |
| **Twi** | `tw` | English | Common in Ghana |
| **Ewe** | `ee` | English | Common in Ghana/Togo |
| **Akan** | `ak` | English | Common in Ghana |
| **Bambara** | `bm` | French | Common in Mali |
| **Nigerian Pidgin** | `pcm` | English | English-based creole |
| **Krio** | `kri` | English | English-based creole (Sierra Leone) |

### East African Languages

| Language | Code | Fallback | Reason |
|----------|------|----------|--------|
| **Amharic** | `am` | English | International language in Ethiopia |
| **Oromo** | `om` | English | International language in Ethiopia |
| **Tigrinya** | `ti` | English | Common second language |
| **Luganda** | `lg` | English | Official language in Uganda |
| **Kirundi** | `rn` | French | Official language in Burundi |

### Central African Languages

| Language | Code | Fallback | Reason |
|----------|------|----------|--------|
| **Lingala** | `ln` | French | Common in DRC |
| **Kikongo** | `kg` | French | Common in DRC/Congo |
| **Luba-Katanga** | `lu` | French | Common in DRC |

### Southern African Languages

| Language | Code | Fallback | Reason |
|----------|------|----------|--------|
| **Xhosa** | `xh` | South African English | Common in South Africa |
| **Sesotho** | `st` | South African English | Official in Lesotho/SA |
| **Setswana** | `tn` | South African English | Official in Botswana/SA |
| **Tsonga** | `ts` | South African English | Common in South Africa |
| **Venda** | `ve` | South African English | Common in South Africa |
| **Shona** | `sn` | South African English | Common in Zimbabwe |
| **Chichewa** | `ny` | English | Official in Malawi |
| **Southern Ndebele** | `nr` | Zulu | Related language |
| **Northern Ndebele** | `nd` | Zulu | Related language |
| **Swati** | `ss` | Zulu | Related Nguni language |

### Arabic Variants (North Africa)

| Language | Code | Fallback |
|----------|------|----------|
| **Arabic (Egypt)** | `ar-EG` | Gulf Arabic (`ar-AE`) |
| **Arabic (Morocco)** | `ar-MA` | Gulf Arabic |
| **Arabic (Algeria)** | `ar-DZ` | Gulf Arabic |
| **Arabic (Tunisia)** | `ar-TN` | Gulf Arabic |
| **Arabic (Sudan)** | `ar-SD` | Gulf Arabic |

## Usage in Flutter

```dart
import '/custom_code/actions/index.dart';

// Get all African languages
final africanLanguages = TranscriptionLanguages.africanLanguages;

// Get only natively supported languages (best quality)
final nativeLanguages = TranscriptionLanguages.nativelySupported;

// Map UI language to transcription language
final transcriptionLang = TranscriptionLanguages.mapUiLanguageToTranscription('sw');
// Returns: 'sw-KE'

// Start transcription with a specific language
// All 6 positional arguments: meetingId, sessionId, action, language, specialty, enableSpeakerIdentification
await controlMedicalTranscription(
  meetingId,
  sessionId,
  'start',
  'sw-KE',        // language - Swahili (Kenya)
  'PRIMARYCARE',  // specialty
  'true',         // enableSpeakerIdentification
);
```

## How Fallback Works

When a user selects a language that's not natively supported by AWS Transcribe:

1. The system logs a message indicating the fallback
2. The closest supported language is used for transcription
3. The API response includes `isNative: false` and a `fallbackNote` explaining the fallback

Example response for Sango:
```json
{
  "success": true,
  "config": {
    "language": "sg",
    "displayName": "Sango",
    "isNative": false,
    "fallbackNote": "Using French (lingua franca in CAR)",
    "awsLanguageCode": "fr-FR"
  }
}
```

## Deployment

Deploy the updated edge function:
```bash
npx supabase functions deploy start-medical-transcription
```

## Future AWS Transcribe Language Support

AWS Transcribe regularly adds new languages. Check the [AWS Transcribe documentation](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) for the latest updates.

When new African languages are added:
1. Update `LANGUAGE_CONFIG` in `supabase/functions/start-medical-transcription/index.ts`
2. Update `TranscriptionLanguages` in `lib/custom_code/actions/control_medical_transcription.dart`
3. Redeploy the edge function

## Sources

- [AWS Transcribe Supported Languages](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html)
- [Amazon Transcribe now supports streaming transcription in 30 additional languages](https://aws.amazon.com/about-aws/whats-new/2024/10/amazon-transcribe-streaming-transcription-additional-languages/)
