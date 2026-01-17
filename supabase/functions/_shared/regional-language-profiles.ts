/**
 * Regional Language Profiles for MedZen
 *
 * Defines language preferences and transcription strategies for different regions.
 * Ensures healthcare services are accessible in local languages, not just English fallbacks.
 *
 * Philosophy: "Not everyone speaks English" - This system prioritizes native language
 * support for medical consultations, respecting linguistic diversity across Africa.
 *
 * @version 1.0.0
 */

export interface RegionalLanguageProfile {
  region: string;
  country: string;
  countryCode: string;
  officialLanguages: string[];
  preferredTranscriptionLanguages: Array<{
    code: string;
    displayName: string;
    nativeSupport: 'native' | 'fallback' | 'unavailable';
    fallbackTo?: string;
    notes?: string;
  }>;
  medicalSpecialties: 'full' | 'limited' | 'english-only';
  recommendedDefaults: {
    primary: string;
    secondary: string;
  };
}

/**
 * NIGERIA - West Africa's Healthcare Hub
 *
 * Nigeria has 500+ languages but major ones are:
 * - English (official, but only ~53% fluent)
 * - Yoruba (45M speakers, Southwest)
 * - Igbo (30M speakers, Southeast)
 * - Hausa (72M speakers, North - also spoken in Niger)
 * - Nigerian Pidgin (creole, ~75M speakers across all regions, lingua franca in cities)
 *
 * CRITICAL: Many healthcare workers and patients are not fluent in English
 * especially in rural areas. Yoruba, Igbo, Hausa speakers need native support.
 */
export const NIGERIA: RegionalLanguageProfile = {
  region: 'West Africa',
  country: 'Nigeria',
  countryCode: 'NG',
  officialLanguages: ['English'],
  preferredTranscriptionLanguages: [
    {
      code: 'en-NG',
      displayName: 'English (Nigeria)',
      nativeSupport: 'fallback',
      fallbackTo: 'en-US',
      notes: 'Standard English with Nigerian accent'
    },
    {
      code: 'yo',
      displayName: 'Yoruba',
      nativeSupport: 'unavailable',
      fallbackTo: 'en-US',
      notes: 'AWS Transcribe does not support Yoruba. Currently falls back to English. Plan: Custom vocabulary with medical Yoruba terms'
    },
    {
      code: 'ig',
      displayName: 'Igbo',
      nativeSupport: 'unavailable',
      fallbackTo: 'en-US',
      notes: 'AWS Transcribe does not support Igbo. Currently falls back to English. Plan: Custom vocabulary with medical Igbo terms'
    },
    {
      code: 'ha-NG',
      displayName: 'Hausa',
      nativeSupport: 'fallback', // AWS supports batch-only
      fallbackTo: 'en-US',
      notes: 'AWS Transcribe supports Hausa (batch only). Recommended for healthcare in Northern Nigeria'
    },
    {
      code: 'pcm',
      displayName: 'Nigerian Pidgin',
      nativeSupport: 'unavailable',
      fallbackTo: 'en-US',
      notes: 'Lingua franca across Nigeria, especially in urban areas. AWS does not support. Plan: Custom medical Pidgin vocabulary'
    }
  ],
  medicalSpecialties: 'english-only',
  recommendedDefaults: {
    primary: 'en-NG', // English (Nigeria variant)
    secondary: 'pcm' // Nigerian Pidgin as fallback
  }
};

/**
 * CAMEROON - Bilingual Crossroads
 *
 * Cameroon has unique linguistic situation:
 * - English (official in Anglophone regions)
 * - French (official in Francophone regions)
 * - Camfranglais (code: ff-CM, unique French-English creole, widely spoken especially in Douala/Yaoundé)
 * - 280+ indigenous languages including Pidgin, Bakoko, Beti, Bantu languages
 *
 * CRITICAL: Camfranglais is NOT an ISO standard language but IS widely spoken.
 * Healthcare workers use it in mixed French-English settings.
 * AWS Transcribe doesn't support it - needs custom approach.
 */
export const CAMEROON: RegionalLanguageProfile = {
  region: 'Central Africa',
  country: 'Cameroon',
  countryCode: 'CM',
  officialLanguages: ['French', 'English'],
  preferredTranscriptionLanguages: [
    {
      code: 'fr-CM',
      displayName: 'French (Cameroon)',
      nativeSupport: 'fallback',
      fallbackTo: 'fr-FR',
      notes: 'Cameroon French dialect, uses fr-FR model'
    },
    {
      code: 'en-CM',
      displayName: 'English (Cameroon)',
      nativeSupport: 'fallback',
      fallbackTo: 'en-US',
      notes: 'Cameroon English dialect, uses en-US model'
    },
    {
      code: 'ff-CM',
      displayName: 'Camfranglais',
      nativeSupport: 'unavailable',
      fallbackTo: 'fr-FR',
      notes: 'French-English creole (NOT ISO standard). Widely spoken in cities. AWS unsupported. Plan: Custom Camfranglais medical vocabulary blending French + English medical terms'
    },
    {
      code: 'pcm',
      displayName: 'Nigerian Pidgin (Cross-border)',
      nativeSupport: 'unavailable',
      fallbackTo: 'en-US',
      notes: 'Spoken in border regions. Falls back to English'
    }
  ],
  medicalSpecialties: 'english-only',
  recommendedDefaults: {
    primary: 'fr-CM', // French (Cameroon)
    secondary: 'ff-CM' // Camfranglais
  }
};

/**
 * KENYA - East African Healthcare Hub
 *
 * Kenya has official bilingual policy:
 * - English (official)
 * - Swahili (national language, ~16M native speakers)
 * - 40+ other languages (Kikuyu, Kalenjin, Kamba, Somali, Luhya, etc.)
 *
 * CRITICAL: Swahili is widely understood and preferred in healthcare settings
 * especially outside major cities. Strong Swahili-speaking medical workforce.
 */
export const KENYA: RegionalLanguageProfile = {
  region: 'East Africa',
  country: 'Kenya',
  countryCode: 'KE',
  officialLanguages: ['English', 'Swahili'],
  preferredTranscriptionLanguages: [
    {
      code: 'en-KE',
      displayName: 'English (Kenya)',
      nativeSupport: 'fallback',
      fallbackTo: 'en-US',
      notes: 'Kenyan English dialect'
    },
    {
      code: 'sw-KE',
      displayName: 'Swahili (Kenya)',
      nativeSupport: 'native',
      notes: 'AWS Transcribe supports sw-KE (batch & streaming). Recommended for healthcare'
    },
    {
      code: 'ki',
      displayName: 'Kikuyu',
      nativeSupport: 'unavailable',
      fallbackTo: 'en-US',
      notes: 'Spoken in Central Kenya. AWS unsupported, falls back to English'
    }
  ],
  medicalSpecialties: 'english-only',
  recommendedDefaults: {
    primary: 'sw-KE', // Swahili (Kenya)
    secondary: 'en-KE' // English (Kenya)
  }
};

/**
 * DEMOCRATIC REPUBLIC OF CONGO (DRC) - French-speaking Africa
 *
 * DRC is Francophone African country with complex linguistics:
 * - French (official, ~35M speakers)
 * - Lingala (widely used, especially in Kinshasa)
 * - Kikongo (Southwestern regions)
 * - Tshiluba/Luba languages
 *
 * CRITICAL: French is lingua franca but many regional languages important
 * for grassroots healthcare accessibility.
 */
export const DRC: RegionalLanguageProfile = {
  region: 'Central Africa',
  country: 'Democratic Republic of Congo',
  countryCode: 'CD',
  officialLanguages: ['French'],
  preferredTranscriptionLanguages: [
    {
      code: 'fr-CD',
      displayName: 'French (DRC)',
      nativeSupport: 'fallback',
      fallbackTo: 'fr-FR',
      notes: 'DRC French dialect, uses fr-FR model'
    },
    {
      code: 'ln',
      displayName: 'Lingala',
      nativeSupport: 'unavailable',
      fallbackTo: 'fr-FR',
      notes: 'Lingua franca in Kinshasa. AWS unsupported, falls back to French'
    },
    {
      code: 'kg',
      displayName: 'Kikongo',
      nativeSupport: 'unavailable',
      fallbackTo: 'fr-FR',
      notes: 'Important in Southwest DRC. AWS unsupported, falls back to French'
    }
  ],
  medicalSpecialties: 'english-only',
  recommendedDefaults: {
    primary: 'fr-CD', // French (DRC)
    secondary: 'ln' // Lingala
  }
};

/**
 * SOUTH AFRICA - Multilingual Society
 *
 * South Africa has 11 official languages:
 * - English (lingua franca in business/healthcare)
 * - Zulu (~10M native speakers)
 * - Xhosa (~8M native speakers)
 * - Afrikaans (~7M native speakers)
 * - Sotho, Setswana, Xitsonga, Venda, Ndebele, Tshivenda
 *
 * CRITICAL: English is healthcare standard but many patients prefer their
 * native Bantu languages. Zulu and Xhosa especially important.
 */
export const SOUTH_AFRICA: RegionalLanguageProfile = {
  region: 'Southern Africa',
  country: 'South Africa',
  countryCode: 'ZA',
  officialLanguages: ['English', 'Afrikaans', 'Zulu', 'Xhosa', 'Sotho', 'Setswana', 'Xitsonga', 'Venda', 'Ndebele', 'Tshivenda', 'Sepedi'],
  preferredTranscriptionLanguages: [
    {
      code: 'en-ZA',
      displayName: 'English (South Africa)',
      nativeSupport: 'native',
      notes: 'Standard in healthcare'
    },
    {
      code: 'af-ZA',
      displayName: 'Afrikaans (South Africa)',
      nativeSupport: 'native',
      notes: 'AWS Transcribe supports af-ZA'
    },
    {
      code: 'zu-ZA',
      displayName: 'Zulu',
      nativeSupport: 'native',
      notes: 'Largest native language group. AWS Transcribe supports zu-ZA'
    },
    {
      code: 'xh',
      displayName: 'Xhosa',
      nativeSupport: 'fallback',
      fallbackTo: 'en-ZA',
      notes: 'Important in Eastern Cape. AWS unsupported, falls back to South African English'
    },
    {
      code: 'st',
      displayName: 'Sesotho',
      nativeSupport: 'fallback',
      fallbackTo: 'en-ZA',
      notes: 'AWS unsupported, falls back to South African English'
    }
  ],
  medicalSpecialties: 'full',
  recommendedDefaults: {
    primary: 'en-ZA', // English (South Africa)
    secondary: 'zu-ZA' // Zulu
  }
};

/**
 * UGANDA - East African Nation
 *
 * Uganda has diverse linguistic landscape:
 * - English (official)
 * - Swahili (regional lingua franca)
 * - Luganda (~5M speakers, dominant in Kampala region)
 * - Lango, Acholi, Teso, Runyankole-Rukiga
 *
 * CRITICAL: Luganda crucial for healthcare in Central Uganda
 */
export const UGANDA: RegionalLanguageProfile = {
  region: 'East Africa',
  country: 'Uganda',
  countryCode: 'UG',
  officialLanguages: ['English', 'Swahili'],
  preferredTranscriptionLanguages: [
    {
      code: 'en-UG',
      displayName: 'English (Uganda)',
      nativeSupport: 'fallback',
      fallbackTo: 'en-US',
      notes: 'Ugandan English dialect'
    },
    {
      code: 'sw',
      displayName: 'Swahili',
      nativeSupport: 'native',
      notes: 'AWS Transcribe supports Swahili (streaming)'
    },
    {
      code: 'lg',
      displayName: 'Luganda',
      nativeSupport: 'unavailable',
      fallbackTo: 'en-US',
      notes: 'Important in Central Uganda. AWS unsupported, falls back to English'
    }
  ],
  medicalSpecialties: 'english-only',
  recommendedDefaults: {
    primary: 'en-UG', // English (Uganda)
    secondary: 'sw' // Swahili
  }
};

/**
 * Get regional profile by country code
 */
export function getRegionalProfile(countryCode: string): RegionalLanguageProfile | null {
  const profiles: Record<string, RegionalLanguageProfile> = {
    'NG': NIGERIA,
    'CM': CAMEROON,
    'KE': KENYA,
    'CD': DRC,
    'ZA': SOUTH_AFRICA,
    'UG': UGANDA,
  };

  return profiles[countryCode.toUpperCase()] || null;
}

/**
 * Get recommended transcription language for a region
 */
export function getRecommendedLanguage(countryCode: string, preference?: 'primary' | 'secondary'): string | null {
  const profile = getRegionalProfile(countryCode);
  if (!profile) return null;

  const chosen = preference === 'secondary'
    ? profile.recommendedDefaults.secondary
    : profile.recommendedDefaults.primary;

  return chosen;
}

/**
 * Check if a language is natively supported for a region
 */
export function isLanguageNativelySupported(countryCode: string, languageCode: string): boolean {
  const profile = getRegionalProfile(countryCode);
  if (!profile) return false;

  const lang = profile.preferredTranscriptionLanguages.find(
    l => l.code === languageCode || l.code === languageCode.split('-')[0]
  );

  return lang ? lang.nativeSupport === 'native' : false;
}

/**
 * Get fallback language for a region
 */
export function getLanguageFallback(countryCode: string, languageCode: string): string | null {
  const profile = getRegionalProfile(countryCode);
  if (!profile) return null;

  const lang = profile.preferredTranscriptionLanguages.find(
    l => l.code === languageCode
  );

  return lang?.fallbackTo || null;
}

/**
 * Regional Language Summary for Logging
 */
export function getRegionalSummary(countryCode: string): string {
  const profile = getRegionalProfile(countryCode);
  if (!profile) return `Unknown country: ${countryCode}`;

  const nativeCount = profile.preferredTranscriptionLanguages.filter(l => l.nativeSupport === 'native').length;
  const fallbackCount = profile.preferredTranscriptionLanguages.filter(l => l.nativeSupport === 'fallback').length;
  const unavailableCount = profile.preferredTranscriptionLanguages.filter(l => l.nativeSupport === 'unavailable').length;

  return `${profile.country}: ${nativeCount} native, ${fallbackCount} fallback, ${unavailableCount} unavailable languages`;
}

/**
 * All Supported Regions
 */
export const SUPPORTED_REGIONS = [
  NIGERIA,
  CAMEROON,
  KENYA,
  DRC,
  SOUTH_AFRICA,
  UGANDA,
];
