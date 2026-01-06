import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'fr', 'af'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? frText = '',
    String? afText = '',
  }) =>
      [enText, frText, afText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // Provider_confirmation_page
  {
    'yiub764p': {
      'en': 'Thanks for Signing Up!',
      'af': 'Dankie vir jou aanmelding!',
      'fr': 'Merci de vous être inscrit !',
    },
    'ty1yw4gs': {
      'en': 'Verifying your credentials...',
      'af': 'Verifieer tans jou geloofsbriewe...',
      'fr': 'Vérification de vos identifiants...',
    },
    'wzlrdf7j': {
      'en': 'This usually takes 2 - 5 Business Days',
      'af': 'Dit neem gewoonlik 2 - 5 werksdae',
      'fr': 'Cela prendra 2 à 5 jours ouvrables.',
    },
    '7puotn60': {
      'en': 'What\'s happening now?',
      'af': 'Wat gebeur nou?',
      'fr': 'Que se passe-t-il maintenant ?',
    },
    'sbijpr8q': {
      'en':
          'Our medical verification team is reviewing your credentials, license information, and professional background to ensure you meet our platform standards.',
      'af':
          'Ons mediese verifikasiespan hersien u geloofsbriewe, lisensie-inligting en professionele agtergrond om te verseker dat u aan ons platformstandaarde voldoen.',
      'fr':
          'Notre équipe de vérification médicale examine vos qualifications, vos informations de licence et votre parcours professionnel afin de s\'assurer que vous répondez aux normes de notre plateforme.',
    },
    'ttbkeotd': {
      'en': 'What\'s next?',
      'af': 'Wat is volgende?',
      'fr': 'La suite...',
    },
    'r6rtmabx': {
      'en':
          'Once verified, you\'ll receive an email confirmation and can start accepting patient appointments on the MedZen platform.',
      'af':
          'Sodra dit geverifieer is, sal jy \'n e-posbevestiging ontvang en kan jy pasiëntafsprake op die MedZen-platform begin aanvaar.',
      'fr':
          'Une fois votre compte vérifié, vous recevrez un e-mail de confirmation et vous pourrez commencer à accepter les rendez-vous des patients sur la plateforme MedZen.',
    },
    'lno2mr49': {
      'en': 'Need help or have questions?',
      'af': 'Het jy hulp nodig of vrae?',
      'fr': 'Besoin d\'aide ou des questions ?',
    },
    'jb7v3ggu': {
      'en': '(+237)670707070',
      'af': '+1 (240)4604692',
      'fr': '+1 (240)4604692',
    },
    'etvb02yu': {
      'en': 'support@medzenhealth.app',
      'af': 'ondersteuning@medzenhealth.app',
      'fr': 'support@medzenhealth.app',
    },
    '47cxk14b': {
      'en':
          'We\'ll send you email updates throughout the verification process. Please check your spam folder if you don\'t see our emails.',
      'af':
          'Ons sal vir jou e-posopdaterings stuur dwarsdeur die verifikasieproses. Gaan asseblief jou strooiposvouer na as jy nie ons e-posse sien nie.',
      'fr':
          'Nous vous enverrons des mises à jour par courriel tout au long du processus de vérification. Si vous ne voyez pas nos courriels, veuillez vérifier votre dossier de courriers indésirables.',
    },
    'ojn6awv2': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
    'm9py3wxt': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Role_page
  {
    'ksk5e5ho': {
      'en': 'Create ',
      'af': 'Skep',
      'fr': 'Créez',
    },
    'fsbkwkxx': {
      'en': 'Your',
      'af': 'Jou',
      'fr': 'Votre',
    },
    'wkrwttrf': {
      'en': ' Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'nhoe94i3': {
      'en': 'Welcome to MedZen Health',
      'af': 'Welkom by MedZen Gesondheid',
      'fr': 'Bienvenue chez MedZen Health',
    },
    'y18qorra': {
      'en': 'Let\'s set up your profile to get started with our services.',
      'af': 'Kom ons stel jou profiel op om met ons dienste te begin.',
      'fr': 'Configurons votre profil pour commencer à utiliser nos services.',
    },
    'h0cnz8yc': {
      'en': 'Please Select Your Role',
      'af': 'Kies asseblief u rol',
      'fr': 'Veuillez sélectionner votre rôle',
    },
    'zi6qod2y': {
      'en': 'Patient',
      'af': 'Pasiënt',
      'fr': 'Patient',
    },
    'skza7ixp': {
      'en': 'I need medical consultation',
      'af': 'Ek benodig mediese konsultasie',
      'fr': 'J\'ai besoin d\'une consultation médicale',
    },
    'g56kue82': {
      'en': 'Medical Provider',
      'af': 'Mediese Verskaffer',
      'fr': 'Fournisseur de soins médicaux',
    },
    'la19gz1c': {
      'en': 'I provide medical services',
      'af': 'Ek verskaf mediese dienste',
      'fr': 'Je fournis des services médicaux',
    },
    '0t8z70dv': {
      'en': 'System Administrator',
      'af': 'Stelseladministrateur',
      'fr': 'Administrateur du système',
    },
    'zncshnt2': {
      'en': 'Manage users and system settings',
      'af': 'Bestuur gebruikers en stelselinstellings',
      'fr': 'Gérer les utilisateurs et les paramètres système',
    },
    'kh5baj20': {
      'en': 'Facility Administrator',
      'af': 'Fasiliteitsadministrateur',
      'fr': 'Administrateur ',
    },
    'sk4b81vf': {
      'en': 'Manage Facility and Users',
      'af': 'Bestuur Fasiliteit en Gebruikers',
      'fr': 'Gérer l\'etablissement et les utilisateurs',
    },
    's6zqmbss': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // PatientAccountCreation
  {
    't0ub9ven': {
      'en': 'Patient Basic Information',
      'af': 'Pasiënt Basiese Inligting',
      'fr': 'Informations de base pour le patient',
    },
    '94j269nt': {
      'en': 'Let\'s start with some basic information to set up your account.',
      'af':
          'Kom ons begin met \'n paar basiese inligting om jou rekening op te stel.',
      'fr':
          'Commençons par quelques informations de base pour configurer votre compte.',
    },
    'siffyl0r': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'd29w6tzt': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'nc3eag4g': {
      'en': 'patient',
      'af': 'pasiënt',
      'fr': 'patient',
    },
    'e7ww8b3d': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'v28inzqp': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '0ka32x5l': {
      'en': 'French',
      'af': 'Frans',
      'fr': 'Français',
    },
    'arkulhht': {
      'en': 'English',
      'af': 'Engels',
      'fr': 'Anglais',
    },
    'mrqgtqh7': {
      'en': 'Fulfulde',
      'af': 'Fulfulde',
      'fr': 'Fulfulde',
    },
    '3i8hc8ls': {
      'en': 'Preferred Spoken Language',
      'af': 'Voorkeur Gesproke Taal',
      'fr': 'Langue parlée préférée',
    },
    'mmtf43tu': {
      'en': 'First Name',
      'af': 'Voornaam',
      'fr': 'Prénom',
    },
    's2tmuucn': {
      'en': 'Middle Name',
      'af': 'Middelnaam',
      'fr': 'Deuxième prénom',
    },
    'mxfe8rqk': {
      'en': 'Last Name',
      'af': 'Van',
      'fr': 'Nom de famille',
    },
    '1pt8frk2': {
      'en': 'Date Of Birth',
      'af': 'Geboortedatum',
      'fr': 'Date de naissance',
    },
    '7ecn42i5': {
      'en': 'ID Card Details',
      'af': 'ID-kaartbesonderhede',
      'fr': 'Détails de la carte d\'identité',
    },
    'l5qp0ngg': {
      'en': 'ID CARD NUMBER',
      'af': 'ID-KAARTNOMMER',
      'fr': 'NUMÉRO DE CARTE D\'IDENTITÉ',
    },
    '9fyo54ez': {
      'en': 'ISSUE DATE',
      'af': 'UITREIKINGSDATUM',
      'fr': 'DATE D\'ÉMISSION',
    },
    '76q3y5gy': {
      'en': 'EXPIRATION DATE',
      'af': 'VERVALDATUM',
      'fr': 'DATE D\'EXPIRATION',
    },
    'p9jjfih0': {
      'en': 'Select Gender',
      'af': 'Kies Geslag',
      'fr': 'Sélectionner le sexe',
    },
    'zbr7h137': {
      'en': 'male',
      'af': 'manlik',
      'fr': 'masculin',
    },
    'lgdltdhs': {
      'en': 'female',
      'af': 'vroulik',
      'fr': 'féminin',
    },
    '9ivpc08c': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'k4ogu00z': {
      'en': 'Street',
      'af': 'Straat',
      'fr': 'Rue',
    },
    'vfhfsrb8': {
      'en': 'City ',
      'af': 'Stad',
      'fr': 'Ville',
    },
    's5putqpc': {
      'en': 'Region',
      'af': 'Streek',
      'fr': 'Région',
    },
    '4dypvg34': {
      'en': 'Zip Code / P.O Box',
      'af': 'Poskode / Posbus',
      'fr': 'Code postal / Boîte postale',
    },
    'yt5pqg4d': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'r08qq7he': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    '5kzcigiy': {
      'en': 'Role is Required',
      'af': 'Rol word vereis',
      'fr': 'Rôle requis',
    },
    '8f62k787': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'cpmvgs1a': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    'tuhq0y9p': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'wz0oxj8q': {
      'en': 'Middle Name is required',
      'af': 'Middelnaam word vereis',
      'fr': 'Le deuxième prénom est obligatoire.',
    },
    'fgu5uenr': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'cagmk1lf': {
      'en': 'Last Name is required',
      'af': 'Vannaam word vereis',
      'fr': 'Le nom de famille est obligatoire.',
    },
    '1evmms4o': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'i5enjk7g': {
      'en': 'Date Of Birth is required',
      'af': 'Geboortedatum word vereis',
      'fr': 'La date de naissance est requise.',
    },
    'thorxyd9': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '3dqlo2ie': {
      'en': 'ID Card Number Is Required',
      'af': 'ID-kaartnommer word vereis',
      'fr': 'Le numéro de carte d\'identité est requis.',
    },
    'vxchorhj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'etg8ce3u': {
      'en': 'ID CARD DATE OF ISSUE is required',
      'af': 'ID-KAART DATUM VAN UITREIKING word vereis',
      'fr': 'La date d\'émission de la carte d\'identité est requise.',
    },
    'op48v0oh': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'bf8gux43': {
      'en': 'ID CARD DATE OF EXPIRATION is required',
      'af': 'ID-KAART VERVALDATUM word vereis',
      'fr': 'La date d\'expiration de la carte d\'identité est requise.',
    },
    'mslpszr6': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '2xfm9xd3': {
      'en': 'ID CARD PLACE OF ISSUE is required',
      'af': 'ID-KAART PLEK VAN UITREIKING word vereis',
      'fr': 'La carte d\'identité et le lieu de délivrance sont requis.',
    },
    'odqlzyj4': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'dx9d0slv': {
      'en': 'Select Gender is required',
      'af': 'Kies Geslag is verpligtend',
      'fr': 'Le choix du sexe est obligatoire.',
    },
    'm3a4n829': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ibxhgmuk': {
      'en': '+237 is required',
      'af': '+236 word vereis',
      'fr': '+237 est requis',
    },
    'kwc0wtrl': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'mt3iiwkf': {
      'en': 'Phone Number  is required',
      'af': 'Telefoonnommer word vereis',
      'fr': 'Un numéro de téléphone est requis.',
    },
    '41f5li2o': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'r4uh3hir': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    'clemurwi': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '09yxgu2d': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro de police est requis.',
    },
    'o27y06wi': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'f4bbauac': {
      'en': 'Group Number (Optional) is required',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif) est requis.',
    },
    'pmpzq0ut': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '91l8wm1k': {
      'en': 'Zip Code / P.O Box is required',
      'af': 'Poskode / Posbus word vereis',
      'fr': 'Le code postal ou la boîte postale est requis.',
    },
    'b4iiqn42': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '62jfurp1': {
      'en': 'Patient Details',
      'af': 'Pasiëntbesonderhede',
      'fr': 'Détails du patient',
    },
    '1xhftcik': {
      'en':
          'Please provide your health information to help us provide better care.',
      'af':
          'Verskaf asseblief u gesondheidsinligting om ons te help om beter sorg te bied.',
      'fr':
          'Veuillez nous fournir vos informations de santé afin de nous aider à vous prodiguer de meilleurs soins.',
    },
    'zbg929cu': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'o51ssnkz': {
      'en': 'Insurance Provider',
      'af': 'Versekeringsverskaffer',
      'fr': 'Fournisseur d\'assurance',
    },
    '17ml7t4r': {
      'en': 'Member ID/Policy Number',
      'af': 'Lid-ID/Polisnommer',
      'fr': 'Numéro d\'identification de membre/Numéro de police',
    },
    'h33zhi33': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel)',
      'fr': 'Numéro de groupe (facultatif)',
    },
    'wzosbk43': {
      'en': 'Voluntary Offerings',
      'af': 'Vrywillige Offerandes',
      'fr': 'Offrandes volontaires',
    },
    'etkfehl5': {
      'en': 'Will You Like To Be Registerted As  A Blood Donor ?',
      'af': 'Wil jy as \'n bloedskenker geregistreer word?',
      'fr': 'Souhaiteriez-vous vous inscrire comme donneur de sang ?',
    },
    'uxchc70m': {
      'en': 'Blood Donor ??',
      'af': 'Bloedskenker??',
      'fr': 'Donneur de sang ??',
    },
    'dqm5mhx8': {
      'en': 'yes',
      'af': 'ja',
      'fr': 'Oui',
    },
    '72eofd7c': {
      'en': 'no',
      'af': 'nee',
      'fr': 'Non',
    },
    'xpchd4u2': {
      'en': 'Emergency Contact Information',
      'af': 'Noodkontakbesonderhede',
      'fr': 'Informations de contact en cas d\'urgence',
    },
    'y0m62lvh': {
      'en': 'Emergency Names',
      'af': 'Noodname',
      'fr': 'Noms d\'urgence',
    },
    'mxwg32wh': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    '5yb4f65d': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'vccoqhof': {
      'en': 'Wife',
      'af': 'vrou',
      'fr': 'Épouse',
    },
    '0sx2o9wn': {
      'en': 'Husband',
      'af': 'Man',
      'fr': 'Mari',
    },
    'thrzqi01': {
      'en': 'Father',
      'af': 'Vader',
      'fr': 'Père',
    },
    'z82ifd45': {
      'en': 'Mother',
      'af': 'Moeder',
      'fr': 'Mère',
    },
    'h74r4xxe': {
      'en': 'Brother',
      'af': 'Broer',
      'fr': 'Frère',
    },
    's1pm4vbl': {
      'en': 'Sister',
      'af': 'Suster',
      'fr': 'Sœur',
    },
    'kp36e5jz': {
      'en': 'Children',
      'af': 'Kinders',
      'fr': 'Enfants',
    },
    '90exko3k': {
      'en': 'GrandParents',
      'af': 'Grootouers',
      'fr': 'Grands-parents',
    },
    'y4cy3yi6': {
      'en': 'Friend',
      'af': 'Vriend',
      'fr': 'Ami',
    },
    'n5wyjtn8': {
      'en': 'Relationship',
      'af': 'Verhouding',
      'fr': 'Relation',
    },
    'douksh4q': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    '4a42vxru': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'n2sleots': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    'qthhpfjz': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'faesa4dq': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro de police est requis.',
    },
    '4ebnrs0v': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'q2e8dvti': {
      'en': 'Group Number (Optional) ',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif).',
    },
    'd0fni625': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'cgy4cr5x': {
      'en': 'Existing Medical Conditions is required',
      'af': 'Bestaande mediese toestande word vereis',
      'fr': 'Les conditions médicales existantes sont requises',
    },
    'fuglwael': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'sz02aoon': {
      'en': 'Current Medications is required',
      'af': 'Huidige medikasie word benodig',
      'fr': 'Les médicaments en cours sont requis',
    },
    'rijrqduf': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'gfctmygj': {
      'en': 'Allergies is required',
      'af': 'Allergieë is nodig',
      'fr': 'Les allergies sont requises',
    },
    '5vdea9ik': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'te6qwqj4': {
      'en': 'Emergency Names is required',
      'af': 'Noodname word vereis',
      'fr': 'Les noms d\'urgence sont requis',
    },
    'z6c6wecu': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '4twbmy1i': {
      'en': 'Relationship is required',
      'af': 'Verhouding word vereis',
      'fr': 'Un lien de parenté est nécessaire',
    },
    'fhbdvnjo': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '9t31r3xr': {
      'en': 'Patient Account Verification',
      'af': 'Pasiëntrekeningverifikasie',
      'fr': 'Vérification du compte patient',
    },
    '03jt72jt': {
      'en':
          'Please review your information below to ensure everything is correct before creating your account.',
      'af':
          'Gaan asseblief u inligting hieronder na om te verseker dat alles korrek is voordat u u rekening skep.',
      'fr':
          'Veuillez vérifier vos informations ci-dessous pour vous assurer qu\'elles sont correctes avant de créer votre compte.',
    },
    'm7ojlahr': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'mhdducix': {
      'en': 'UseRole:',
      'af': 'GebruikRol:',
      'fr': 'Rôle d\'utilisation :',
    },
    'cakuwu9y': {
      'en': 'Prefrerred Language:',
      'af': 'Voorkeurtaal:',
      'fr': 'Langue préférée :',
    },
    '8r4qm26u': {
      'en': 'First Name:',
      'af': 'Voornaam:',
      'fr': 'Prénom:',
    },
    'jxv2gwx4': {
      'en': 'Middle Name:',
      'af': 'Middelnaam:',
      'fr': 'Deuxième prénom:',
    },
    'wugdqki0': {
      'en': 'Last Name:',
      'af': 'Van:',
      'fr': 'Nom de famille:',
    },
    'upoqqnp2': {
      'en': 'Date Of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'ftjpah4e': {
      'en': 'ID Card Number:',
      'af': 'ID-kaartnommer:',
      'fr': 'Numéro de carte d\'identité :',
    },
    'zhd5t1qn': {
      'en': 'ID Card Issue Date:',
      'af': 'ID-kaart uitreikingsdatum:',
      'fr': 'Date d\'émission de la carte d\'identité :',
    },
    '8mqu4fky': {
      'en': 'ID Card Expiration Date:',
      'af': 'ID-kaart vervaldatum:',
      'fr': 'Date d\'expiration de la carte d\'identité :',
    },
    's14th9vw': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    '7wbr9rcs': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'n4p8iz7h': {
      'en': 'Street / Rue:',
      'af': 'Straat / Rue:',
      'fr': 'Rue :',
    },
    '3exptirt': {
      'en': 'City / Ville:',
      'af': 'Stad / Dorp:',
      'fr': 'Ville :',
    },
    'mo9pnjk4': {
      'en': 'Region:',
      'af': 'Streek:',
      'fr': 'Région:',
    },
    'wznjvv0r': {
      'en': 'Zip Code / P.O Box:',
      'af': 'Poskode / Posbus:',
      'fr': 'Code postal / Boîte postale :',
    },
    'k9z8f19x': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'vw2do66n': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    '57u8sgp6': {
      'en': 'PolicyNumber:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    'un27apr1': {
      'en': 'Group Number:',
      'af': 'Groepnommer:',
      'fr': 'Numéro de groupe :',
    },
    'd37xt0c2': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'z0np1156': {
      'en': 'Emergency Names:',
      'af': 'Noodname:',
      'fr': 'Noms en cas d\'urgence :',
    },
    '5dpaedxd': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'lxcnntzj': {
      'en': 'Emegency Phone:',
      'af': 'Noodfoon:',
      'fr': 'Téléphone d\'urgence :',
    },
    '4ujxmy7i': {
      'en': 'Credentials',
      'af': 'Geloofsbriewe',
      'fr': 'Informations d\'identification',
    },
    '87tao4nc': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'qv9toouh': {
      'en': '+237',
      'af': '+237',
      'fr': '+237',
    },
    'zjhowijb': {
      'en': 'Phone Number ',
      'af': 'Telefoonnommer',
      'fr': 'Numéro de téléphone',
    },
    '95nriwr5': {
      'en': 'Password',
      'af': 'Wagwoord',
      'fr': 'Mot de passe',
    },
    'jmh9bkl1': {
      'en': 'Confirm Password',
      'af': 'Bevestig wagwoord',
      'fr': 'Confirmez le mot de passe',
    },
    '0xd12wfx': {
      'en':
          'Password must be at least 8 characters with one number and special character',
      'af':
          'Wagwoord moet ten minste 8 karakters wees met een nommer en spesiale karakter',
      'fr':
          'Le mot de passe doit comporter au moins 8 caractères, dont un chiffre et un caractère spécial.',
    },
    '8ubf8wu3': {
      'en':
          'By creating an account, you agree to our Terms of Service and Privacy Policy.',
      'af':
          'Deur \'n rekening te skep, stem jy in tot ons Diensbepalings en Privaatheidsbeleid.',
      'fr':
          'En créant un compte, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité.',
    },
    'b4bnwrl7': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    '208c2kyc': {
      'en': 'Update  Account',
      'af': 'Rekening opdateer',
      'fr': 'Mettre à jour le compte',
    },
    '5jgoe0gm': {
      'en': 'Phone Number is required',
      'af': 'Telefoonnommer word vereis',
      'fr': 'Un numéro de téléphone est requis.',
    },
    'aay2fndo': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'dqw218co': {
      'en': 'Password is required',
      'af': 'Wagwoord word vereis',
      'fr': 'Un mot de passe est requis.',
    },
    '3eckbmgm': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'r2pe9e3o': {
      'en': 'Confirm Password is required',
      'af': 'Bevestig wagwoord word vereis',
      'fr': 'Confirmer le mot de passe est requis',
    },
    'i3detnzb': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '049qbet5': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // systemAdminLanding_page
  {
    '5k98dttp': {
      'en': 'System Admin Dashboard',
      'af': 'Stelseladministrateur-dashboard',
      'fr': 'Tableau de bord de l\'administrateur système',
    },
    'klpvpviy': {
      'en': 'Appointments ',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    '7mrui1zp': {
      'en': 'Total',
      'af': 'Totaal',
      'fr': 'Total',
    },
    'p4f1t548': {
      'en': 'Appointments',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'ezsjkbfs': {
      'en': 'Upcoming',
      'af': 'Komende',
      'fr': 'Prochain',
    },
    'cjqhiopy': {
      'en': 'Appointments ',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'g2erbbcz': {
      'en': 'Past',
      'af': 'Verlede',
      'fr': 'Passé',
    },
    'ybeecbwy': {
      'en': 'Appointments ',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'oq204lxv': {
      'en': 'Approval Status',
      'af': 'Goedkeuringsstatus',
      'fr': 'Statut d\'approbation',
    },
    'jb5wtsez': {
      'en': 'Approved',
      'af': 'Totaal',
      'fr': 'Total',
    },
    'pimgf018': {
      'en': 'Applications',
      'af': 'Toepassings',
      'fr': 'Applications',
    },
    'nxldh3mn': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    'ulm3594e': {
      'en': 'Applications',
      'af': 'Toepassings',
      'fr': 'Applications',
    },
    '5veqfumr': {
      'en': 'Rejected',
      'af': 'Verwerp',
      'fr': 'Rejeté',
    },
    'r4mfszme': {
      'en': 'Applications',
      'af': 'Toepassings',
      'fr': 'Applications',
    },
    'gvhzbxrl': {
      'en': 'Application Personels',
      'af': 'Aansoekpersoneel',
      'fr': 'Personnel d\'application',
    },
    'p5wjopx1': {
      'en': 'Medical',
      'af': 'Medies',
      'fr': 'Médical',
    },
    '0kkonkcn': {
      'en': 'Providers',
      'af': 'Verskaffers',
      'fr': 'Fournisseurs',
    },
    '5vutw6vj': {
      'en': 'Active',
      'af': 'Aktief',
      'fr': 'Actif',
    },
    'rfegv1gk': {
      'en': 'Patients',
      'af': 'Pasiënte',
      'fr': 'Patients',
    },
    'rx7aqf8b': {
      'en': 'Facility',
      'af': 'Fasiliteit',
      'fr': 'Facilité',
    },
    'pb7laxfy': {
      'en': 'Admins',
      'af': 'Fasiliteit',
      'fr': 'Facilité',
    },
    'e7xeo2ck': {
      'en': 'Administration',
      'af': 'Administrasie',
      'fr': 'Administration',
    },
    'luvj1sue': {
      'en': 'Appointments',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    '0yi19o8x': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'jn3tzwqn': {
      'en': 'Analytics',
      'af': 'Analise',
      'fr': 'Analytique',
    },
    'u0hc16t3': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'm5hszuxg': {
      'en': 'Providers',
      'af': 'Verskaffers',
      'fr': 'Fournisseurs',
    },
    'tq9uv1hc': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'q9fgvo3s': {
      'en': 'Patients',
      'af': 'Pasiënte',
      'fr': 'Patients',
    },
    '6978spsi': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    's775hyga': {
      'en': 'Admins',
      'af': 'Administrateurs',
      'fr': 'Administrateurs',
    },
    'qikkjtmb': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'o8wueu42': {
      'en': 'Facilities',
      'af': 'Fasiliteite',
      'fr': 'Installations',
    },
    'o71nb4wb': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'xmetg7uj': {
      'en': 'Admin Actions',
      'af': 'Admin-aksies',
      'fr': 'Actions de l\'administrateur',
    },
    'lbzkep8o': {
      'en': 'Add Facility',
      'af': 'Voeg Sorgsentrum by',
      'fr': 'Ajouter un centre de soins',
    },
    '5vmynu6p': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // facilityAdminLanding_page
  {
    'm6w4wcn6': {
      'en': 'Appointments ',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'xbeefcro': {
      'en': 'Total',
      'af': 'Totaal',
      'fr': 'Total',
    },
    'k1vv6grv': {
      'en': 'Appointments',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'c53nvmo9': {
      'en': 'Upcoming',
      'af': 'Komende',
      'fr': 'Prochain',
    },
    '1kq07o3n': {
      'en': 'Appointments ',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    '5q2mdw92': {
      'en': 'Past',
      'af': 'Verlede',
      'fr': 'Passé',
    },
    'ecr9u3z6': {
      'en': 'Appointments ',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'tntt30ls': {
      'en': 'Approval Status',
      'af': 'Goedkeuringsstatus',
      'fr': 'Statut d\'approbation',
    },
    'twbxj99l': {
      'en': 'Total',
      'af': 'Totaal',
      'fr': 'Total',
    },
    'retp7b02': {
      'en': 'Practitioners',
      'af': 'Toepassings',
      'fr': 'Applications',
    },
    'zpv2zaw2': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    '4ofexwg0': {
      'en': 'Practitioners',
      'af': 'Toepassings',
      'fr': 'Applications',
    },
    'suw19763': {
      'en': 'Rejected',
      'af': 'Verwerp',
      'fr': 'Rejeté',
    },
    'rrdp89im': {
      'en': 'Practitioners',
      'af': 'Toepassings',
      'fr': 'Applications',
    },
    'bsbue0vu': {
      'en': 'Application Personels',
      'af': 'Aansoekpersoneel',
      'fr': 'Personnel d\'application',
    },
    'f3av4933': {
      'en': 'Medical',
      'af': 'Medies',
      'fr': 'Médical',
    },
    'eifsmnqr': {
      'en': 'Providers',
      'af': 'Verskaffers',
      'fr': 'Fournisseurs',
    },
    'su2u10r3': {
      'en': 'Active',
      'af': 'Aktief',
      'fr': 'Actif',
    },
    'poxdgw5u': {
      'en': 'Patients',
      'af': 'Pasiënte',
      'fr': 'Patients',
    },
    'q4nqn2zw': {
      'en': 'Facility',
      'af': 'Fasiliteit',
      'fr': 'Facilité',
    },
    'iujo05gi': {
      'en': 'Admins',
      'af': 'Administrateurs',
      'fr': 'Administrateurs',
    },
    'twmudscs': {
      'en': 'Administration',
      'af': 'Administrasie',
      'fr': 'Administration',
    },
    'zxrh940q': {
      'en': 'Appointments',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'lwy1fwfj': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'jm8tn3nm': {
      'en': 'Analytics',
      'af': 'Analise',
      'fr': 'Analytique',
    },
    '6ymo9k5r': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'pkd1jei0': {
      'en': 'Providers',
      'af': 'Verskaffers',
      'fr': 'Fournisseurs',
    },
    'l9u7pklp': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'lmguxitg': {
      'en': 'Patients',
      'af': 'Pasiënte',
      'fr': 'Patients',
    },
    'ibux0asx': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    'pck8z3tc': {
      'en': 'Payments',
      'af': 'Administrateurs',
      'fr': 'Administrateurs',
    },
    '846wlfrf': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    '2enxfwzq': {
      'en': 'Facility',
      'af': 'Administrateurs',
      'fr': 'Administrateurs',
    },
    'ito1cmcj': {
      'en': 'View Details',
      'af': 'Bekyk Besonderhede',
      'fr': 'Voir les détails',
    },
    '6755vkpx': {
      'en': 'Facility Performance',
      'af': 'Fasiliteitsprestasie',
      'fr': 'Performance des installations',
    },
    '46eftkgc': {
      'en': 'This Month',
      'af': 'Hierdie Maand',
      'fr': 'Ce mois-ci',
    },
    'krgu0fh7': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'w7b12zk8': {
      'en': 'This Month',
      'af': 'Hierdie Maand',
      'fr': 'Ce mois-ci',
    },
    'y62wxfv7': {
      'en': 'Last Month',
      'af': 'Verlede Maand',
      'fr': 'Mois dernier',
    },
    '1rzs3170': {
      'en': 'Last 3 Months',
      'af': 'Laaste 3 Maande',
      'fr': 'Les 3 derniers mois',
    },
    '15qggd9j': {
      'en': 'Consultations',
      'af': 'Konsultasies',
      'fr': 'Consultations',
    },
    'splq5nbt': {
      'en': '0',
      'af': '1 245',
      'fr': '1 245',
    },
    'w4j7oqg8': {
      'en': 'Patient Satisfaction',
      'af': 'Pasiënttevredenheid',
      'fr': 'Satisfaction des patients',
    },
    'txzwejdo': {
      'en': '0/0',
      'af': '4.8/5',
      'fr': '4,8/5',
    },
    '4l8z5gbd': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // PatientProfile_page
  {
    '0uof2asm': {
      'en': 'Profile Home',
      'af': 'Profiel Tuisblad',
      'fr': 'Profil Accueil',
    },
    'jc34sgps': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    '0tf6kwss': {
      'en': 'Full Name:',
      'af': 'Volle Naam:',
      'fr': 'Nom et prénom:',
    },
    'y1fl567h': {
      'en': 'Date of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'qhwww1bc': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'ezaaenyl': {
      'en': 'Identity Information',
      'af': 'Identiteitsinligting',
      'fr': 'Informations d\'identité',
    },
    'v222sm6v': {
      'en': 'National ID #:',
      'af': 'Nasionale ID-nommer:',
      'fr': 'Numéro d\'identification national :',
    },
    '1927t15f': {
      'en': 'National ID Issue Date:',
      'af': 'Nasionale ID-uitreikingsdatum:',
      'fr': 'Date de délivrance de la CNI:',
    },
    'ffatc7r4': {
      'en': 'National ID Exp Date:',
      'af': 'Nasionale ID-vervaldatum:',
      'fr': 'Date d\'expiration de la CNI :',
    },
    'ykf3kz2l': {
      'en': 'Contact Information',
      'af': 'Kontakbesonderhede',
      'fr': 'Coordonnées',
    },
    'tuted4hc': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    '2qp5obsz': {
      'en': 'Address:',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    '25554rm6': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    '7tvvd899': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'z7e2kxe1': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    'c6bboitt': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'pzsgv8es': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    '9pw4g3ou': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    '5lh40ci4': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'wwbxdvfx': {
      'en': 'CareCenter',
      'af': 'Sorgsentrum',
      'fr': 'Centre de soins',
    },
  },
  // HomePage
  {
    'hksu6dmf': {
      'en': 'Features',
      'af': 'Kenmerke',
      'fr': 'Fonctionnalités',
    },
    '5av0harn': {
      'en': 'Publications',
      'af': 'Publikasies',
      'fr': 'Publications',
    },
    'g1il742n': {
      'en': 'About us',
      'af': 'Oor ons',
      'fr': 'À propos de nous',
    },
    '7ofyvltg': {
      'en': 'Healthcare at Your Fingertips',
      'af': 'Gesondheidsorg binne jou vingerpunte',
      'fr': 'Des soins de santé à portée de main',
    },
    's92ek7hm': {
      'en':
          'Connect with doctors, nurses, and healthcare providers from the comfort of your home. Our telemedicine platform makes healthcare accessible to everyone,  anywhere at anytime.',
      'af':
          'Kontak dokters, verpleegsters en gesondheidsorgverskaffers vanuit die gemak van jou huis. Ons telemedisyne-platform maak gesondheidsorg toeganklik vir almal, enige plek en enige tyd.',
      'fr':
          'Consultez des médecins, des infirmières et d\'autres professionnels de la santé depuis chez vous. Notre plateforme de télémédecine rend les soins de santé accessibles à tous, partout et à tout moment.',
    },
    'pyq96kxp': {
      'en': 'Get Started',
      'af': 'Begin',
      'fr': 'Commencer',
    },
    '6na0py29': {
      'en': 'Healthcare at Your Fingertips',
      'af': 'Gesondheidsorg binne jou vingerpunte',
      'fr': 'Des soins de santé à portée de main',
    },
    'cj7kxrbl': {
      'en':
          'Connect with doctors, nurses, and healthcare providers from the comfort of your home. Our telemedicine platform makes healthcare accessible to everyone,  anywhere at anytime.',
      'af':
          'Kontak dokters, verpleegsters en gesondheidsorgverskaffers vanuit die gemak van jou huis. Ons telemedisyne-platform maak gesondheidsorg toeganklik vir almal, enige plek en enige tyd.',
      'fr':
          'Consultez des médecins, des infirmières et d\'autres professionnels de la santé depuis chez vous. Notre plateforme de télémédecine rend les soins de santé accessibles à tous, partout et à tout moment.',
    },
    'apc14u4r': {
      'en': 'Get Started',
      'af': 'Begin',
      'fr': 'Commencer',
    },
    '0oa9ytlz': {
      'en': 'Platform Overview',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    'as4pcyl2': {
      'en': 'Available on web, iOS, and Android devices',
      'af': 'Beskikbaar op web-, iOS- en Android-toestelle',
      'fr': 'Disponible sur le Web, iOS et Android',
    },
    '1o9snxy5': {
      'en':
          'MedZen is a state-of-the-art telehealth platform designed to connect patients with healthcare providers through secure, HIPAA-compliant video consultations. ',
      'af':
          'MedZen is \'n moderne telehealth-platform wat ontwerp is om pasiënte met gesondheidsorgverskaffers te verbind deur middel van veilige, HIPAA-voldoenende videokonsultasies.',
      'fr':
          'MedZen est une plateforme de télésanté de pointe conçue pour mettre en relation les patients et les professionnels de santé grâce à des consultations vidéo sécurisées et conformes à la loi HIPAA.',
    },
    '1zp9rjm9': {
      'en':
          'We are delivering healthcare to Africa\'s most remote communities with nothing more than a basic phone and a simple text message. No internet required. No smartphone needed. Just revolutionary care, accessible to all. ',
      'af':
          'Ons lewer gesondheidsorg aan Afrika se mees afgeleë gemeenskappe met niks meer as \'n basiese foon en \'n eenvoudige teksboodskap nie. Geen internet nodig nie. Geen slimfoon nodig nie. Net revolusionêre sorg, toeganklik vir almal.',
      'fr':
          'Nous offrons des soins de santé aux communautés les plus reculées d\'Afrique grâce à un simple téléphone portable et un SMS. Pas besoin d\'internet ni de smartphone. Des soins révolutionnaires, accessibles à tous.',
    },
    '5vrc2k19': {
      'en':
          'MedZen provides 24/7 access to healthcare services from anywhere with an internet connection. ',
      'af':
          'MedZen bied 24/7 toegang tot gesondheidsorgdienste vanaf enige plek met \'n internetverbinding.',
      'fr':
          'MedZen offre un accès 24h/24 et 7j/7 aux services de santé, où que vous soyez, grâce à une connexion internet.',
    },
    'innlqhfp': {
      'en': 'Core Platform Features',
      'af': 'Kernplatformkenmerke',
      'fr': 'Fonctionnalités principales de la plateforme',
    },
    'vx0wkh1u': {
      'en':
          'Medzen offers a comprehensive set of features that power our telehealth ecosystem.',
      'af':
          'Medzen bied \'n omvattende stel funksies wat ons telehealth-ekosisteem aandryf.',
      'fr':
          'Medzen offre un ensemble complet de fonctionnalités qui alimentent notre écosystème de télésanté.',
    },
    'hxffv6ac': {
      'en': 'HD Video Consultations',
      'af': 'HD-videokonsultasies',
      'fr': 'Consultations vidéo HD',
    },
    'reuo7dya': {
      'en':
          'High-definition, secure video consultations with healthcare providers through our stable, optimized platform.',
      'af':
          'Hoë-definisie, veilige videokonsultasies met gesondheidsorgverskaffers deur ons stabiele, geoptimaliseerde platform.',
      'fr':
          'Consultations vidéo sécurisées en haute définition avec des professionnels de santé via notre plateforme stable et optimisée.',
    },
    'sbyldo5p': {
      'en': 'Smart Scheduling',
      'af': 'Slim skedulering',
      'fr': 'Planification intelligente',
    },
    'uujvmr71': {
      'en':
          'Intuitive appointment scheduling with real-time availability, reminders, and calendar integrations.',
      'af':
          'Intuïtiewe afspraakskedulering met intydse beskikbaarheid, herinneringe en kalenderintegrasies.',
      'fr':
          'Planification intuitive des rendez-vous avec disponibilité en temps réel, rappels et intégrations de calendrier.',
    },
    'nbcymsg1': {
      'en': 'Electronic Prescriptions',
      'af': 'Elektroniese Voorskrifte',
      'fr': 'Ordonnances électroniques',
    },
    '38eekwnf': {
      'en':
          'Digital prescription services with direct pharmacy integration and medication management tools.',
      'af':
          'Digitale voorskrifdienste met direkte apteekintegrasie en medikasiebestuursinstrumente.',
      'fr':
          'Services de prescription numérique avec intégration directe avec les pharmacies et outils de gestion des médicaments.',
    },
    '4wf77k8a': {
      'en': 'Secure Messaging',
      'af': 'Veilige Boodskappe',
      'fr': 'Messagerie sécurisée',
    },
    'xo1oah3h': {
      'en':
          'HIPAA-compliant messaging system for secure communication between patients and providers.',
      'af':
          'HIPAA-voldoenende boodskapstelsel vir veilige kommunikasie tussen pasiënte en verskaffers.',
      'fr':
          'Système de messagerie conforme à la loi HIPAA pour une communication sécurisée entre patients et prestataires de soins.',
    },
    'askx2ywh': {
      'en': 'SMS Access',
      'af': 'SMS-toegang',
      'fr': 'Accès SMS',
    },
    'k3naxyb3': {
      'en': 'No internet needed',
      'af': 'Geen internet nodig nie',
      'fr': 'Internet non requis',
    },
    'pf6hh0r0': {
      'en': 'USSD Access',
      'af': 'USSD-toegang',
      'fr': 'Accès USSD',
    },
    '143gbjyp': {
      'en': 'No internet needed',
      'af': 'Geen internet nodig nie',
      'fr': 'Internet non requis',
    },
    'bverdr6n': {
      'en': 'Core Platform Features',
      'af': 'Kernplatformkenmerke',
      'fr': 'Fonctionnalités principales de la plateforme',
    },
    'esk8pn2d': {
      'en':
          'MedZen offers a comprehensive set of features that power our telehealth ecosystem.',
      'af':
          'MedZen bied \'n omvattende stel funksies wat ons telehealth-ekosisteem aandryf.',
      'fr':
          'MedZen offre un ensemble complet de fonctionnalités qui alimentent notre écosystème de télésanté.',
    },
    '885wc1l2': {
      'en': 'HD Video Consultations',
      'af': 'HD-videokonsultasies',
      'fr': 'Consultations vidéo HD',
    },
    'h3xbsnhq': {
      'en':
          'High-definition, secure video consultations with healthcare providers through our stable, optimized platform.',
      'af':
          'Hoë-definisie, veilige videokonsultasies met gesondheidsorgverskaffers deur ons stabiele, geoptimaliseerde platform.',
      'fr':
          'Consultations vidéo sécurisées en haute définition avec des professionnels de santé via notre plateforme stable et optimisée.',
    },
    '2t7scj90': {
      'en': 'Smart Scheduling',
      'af': 'Slim skedulering',
      'fr': 'Planification intelligente',
    },
    '6rl42nkl': {
      'en':
          'Intuitive appointment scheduling with real-time availability, reminders, and calendar integrations.',
      'af':
          'Intuïtiewe afspraakskedulering met intydse beskikbaarheid, herinneringe en kalenderintegrasies.',
      'fr':
          'Planification intuitive des rendez-vous avec disponibilité en temps réel, rappels et intégrations de calendrier.',
    },
    'u069fo89': {
      'en': 'Electronic Health Reacords ( EHR )',
      'af': 'Elektroniese Gesondheidsrekords (EHR)',
      'fr': 'Dossiers de santé électroniques (DSE)',
    },
    'hunxp0e3': {
      'en':
          'Comprehensive digital health records system with integrated prescription services, pharmacy connectivity, and smart medication management tools.',
      'af':
          'Omvattende digitale gesondheidsrekordstelsel met geïntegreerde voorskrifdienste, apteekkonnektiwiteit en slim medikasiebestuursinstrumente.',
      'fr':
          'Système complet de dossiers médicaux numériques avec services de prescription intégrés, connectivité avec les pharmacies et outils intelligents de gestion des médicaments.',
    },
    'wpggws0f': {
      'en': 'Secure Messaging',
      'af': 'Veilige Boodskappe',
      'fr': 'Messagerie sécurisée',
    },
    '8gd340h1': {
      'en':
          'HIPAA-compliant messaging system for secure communication between patients and providers.',
      'af':
          'HIPAA-voldoenende boodskapstelsel vir veilige kommunikasie tussen pasiënte en verskaffers.',
      'fr':
          'Système de messagerie conforme à la loi HIPAA pour une communication sécurisée entre patients et prestataires de soins.',
    },
    '586o3ukn': {
      'en': 'SMS Access',
      'af': 'SMS-toegang',
      'fr': 'Accès SMS',
    },
    '9oaz6cs6': {
      'en': 'No internet needed',
      'af': 'Geen internet nodig nie',
      'fr': 'Internet non requis',
    },
    'h8fbd5kc': {
      'en': 'USSD Access',
      'af': 'USSD-toegang',
      'fr': 'Accès USSD',
    },
    'niegufh2': {
      'en': 'No internet needed',
      'af': 'Geen internet nodig nie',
      'fr': 'Internet non requis',
    },
    'jydphx9u': {
      'en': 'Features',
      'af': 'Kenmerke',
      'fr': 'Caractéristiques',
    },
    '89hacu0l': {
      'en': 'Publications',
      'af': 'Publikasies',
      'fr': 'Publications',
    },
    '2a5wwtx5': {
      'en': 'About Us',
      'af': 'Oor Ons',
      'fr': 'À propos de nous',
    },
    '2et0d5gg': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Features
  {
    'ejlzgxyk': {
      'en': 'MedZen Health Features',
      'af': 'MedZen Gesondheidskenmerke',
      'fr': 'Fonctionnalités santé de MedZen',
    },
    'k33pgxu6': {
      'en': 'Comprehensive Telehealth Solutions for Modern Healthcare Needs',
      'af':
          'Omvattende telehealth-oplossings vir moderne gesondheidsorgbehoeftes',
      'fr':
          'Solutions de télésanté complètes pour les besoins de santé modernes',
    },
    'p70jsrg0': {
      'en': 'Platform Overview',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    '1ka4yavl': {
      'en':
          'BEYOND BARRIERS, BEYOND BOUNDARIES\nMedZen is a state-of-the-art telehealth platform designed to connect patients with healthcare providers through secure, HIPAA-compliant video consultations. Our feature-rich platform offers a comprehensive suite of tools for both patients and providers, creating a seamless virtual healthcare experience.',
      'af':
          'VERBY HINDRINGS, VERBY GRENSE\nMedZen is \'n moderne telehealth-platform wat ontwerp is om pasiënte met gesondheidsorgverskaffers te verbind deur middel van veilige, HIPAA-voldoenende videokonsultasies. Ons funksie-ryke platform bied \'n omvattende reeks gereedskap vir beide pasiënte en verskaffers, wat \'n naatlose virtuele gesondheidsorgervaring skep.',
      'fr':
          'AU-DELÀ DES BARRIÈRES, AU-DELÀ DES LIMITES\nMedZen est une plateforme de télésanté de pointe conçue pour mettre en relation patients et professionnels de santé grâce à des consultations vidéo sécurisées et conformes à la loi HIPAA. Notre plateforme riche en fonctionnalités offre une gamme complète d\'outils pour les patients et les professionnels de santé, créant ainsi une expérience de soins virtuels optimale.',
    },
    'ni63nrvo': {
      'en':
          'Where others stop at the digital divide, we break through—delivering healthcare to Africa\'s most remote communities with nothing more than a basic phone and a simple text message. No internet required. No smartphone needed. Just revolutionary care, accessible to all.',
      'af':
          'Waar ander by die digitale kloof stop, breek ons ​​deur—en lewer gesondheidsorg aan Afrika se mees afgeleë gemeenskappe met niks meer as \'n basiese foon en \'n eenvoudige SMS nie. Geen internet nodig nie. Geen slimfoon nodig nie. Net revolusionêre sorg, toeganklik vir almal.',
      'fr':
          'Là où d\'autres s\'arrêtent face à la fracture numérique, nous la surmontons : nous offrons des soins de santé aux communautés les plus reculées d\'Afrique grâce à un simple téléphone portable et un SMS. Pas besoin d\'internet ni de smartphone. Des soins révolutionnaires, accessibles à tous.',
    },
    'edqe01sg': {
      'en':
          'Available on web, iOS, and Android devices, MedZen provides 24/7 access to healthcare services from anywhere with an internet connection. From on-demand consultations to scheduled appointments, prescription management to secure messaging, our platform delivers the tools needed for effective virtual care.',
      'af':
          'MedZen is beskikbaar op web-, iOS- en Android-toestelle en bied 24/7 toegang tot gesondheidsorgdienste vanaf enige plek met \'n internetverbinding. Van konsultasies op aanvraag tot geskeduleerde afsprake, voorskrifbestuur tot veilige boodskappe, ons platform lewer die gereedskap wat nodig is vir effektiewe virtuele sorg.',
      'fr':
          'Disponible sur le web, iOS et Android, MedZen offre un accès 24h/24 et 7j/7 aux services de santé, où que vous soyez, grâce à une connexion internet. Consultations à la demande, rendez-vous programmés, gestion des ordonnances, messagerie sécurisée : notre plateforme fournit tous les outils nécessaires à une prise en charge virtuelle efficace.',
    },
    '8llyklqh': {
      'en': 'Core Platform Features',
      'af': 'Kernplatformkenmerke',
      'fr': 'Fonctionnalités principales ',
    },
    'nv7qc1h3': {
      'en':
          'MedZen offers a comprehensive set of features that power our telehealth ecosystem.',
      'af':
          'MedZen bied \'n omvattende stel funksies wat ons telehealth-ekosisteem aandryf.',
      'fr':
          'MedZen offre un ensemble complet de fonctionnalités qui alimentent notre écosystème de télésanté.',
    },
    'k3ql1c03': {
      'en': 'HD Video Consultations',
      'af': 'HD-videokonsultasies',
      'fr': 'Consultations vidéo HD',
    },
    'jw0qepf6': {
      'en':
          'High-definition, secure video consultations with healthcare providers through our stable, optimized platform.',
      'af':
          'Hoë-definisie, veilige videokonsultasies met gesondheidsorgverskaffers deur ons stabiele, geoptimaliseerde platform.',
      'fr':
          'Consultations vidéo sécurisées en haute définition avec des professionnels de santé via notre plateforme stable et optimisée.',
    },
    'eros8u93': {
      'en': 'Smart Scheduling',
      'af': 'Slim skedulering',
      'fr': 'Planification intelligente',
    },
    '36t547p1': {
      'en':
          'Intuitive appointment scheduling with real-time availability, reminders, and calendar integrations.',
      'af':
          'Intuïtiewe afspraakskedulering met intydse beskikbaarheid, herinneringe en kalenderintegrasies.',
      'fr':
          'Planification intuitive des rendez-vous avec disponibilité en temps réel, rappels et intégrations de calendrier.',
    },
    'eb3dofyl': {
      'en': 'Electronic Prescriptions',
      'af': 'Elektroniese Voorskrifte',
      'fr': 'Ordonnances électroniques',
    },
    '7cshp1sd': {
      'en':
          'Digital prescription services with direct pharmacy integration and medication management tools.',
      'af':
          'Digitale voorskrifdienste met direkte apteekintegrasie en medikasiebestuursinstrumente.',
      'fr':
          'Services de prescription numérique avec intégration directe avec les pharmacies et outils de gestion des médicaments.',
    },
    'ysg9tdhx': {
      'en': 'Secure Messaging',
      'af': 'Veilige Boodskappe',
      'fr': 'Messagerie sécurisée',
    },
    'dpc7fbh6': {
      'en':
          'HIPAA-compliant messaging system for secure communication between patients and providers.',
      'af':
          'HIPAA-voldoenende boodskapstelsel vir veilige kommunikasie tussen pasiënte en verskaffers.',
      'fr':
          'Système de messagerie conforme à la loi HIPAA pour une communication sécurisée entre patients et prestataires de soins.',
    },
    '6ermoqsu': {
      'en': 'HD Video Consultations',
      'af': 'HD-videokonsultasies',
      'fr': 'Consultations vidéo HD',
    },
    '9tkg4k7k': {
      'en':
          'High-definition, secure video consultations with healthcare providers through our stable, optimized platform.',
      'af':
          'Hoë-definisie, veilige videokonsultasies met gesondheidsorgverskaffers deur ons stabiele, geoptimaliseerde platform.',
      'fr':
          'Consultations vidéo sécurisées en haute définition avec des professionnels de santé via notre plateforme stable et optimisée.',
    },
    '6mfss3h1': {
      'en': 'Smart Scheduling',
      'af': 'Slim skedulering',
      'fr': 'Planification intelligente',
    },
    'xl8fyfyf': {
      'en':
          'Intuitive appointment scheduling with real-time availability, reminders, and calendar integrations.',
      'af':
          'Intuïtiewe afspraakskedulering met intydse beskikbaarheid, herinneringe en kalenderintegrasies.',
      'fr':
          'Planification intuitive des rendez-vous avec disponibilité en temps réel, rappels et intégrations de calendrier.',
    },
    '7e402bio': {
      'en': 'Electronic Prescriptions',
      'af': 'Elektroniese Voorskrifte',
      'fr': 'Ordonnances électroniques',
    },
    'pnodkgwg': {
      'en':
          'Digital prescription services with direct pharmacy integration and medication management tools.',
      'af':
          'Digitale voorskrifdienste met direkte apteekintegrasie en medikasiebestuursinstrumente.',
      'fr':
          'Services de prescription numérique avec intégration directe avec les pharmacies et outils de gestion des médicaments.',
    },
    'd171j5ti': {
      'en': 'Secure Messaging',
      'af': 'Veilige Boodskappe',
      'fr': 'Messagerie sécurisée',
    },
    '44rreimr': {
      'en':
          'HIPAA-compliant messaging system for secure communication between patients and providers.',
      'af':
          'HIPAA-voldoenende boodskapstelsel vir veilige kommunikasie tussen pasiënte en verskaffers.',
      'fr':
          'Système de messagerie conforme à la loi HIPAA pour une communication sécurisée entre patients et prestataires de soins.',
    },
    'acubk4yn': {
      'en': 'Patient-Centered Features',
      'af': 'Pasiëntgesentreerde kenmerke',
      'fr': 'Caractéristiques axées sur le patient',
    },
    'f9ofl3b9': {
      'en':
          'MedZen puts patients first with features designed to enhance the virtual healthcare experience.',
      'af':
          'MedZen stel pasiënte eerste met funksies wat ontwerp is om die virtuele gesondheidsorgervaring te verbeter.',
      'fr':
          'MedZen place les patients au premier plan grâce à des fonctionnalités conçues pour améliorer l\'expérience des soins de santé virtuels.',
    },
    'z2ililfd': {
      'en': 'Provider Directory & Reviews',
      'af': 'Verskaffersgids en resensies',
      'fr': 'Annuaire des prestataires et avis',
    },
    'cekyawbv': {
      'en':
          'Browse our comprehensive directory of healthcare providers with detailed profiles, credentials, specialties, and verified patient reviews to help you find the right provider for your needs.',
      'af':
          'Blaai deur ons omvattende gids van gesondheidsorgverskaffers met gedetailleerde profiele, geloofsbriewe, spesialiteite en geverifieerde pasiëntresensies om jou te help om die regte verskaffer vir jou behoeftes te vind.',
      'fr':
          'Consultez notre répertoire complet de professionnels de la santé, avec des profils détaillés, leurs qualifications, leurs spécialités et des avis de patients vérifiés, pour vous aider à trouver le professionnel qui répond à vos besoins.',
    },
    '97zb1ggr': {
      'en': 'On-Demand & Scheduled Care',
      'af': 'Sorg op aanvraag en geskeduleerde sorg',
      'fr': 'Soins à la demande et programmés',
    },
    '9e4rooie': {
      'en':
          'Choose between immediate on-demand consultations when you need care right away, or schedule appointments at your convenience with your preferred healthcare providers.',
      'af':
          'Kies tussen onmiddellike konsultasies op aanvraag wanneer u dadelik sorg benodig, of skeduleer afsprake op u gemak met u voorkeur-gesondheidsorgverskaffers.',
      'fr':
          'Choisissez entre des consultations immédiates à la demande lorsque vous avez besoin de soins sans délai, ou prenez rendez-vous à votre convenance avec vos prestataires de soins de santé préférés.',
    },
    'fkstcpwg': {
      'en': 'Provider Features',
      'af': 'Verskafferkenmerke',
      'fr': 'Fonctionnalités du fournisseur',
    },
    '8plsrqec': {
      'en':
          'MedZen equips healthcare providers with powerful tools to deliver exceptional virtual care.',
      'af':
          'MedZen rus gesondheidsorgverskaffers toe met kragtige gereedskap om uitsonderlike virtuele sorg te lewer.',
      'fr':
          'MedZen fournit aux professionnels de la santé des outils performants pour offrir des soins virtuels exceptionnels.',
    },
    'sxozu8xt': {
      'en': 'Virtual Waiting Room',
      'af': 'Virtuele wagkamer',
      'fr': 'Salle d\'attente virtuelle',
    },
    '19fv3495': {
      'en':
          'Manage your patient queue efficiently with our virtual waiting room, complete with estimated wait times and the ability to prioritize urgent cases.',
      'af':
          'Bestuur u pasiëntwaglys doeltreffend met ons virtuele wagkamer, kompleet met beraamde wagtye en die vermoë om dringende gevalle te prioritiseer.',
      'fr':
          'Gérez efficacement votre file d\'attente de patients grâce à notre salle d\'attente virtuelle, qui affiche les temps d\'attente estimés et permet de prioriser les cas urgents.',
    },
    'rmzpx272': {
      'en': 'Clinical Documentation',
      'af': 'Kliniese Dokumentasie',
      'fr': 'Documentation clinique',
    },
    'lmlayfgl': {
      'en':
          'Streamlined documentation tools with customizable templates, voice-to-text capabilities, and automatic integration with patient records.',
      'af':
          'Gestroomlynde dokumentasie-instrumente met aanpasbare sjablone, stem-na-teks-vermoëns en outomatiese integrasie met pasiëntrekords.',
      'fr':
          'Outils de documentation simplifiés avec des modèles personnalisables, des fonctionnalités de transcription vocale et une intégration automatique avec les dossiers des patients.',
    },
    'hkw1x08x': {
      'en': 'Request Demo',
      'af': 'Versoek demonstrasie',
      'fr': 'Demander une démo',
    },
    'h47fs7m8': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // AboutUs
  {
    '1kv40o6e': {
      'en': 'About US',
      'af': 'Oor ONS',
      'fr': 'À propos de nous',
    },
    'cwfzbnw6': {
      'en':
          'MedZen is a telemedicine platform designed to provide seamless healthcare services remotely. Whether you need a consultation with a doctor, medical advice from a nurse, or urgent care assistance, MedZen connects you with certified healthcare providers anytime, anywhere.',
      'af':
          'MedZen is \'n telemedisyne-platform wat ontwerp is om naatlose gesondheidsorgdienste op afstand te verskaf. Of jy nou \'n konsultasie met \'n dokter, mediese advies van \'n verpleegster of dringende sorgbystand benodig, MedZen verbind jou enige tyd en enige plek met gesertifiseerde gesondheidsorgverskaffers.',
      'fr':
          'MedZen est une plateforme de télémédecine conçue pour fournir des services de santé à distance. Que vous ayez besoin d\'une consultation avec un médecin, de conseils médicaux d\'une infirmière ou d\'une assistance urgente, MedZen vous met en relation avec des professionnels de santé certifiés, à tout moment et où que vous soyez.',
    },
    'bt1wf2ej': {
      'en': 'Meet Our Providers',
      'af': 'Ontmoet ons verskaffers',
      'fr': 'Découvrez nos prestataires',
    },
    'y8u58yvf': {
      'en':
          'Our platform hosts a network of licensed doctors, nurses, and medical professionals ready to assist you. Each provider is vetted and verified to ensure high-quality healthcare services. You can search for specialists, nearby hospitals, and even facilities with incubators or blood banks.',
      'af':
          'Ons platform huisves \'n netwerk van gelisensieerde dokters, verpleegsters en mediese professionele persone wat gereed is om jou te help. Elke verskaffer word gekeur en geverifieer om hoëgehalte gesondheidsorgdienste te verseker. Jy kan soek na spesialiste, nabygeleë hospitale en selfs fasiliteite met broeikaste of bloedbanke.',
      'fr':
          'Notre plateforme vous donne accès à un réseau de médecins, d\'infirmières et de professionnels de santé agréés, prêts à vous aider. Chaque professionnel est sélectionné et vérifié afin de garantir des soins de qualité. Vous pouvez rechercher des spécialistes, des hôpitaux à proximité et même des établissements disposant d\'incubateurs ou de banques de sang.',
    },
    't0btruiu': {
      'en': 'Key Features',
      'af': 'Belangrike kenmerke',
      'fr': 'Caractéristiques principales',
    },
    'qmnfui29': {
      'en':
          'Virtual or In-person consultations with doctors, nurses and other healthcare providers.',
      'af':
          'Virtuele of persoonlike konsultasies met dokters, verpleegsters en ander gesondheidsorgverskaffers.',
      'fr':
          'Consultations virtuelles ou en personne avec des médecins, des infirmières et d\'autres professionnels de la santé.',
    },
    '6tz78ivi': {
      'en': 'Easy appointment scheduling',
      'af': 'Maklike afspraakskedulering',
      'fr': 'Prise de rendez-vous facile',
    },
    'ghxgv4v5': {
      'en': 'Secure medical records management',
      'af': 'Veilige bestuur van mediese rekords',
      'fr': 'Gestion sécurisée des dossiers médicaux',
    },
    'kdkpfs5i': {
      'en': 'Search for nearby hospitals, blood banks, and incubators',
      'af': 'Soek vir nabygeleë hospitale, bloedbanke en broeikaste',
      'fr':
          'Recherchez les hôpitaux, les banques de sang et les incubateurs à proximité.',
    },
    'hxerdaub': {
      'en':
          'Seamless payment integration with MTN Mobile Money and Orange Money',
      'af': 'Naatlose betalingsintegrasie met MTN Mobile Money en Orange Money',
      'fr':
          'Intégration fluide des paiements avec MTN Mobile Money et Orange Money',
    },
    'tivtn12s': {
      'en': 'Real-time notifications for appointments',
      'af': 'Kennisgewings intyds vir afsprake',
      'fr': 'Notifications en temps réel pour les rendez-vous',
    },
    'f7034p4e': {
      'en': 'Get in Touch',
      'af': 'Kontak Ons',
      'fr': 'Entrer en contact',
    },
    'keqdc4ga': {
      'en': '📱',
      'af': '📱',
      'fr': '📱',
    },
    'b4lsvkka': {
      'en': 'Phone',
      'af': 'Foon',
      'fr': 'Téléphone',
    },
    '7g4iv484': {
      'en': '+1 (800) 555-1234',
      'af': '+1 (800) 555-1234',
      'fr': '+1 (800) 555-1234',
    },
    's8upyphn': {
      'en': 'Mon-Fri: 8AM-8PM EST',
      'af': 'Ma-Vr: 8VM-8NM EST',
      'fr': 'Du Lundi au Vendredi : de 8 h à 20 h',
    },
    'ek1e58vt': {
      'en': '✉️',
      'af': '✉️',
      'fr': '✉️',
    },
    'mkmmngsy': {
      'en': 'Email',
      'af': 'E-pos',
      'fr': 'E-mail',
    },
    'n2y6lite': {
      'en': 'support@medihealth.app',
      'af': 'ondersteuning@medihealth.app',
      'fr': 'support@medihealth.app',
    },
    '7i33yfye': {
      'en': 'info@medihealth.app',
      'af': 'info@medihealth.app',
      'fr': 'info@medihealth.app',
    },
    'nj4cgxxm': {
      'en': '📍',
      'af': '📍',
      'fr': '📍',
    },
    '5815ogbz': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    '17xltufi': {
      'en': '123 Health Avenue, Suite 500',
      'af': '123 Healthlaan, Suite 500',
      'fr': '123, avenue de la Santé, bureau 500',
    },
    'xtwonk3q': {
      'en': 'Boston, MA 02108',
      'af': 'Boston, MA 02108',
      'fr': 'Boston, MA 02108',
    },
    'p07dv1qt': {
      'en': '💬',
      'af': '💬',
      'fr': '💬',
    },
    'f8v0lxpa': {
      'en': 'Live Chat',
      'af': 'Regstreekse klets',
      'fr': 'Chat en direct',
    },
    'newj0h0g': {
      'en': 'Available in our app ',
      'af': 'Beskikbaar in ons app',
      'fr': 'Disponible dans notre application',
    },
    'ke5yz8zs': {
      'en': '24/7 for urgent matters',
      'af': '24/7 vir dringende sake',
      'fr': 'Service disponible 24h/24 et 7j/7 pour les urgences',
    },
    'hdj94lws': {
      'en': 'Connect With Us',
      'af': 'Kontak Ons',
      'fr': 'Contactez-nous',
    },
    'llrtfgvn': {
      'en': 'Send a Message',
      'af': 'Stuur \'n boodskap',
      'fr': 'Envoyer un message',
    },
    'bbn0eqco': {
      'en': 'Full Name',
      'af': 'Volle Naam',
      'fr': 'Nom et prénom',
    },
    '407508ia': {
      'en': 'Email Address',
      'af': 'E-posadres',
      'fr': 'Adresse email',
    },
    'j3n4147n': {
      'en': 'Phone Number (Optional)',
      'af': 'Telefoonnommer (Opsioneel)',
      'fr': 'Numéro de téléphone (facultatif)',
    },
    'w9ace3zu': {
      'en': 'Subject',
      'af': 'Onderwerp',
      'fr': 'Sujet',
    },
    '6l2672od': {
      'en': 'Select a topic',
      'af': 'Kies \'n onderwerp',
      'fr': 'Sélectionnez un sujet',
    },
    'op4dqea4': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '4c0qkhdi': {
      'en': 'Technical Support',
      'af': 'Tegniese Ondersteuning',
      'fr': 'Assistance technique',
    },
    'e6zzolvn': {
      'en': 'Billing Question',
      'af': 'Faktuurvraag',
      'fr': 'Question de facturation',
    },
    'pxsjzcit': {
      'en': 'Account Management',
      'af': 'Rekeningbestuur',
      'fr': 'Gestion de compte',
    },
    '0h0djt5y': {
      'en': 'App Feedback',
      'af': 'Programterugvoer',
      'fr': 'Commentaires sur l\'application',
    },
    'lvxnpb2m': {
      'en': 'Partnership Inquiry',
      'af': 'Vennootskapsondersoek',
      'fr': 'Demande de partenariat',
    },
    'ro0fraex': {
      'en': 'Other',
      'af': 'Ander',
      'fr': 'Autre',
    },
    'nolbm4wm': {
      'en': 'Your Message',
      'af': 'Jou Boodskap',
      'fr': 'Votre message',
    },
    'lwjbbcpk': {
      'en': 'Send Message',
      'af': 'Stuur boodskap',
      'fr': 'Envoyer un message',
    },
    '9huy9fa7': {
      'en': 'Full Name is required',
      'af': '',
      'fr': 'Nom complet est obligatoire.',
    },
    'st36onpj': {
      'en': 'Please choose an option from the dropdown',
      'af': '',
      'fr': 'Sélectionner une option',
    },
    'bso4ym2s': {
      'en': 'Email Address is required',
      'af': 'E-posadres word vereis',
      'fr': 'Une adresse e-mail est obligatoire.',
    },
    '4t2eytpt': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Sélectionner une option.',
    },
    'hg6ao3lp': {
      'en': 'Phone Number  is required',
      'af': 'Telefoonnommer (Opsioneel) word vereis',
      'fr': 'Numéro de téléphone obligatoire',
    },
    'ccad3w2u': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Sélectionner une option.',
    },
    'l1kl12a8': {
      'en': 'Field is required',
      'af': 'Veld is verpligtend',
      'fr': 'Ce champ est obligatoire.',
    },
    'a7pumlen': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Sélectionner une option.',
    },
    '1n6cvstc': {
      'en': 'Frequently Asked Questions',
      'af': 'Gereelde vrae',
      'fr': 'Questions recurrentes',
    },
    '3yu5h2c6': {
      'en': 'How quickly can I expect a response?',
      'af': 'Hoe vinnig kan ek \'n reaksie verwag?',
      'fr': 'Quel est le délai d\'attente pour espérer avoir une réponse ?',
    },
    'y12f3rm9': {
      'en':
          'For general inquiries, we aim to respond within 1 business day. Technical support requests are typically addressed within 4-8 hours. For urgent matters, please use the in-app chat support for faster assistance.',
      'af':
          'Vir algemene navrae streef ons daarna om binne 1 werksdag te reageer. Tegniese ondersteuningsversoeke word gewoonlik binne 4-8 uur hanteer. Vir dringende sake, gebruik asseblief die kletsondersteuning in die toepassing vir vinniger hulp.',
      'fr':
          'Pour toute question d\'ordre général, nous nous efforçons de répondre sous 24 heures ouvrables. Les demandes d\'assistance technique sont généralement traitées sous 4 à 8 heures. Pour les urgences, veuillez utiliser le chat intégré à l\'application pour une assistance plus rapide.',
    },
    '8vf9f37x': {
      'en': 'Is there a way to schedule a meeting with your team?',
      'af': 'Is daar \'n manier om \'n vergadering met jou span te skeduleer?',
      'fr':
          'Existe-t-il un moyen de programmer une réunion avec votre équipe ?',
    },
    '246e20a4': {
      'en':
          'Yes! For partnership inquiries or detailed technical consultations, you can schedule a meeting with our team by sending an email to meetings@medzenhealth.app with your preferred date and time.',
      'af':
          'Ja! Vir vennootskapsnavrae of gedetailleerde tegniese konsultasies, kan u \'n vergadering met ons span skeduleer deur \'n e-pos te stuur na meetings@medihealth.app met u voorkeurdatum en -tyd.',
      'fr':
          'Oui ! Pour toute demande de partenariat ou consultation technique approfondie, vous pouvez programmer une réunion avec notre équipe en envoyant un courriel à meetings@medzenhealth.app en indiquant la date et l\'heure qui vous conviennent.',
    },
    'ime687fx': {
      'en': 'Do you offer phone support on weekends?',
      'af': 'Bied julle telefoniese ondersteuning oor naweke?',
      'fr': 'Proposez-vous une assistance téléphonique le week-end ?',
    },
    'dy8oaogg': {
      'en':
          'Our phone support operates Monday through Friday from 8AM to 8PM EST. For weekend support, please use our in-app chat feature which is available 24/7 for urgent matters.',
      'af':
          'Ons telefoonondersteuning is Maandag tot Vrydag oop van 08:00 tot 20:00 EST. Vir naweekondersteuning, gebruik asseblief ons kletsfunksie in die toepassing wat 24/7 beskikbaar is vir dringende sake.',
      'fr':
          'Notre assistance téléphonique est disponible du lundi au vendredi de 8h à 20h . Pour une assistance le week-end, veuillez utiliser notre messagerie instantanée intégrée à l\'application, disponible 24h/24 et 7j/7 pour les urgences.',
    },
    'p5kwjq7g': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Publications
  {
    '3rse8oys': {
      'en': 'Research Articles',
      'af': 'Navorsingsartikels',
      'fr': 'Articles de recherche',
    },
    'nk8ywudw': {
      'en': 'Medical Research Hub',
      'af': 'Mediese Navorsingsentrum',
      'fr': 'Centre de recherche médicale',
    },
    'd3ebrtsv': {
      'en': 'Discover the latest health insights from medical professionals',
      'af':
          'Ontdek die nuutste gesondheidsinsigte van mediese professionele persone',
      'fr':
          'Découvrez les dernières informations en matière de santé fournies par des professionnels de la santé',
    },
    'lt8e6144': {
      'en': 'Search articles, providers, or conditions...',
      'af': 'Soek artikels, verskaffers of voorwaardes...',
      'fr': 'Rechercher des articles, des fournisseurs ou des conditions...',
    },
    'r22qhd6r': {
      'en': 'Recent',
      'af': 'Onlangs',
      'fr': 'Récent',
    },
    'k9ndpr33': {
      'en': '  Most Recent',
      'af': 'Mees onlangse',
      'fr': 'Plus récent',
    },
    'w9w6l10f': {
      'en': '  Most Popular',
      'af': 'Mees gewild',
      'fr': 'Les plus populaires',
    },
    '5mbc4qt7': {
      'en': '  Most Viewed',
      'af': 'Mees gekyk',
      'fr': 'Les plus consultés',
    },
    'tpb7x0to': {
      'en': 'Category',
      'af': 'Kategorie',
      'fr': 'Catégorie',
    },
    'xc5967om': {
      'en': 'Provider',
      'af': 'Verskaffer',
      'fr': 'Professionel de santé',
    },
    'wt1844wh': {
      'en': '  All Categories',
      'af': 'Alle kategorieë',
      'fr': 'Toutes les catégories',
    },
    '6wlmy8mz': {
      'en': '  Cardiology',
      'af': 'Kardiologie',
      'fr': 'Cardiologie',
    },
    'faqsh40w': {
      'en': '  Diabetes',
      'af': 'Diabetes',
      'fr': 'Diabète',
    },
    'w821l6lw': {
      'en': '  Mental Health',
      'af': 'Geestesgesondheid',
      'fr': 'Santé mentale',
    },
    'xx9jdyil': {
      'en': '  Nutrition',
      'af': 'Voeding',
      'fr': 'Nutrition',
    },
    'mygv76jj': {
      'en': 'Cardiology',
      'af': 'Kardiologie',
      'fr': 'Cardiologie',
    },
    '4boiwovz': {
      'en': '2 hours ago',
      'af': '2 ure gelede',
      'fr': 'il y a 2 heures',
    },
    '28f5wkm3': {
      'en': 'Understanding Heart Disease Prevention in Young Adults',
      'af': 'Verstaan ​​​​hartsiektevoorkoming by jong volwassenes',
      'fr':
          'Comprendre la prévention des maladies cardiaques chez les jeunes adultes',
    },
    'ze3ciz16': {
      'en':
          'Recent studies show that cardiovascular disease prevention should start early. This comprehensive guide covers lifestyle modifications, dietary recommendations, and screening protocols for adults under 40.',
      'af':
          'Onlangse studies toon dat voorkoming van kardiovaskulêre siektes vroeg moet begin. Hierdie omvattende gids dek lewenstylveranderinge, dieetaanbevelings en siftingsprotokolle vir volwassenes onder 40.',
      'fr':
          'Des études récentes montrent que la prévention des maladies cardiovasculaires doit commencer tôt. Ce guide complet aborde les modifications du mode de vie, les recommandations diététiques et les protocoles de dépistage pour les adultes de moins de 40 ans.',
    },
    '9h70foc0': {
      'en': 'Dr. Sarah Chen',
      'af': 'Dr. Sarah Chen',
      'fr': 'Dr Sarah Chen',
    },
    '948t0pkk': {
      'en': '1.2k',
      'af': '1.2k',
      'fr': '1,2k',
    },
    'xskin34e': {
      'en': '89',
      'af': '89',
      'fr': '89',
    },
    'w412z5hd': {
      'en': 'Mental Health',
      'af': 'Geestesgesondheid',
      'fr': 'Santé mentale',
    },
    '3xngqror': {
      'en': '5 hours ago',
      'af': '5 uur gelede',
      'fr': 'il y a 5 heures',
    },
    '7hs9thov': {
      'en': 'Managing Anxiety in the Digital Age: A Clinical Perspective',
      'af':
          'Die hantering van angs in die digitale era: \'n kliniese perspektief',
      'fr': 'Gérer l’anxiété à l’ère du numérique : une perspective clinique',
    },
    'aocouq5u': {
      'en':
          'Digital technology\'s impact on mental health requires new therapeutic approaches. This article explores evidence-based strategies for treating anxiety disorders in our connected world.',
      'af':
          'Digitale tegnologie se impak op geestesgesondheid vereis nuwe terapeutiese benaderings. Hierdie artikel ondersoek bewysgebaseerde strategieë vir die behandeling van angsversteurings in ons gekoppelde wêreld.',
      'fr':
          'L’impact des technologies numériques sur la santé mentale exige de nouvelles approches thérapeutiques. Cet article explore des stratégies fondées sur des données probantes pour traiter les troubles anxieux dans notre monde connecté.',
    },
    'egsi167d': {
      'en': 'Dr. Michael Rodriguez',
      'af': 'Dr. Michael Rodriguez',
      'fr': 'Dr Michael Rodriguez',
    },
    'gw5adsf7': {
      'en': '856',
      'af': '856',
      'fr': '856',
    },
    '9u3cm7vp': {
      'en': '67',
      'af': '67',
      'fr': '67',
    },
    'ccizlyxv': {
      'en': 'Nutrition',
      'af': 'Voeding',
      'fr': 'Nutrition',
    },
    'veedukbe': {
      'en': '1 day ago',
      'af': '1 dag gelede',
      'fr': 'il y a 1 jour',
    },
    'q86oer1f': {
      'en': 'Plant-Based Diets and Chronic Disease Prevention',
      'af': 'Plantgebaseerde diëte en voorkoming van chroniese siektes',
      'fr':
          'Régimes alimentaires à base de plantes et prévention des maladies chroniques',
    },
    'x6zm0md1': {
      'en':
          'Comprehensive review of current research on plant-based nutrition and its role in preventing diabetes, heart disease, and certain cancers. Includes practical implementation strategies for patients.',
      'af':
          'Omvattende oorsig van huidige navorsing oor plantgebaseerde voeding en die rol daarvan in die voorkoming van diabetes, hartsiektes en sekere kankers. Sluit praktiese implementeringsstrategieë vir pasiënte in.',
      'fr':
          'Synthèse exhaustive des recherches actuelles sur l\'alimentation végétale et son rôle dans la prévention du diabète, des maladies cardiovasculaires et de certains cancers. Comprend des stratégies pratiques pour les patients.',
    },
    '1jnl7yds': {
      'en': 'Dr. Emily Johnson',
      'af': 'Dr. Emily Johnson',
      'fr': 'Dr Emily Johnson',
    },
    'kcxo1bgk': {
      'en': '2.1k',
      'af': '2.1k',
      'fr': '2,1k',
    },
    'fnpmdoqd': {
      'en': '156',
      'af': '156',
      'fr': '156',
    },
    '12r9n4pf': {
      'en': 'Diabetes',
      'af': 'Diabetes',
      'fr': 'Diabète',
    },
    'bqmndhk2': {
      'en': '2 days ago',
      'af': '2 dae gelede',
      'fr': 'il y a 2 jours',
    },
    '25nt9zqv': {
      'en':
          'Continuous Glucose Monitoring: Latest Guidelines and Best Practices',
      'af': 'Deurlopende Glukosemonitering: Nuutste Riglyne en Beste Praktyke',
      'fr':
          'Surveillance continue de la glycémie : dernières recommandations et meilleures pratiques',
    },
    'yx10c3dq': {
      'en':
          'Updated clinical guidelines for CGM implementation in Type 1 and Type 2 diabetes management. Covers patient selection criteria, data interpretation, and integration with insulin therapy.',
      'af':
          'Opgedateerde kliniese riglyne vir die implementering van CGM in die bestuur van tipe 1- en tipe 2-diabetes. Dek pasiëntseleksiekriteria, data-interpretasie en integrasie met insulienterapie.',
      'fr':
          'Recommandations cliniques actualisées pour la mise en œuvre de la surveillance continue du glucose dans la prise en charge du diabète de type 1 et de type 2. Elles abordent les critères de sélection des patients, l\'interprétation des données et l\'intégration au traitement par insuline.',
    },
    '6l16tgwi': {
      'en': 'Dr. Sarah Chen',
      'af': 'Dr. Sarah Chen',
      'fr': 'Dr Sarah Chen',
    },
    'wuu1590f': {
      'en': '945',
      'af': '945',
      'fr': '945',
    },
    '6xlfgeu8': {
      'en': '78',
      'af': '78',
      'fr': '78',
    },
    '84ij6rzj': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // systemAdminAccountCreation
  {
    'f1g7c8qf': {
      'en': 'Admin Basic Information',
      'af': 'Basiese inligting vir administrateurs',
      'fr': 'Informations de base de l\'administrateur',
    },
    'brtm7ers': {
      'en': 'Let\'s start with some basic information to set up your account.',
      'af':
          'Kom ons begin met \'n paar basiese inligting om jou rekening op te stel.',
      'fr':
          'Commençons par quelques informations de base pour créer votre compte.',
    },
    '2uetjuiq': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'c31usn9w': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '3iu2bem4': {
      'en': 'system admin',
      'af': 'stelseladministrateur',
      'fr': 'administrateur système',
    },
    'h1o4o0fe': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'emno116n': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'r4wwkgjf': {
      'en': 'English',
      'af': 'Engels',
      'fr': 'Anglais',
    },
    'ibnoq83j': {
      'en': 'French',
      'af': 'Frans',
      'fr': 'Français',
    },
    'ydmmadhi': {
      'en': 'Fulfude',
      'af': 'Fulfude',
      'fr': 'Fulfude',
    },
    'dqc8guc1': {
      'en': 'Preferred Language',
      'af': 'Voorkeurtaal',
      'fr': 'Langue préférée',
    },
    'inpdmw1h': {
      'en': 'First Name',
      'af': 'Voornaam',
      'fr': 'Prénom',
    },
    'x08ur3mv': {
      'en': 'Middle Name',
      'af': 'Middelnaam',
      'fr': 'Deuxième prénom',
    },
    'wa40q5l3': {
      'en': 'Last Name',
      'af': 'Van',
      'fr': 'Nom de famille',
    },
    'f5qx5jba': {
      'en': 'Date Of Birth',
      'af': 'Geboortedatum',
      'fr': 'Date de naissance',
    },
    '09nu9629': {
      'en': 'ID Card Details',
      'af': 'ID-kaartbesonderhede',
      'fr': 'Détails de la carte d\'identité',
    },
    'avnf9ahw': {
      'en': 'ID CARD NUMBER',
      'af': 'ID-KAARTNOMMER',
      'fr': 'NUMÉRO DE CARTE D\'IDENTITÉ',
    },
    'c9k9fmrr': {
      'en': 'ISSUE DATE',
      'af': 'UITREIKINGSDATUM',
      'fr': 'DATE D\'ÉMISSION',
    },
    '2r07n3y3': {
      'en': 'EXPIRATION DATE',
      'af': 'VERVALDATUM',
      'fr': 'DATE D\'EXPIRATION',
    },
    'nzrzps4q': {
      'en': 'Select Gender',
      'af': 'Kies Geslag',
      'fr': 'Sélectionner le sexe',
    },
    'a449gy98': {
      'en': 'M',
      'af': 'M',
      'fr': 'M',
    },
    'oa095z46': {
      'en': 'F',
      'af': 'F',
      'fr': 'F',
    },
    'cy5ru0eu': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    '80l9nbmb': {
      'en': 'Street',
      'af': 'Straat',
      'fr': 'Rue',
    },
    'dkomul9w': {
      'en': 'City ',
      'af': 'Stad',
      'fr': 'Ville',
    },
    'g7n3b2c6': {
      'en': 'Region',
      'af': 'Streek',
      'fr': 'Région',
    },
    'keihzmf6': {
      'en': 'Zip Code / P.O Box',
      'af': 'Poskode / Posbus',
      'fr': 'Code postal / Boîte postale',
    },
    'ixwd4yzz': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    '9sze24or': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    '77ld4814': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    '44q0yx7t': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'cpvhg5xn': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    'rim97b7y': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'q2zgies8': {
      'en': 'Middle Name is required',
      'af': 'Middelnaam word vereis',
      'fr': 'Le deuxième prénom est obligatoire.',
    },
    'qc7k7czc': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'pfh04a17': {
      'en': 'Last Name is required',
      'af': 'Vannaam word vereis',
      'fr': 'Le nom de famille est obligatoire.',
    },
    '5nakhmg2': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'e7qx2tas': {
      'en': 'Date OF BIRTH is required',
      'af': 'GEBOORTEDATUM word vereis',
      'fr': 'La date de naissance est requise.',
    },
    '0p8q30h4': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '7ftvs2rf': {
      'en': 'ID CARD NUMBER is required',
      'af': 'ID-KAARTNOMMER word vereis',
      'fr': 'Le numéro de carte d\'identité est requis.',
    },
    'j007pma6': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'sotqsiyj': {
      'en': 'ID CARD DATE OF ISSUE is required',
      'af': 'ID-KAART DATUM VAN UITREIKING word vereis',
      'fr': 'La date d\'émission de la carte d\'identité est requise.',
    },
    'hnsj1g1r': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '5olaxbge': {
      'en': 'ID CARD DATE OF EXPIRATION is required',
      'af': 'ID-KAART VERVALDATUM word vereis',
      'fr': 'La date d\'expiration de la carte d\'identité est requise.',
    },
    'bjdqkva1': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '891xqn07': {
      'en': 'Select Place Of Issue Is Required',
      'af': 'Kies plek van uitreiking is verpligtend',
      'fr': 'Le lieu de délivrance est obligatoire.',
    },
    'g3qfsdna': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'xem6q26j': {
      'en': 'Select Gender is required',
      'af': 'Kies Geslag is verpligtend',
      'fr': 'Le choix du sexe est obligatoire.',
    },
    'sp059ftx': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '856wor3p': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ghg567fr': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '810qe07s': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'utg4s62h': {
      'en': 'Zip Code / P.O Box is required',
      'af': 'Poskode / Posbus word vereis',
      'fr': 'Le code postal ou la boîte postale est requis.',
    },
    'wgb1c1q0': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '8uhceo3d': {
      'en': 'Admin Details',
      'af': 'Admin Besonderhede',
      'fr': 'Détails de l\'administrateur',
    },
    'bn60ayha': {
      'en':
          'Please provide your health information to help us provide better care.',
      'af':
          'Verskaf asseblief u gesondheidsinligting om ons te help om beter sorg te bied.',
      'fr':
          'Veuillez nous fournir vos informations de santé afin de nous aider à vous prodiguer de meilleurs soins.',
    },
    'oouldq7s': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    '19gothnb': {
      'en': 'Insurance Provider',
      'af': 'Versekeringsverskaffer',
      'fr': 'Fournisseur d\'assurance',
    },
    'm8z762oi': {
      'en': 'Member ID/Policy Number',
      'af': 'Lid-ID/Polisnommer',
      'fr': 'Numéro d\'identification de membre/Numéro de police',
    },
    'qc7agcb8': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel)',
      'fr': 'Numéro de groupe (facultatif)',
    },
    'jc1j0akr': {
      'en': 'Emergency Contact Information',
      'af': 'Noodkontakbesonderhede',
      'fr': 'Informations de contact en cas d\'urgence',
    },
    'onxluf4w': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    'gjf1tmnj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '550xnju8': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro de police est requis.',
    },
    'cgms7v00': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '6c0jy1is': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif) ',
    },
    'c9we28z4': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '00av0m4x': {
      'en': 'Existing Medical Conditions is required',
      'af': 'Bestaande mediese toestande word vereis',
      'fr': 'Les conditions médicales existantes sont requises',
    },
    '9lqn6z1d': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ugbf5nb4': {
      'en': 'Current Medications is required',
      'af': 'Huidige medikasie word benodig',
      'fr': 'Les médicaments en cours sont requis',
    },
    'w58v812i': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'gxx4489m': {
      'en': 'Allergies is required',
      'af': 'Allergieë is nodig',
      'fr': 'Les allergies sont requises',
    },
    'yayzbrzd': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'gawbr9oj': {
      'en': 'Emergency Names is required',
      'af': 'Noodname word vereis',
      'fr': 'Les noms d\'urgence sont requis',
    },
    '0mfqxjpw': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'lxiywp70': {
      'en': 'Relationship is required',
      'af': 'Verhouding word vereis',
      'fr': 'Le lien de parenté est nécessaire',
    },
    '0jbbopgs': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '4wvs5smn': {
      'en': 'Emergency Names',
      'af': 'Noodname',
      'fr': 'Contact d\'urgence',
    },
    '0c7ws80q': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'weifik1x': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'f64fv72x': {
      'en': 'Wife',
      'af': 'vrou',
      'fr': 'Épouse',
    },
    'zn66i8i5': {
      'en': 'Husband',
      'af': 'Man',
      'fr': 'Mari',
    },
    'z4n9fp6u': {
      'en': 'Father',
      'af': 'Vader',
      'fr': 'Père',
    },
    'uyzs65zq': {
      'en': 'Mother',
      'af': 'Moeder',
      'fr': 'Mère',
    },
    'acrjtkw2': {
      'en': 'Brother',
      'af': 'Broer',
      'fr': 'Frère',
    },
    '2ofhpqi2': {
      'en': 'Sister',
      'af': 'Suster',
      'fr': 'Sœur',
    },
    '28hqtljb': {
      'en': 'Children',
      'af': 'Kinders',
      'fr': 'Enfants',
    },
    'k5r16i79': {
      'en': 'GrandParents',
      'af': 'Grootouers',
      'fr': 'Grands-parents',
    },
    'uwiud90e': {
      'en': 'Friend',
      'af': 'Vriend',
      'fr': 'Ami',
    },
    'n5vnqhbc': {
      'en': 'Relationship',
      'af': 'Verhouding',
      'fr': 'Le lien de parenté',
    },
    'okg4q3gl': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'x412dwck': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'i7xnn15h': {
      'en': 'System Admin Account Verification',
      'af': 'Verifikasie van stelseladministrateurrekening',
      'fr': 'Vérification du compte d\'administrateur système',
    },
    '1yfo4wqz': {
      'en':
          'Please review your information below to ensure everything is correct before creating your account.',
      'af':
          'Gaan asseblief u inligting hieronder na om te verseker dat alles korrek is voordat u u rekening skep.',
      'fr':
          'Veuillez vérifier vos informations ci-dessous pour vous assurer qu\'elles sont correctes avant de créer votre compte.',
    },
    'g10uqahj': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'brngvgqe': {
      'en': 'UserType:',
      'af': 'Gebruikersoort:',
      'fr': 'Type d\'utilisateur :',
    },
    'fp9x82nd': {
      'en': 'System Admin',
      'af': 'Stelseladministrateur',
      'fr': 'Administrateur système',
    },
    'fwi1gf1b': {
      'en': 'First Name:',
      'af': 'Voornaam:',
      'fr': 'Prénom:',
    },
    '58gkklzk': {
      'en': 'Middle Name:',
      'af': 'Middelnaam:',
      'fr': 'Deuxième prénom:',
    },
    'gig7a8h3': {
      'en': 'Last Name:',
      'af': 'Van:',
      'fr': 'Nom de famille:',
    },
    'euijbmnh': {
      'en': 'Date Of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'q6w89jeb': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'k8a6rm9o': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'mah3w2zv': {
      'en': 'Street / Rue:',
      'af': 'Straat / Rue:',
      'fr': 'Rue :',
    },
    'hw42cg5v': {
      'en': 'City / Ville:',
      'af': 'Stad / Dorp:',
      'fr': 'Ville :',
    },
    'f8nshnhu': {
      'en': 'Region:',
      'af': 'Streek:',
      'fr': 'Région:',
    },
    '0t0k09ra': {
      'en': 'Zip Code / P.O Box:',
      'af': 'Poskode / Posbus:',
      'fr': 'Code postal / Boîte postale :',
    },
    '3luwxae7': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'tyvczhot': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'qo0wwqdr': {
      'en': 'PolicyNumber:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance:',
    },
    '6ucd3566': {
      'en': 'Group Number:',
      'af': 'Groepnommer:',
      'fr': 'Numéro de groupe :',
    },
    'xn8sz0nf': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'aa8a5qyi': {
      'en': 'Emergency Names:',
      'af': 'Noodname:',
      'fr': 'Noms d\'urgence :',
    },
    'hl8356p5': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Le lien de parenté:',
    },
    'lsdrfiu2': {
      'en': 'Emegency Phone:',
      'af': 'Noodfoon:',
      'fr': 'Téléphone d\'urgence :',
    },
    '4ka5eufb': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'epqtm2md': {
      'en': 'Submit For Verification',
      'af': 'Dien in vir verifikasie',
      'fr': 'Soumettre pour vérification',
    },
    '64lb8tdj': {
      'en': 'Email is required',
      'af': 'E-posadres is vereis',
      'fr': 'L\'adresse électronique est requise.',
    },
    'o2w0p0q9': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '3boph7ol': {
      'en': 'Password is required',
      'af': 'Wagwoord word vereis',
      'fr': 'Un mot de passe est requis.',
    },
    'b7mzzg5s': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'hhtf85vn': {
      'en': 'Confirm Password is required',
      'af': 'Bevestig wagwoord word vereis',
      'fr': 'Confirmer le mot de passe est requis',
    },
    'ndiuoccj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '7iu9emtw': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // FacilityAdminAccountCreation
  {
    'ak16c9ns': {
      'en': 'Facility Admin Basic Information',
      'af': 'Basiese inligting oor fasiliteitsadministrasie',
      'fr': 'Informations de base sur l\'administrateur de l\'etablissement',
    },
    'o25rvs0a': {
      'en': 'Let\'s start with some basic information to set up your account.',
      'af':
          'Kom ons begin met \'n paar basiese inligting om jou rekening op te stel.',
      'fr':
          'Commençons par quelques informations de base pour créer votre compte.',
    },
    'ux4bbf8p': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    '1a5slcqd': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '859wqfsy': {
      'en': 'Facility admin  ',
      'af': 'Fasiliteitsadministrateur',
      'fr': 'Administrateur de l\'etablissement',
    },
    'lqw6kdi6': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'cddf7z7x': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'vxxknhx8': {
      'en': 'English',
      'af': 'Engels',
      'fr': 'Anglais',
    },
    'as12oz6y': {
      'en': 'French',
      'af': 'Frans',
      'fr': 'Français',
    },
    '4438pgxs': {
      'en': 'Fulfude',
      'af': 'Fulfude',
      'fr': 'Fulfude',
    },
    'ob30zimm': {
      'en': 'Preferred Language',
      'af': 'Voorkeurtaal',
      'fr': 'Langue préférée',
    },
    '3d2ohcop': {
      'en': 'First Name',
      'af': 'Voornaam',
      'fr': 'Prénom',
    },
    '6ela19fq': {
      'en': 'Middle Name',
      'af': 'Middelnaam',
      'fr': 'Deuxième prénom',
    },
    'ztl63sp7': {
      'en': 'Last Name',
      'af': 'Van',
      'fr': 'Nom de famille',
    },
    'u2q3gy2n': {
      'en': 'Date Of Birth',
      'af': 'Geboortedatum',
      'fr': 'Date de naissance',
    },
    'wc0w8prk': {
      'en': 'ID Card Details',
      'af': 'ID-kaartbesonderhede',
      'fr': 'Détails de la carte d\'identité',
    },
    'ea69r9xw': {
      'en': 'ID CARD NUMBER',
      'af': 'ID-KAARTNOMMER',
      'fr': 'NUMÉRO DE CARTE D\'IDENTITÉ',
    },
    '58btrk6n': {
      'en': 'ISSUE DATE',
      'af': 'UITREIKINGSDATUM',
      'fr': 'DATE D\'ÉMISSION',
    },
    'ndzflvpj': {
      'en': 'EXPIRATION DATE',
      'af': 'VERVALDATUM',
      'fr': 'DATE D\'EXPIRATION',
    },
    'ffq6a6yc': {
      'en': 'Select Gender',
      'af': 'Kies Geslag',
      'fr': 'Sélectionner le sexe',
    },
    'xbyfz5zu': {
      'en': 'M',
      'af': 'M',
      'fr': 'M',
    },
    'sdq6fgpw': {
      'en': 'F',
      'af': 'F',
      'fr': 'F',
    },
    'nguc9c0l': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'acrjng77': {
      'en': 'Street',
      'af': 'Straat',
      'fr': 'Rue',
    },
    '271ul23l': {
      'en': 'City ',
      'af': 'Stad',
      'fr': 'Ville',
    },
    'kv3vwl4c': {
      'en': 'Region',
      'af': 'Streek',
      'fr': 'Région',
    },
    'vzl9zlen': {
      'en': 'Zip Code / P.O Box',
      'af': 'Poskode / Posbus',
      'fr': 'Code postal / Boîte postale',
    },
    'bshi4hh2': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'lqpd3hfq': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    '7tp9914j': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    '2cucujwj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '1fzme2y9': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    'tnwnujhr': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'cr2d3c2y': {
      'en': 'Middle Name is required',
      'af': 'Middelnaam word vereis',
      'fr': 'Le deuxième prénom est obligatoire.',
    },
    '89x3t8nf': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '4undjea1': {
      'en': 'Last Name is required',
      'af': 'Vannaam word vereis',
      'fr': 'Le nom de famille est obligatoire.',
    },
    'ykxuxlzu': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'gxviwhp0': {
      'en': 'Date OF BIRTH is required',
      'af': 'GEBOORTEDATUM word vereis',
      'fr': 'La date de naissance est requise.',
    },
    'tslbe7hg': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'xlh0htjm': {
      'en': 'ID CARD NUMBER is required',
      'af': 'ID-KAARTNOMMER word vereis',
      'fr': 'Le numéro de carte d\'identité est requis.',
    },
    'i50ornka': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ohzjjeas': {
      'en': 'ID CARD DATE OF ISSUE is required',
      'af': 'ID-KAART DATUM VAN UITREIKING word vereis',
      'fr': 'La date d\'émission de la carte d\'identité est requise.',
    },
    'z12m6pn3': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ye1jmo40': {
      'en': 'ID CARD DATE OF EXPIRATION is required',
      'af': 'ID-KAART VERVALDATUM word vereis',
      'fr': 'La date d\'expiration de la carte d\'identité est requise.',
    },
    'im36uy3i': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'tck8w5fe': {
      'en': 'Select Place Of Issue Is Required',
      'af': 'Kies plek van uitreiking is verpligtend',
      'fr': 'Le lieu de délivrance est obligatoire.',
    },
    'wwkizxgk': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '0ohq3sh5': {
      'en': 'Select Gender is required',
      'af': 'Kies Geslag is verpligtend',
      'fr': 'Le choix du sexe est obligatoire.',
    },
    '35o8ivz3': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'yaqz8lz0': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'gaqxaopk': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'wybbc5oc': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'zus8hrxo': {
      'en': 'Zip Code / P.O Box is required',
      'af': 'Poskode / Posbus word vereis',
      'fr': 'Le code postal ou la boîte postale est requis.',
    },
    'rtk3pxrj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'fpgeme4n': {
      'en': 'Admin Details',
      'af': 'Admin Besonderhede',
      'fr': 'Détails de l\'administrateur',
    },
    'ow9fgvlf': {
      'en':
          'Please provide your health information to help us provide better care.',
      'af':
          'Verskaf asseblief u gesondheidsinligting om ons te help om beter sorg te bied.',
      'fr':
          'Veuillez nous fournir vos informations de santé afin de nous aider à vous prodiguer de meilleurs soins.',
    },
    'hw93uls1': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'z6jz26gu': {
      'en': 'Insurance Provider',
      'af': 'Versekeringsverskaffer',
      'fr': 'Fournisseur d\'assurance',
    },
    'kmzx51gg': {
      'en': 'Member ID/Policy Number',
      'af': 'Lid-ID/Polisnommer',
      'fr': 'Numéro d\'identification de membre/Numéro d\'assurance',
    },
    'omiqd29c': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel)',
      'fr': 'Numéro de groupe (facultatif)',
    },
    '3yugv2pg': {
      'en': 'Provider Practice Address',
      'af': 'Verskafferpraktykadres',
      'fr': 'Adresse du cabinet du prestataire',
    },
    'g3e4ol8o': {
      'en': 'Select From A List Of Existing Medical Facilities',
      'af': 'Kies uit \'n lys van bestaande mediese fasiliteite',
      'fr': 'Sélectionnez un établissement médical parmi une liste existante.',
    },
    'm4x2tu2f': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'dy1rppoc': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'p8xlccbo': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '5ea7hl17': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'zzikfiri': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    '59qiz1r9': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    '3hxhxi7o': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    '1rg9u7qh': {
      'en': 'Emergency Contact Information',
      'af': 'Noodkontakbesonderhede',
      'fr': 'Informations de contact en cas d\'urgence',
    },
    't1mq8jt8': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    'rrol6pyv': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'bm043yu2': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro d\'assurance est requis.',
    },
    '1lbzlkam': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'fxg2p04d': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif).',
    },
    'o3mixaxu': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'm48iwuic': {
      'en': 'Existing Medical Conditions is required',
      'af': 'Bestaande mediese toestande word vereis',
      'fr': 'Les conditions médicales existantes sont requises',
    },
    'jffqtvzj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ryu3pn83': {
      'en': 'Current Medications is required',
      'af': 'Huidige medikasie word benodig',
      'fr': 'Les médicaments en cours sont requis',
    },
    'eyomxgqc': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'mio5xc7g': {
      'en': 'Allergies is required',
      'af': 'Allergieë is nodig',
      'fr': 'Les allergies sont requises',
    },
    'gnb7lg15': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '3c0cm2uj': {
      'en': 'Emergency Names is required',
      'af': 'Noodname word vereis',
      'fr': 'Les noms d\'urgence sont requis',
    },
    'kgm3nu2y': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ub73gz0u': {
      'en': 'Relationship is required',
      'af': 'Verhouding word vereis',
      'fr': 'Le lien de parenté est nécessaire',
    },
    'p1e99h78': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'rkly702d': {
      'en': 'Emergency Names',
      'af': 'Noodname',
      'fr': 'Noms d\'urgence',
    },
    'e21fvalp': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    '6g0pnqi3': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'w06065ny': {
      'en': 'Wife',
      'af': 'vrou',
      'fr': 'Épouse',
    },
    '9j3k6uue': {
      'en': 'Husband',
      'af': 'Man',
      'fr': 'Mari',
    },
    'hv679mki': {
      'en': 'Father',
      'af': 'Vader',
      'fr': 'Père',
    },
    'yp6qic5w': {
      'en': 'Mother',
      'af': 'Moeder',
      'fr': 'Mère',
    },
    '1jzj78ye': {
      'en': 'Brother',
      'af': 'Broer',
      'fr': 'Frère',
    },
    '3v6tarru': {
      'en': 'Sister',
      'af': 'Suster',
      'fr': 'Sœur',
    },
    'ocsxeqet': {
      'en': 'Children',
      'af': 'Kinders',
      'fr': 'Enfants',
    },
    'kadh5tsn': {
      'en': 'GrandParents',
      'af': 'Grootouers',
      'fr': 'Grands-parents',
    },
    'kr2dmqci': {
      'en': 'Friend',
      'af': 'Vriend',
      'fr': 'Ami',
    },
    'mlnehr7v': {
      'en': 'Relationship',
      'af': 'Verhouding',
      'fr': 'Lien de parenté',
    },
    'z9rkuqls': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'ybcdndvp': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'zc7epzik': {
      'en': 'Admin Account Verification',
      'af': 'Verifikasie van administrateurrekening',
      'fr': 'Vérification du compte administrateur',
    },
    'sz99vp81': {
      'en':
          'Please review your information below to ensure everything is correct before creating your account.',
      'af':
          'Gaan asseblief u inligting hieronder na om te verseker dat alles korrek is voordat u u rekening skep.',
      'fr':
          'Veuillez vérifier vos informations ci-dessous pour vous assurer qu\'elles sont correctes avant de créer votre compte.',
    },
    '7e728gf6': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'rgxu1pfj': {
      'en': 'UserType:',
      'af': 'Gebruikersoort:',
      'fr': 'Type d\'utilisateur :',
    },
    '8z7fd26a': {
      'en': 'Facility Admin',
      'af': 'Fasiliteitsadministrateur',
      'fr': 'Administrateur de l\'etablissement',
    },
    'it94g9f7': {
      'en': 'First Name:',
      'af': 'Voornaam:',
      'fr': 'Prénom:',
    },
    '9ftg12cu': {
      'en': 'Middle Name:',
      'af': 'Middelnaam:',
      'fr': 'Deuxième prénom:',
    },
    'm2p0y1z4': {
      'en': 'Last Name:',
      'af': 'Van:',
      'fr': 'Nom de famille:',
    },
    'ugt3d8e5': {
      'en': 'Date Of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'jxftrog7': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'ag4528vu': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'tu28guly': {
      'en': 'Street:',
      'af': 'Straat / Rue:',
      'fr': 'Rue :',
    },
    '2v627jvh': {
      'en': 'City :',
      'af': 'Stad / Dorp:',
      'fr': 'Ville :',
    },
    'a2z3m3ar': {
      'en': 'Region:',
      'af': 'Streek:',
      'fr': 'Région:',
    },
    'ou27lyu4': {
      'en': 'Zip Code / P.O Box:',
      'af': 'Poskode / Posbus:',
      'fr': 'Code postal / Boîte postale :',
    },
    '5fy8n539': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'b57ujauv': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'n9q932h6': {
      'en': 'PolicyNumber:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    'ca6h8prr': {
      'en': 'Group Number:',
      'af': 'Groepnommer:',
      'fr': 'Numéro de groupe :',
    },
    'o6zlv5f1': {
      'en': 'Facility Information ',
      'af': 'Fasiliteitsinligting',
      'fr': 'Informations sur l\'établissement',
    },
    'rsv9ryhe': {
      'en': 'Facility:',
      'af': 'Fasiliteit:',
      'fr': 'Etablissement sanitaire:',
    },
    'i3fr7wc2': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    '3zfa0g7j': {
      'en': 'Emergency Names:',
      'af': 'Noodname:',
      'fr': 'Noms d\'urgence :',
    },
    '6d8lsg0y': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'p6mix1fe': {
      'en': 'Emegency Phone:',
      'af': 'Noodfoon:',
      'fr': 'Téléphone d\'urgence :',
    },
    '48gbgng8': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'ae9e2mhs': {
      'en': 'Submit For Verification',
      'af': 'Dien in vir verifikasie',
      'fr': 'Soumettre pour vérification',
    },
    'u1h4yjim': {
      'en': 'Email is required',
      'af': 'E-posadres is vereis',
      'fr': 'L\'adresse électronique est requise.',
    },
    'p0uo9wbo': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ln8iguaf': {
      'en': 'Password is required',
      'af': 'Wagwoord word vereis',
      'fr': 'Un mot de passe est requis.',
    },
    'lln20pof': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'kju8v4ky': {
      'en': 'Confirm Password is required',
      'af': 'Bevestig wagwoord word vereis',
      'fr': 'Confirmer le mot de passe est requis',
    },
    '3tt0u6jr': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ljosdess': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // patient_landing_page
  {
    '5ok6erwh': {
      'en': 'Subscription ',
      'af': 'Subskripsie',
      'fr': 'Abonnement',
    },
    '4uxdbxkp': {
      'en': 'Subscription Status:',
      'af': 'Subskripsiestatus:',
      'fr': 'Statut de l\'abonnement :',
    },
    'wmhsv85g': {
      'en': 'Subscription Type:',
      'af': 'Subskripsietipe:',
      'fr': 'Type d\'abonnement :',
    },
    'g64qwbbp': {
      'en': 'Upcoming Appointment',
      'af': 'Aanstaande afspraak',
      'fr': 'Prochain rendez-vous',
    },
    'hhpvy7wq': {
      'en': 'View',
      'af': '',
      'fr': 'Détails',
    },
    'z52qwz2c': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'hr9vic30': {
      'en': 'Name :',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'oqqjds7j': {
      'en': 'Relationship :',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'xvus81ku': {
      'en': 'Phone :',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'gw7kq2w4': {
      'en': 'Recent Vitals',
      'af': 'Onlangse vitale data',
      'fr': 'Signes vitaux récents',
    },
    'unkbd0p4': {
      'en': '/',
      'af': '/',
      'fr': '/',
    },
    '1re70z12': {
      'en': 'Blood Pressure',
      'af': 'Bloeddruk',
      'fr': 'Pression sanguine',
    },
    'qrs89his': {
      'en': 'Weight',
      'af': 'Gewig',
      'fr': 'Poids',
    },
    '7dnflka4': {
      'en': 'Blood Type',
      'af': 'Bloedgroep',
      'fr': 'Groupe sanguin',
    },
    '99ibiswz': {
      'en': 'Recent Demographics',
      'af': 'Onlangse Demografie',
      'fr': 'Données démographiques récentes',
    },
    'x5dwj1ue': {
      'en': 'Height',
      'af': 'Hoogte',
      'fr': 'Taille',
    },
    '89iir075': {
      'en': 'Blood Donor',
      'af': 'Bloedskenker',
      'fr': 'Donneur de sang',
    },
    'tkr3ktzh': {
      'en': 'Allergies',
      'af': 'Allergieë',
      'fr': 'Allergies',
    },
    'oug5aozl': {
      'en': 'Quick Links',
      'af': 'Vinnige skakels',
      'fr': 'Liens rapides',
    },
    'b90ruerf': {
      'en': 'Care Centers',
      'af': 'Care Centers',
      'fr': 'Centre de soins',
    },
    '54pihnhw': {
      'en': 'Call support',
      'af': 'Bel ondersteuning',
      'fr': 'Assistance',
    },
    't7xb34tj': {
      'en': 'Query',
      'af': 'Navraag',
      'fr': 'Requête',
    },
    'o4x06uij': {
      'en': 'Message',
      'af': 'Boodskap',
      'fr': 'Message',
    },
    '65gb76ez': {
      'en': 'Diagnostic History',
      'af': 'Diagnostiese Geskiedenis',
      'fr': 'Antécédents diagnostiques',
    },
    '0u6su9nw': {
      'en': 'View All',
      'af': 'Bekyk alles',
      'fr': 'Afficher tout',
    },
    'fx1racpq': {
      'en': 'Order ID',
      'af': 'Bestelling-ID',
      'fr': 'Numéro de commande',
    },
    'kz6tglvd': {
      'en': 'Date',
      'af': 'Datum',
      'fr': 'Date',
    },
    'y28f2vba': {
      'en': 'Total',
      'af': 'Totaal',
      'fr': 'Total',
    },
    'ppddmoxo': {
      'en': 'Status',
      'af': 'Status',
      'fr': 'Statut',
    },
    'dk15xwk2': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'ufmas5tt': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'c2anshv8': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'otclatv6': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'j9h7ghfb': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Appointments
  {
    'n4hz4lla': {
      'en': 'Upcoming',
      'af': 'Komende',
      'fr': 'À venir',
    },
    'arnvzx2q': {
      'en': 'FeedBack',
      'af': 'Terugvoer',
      'fr': 'Commentaires',
    },
    'd0mhsgbp': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    't805r6mw': {
      'en': 'Refresh',
      'af': 'Verfris',
      'fr': 'Rafraîchir',
    },
    'zyq6olzw': {
      'en': 'Retry Payment',
      'af': 'Herbetaal',
      'fr': 'Réessayer le paiement',
    },
    '4f180vl2': {
      'en': 'Past',
      'af': 'Verlede',
      'fr': 'Passé',
    },
    'ep2yh1i9': {
      'en': 'View Notes',
      'af': 'Bekyk Notas',
      'fr': 'Voir les notes',
    },
    'p54qugpq': {
      'en': 'Review',
      'af': 'Resensie',
      'fr': 'Avis',
    },
    'sxhk0shq': {
      'en': 'Schedule Appointment',
      'af': 'Beplan Afspraak',
      'fr': 'Prendre rendez-vous',
    },
    'mlskunp5': {
      'en': 'CareCenter',
      'af': 'Sorgsentrum',
      'fr': 'Centre de soins',
    },
  },
  // CareCenterRegistrationPage
  {
    'fq7t6st5': {
      'en': 'Facility Information ',
      'af': 'Fasiliteitsinligting',
      'fr': 'Informations sur l\'établissement',
    },
    '99xsbryo': {
      'en': 'Please select the type of medical facility you\'re registering.',
      'af': 'Kies asseblief die tipe mediese fasiliteit wat u registreer.',
      'fr':
          'Veuillez sélectionner le type d\'établissement médical que vous enregistrez.',
    },
    'kiu21fwh': {
      'en': 'Facility Name',
      'af': 'Fasiliteitsnaam',
      'fr': 'Nom de l\'établissement',
    },
    'hwm934l6': {
      'en': 'Select Facility Type ..',
      'af': 'Kies Fasiliteitstipe..',
      'fr': 'Sélectionnez le type d\'établissement...',
    },
    'deddllx8': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '6k6qor1i': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'ft03ff4m': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    '27s3mv24': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    'dyrmuwx6': {
      'en': 'FacilityType',
      'af': 'Fasiliteitstipe',
      'fr': 'Type d\'établissement',
    },
    'ib9r4n2z': {
      'en': 'Please Select The Different Departments In Your Facility',
      'af': 'Kies asseblief die verskillende departemente in u fasiliteit',
      'fr':
          'Veuillez sélectionner les différents services de votre établissement.',
    },
    '4cl3kzle': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'fl6ukzok': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    'o18qygyt': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    'ua7tzt9w': {
      'en': 'Consultation Fee:',
      'af': 'Konsultasiefooi:',
      'fr': 'Honoraires de consultation :',
    },
    'q7qhhoqh': {
      'en': 'consultation Fee',
      'af': 'konsultasiefooi',
      'fr': 'Honoraires de consultation',
    },
    'qr4nr757': {
      'en': 'FCFA',
      'af': 'FCFA',
      'fr': 'FCFA',
    },
    'jmn81asq': {
      'en': 'Registration/License Number',
      'af': 'Registrasie-/Lisensienommer',
      'fr': 'Numéro d\'immatriculation/de licence',
    },
    'r9a8o1rj': {
      'en': 'Year Established',
      'af': 'Jaar van Gestigting',
      'fr': 'Année de création',
    },
    'mgb172f8': {
      'en': 'Ownership Type',
      'af': 'Eienaarskapsoort',
      'fr': 'Type de propriété',
    },
    'ovfompmn': {
      'en': 'Email Address',
      'af': 'E-posadres',
      'fr': 'Adresse email',
    },
    'kwa80nib': {
      'en': 'Website',
      'af': 'Webwerf',
      'fr': 'Site web',
    },
    '5esp8yiv': {
      'en': 'Description/About Us',
      'af': 'Beskrywing/Oor Ons',
      'fr': 'Description/À propos de nous',
    },
    'hw7lz8k6': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'kfe832fo': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'wrb2vfae': {
      'en': 'FacilityType is required',
      'af': 'Fasiliteittipe word vereis',
      'fr': 'Le type d\'établissement est requis.',
    },
    'e863np93': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'psvmtxuj': {
      'en': 'Facility Name is required',
      'af': 'Fasiliteitsnaam word vereis',
      'fr': 'Le nom de l\'établissement est requis.',
    },
    'nz7xgs91': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '8az6xgrd': {
      'en': 'Legal Business Name  is required',
      'af': 'Wettige besigheidsnaam word vereis',
      'fr': 'Le nom légal de l\'entreprise est requis.',
    },
    '3dmzca5z': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'jx7ftcou': {
      'en': 'Registration/License Number is required',
      'af': 'Registrasie-/lisensienommer word vereis',
      'fr': 'Un numéro d\'immatriculation/de permis est requis.',
    },
    'vg2cd6h2': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '66dmaa00': {
      'en': 'Year Established is required',
      'af': 'Jaar van vestiging word vereis',
      'fr': 'L\'année de création est obligatoire.',
    },
    'cu1cgg09': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '6dnx54bl': {
      'en': 'Ownership Type is required',
      'af': 'Eienaarskapsoort is vereis',
      'fr': 'Le type de propriété est requis.',
    },
    'row7z6by': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'vk6hk4kx': {
      'en': 'Email Address is required',
      'af': 'E-posadres word vereis',
      'fr': 'Une adresse e-mail est requise.',
    },
    'p7qri1kb': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '387le0sl': {
      'en': 'Website is required',
      'af': 'Webwerf is vereis',
      'fr': 'Site web requis',
    },
    '7jfab1rv': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '2tt5xl19': {
      'en': 'Description/About Us is required',
      'af': 'Beskrywing/Oor Ons is vereis',
      'fr': 'Une description/un formulaire « À propos de nous » est requis.',
    },
    '3fygzche': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'aescscok': {
      'en': 'Location & Operational Details',
      'af': 'Ligging en Operasionele Besonderhede',
      'fr': 'Détails de localisation et d\'exploitation',
    },
    'ofv98ufw': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    't7w5bsa2': {
      'en':
          'Please provide information about where and when your facility operates.',
      'af':
          'Verskaf asseblief inligting oor waar en wanneer u fasiliteit in werking is.',
      'fr':
          'Veuillez fournir des informations sur le lieu et les horaires d\'ouverture de votre établissement.',
    },
    'y2eehlp3': {
      'en': 'Street Address',
      'af': 'Straatadres',
      'fr': 'Nom de la rue',
    },
    'zkxlqk8p': {
      'en': 'City',
      'af': 'Stad',
      'fr': 'Ville',
    },
    'tn3d912l': {
      'en': 'Region',
      'af': 'Streek',
      'fr': 'Région',
    },
    'o4w0h4n5': {
      'en': 'Postal Code',
      'af': 'Poskode',
      'fr': 'Code Postal',
    },
    'mzp0u8xe': {
      'en': 'Select CareCenter Availability',
      'af': 'Kies Sorgsentrum Beskikbaarheid',
      'fr': 'Sélectionnez la disponibilité du Centre de santé',
    },
    'hsqcv43b': {
      'en': 'Monday',
      'af': 'Maandag',
      'fr': 'Lundi',
    },
    'slsd0ri4': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    '3fvmx6vo': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverteure',
    },
    'zakx1kd7': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'mx9zu53d': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'zyg9vty2': {
      'en': 'Tuesday',
      'af': 'Dinsdag',
      'fr': 'Mardi',
    },
    '7b0zios7': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'aul2om3k': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverteure',
    },
    'lvl7sq7c': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'j7enmggd': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'l476wg4k': {
      'en': 'Wednesday',
      'af': 'Woensdag',
      'fr': 'Mercredi',
    },
    'd7o2tkzq': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'ajw61bhn': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'yz30q9vs': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'chmoy2a9': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'rfvksful': {
      'en': 'Thursday',
      'af': 'Donderdag',
      'fr': 'Jeudi',
    },
    'lxr2rvi0': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'z4alg17e': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '68ds9kjy': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '5w23p9jp': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    't53nytxr': {
      'en': 'Friday',
      'af': 'Vrydag',
      'fr': 'Vendredi',
    },
    'fopyma52': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'dywc7q6k': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'z44lxnc5': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '1wzgpmok': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'jeibtn31': {
      'en': 'Saturday',
      'af': 'Saterdag',
      'fr': 'Samedi',
    },
    'vnm4bwfw': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'fnw4l68z': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '0ktxj7an': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'vvw6adeh': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    '91pg9u93': {
      'en': 'Sunday',
      'af': 'Sondag',
      'fr': 'Dimanche',
    },
    'fkhaebrd': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'ttf3t21r': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverteure',
    },
    'jmhp07mz': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'bgtkekca': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'o7n7rcbs': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'aaycurd3': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'z3at8xjp': {
      'en': 'Street Address is required',
      'af': 'Straatadres word vereis',
      'fr': 'Une adresse postale est requise.',
    },
    '3jtxd995': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'hknzg6z9': {
      'en': 'City is required',
      'af': 'Stad is vereis',
      'fr': 'La ville est requise',
    },
    '854okgtj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'x7itnabs': {
      'en': 'State/Province is required',
      'af': 'Staat/Provinsie word vereis',
      'fr': 'la Region est requise',
    },
    'dptdx6x7': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '7omiqnsv': {
      'en': 'ZIPPostalCode is required',
      'af': 'Poskode word vereis',
      'fr': 'Le code postal est obligatoire.',
    },
    '2rytulbu': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ukfewkx5': {
      'en': 'Country is required',
      'af': 'Land is vereis',
      'fr': 'Le pays est requis.',
    },
    'oqkncr5x': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'txtqmo95': {
      'en': 'Google Maps Location Pin (Optional) ',
      'af': 'Google Maps-liggingspeld (opsioneel) word vereis',
      'fr': 'L\'épingle de localisation Google Maps (facultative)',
    },
    'spvj3ruf': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'l5y5q5gu': {
      'en': 'OperatingDays is required',
      'af': 'Bedryfsdae word vereis',
      'fr': 'Les jours ouvrables sont requis',
    },
    'u43p4mnr': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '7ek3asjj': {
      'en': 'Review & Submit',
      'af': 'Hersien en dien in',
      'fr': 'Examiner et soumettre',
    },
    'ejrpe13f': {
      'en': 'Please review your information before final submission.',
      'af': 'Hersien asseblief u inligting voor finale indiening.',
      'fr':
          'Veuillez vérifier vos informations avant de les soumettre définitivement.',
    },
    '5rz266lz': {
      'en': 'CareCenter Type:',
      'af': 'Sorgsentrum Tipe:',
      'fr': 'Type de centre de soins :',
    },
    'qui47vi7': {
      'en': 'Facility Name:',
      'af': 'Naam van fasiliteit:',
      'fr': 'Nom de l\'établissement :',
    },
    '8fsvh5zb': {
      'en': 'Facility Departments:',
      'af': 'Fasiliteitsdepartemente:',
      'fr': 'Services de l\'établissement :',
    },
    '6gre246c': {
      'en': 'Registration Number',
      'af': 'Registrasienommer',
      'fr': 'Numéro d\'immatriculation',
    },
    'cj0h3kb5': {
      'en': 'Year Established:',
      'af': 'Jaar van Gestigting:',
      'fr': 'Année de création :',
    },
    'f51yi5yi': {
      'en': 'Ownership Type:',
      'af': 'Eienaarskapsoort:',
      'fr': 'Type de propriété :',
    },
    '2x402w0g': {
      'en': 'Contact Number:',
      'af': 'Kontaknommer:',
      'fr': 'Numéro de contact :',
    },
    '6f0d6cz8': {
      'en': 'Email:',
      'af': 'E-pos:',
      'fr': 'E-mail:',
    },
    'i692igo4': {
      'en': 'Website:',
      'af': 'Webwerf:',
      'fr': 'Site web:',
    },
    'oo17c6v1': {
      'en': 'AboutUS:',
      'af': 'Oor ONS:',
      'fr': 'À propos de nous:',
    },
    'f5vx0zrp': {
      'en': 'Consultation Fee:',
      'af': 'Konsultasiefooi:',
      'fr': 'Honoraires de consultation :',
    },
    '789nroha': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'cmi9q8g9': {
      'en': 'Address:',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    'tajixeju': {
      'en': 'City :',
      'af': 'Stad / Dorp:',
      'fr': 'Ville :',
    },
    'qobyrgsm': {
      'en': 'Region:',
      'af': 'Streek:',
      'fr': 'Région:',
    },
    'zah5lad4': {
      'en': 'Postal Code:',
      'af': 'Poskode:',
      'fr': 'Code Postal:',
    },
    'fo7vgbgu': {
      'en': 'Availabilty',
      'af': 'Beskikbaarheid',
      'fr': 'Disponibilité',
    },
    '3o30n4sp': {
      'en': 'Monday',
      'af': 'Maandag',
      'fr': 'Lundi',
    },
    '1t38lsiw': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    '5r54eapx': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture:',
    },
    '8y14fer8': {
      'en': 'Tuesday',
      'af': 'Dinsdag',
      'fr': 'Mardi',
    },
    'wbvrbq7k': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    '3p0y0q88': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'b1qwlvkb': {
      'en': 'Wednesday',
      'af': 'Woensdag',
      'fr': 'Mercredi',
    },
    'r3pk4dgp': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'u1u581rd': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'tkovzzy0': {
      'en': 'Thursday',
      'af': 'Donderdag',
      'fr': 'Jeudi',
    },
    '117lqqpv': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    's8opx13g': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    '1v9vk5tr': {
      'en': 'Friday',
      'af': 'Vrydag',
      'fr': 'Vendredi',
    },
    'wthqypry': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'agzpylzg': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'kxniw8av': {
      'en': 'Saturday',
      'af': 'Saterdag',
      'fr': 'Samedi',
    },
    '5vwvdg6f': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'm21gn2vz': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    '7taaw90t': {
      'en': 'Sunday',
      'af': 'Sondag',
      'fr': 'Dimanche',
    },
    'eqo35os0': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    '8waqa91h': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'dsi075uf': {
      'en':
          'By submitting this form, you confirm that all information provided is accurate and true. Your facility will be verified within 48 hours',
      'af':
          'Deur hierdie vorm in te dien, bevestig u dat alle inligting wat verskaf is akkuraat en waar is. U fasiliteit sal binne 48 uur geverifieer word.',
      'fr':
          'En soumettant ce formulaire, vous confirmez que toutes les informations fournies sont exactes et véridiques. Votre établissement sera vérifié sous 48 heures.',
    },
    'ogw5cmwa': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'mx6i3cjn': {
      'en': 'Submit for verification',
      'af': 'Dien in vir verifikasie',
      'fr': 'Soumettre pour vérification',
    },
    '5jas5l2v': {
      'en': 'Email is required',
      'af': 'E-posadres is vereis',
      'fr': 'L\'adresse électronique est requise.',
    },
    '3vzli8e7': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '75jb5ctm': {
      'en': 'Password is required',
      'af': 'Wagwoord word vereis',
      'fr': 'Un mot de passe est requis.',
    },
    'jv1vhvo3': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '7iuuwk2y': {
      'en': 'Confirm Password is required',
      'af': 'Bevestig wagwoord word vereis',
      'fr': 'Confirmer le mot de passe est requis',
    },
    '54a0tz79': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'wvdx7l2m': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // AdminStatusPage
  {
    'rv3m1lye': {
      'en': 'Admin Status',
      'af': 'Adminstatus',
      'fr': 'Statut administratif',
    },
    'zx0tl3zt': {
      'en': 'Search facility admins.....',
      'af': 'Soekverskaffers...',
      'fr': 'recherche d\'un administrateur...',
    },
    '6zyf3qmn': {
      'en': 'All',
      'af': 'Alles',
      'fr': 'Tout',
    },
    '9shisqdg': {
      'en': 'Approved',
      'af': 'Goedgekeur',
      'fr': 'Approuvé',
    },
    '6vlskbys': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    '9qj2ft1t': {
      'en': 'Rejected',
      'af': 'Verwerp',
      'fr': 'Rejeté',
    },
    'jkos8xix': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'p5t2k813': {
      'en': 'Admin',
      'af': 'Admin',
      'fr': 'Administrateur',
    },
    'udez1mz3': {
      'en': 'Facility:  ',
      'af': 'ID-nommer:',
      'fr': 'IDENTIFIANT #:',
    },
    'urp0iu17': {
      'en': 'ID',
      'af': 'ID',
      'fr': 'IDENTIFIANT',
    },
    '8i3g7zi2': {
      'en': 'Tel: ',
      'af': 'Tel:',
      'fr': 'Tél. :',
    },
    '9flyqc0y': {
      'en': 'Phone',
      'af': 'Foon',
      'fr': 'Téléphone',
    },
    'y4pbj22l': {
      'en': ' Approve',
      'af': 'Goedkeur',
      'fr': 'Approuver',
    },
    'f27dzgqv': {
      'en': 'Reject ',
      'af': 'Verwerp',
      'fr': 'Rejeter',
    },
    'yu2y4bom': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // PaymentHistory
  {
    'uwm467qz': {
      'en': 'Below are a summary of your invoices.',
      'af': 'Hieronder is \'n opsomming van u fakture.',
      'fr': 'Vous trouverez ci-dessous un récapitulatif de vos factures.',
    },
    'ofa2av07': {
      'en': 'Total Earnings',
      'af': 'Totale verdienste',
      'fr': 'Revenus totaux',
    },
    'ecqx9imq': {
      'en': 'Balance',
      'af': 'Saldo',
      'fr': 'Solde',
    },
    'ye31d5o5': {
      'en': 'Withdrawn',
      'af': 'Teruggetrek',
      'fr': 'Retiré',
    },
    'ouuyiutp': {
      'en': 'All',
      'af': 'Alles',
      'fr': 'Tout',
    },
    'wshysw3z': {
      'en': 'Paid',
      'af': 'Betaal',
      'fr': 'Payé',
    },
    'gso8cnj2': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    '8cf40daz': {
      'en': 'Earnings',
      'af': 'Verdienste',
      'fr': 'Gains',
    },
    'o5f271d6': {
      'en': 'Withdrew',
      'af': 'Onttrek',
      'fr': 'Retrait',
    },
    'mfnhr7yj': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    'xfh21281': {
      'en': 'withdraw',
      'af': 'onttrek',
      'fr': 'Retrait',
    },
    'ce2qbgho': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // MedicalPractitioners
  {
    '989vijvr': {
      'en': 'Search Providers....',
      'af': 'Soekverskaffers...',
      'fr': 'Fournisseurs de recherche...',
    },
    'h4nunhw4': {
      'en': '  years of experience',
      'af': 'jare se ondervinding',
      'fr': ' années d\'expérience',
    },
    'z59mi6vv': {
      'en': 'View',
      'af': 'Goedkeur',
      'fr': 'Détails',
    },
    'u9nu89jc': {
      'en': 'Book',
      'af': 'Goedkeur',
      'fr': 'Réserver ',
    },
    'g7xyhbez': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // PractionerDetail
  {
    '3368z4jf': {
      'en': 'Consultations',
      'af': 'Konsultasies',
      'fr': 'Consultations',
    },
    'ahomcxxh': {
      'en': 'About',
      'af': 'Oor',
      'fr': 'À propos',
    },
    'b2qyi0ti': {
      'en': 'Biography',
      'af': ' Biografie',
      'fr': 'Biographie ',
    },
    '6ldqdsrs': {
      'en': 'Working Hours',
      'af': 'Werksure',
      'fr': 'Heures de travail',
    },
    '1l91aunw': {
      'en': 'Monday - Friday, 08.00 AM - 08.00 PM',
      'af': 'Maandag - Vrydag, 08:00 - 20:00',
      'fr': 'Du lundi au vendredi, de 8h00 à 20h00',
    },
    'i6cb1he3': {
      'en': 'Reviews',
      'af': 'Resensies',
      'fr': 'Avis',
    },
    't92f1ltr': {
      'en': 'Reviewed on : ',
      'af': 'Geresenseer op:',
      'fr': 'Évalué le :',
    },
    'sx4h2t0t': {
      'en': 'Consultation fees',
      'af': 'Konsultasiefooie',
      'fr': 'honoraires de consultation',
    },
    'fx6721ol': {
      'en': 'Book',
      'af': 'Boek',
      'fr': 'Réserver ',
    },
    'bkfawz99': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // CareCenterSearchPage
  {
    '7mtr7pat': {
      'en': 'Search facility ',
      'af': 'Soekfasiliteit',
      'fr': 'Recherche d\'etablissement',
    },
    '0k5dt9mm': {
      'en': 'Search facility.....',
      'af': 'Soekfasiliteit.....',
      'fr': 'Recherche d\'etablissement...',
    },
    'abtj0g0l': {
      'en': 'Search facility Services...',
      'af': 'Soekfasiliteitdienste...',
      'fr': 'Recherche des services d\'un etablissement...',
    },
    '808fkuk9': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '0cg2pn5n': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'nxib66ja': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    '0k7ktbyy': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    'uvdyphaa': {
      'en': 'Search Facility Type ..',
      'af': 'Soek Fasiliteit Tipe ..',
      'fr': 'Recherche du type d\'etablissement ..',
    },
    'pxsx24b6': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'rw6z62g3': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'mzw901vp': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    '4mnvtdjx': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    '6kcbfcz5': {
      'en': 'facility name',
      'af': 'fasiliteit se naam',
      'fr': 'nom de l\'établissement',
    },
    'ehonnxro': {
      'en': 'Type',
      'af': 'Tipe',
      'fr': 'Model',
    },
    'aceo6d9t': {
      'en': 'phone',
      'af': 'foon',
      'fr': 'téléphone',
    },
    '1abo72e9': {
      'en': 'services',
      'af': 'dienste',
      'fr': 'services',
    },
    'm5vuu4tl': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // ProviderProfile_page
  {
    'h1uqtk8b': {
      'en': 'Profile Home',
      'af': 'Profiel Tuisblad',
      'fr': 'Profil Accueil',
    },
    'ljz1g40h': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'db3ml4s0': {
      'en': 'Full Name:',
      'af': 'Volle Naam:',
      'fr': 'Nom et prénom:',
    },
    'rrt159ii': {
      'en': 'Date of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    '03reqywo': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'd1z9sicm': {
      'en': 'Identity Information',
      'af': 'Identiteitsinligting',
      'fr': 'Informations d\'identité',
    },
    'rv6528e9': {
      'en': 'License #:',
      'af': 'Nasionale ID-nommer:',
      'fr': 'Numéro d\'identification national :',
    },
    'qi1sk3u0': {
      'en': 'National ID #:',
      'af': 'Nasionale ID-nommer:',
      'fr': 'Numéro d\'identification national :',
    },
    'x6tpgf6e': {
      'en': 'National ID Issue Date:',
      'af': 'Nasionale ID-uitreikingsdatum:',
      'fr': 'Date de délivrance de la CNI :',
    },
    'f5usi34s': {
      'en': 'National ID Exp Date:',
      'af': 'Nasionale ID-vervaldatum:',
      'fr': 'Date d\'expiration de la CNI :',
    },
    'n332x1gh': {
      'en': 'Contact Information',
      'af': 'Kontakbesonderhede',
      'fr': 'Coordonnées',
    },
    'r69zm4rs': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'arsspwxk': {
      'en': 'Address:',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    '6dn6w0ed': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    '8q5m7ftj': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'ukbqz4ry': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro de police :',
    },
    '1yii4qfa': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'llgkn57l': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'eeiwbjo0': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'bpd1ncwe': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'npm0p03z': {
      'en': 'CareCenter',
      'af': 'Sorgsentrum',
      'fr': 'Centre de soins',
    },
  },
  // PatientsMedicationPage
  {
    '5bsoyejt': {
      'en': 'Medications',
      'af': 'Medikasie',
      'fr': 'Médicaments',
    },
    'd170077o': {
      'en': 'Search medications...',
      'af': 'Soek medikasie...',
      'fr': 'Rechercher des médicaments...',
    },
    'zcd5ngxw': {
      'en': 'Current Medications',
      'af': 'Huidige Medikasie',
      'fr': 'Médicaments actuels',
    },
    'r3xpt7d9': {
      'en': 'No medication',
      'af': 'Geen medikasie',
      'fr': 'Aucun médicament',
    },
    'mav5bwwg': {
      'en': 'Medication History',
      'af': 'Medikasiegeskiedenis',
      'fr': 'Médicaments antécédents ',
    },
    'hxyulw9x': {
      'en': 'No medication',
      'af': 'Geen medikasie',
      'fr': 'Aucun médicament',
    },
    'oocdvfp3': {
      'en': 'Request Refill',
      'af': 'Versoek hervulling',
      'fr': 'Demande de recharge',
    },
    'bbkhkgi7': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Patient_Diagnostics
  {
    'hofgws01': {
      'en': 'Patient Diagnostics',
      'af': 'Pasiëntdiagnostiek',
      'fr': 'Diagnostic du patient',
    },
    '2zqd9m3g': {
      'en': 'Gender: ',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'y05pph7k': {
      'en': 'Age: 34 • Female',
      'af': 'Ouderdom: 34 • Vroulik',
      'fr': 'Âge : 34 ans • Femme',
    },
    'z92fcvkk': {
      'en': 'ID: ',
      'af': 'ID:',
      'fr': 'IDENTIFIANT:',
    },
    'y45t6s7t': {
      'en': 'ID: MZ-2024-7891',
      'af': 'ID: MZ-2024-7891',
      'fr': 'ID : MZ-2024-7891',
    },
    't1dz2ysc': {
      'en': 'Last Visit',
      'af': 'Laaste besoek',
      'fr': 'Dernière visite',
    },
    '2allwt56': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'hfgolo9p': {
      'en': 'Primary Doctor',
      'af': 'Primêre Dokter',
      'fr': 'Médecin généraliste',
    },
    'ovw8awaj': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    '7i6fu65b': {
      'en': 'Search diagnostics...',
      'af': 'Soek diagnostiek...',
      'fr': 'Recherche de diagnostics...',
    },
    'hq0igq2k': {
      'en': 'Date:  null',
      'af': 'Datum: nul',
      'fr': 'Date : nulle',
    },
    'ev4ffpqp': {
      'en': 'No Diagnostics',
      'af': 'Geen Diagnostiek',
      'fr': 'Aucun diagnostic',
    },
  },
  // signIn
  {
    'dhbzbfgz': {
      'en': 'Sign In',
      'af': 'Aanmeld',
      'fr': 'Se connecter',
    },
    'kb3q4w5y': {
      'en': 'Enter Account Credentials',
      'af': 'Voer rekeningbewyse in',
      'fr': 'Saisissez les identifiants du compte',
    },
    'hwpuecwh': {
      'en': 'Password',
      'af': 'Wagwoord',
      'fr': 'Mot de passe',
    },
    'ggzuqb6i': {
      'en': 'Login',
      'af': 'Aanmeld',
      'fr': 'Se connecter',
    },
    '2nmqgsor': {
      'en': 'Don\'t have an account?',
      'af': 'Het jy nie \'n rekening nie?',
      'fr': 'Vous n\'avez pas de compte ?',
    },
    'xvqw9h9q': {
      'en': ' Sign Up',
      'af': 'Registreer',
      'fr': 'S\'inscrire',
    },
    '36sxueqo': {
      'en': 'Forgot Password?',
      'af': 'Wagwoord vergeet?',
      'fr': 'Mot de passe oublié ?',
    },
    'yyudfxol': {
      'en': 'Sign Up',
      'af': '',
      'fr': 'S\'inscrire',
    },
    'z0jgnqkd': {
      'en': 'Create an account',
      'af': 'Skep \'n rekening',
      'fr': 'Créer un compte',
    },
    'vumgmjf8': {
      'en': 'Let\'s get started by filling out the form below.',
      'af': 'Kom ons begin deur die onderstaande vorm in te vul.',
      'fr': 'Commençons par remplir le formulaire ci-dessous.',
    },
    'atj9l851': {
      'en': 'Password *',
      'af': 'Wagwoord',
      'fr': 'Mot de passe',
    },
    '4yb91xok': {
      'en': 'Passwod required',
      'af': 'Wagwoord benodig',
      'fr': 'Mot de passe requis',
    },
    'x6xkcup7': {
      'en': 'Password must be at least 8 characters',
      'af': 'Wagwoord voldoen nie aan vereistes nie',
      'fr': 'Le mot de passe ne répond pas aux exigences',
    },
    'dkh9yucf': {
      'en':
          'Minimum length of 8 characters\nAt least  One upper case. \nAt least  One digit.\nAt least  One special character (?=.[!@#\$%^&()_+\\-={};\':\"\\\\|,.<>\\/?])',
      'af': '',
      'fr':
          'Longueur minimale de 8 caractères.  \nAu moins une majuscule.  \nAu moins un chiffre.  \nAu moins un caractère spécial (?=.[!@#\$%^&()_+\\-={};\':\"\\\\|,.<>\\/?])',
    },
    '7gaz3aia': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'h2w1u1ax': {
      'en': 'Confirm Password *',
      'af': 'Bevestig wagwoord',
      'fr': 'Confirmez le mot de passe *',
    },
    '30kmz7kg': {
      'en': 'Password  does not match',
      'af':
          'Die wagwoord moet ten minste 8 karakters lank wees en \'n kleinletter, \'n hoofletter en \'n nommer of simbool insluit.',
      'fr':
          'Le mot de passe doit comporter au moins 8 caractères et inclure une lettre minuscule, une lettre majuscule et un chiffre ou un symbole.',
    },
    'lnig5dfa': {
      'en': 'I\'ve read and  accept the  ',
      'af': 'Ek het die gelees en aanvaar',
      'fr': 'J\'ai lu et j\'accepte',
    },
    'dvu7x7de': {
      'en': 'terms and conditions',
      'af': 'bepalings en voorwaardes',
      'fr': 'Termes et conditions',
    },
    'v1wirb5a': {
      'en': 'By signing up you agree to the terms and conditions',
      'af': 'Deur aan te meld, stem jy in tot die bepalings en voorwaardes',
      'fr': 'En vous inscrivant, vous acceptez les conditions générales',
    },
    '6wbh52jt': {
      'en': 'Create Account',
      'af': 'Skep Rekening',
      'fr': 'Créer un compte',
    },
    'nhp8ye2a': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // patientsSettingsPage
  {
    'bhrch1vk': {
      'en': 'Profile Information',
      'af': 'Profielinligting',
      'fr': 'Informations de profil',
    },
    '877jla3k': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    '29qxg2km': {
      'en': 'Date Of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    '167bwpae': {
      'en': 'Phone Number:',
      'af': 'Telefoonnommer:',
      'fr': 'Numéro de téléphone:',
    },
    'x3gdq8oi': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'g3fbt70p': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'hkeqig9g': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'etc77cx5': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d \' assurance :',
    },
    'dlh5im8m': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    '3shdva7k': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'qpecen19': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'oabywhe9': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '2lsritr5': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '64kn2ygj': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    '2nzyoooi': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    '47u9z8z9': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'kyuxg3qj': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '5z65jgmn': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'qzebp0te': {
      'en': 'Preferences',
      'af': 'Voorkeure',
      'fr': 'Préférences',
    },
    '2yzlqgfm': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'vxxaf8mj': {
      'en': 'View profile details',
      'af': 'Bekyk profielbesonderhede',
      'fr': 'Voir les détails du profil',
    },
    'b4kb02oy': {
      'en': 'Documents',
      'af': 'Dokumente',
      'fr': 'Documents',
    },
    'a7prwpf7': {
      'en': 'View documents',
      'af': 'Bekyk dokumente',
      'fr': 'Consulter les documents',
    },
    '93ms8qxk': {
      'en': 'Notification Sounds',
      'af': 'Kennisgewingklanke',
      'fr': 'Sons de notification',
    },
    'dq2l0l83': {
      'en': 'Enable audio alerts',
      'af': 'Aktiveer oudio-waarskuwings',
      'fr': 'Activer les alertes audio',
    },
    '4mra454j': {
      'en': 'Auto-Refresh',
      'af': 'Outomatiese herlaai',
      'fr': 'Actualisation automatique',
    },
    'b9cbt7r5': {
      'en': 'Automatically update data',
      'af': 'Dateer data outomaties op',
      'fr': 'Mise à jour automatique des données',
    },
    'rdqso950': {
      'en': 'Appointment Alerts',
      'af': 'Afspraakwaarskuwings',
      'fr': 'Alertes de rendez-vous',
    },
    'g0jc27c2': {
      'en': 'Get notified about appointments',
      'af': 'Kry kennisgewings oor afsprake',
      'fr': 'Recevez des notifications concernant vos rendez-vous',
    },
    'tmcw22s2': {
      'en': 'Payment Methods',
      'af': 'Betaalmetodes',
      'fr': 'Modes de paiement',
    },
    'lwceuzv4': {
      'en': 'Choose payment methods',
      'af': 'Kies betaalmetodes',
      'fr': 'Choisissez vos modes de paiement',
    },
    '6xmxot25': {
      'en': 'Manage',
      'af': 'Bestuur',
      'fr': 'Gérer',
    },
    'f9rioc8a': {
      'en': 'Language',
      'af': 'Taal',
      'fr': 'Langue',
    },
    '8g8hndif': {
      'en': 'Choose your language',
      'af': 'Kies jou taal',
      'fr': 'Choisissez votre langue',
    },
    '4pjwjl42': {
      'en': 'Privacy & Security',
      'af': 'Privaatheid en sekuriteit',
      'fr': 'Confidentialité et sécurité',
    },
    'n3zzlb3u': {
      'en': 'Two-Factor Authentication',
      'af': 'Twee-faktor-verifikasie',
      'fr': 'Authentification à deux facteurs',
    },
    '66dg09q1': {
      'en': 'Add extra security to your account',
      'af': 'Voeg ekstra sekuriteit by jou rekening',
      'fr': 'Renforcez la sécurité de votre compte',
    },
    'gyqkxwvt': {
      'en': 'Data Sharing',
      'af': 'Datadeling',
      'fr': 'Partage de données',
    },
    's516mk3s': {
      'en': 'Allow anonymous usage analytics',
      'af': 'Laat anonieme gebruiksanalise toe',
      'fr': 'Autoriser les analyses d\'utilisation anonymes',
    },
    'mkr82jhj': {
      'en': 'Change Password',
      'af': 'Verander wagwoord',
      'fr': 'Changer le mot de passe',
    },
    'ma3cwp01': {
      'en': 'Save Changes',
      'af': 'Stoor veranderinge',
      'fr': 'Enregistrer les modifications',
    },
    'byllyqb4': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'v2tug54u': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // facilityAdminSettingsPage
  {
    '0i38d1lr': {
      'en': 'Profile Information',
      'af': 'Profielinligting',
      'fr': 'Informations de profil',
    },
    'dmj1hhyn': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '1jvc73vp': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    '0pvwiqf1': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    '52rut4ir': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    't5kktzd1': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'shmyg29q': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    's54ycdfa': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    '4du95mey': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '7m37cfjh': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'ltnbrswn': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'q2nhstbj': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'f92njnx5': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'ri43vzvd': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'gbcsqlqg': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'svnoj0xq': {
      'en': 'Preferences',
      'af': 'Voorkeure',
      'fr': 'Préférences',
    },
    'd1nchxqf': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'ky4jo8ac': {
      'en': 'View profile details',
      'af': 'Bekyk profielbesonderhede',
      'fr': 'Voir les détails du profil',
    },
    'k020h1a4': {
      'en': 'Dark Mode',
      'af': 'Donkermodus',
      'fr': 'Mode sombre',
    },
    'c6j4fx6b': {
      'en': 'Switch to dark theme',
      'af': 'Skakel oor na donker tema',
      'fr': 'Passer au mode sombre',
    },
    'yqt99oa6': {
      'en': 'Notification Sounds',
      'af': 'Kennisgewingklanke',
      'fr': 'Sons de notification',
    },
    '3s6i7l36': {
      'en': 'Enable audio alerts',
      'af': 'Aktiveer oudio-waarskuwings',
      'fr': 'Activer les alertes audio',
    },
    'rwrj0931': {
      'en': 'Auto-Refresh',
      'af': 'Outomatiese herlaai',
      'fr': 'Actualisation automatique',
    },
    'tq5vkemm': {
      'en': 'Automatically update data',
      'af': 'Dateer data outomaties op',
      'fr': 'Mise à jour automatique des données',
    },
    '0hhsp47h': {
      'en': 'Appointment Alerts',
      'af': 'Afspraakwaarskuwings',
      'fr': 'Alertes de rendez-vous',
    },
    'gkisikbp': {
      'en': 'Get notified about appointments',
      'af': 'Kry kennisgewings oor afsprake',
      'fr': 'Recevez des notifications concernant vos rendez-vous',
    },
    'dvdgd8vy': {
      'en': 'Language',
      'af': 'Taal',
      'fr': 'Langue',
    },
    'y0yqkjwn': {
      'en': 'Choose your language',
      'af': 'Kies jou taal',
      'fr': 'Choisissez votre langue',
    },
    'vebpwnj3': {
      'en': 'Privacy & Security',
      'af': 'Privaatheid en sekuriteit',
      'fr': 'Confidentialité et Sécurité',
    },
    'abrfmx7p': {
      'en': 'Two-Factor Authentication',
      'af': 'Twee-faktor-verifikasie',
      'fr': 'Authentification à deux facteurs',
    },
    'nbju8419': {
      'en': 'Add extra security to your account',
      'af': 'Voeg ekstra sekuriteit by jou rekening',
      'fr': 'Renforcez la sécurité de votre compte',
    },
    'u83m72za': {
      'en': 'Data Sharing',
      'af': 'Datadeling',
      'fr': 'Partage de données',
    },
    'm4ojlaev': {
      'en': 'Allow anonymous usage analytics',
      'af': 'Laat anonieme gebruiksanalise toe',
      'fr': 'Autorisez les analyses d\'utilisation anonymes',
    },
    'h8idp7q3': {
      'en': 'Change Password',
      'af': 'Verander wagwoord',
      'fr': 'Changer le mot de passe',
    },
    'arfvhci3': {
      'en': 'Save Changes',
      'af': 'Stoor veranderinge',
      'fr': 'Enregistrez les modifications',
    },
    'pmvqj3xp': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'ktqluyiy': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // ProviderSettingsPage
  {
    '4k794oy1': {
      'en': 'Profile Information',
      'af': 'Profielinligting',
      'fr': 'Informations de profil',
    },
    'h3edakek': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'mv3i9f4k': {
      'en': 'Dr Ketum',
      'af': 'Dr. Ketum',
      'fr': 'Dr Ketum',
    },
    'xedhds4q': {
      'en': 'Specialty: ',
      'af': 'Spesialiteit:',
      'fr': 'Spécialité:',
    },
    'vpklf2qi': {
      'en': 'Specialty',
      'af': 'Spesialiteit',
      'fr': 'Spécialité',
    },
    '0dv2gazs': {
      'en': 'License #: ',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'lyd5aqom': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'npdg0wd8': {
      'en': 'Consultation Fee:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'ixswl22l': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'yjn3gxoz': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'w4mqwktx': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    'vdai2v1x': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'b33zynue': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'ndyojl0e': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'r9hskrm0': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '2xk3t2vx': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '4cuukwfz': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'lj69c9fx': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    '1rzq99u8': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'je23a2vd': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'u3036pja': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'doyrejmx': {
      'en': 'Edit Your Availability',
      'af': 'Wysig jou beskikbaarheid',
      'fr': 'Modifier vos disponibilités',
    },
    'ousxp4rx': {
      'en': 'Monday',
      'af': 'Maandag',
      'fr': 'Lundi',
    },
    'dqdwe8l3': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'u4zm4cs8': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'v3m2sssm': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'xyehw887': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'y9zpqrld': {
      'en': 'Tuesday',
      'af': 'Dinsdag',
      'fr': 'Mardi',
    },
    's4ezqo3z': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'pgx30dx7': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverteure',
    },
    'hc4a0usm': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '94n7u2dw': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    '15t66nj4': {
      'en': 'Wednesday',
      'af': 'Woensdag',
      'fr': 'Mercredi',
    },
    'aj9ec2gd': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'cveu3mhw': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'n5ulj561': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '8yjg2zfm': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'z9sqoj97': {
      'en': 'Thursday',
      'af': 'Donderdag',
      'fr': 'Jeudi',
    },
    'a608ar4d': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'mt12pkz3': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '5h6qqr2t': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'k6gbtzld': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'yrcs3xgv': {
      'en': 'Friday',
      'af': 'Vrydag',
      'fr': 'Vendredi',
    },
    '54x3veyj': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'l5qwr4gr': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '5xuq3pve': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '21279ing': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'vvghi6uv': {
      'en': 'Saturday',
      'af': 'Saterdag',
      'fr': 'Samedi',
    },
    '6yzjn97t': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'i57hxi6w': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'l1vni6ci': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    't1grtt80': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'd4m9nx1b': {
      'en': 'Sunday',
      'af': 'Sondag',
      'fr': 'Dimanche',
    },
    'w1atx2dc': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'lfo0uuwl': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '9t8agrnq': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '31ez5pop': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'ty6wbjdm': {
      'en': 'Preferences',
      'af': 'Voorkeure',
      'fr': 'Préférences',
    },
    '14vwv412': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'm7it6eph': {
      'en': 'View profile details',
      'af': 'Bekyk profielbesonderhede',
      'fr': 'Voir les détails du profil',
    },
    '6l7znh0d': {
      'en': 'Dark Mode',
      'af': 'Donkermodus',
      'fr': 'Mode sombre',
    },
    '4cnn696z': {
      'en': 'Switch to dark theme',
      'af': 'Skakel oor na donker tema',
      'fr': 'Passer en mode sombre',
    },
    '3rdf57j4': {
      'en': 'Notification Sounds',
      'af': 'Kennisgewingklanke',
      'fr': 'Sons de notification',
    },
    '2bclwr06': {
      'en': 'Enable audio alerts',
      'af': 'Aktiveer oudio-waarskuwings',
      'fr': 'Activer les alertes audio',
    },
    'lqf0r3lk': {
      'en': 'Auto-Refresh',
      'af': 'Outomatiese herlaai',
      'fr': 'Actualisation automatique',
    },
    'yyjrn8ho': {
      'en': 'Automatically update data',
      'af': 'Dateer data outomaties op',
      'fr': 'Mise à jour automatique des données',
    },
    'ows03kjp': {
      'en': 'Appointment Alerts',
      'af': 'Afspraakwaarskuwings',
      'fr': 'Alertes de rendez-vous',
    },
    'uxnfysy0': {
      'en': 'Get notified about appointments',
      'af': 'Kry kennisgewings oor afsprake',
      'fr': 'Recevez des notifications concernant vos rendez-vous',
    },
    '4y9i495q': {
      'en': 'Language',
      'af': 'Taal',
      'fr': 'Langue',
    },
    't5j0hsid': {
      'en': 'Choose your language',
      'af': 'Kies jou taal',
      'fr': 'Choisissez votre langue',
    },
    'ndnw27tp': {
      'en': 'Privacy & Security',
      'af': 'Privaatheid en sekuriteit',
      'fr': 'Confidentialité et sécurité',
    },
    'pfvvivw9': {
      'en': 'Two-Factor Authentication',
      'af': 'Twee-faktor-verifikasie',
      'fr': 'Authentification à deux facteurs',
    },
    'tzxx1awi': {
      'en': 'Add extra security to your account',
      'af': 'Voeg ekstra sekuriteit by jou rekening',
      'fr': 'Renforcez la sécurité de votre compte',
    },
    'v2ey8ect': {
      'en': 'Change Password',
      'af': 'Verander wagwoord',
      'fr': 'Changer le mot de passe',
    },
    'joupjcxk': {
      'en': 'Save Changes',
      'af': 'Stoor veranderinge',
      'fr': 'Enregistrer les modifications',
    },
    'pvsm900h': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'ry9k9vef': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // systemAdmin_settings_Page
  {
    'mf4q1442': {
      'en': 'Profile Information',
      'af': 'Profielinligting',
      'fr': 'Informations de profil',
    },
    '1abgdhhg': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'unmrsry3': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    '8apvitot': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'a8yeckya': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    '93mo7w3c': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    't9atgalw': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'nr728xpz': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    '3qwjt1gy': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'pmyhamk3': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'xxql9b7y': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'jhim9cuo': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'o185pm8a': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '0w9d0enz': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'u3jnhxv5': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'en6bfyqq': {
      'en': 'Preferences',
      'af': 'Voorkeure',
      'fr': 'Préférences',
    },
    'wpa26jg5': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'yhypgp0b': {
      'en': 'View profile details',
      'af': 'Bekyk profielbesonderhede',
      'fr': 'Voir les détails du profil',
    },
    'htufb3gh': {
      'en': 'Dark Mode',
      'af': 'Donkermodus',
      'fr': 'Mode sombre',
    },
    '0rmsn2b8': {
      'en': 'Switch to dark theme',
      'af': 'Skakel oor na donker tema',
      'fr': 'Passer en mode sombre',
    },
    'c8nz2jw9': {
      'en': 'Notification Sounds',
      'af': 'Kennisgewingklanke',
      'fr': 'Sons de notification',
    },
    'kw5yxnt9': {
      'en': 'Enable audio alerts',
      'af': 'Aktiveer oudio-waarskuwings',
      'fr': 'Activer les alertes audio',
    },
    '1fttj8q1': {
      'en': 'Auto-Refresh',
      'af': 'Outomatiese herlaai',
      'fr': 'Actualisation automatique',
    },
    'ryu4slxx': {
      'en': 'Automatically update data',
      'af': 'Dateer data outomaties op',
      'fr': 'Mise à jour automatique des données',
    },
    'ez13cpuc': {
      'en': 'Appointment Alerts',
      'af': 'Afspraakwaarskuwings',
      'fr': 'Alertes de rendez-vous',
    },
    'zgwi3bfl': {
      'en': 'Get notified about appointments',
      'af': 'Kry kennisgewings oor afsprake',
      'fr': 'Recevez des notifications concernant vos rendez-vous',
    },
    'hzm73m7n': {
      'en': 'Language',
      'af': 'Taal',
      'fr': 'Langue',
    },
    'f34cxq48': {
      'en': 'Choose your language',
      'af': 'Kies jou taal',
      'fr': 'Choisissez votre langue',
    },
    'ukkido04': {
      'en': 'Privacy & Security',
      'af': 'Privaatheid en sekuriteit',
      'fr': 'Confidentialité et sécurité',
    },
    '5su6wa76': {
      'en': 'Two-Factor Authentication',
      'af': 'Twee-faktor-verifikasie',
      'fr': 'Authentification à deux facteurs',
    },
    'ubzzju4n': {
      'en': 'Add extra security to your account',
      'af': 'Voeg ekstra sekuriteit by jou rekening',
      'fr': 'Renforcez la sécurité de votre compte',
    },
    'r855nb83': {
      'en': 'Data Sharing',
      'af': 'Datadeling',
      'fr': 'Partage de données',
    },
    'yczzblrl': {
      'en': 'Allow anonymous usage analytics',
      'af': 'Laat anonieme gebruiksanalise toe',
      'fr': 'Autoriser les analyses d\'utilisation anonymes',
    },
    'i5z1szl2': {
      'en': 'Change Password',
      'af': 'Verander wagwoord',
      'fr': 'Changer le mot de passe',
    },
    '8m28939s': {
      'en': 'Save Changes',
      'af': 'Stoor veranderinge',
      'fr': 'Enregistrer les modifications',
    },
    'dpmp9je5': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'kek04a8v': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // systemAdminProfilePage
  {
    '7c03bzka': {
      'en': 'Profile Home',
      'af': 'Profiel Tuisblad',
      'fr': 'Profil Accueil',
    },
    'vmuu7fi3': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    '6sd5ele4': {
      'en': 'Full Name:',
      'af': 'Volle Naam:',
      'fr': 'Nom et prénom:',
    },
    'xybwhwah': {
      'en': 'Date of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'ozyftkci': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'civrffyd': {
      'en': 'Identity Information',
      'af': 'Identiteitsinligting',
      'fr': 'Informations d\'identité',
    },
    'nprizpit': {
      'en': 'National ID #:',
      'af': 'Nasionale ID-nommer:',
      'fr': 'Numéro d\'identification national :',
    },
    'v0xsa27p': {
      'en': 'National ID Issue Date:',
      'af': 'Nasionale ID-uitreikingsdatum:',
      'fr': 'Date de délivrance de la carte d\'identité nationale :',
    },
    '71r01je3': {
      'en': 'National ID Exp Date:',
      'af': 'Nasionale ID-vervaldatum:',
      'fr': 'Date d\'expiration de la carte d\'identité nationale :',
    },
    's1tg9z0d': {
      'en': 'Contact Information',
      'af': 'Kontakbesonderhede',
      'fr': 'Coordonnées',
    },
    'gfs96cjq': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'k0ihbzkr': {
      'en': 'Address:',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    'k4uj9ztw': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'cg8s9a84': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'v6hr865z': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    'tfl5i9zf': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    '5g822id1': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    '50dd7qzk': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    '63ztwa04': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'dolyrhaw': {
      'en': 'CareCenter',
      'af': 'Sorgsentrum',
      'fr': 'Centre de soins',
    },
  },
  // facilityAdminProfilePage
  {
    'q2ck12xr': {
      'en': 'Profile Home',
      'af': 'Profiel Tuisblad',
      'fr': 'Profil Accueil',
    },
    'e76qh77x': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    '0o3u15ma': {
      'en': 'Full Name:',
      'af': 'Volle Naam:',
      'fr': 'Nom et prénom:',
    },
    '1rokqxhb': {
      'en': 'Date of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'uscgj3p9': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'i65ye5st': {
      'en': 'Identity Information',
      'af': 'Identiteitsinligting',
      'fr': 'Informations d\'identité',
    },
    'dsjdsrh0': {
      'en': 'National ID #:',
      'af': 'Nasionale ID-nommer:',
      'fr': 'Numéro d\'identification national :',
    },
    'yk52w0tq': {
      'en': 'National ID Issue Date:',
      'af': 'Nasionale ID-uitreikingsdatum:',
      'fr': 'Date de délivrance de CNI:',
    },
    'ybzoy0gy': {
      'en': 'National ID Exp Date:',
      'af': 'Nasionale ID-vervaldatum:',
      'fr': 'Date d\'expiration de CNI:',
    },
    '9fqfqoun': {
      'en': 'Contact Information',
      'af': 'Kontakbesonderhede',
      'fr': 'Coordonnées',
    },
    'hcgahk2v': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    '6ytsdvhd': {
      'en': 'Address:',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    '8ctdlfmi': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'eydcoju6': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'lqu9zl9i': {
      'en': 'Policy Number:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    'ni9rx3p8': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    '1dk3cxk0': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'sjxgepqo': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'e4gsu1tt': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'exjqg3pq': {
      'en': 'CareCenter',
      'af': 'Sorgsentrum',
      'fr': 'Centre de soins',
    },
  },
  // ProvidersDocumentPage
  {
    '3esad3wl': {
      'en': 'Provider Content Management',
      'af': 'Verskaffer Inhoudbestuur',
      'fr': 'Gestion du contenu des Medecins',
    },
    'vktw9k2y': {
      'en': 'Search documents...',
      'af': 'Soek dokumente...',
      'fr': 'Rechercher des documents...',
    },
    'xqqwvytn': {
      'en': 'Upload New Content',
      'af': 'Laai nuwe inhoud op',
      'fr': 'Ajouter du nouveau contenu',
    },
    'ppudrhl8': {
      'en': 'Title',
      'af': 'Titel',
      'fr': 'Titre',
    },
    'my96dvnh': {
      'en': 'Content Title',
      'af': 'Inhoudtitel',
      'fr': 'Titre du contenu',
    },
    '0emmbwln': {
      'en': '  Select Content Type',
      'af': 'Kies Inhoudtipe',
      'fr': 'Sélectionnez le type de contenu',
    },
    'vs8cnkmo': {
      'en': 'Content Type',
      'af': 'Inhoudtipe',
      'fr': 'Type de contenu',
    },
    't0sdv98g': {
      'en': '  Article',
      'af': 'Artikel',
      'fr': 'Article',
    },
    '44eldcei': {
      'en': '  PDF Document',
      'af': 'PDF-dokument',
      'fr': 'Document PDF',
    },
    'sawp9vd3': {
      'en': '  External Link',
      'af': 'Eksterne skakel',
      'fr': 'Lien externe',
    },
    'sdbjpiph': {
      'en': '  Health Tips & Awareness Posts',
      'af': 'Gesondheidswenke en -bewustheidsplasings',
      'fr': 'Conseils de santé et articles de sensibilisation',
    },
    '386m6m8x': {
      'en': '   Research Summary / Update',
      'af': 'Navorsingsopsomming / Opdatering',
      'fr': 'Résumé/mise à jour de la recherche',
    },
    '8bq10l5a': {
      'en': '  Podcast / Audio Clip',
      'af': 'Poduitsending / Oudiogreep',
      'fr': 'Podcast / Extrait audio',
    },
    's5n7t9ag': {
      'en': '  Patient Education Handout',
      'af': 'Pasiëntopvoedingsuitdeelstuk',
      'fr': 'Document d\'information pour les patients',
    },
    'z90ir98q': {
      'en': '  Newsletter / Announcement',
      'af': 'Nuusbrief / Aankondiging',
      'fr': 'Bulletin d\'information / Annonce',
    },
    'cp7s66ej': {
      'en': 'Article Content',
      'af': 'Artikelinhoud',
      'fr': 'Contenu de l\'article',
    },
    '9xokw1lv': {
      'en': 'Write your article content here...',
      'af': 'Skryf jou artikelinhoud hier...',
      'fr': 'Rédigez ici le contenu de votre article...',
    },
    'vo4j0ryu': {
      'en': 'Click to upload files or drag and drop',
      'af': 'Klik om lêers op te laai of sleep en los',
      'fr': 'Cliquez pour ajouter des fichiers .',
    },
    '93y39a42': {
      'en': 'PDF, DOC, DOCX up to 10MB',
      'af': 'PDF, DOC, DOCX tot 10 MB',
      'fr': 'PDF, DOC, DOCX jusqu\'à 10 MB',
    },
    '45uk738g': {
      'en': 'Publish Content',
      'af': 'Publiseer inhoud',
      'fr': 'Publier du contenu',
    },
    'zyviedcy': {
      'en': 'My Publications',
      'af': 'My Publikasies',
      'fr': 'Mes publications',
    },
    '6yrfox8n': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // PatientsDocumentPage
  {
    'ggly852e': {
      'en': 'My Documents',
      'af': 'My Dokumente',
      'fr': 'Mes documents',
    },
    'w5668izx': {
      'en': 'Share medical records with your providers securely',
      'af': 'Deel mediese rekords veilig met jou verskaffers',
      'fr':
          'Partagez vos dossiers médicaux en toute sécurité avec vos professionnels de santé.',
    },
    '0fv3xayr': {
      'en': 'Search documents...',
      'af': 'Soek dokumente...',
      'fr': 'Rechercher des documents...',
    },
    '6jvmmn54': {
      'en': 'Upload New Document',
      'af': 'Laai Nuwe Dokument Op',
      'fr': 'Ajouter un nouveau document',
    },
    'j8m5ia17': {
      'en': 'Document Title',
      'af': 'Dokumenttitel',
      'fr': 'Titre du document',
    },
    '8cctruon': {
      'en': 'Enter document title',
      'af': 'Voer dokumenttitel in',
      'fr': 'Saisissez le titre du document',
    },
    'vshmhnqb': {
      'en': '  Select Document Type',
      'af': 'Kies Dokumenttipe',
      'fr': 'Sélectionnez le type de document',
    },
    'gr8mfrz4': {
      'en': '   Lab Result',
      'af': 'Laboratoriumresultaat',
      'fr': 'Résultats de laboratoire',
    },
    'orow9p72': {
      'en': '   Prescription',
      'af': 'Voorskrif',
      'fr': 'Ordonnance',
    },
    'gmkdp1di': {
      'en': '   Imaging',
      'af': 'Beeldvorming',
      'fr': 'Imagerie',
    },
    'auw16bqj': {
      'en': '   Vaccination Record',
      'af': 'Inentingsrekord',
      'fr': 'Rapport de vaccination',
    },
    '11kemdpn': {
      'en': '   Allergy Record',
      'af': 'Allergie Rekord',
      'fr': 'Dossier d\'allergie',
    },
    'uwcqj8jr': {
      'en': '   Insurance Document',
      'af': 'Versekeringsdokument',
      'fr': 'Document d\'assurance',
    },
    'osflet47': {
      'en': '   Medical Certificate',
      'af': 'Mediese Sertifikaat',
      'fr': 'Certificat Médical',
    },
    'ziq416nf': {
      'en': '   Referral Letter',
      'af': 'Verwysingsbrief',
      'fr': 'Lettre de recommandation',
    },
    '643eyjh6': {
      'en': '   Medical Report',
      'af': 'Mediese Verslag',
      'fr': 'Rapport médical',
    },
    '2v4qbojh': {
      'en': '   Other',
      'af': 'Ander',
      'fr': 'Autre',
    },
    'ttnbqe17': {
      'en': 'Click to upload files or drag and drop',
      'af': 'Klik om lêers op te laai of sleep en los',
      'fr': 'Cliquez pour ajouter des fichiers ou glissez-déposez-les.',
    },
    '89cbpyeh': {
      'en': 'PDF, DOC, DOCX up to 10MB',
      'af': 'PDF, DOC, DOCX tot 10 MB',
      'fr': 'PDF, DOC, DOCX jusqu\'à 10 MB',
    },
    'nvdx1fr7': {
      'en': '  Share with Provider ',
      'af': 'Deel met Verskaffer',
      'fr': 'Partager avec le Medecin',
    },
    '9jwxzmel': {
      'en': '  Dr. Sarah Johnson',
      'af': 'Dr. Sarah Johnson',
      'fr': 'Dr Sarah Johnson',
    },
    'pdbz421t': {
      'en': '  Dr. Michael Chen',
      'af': 'Dr. Michael Chen',
      'fr': 'Dr Michael Chen',
    },
    '4vb1ia0e': {
      'en': '  Dr. Emily Davis',
      'af': 'Dr. Emily Davis',
      'fr': 'Dr Emily Davis',
    },
    'a69o10wb': {
      'en': 'Upload Document',
      'af': 'Laai dokument op',
      'fr': 'Ajouter un document',
    },
    'lsk3y1x8': {
      'en': 'Lab Results',
      'af': 'Laboratoriumresultate',
      'fr': 'Résultats de laboratoire',
    },
    'k4j6giei': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'finz4upl': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'tq2bmpcq': {
      'en': 'Prescription',
      'af': 'Voorskrif',
      'fr': 'Ordonnance',
    },
    'g8tqwsbj': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    '785mblez': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    '8y8dgkbf': {
      'en': 'X-Ray Results',
      'af': 'X-straalresultate',
      'fr': 'Résultats des radiographies',
    },
    'wzz5m26s': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'sujqzet8': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'yt50ch8j': {
      'en': 'Visit Summary',
      'af': 'Besoekopsomming',
      'fr': 'Résumé de la visite',
    },
    'e4mc6yrk': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    '75lad9wp': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'xl0h38un': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // ProviderAccountCreation
  {
    'owa7rsuf': {
      'en': 'Provider Basic Information',
      'af': 'Verskaffer Basiese Inligting',
      'fr': 'Informations de base du Médecin',
    },
    '5wjh8pne': {
      'en': 'Let\'s start with some basic information to set up your account.',
      'af':
          'Kom ons begin met \'n paar basiese inligting om jou rekening op te stel.',
      'fr':
          'Commençons par quelques informations de base pour créer votre compte.',
    },
    '4j7tsz0r': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'ihacafea': {
      'en': 'medical_provider',
      'af': 'mediese_verskaffer',
      'fr': 'fournisseur de soins médicaux',
    },
    'kxap9ge5': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'unuep943': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'qhnydybs': {
      'en': 'French',
      'af': 'Frans',
      'fr': 'Français',
    },
    'ev6djmuh': {
      'en': 'English',
      'af': 'Engels',
      'fr': 'Anglais',
    },
    'imm0w6t9': {
      'en': 'Fulfude',
      'af': 'Fulfude',
      'fr': 'Fulfude',
    },
    '64679jpc': {
      'en': 'Prefered Language',
      'af': 'Voorkeurtaal',
      'fr': 'Langue préférée',
    },
    'unwpzffc': {
      'en': 'First Name',
      'af': 'Voornaam',
      'fr': 'Prénom',
    },
    'hkq5f1lb': {
      'en': 'Middle Name',
      'af': 'Middelnaam',
      'fr': 'Deuxième prénom',
    },
    'x5te1qw3': {
      'en': 'Last Name',
      'af': 'Van',
      'fr': 'Nom de famille',
    },
    'j9lbu333': {
      'en': 'Date Of Birth',
      'af': 'Geboortedatum',
      'fr': 'Date de naissance',
    },
    'yawzmmfd': {
      'en': 'ID Card Details',
      'af': 'ID-kaartbesonderhede',
      'fr': 'Détails de la carte d\'identité',
    },
    '2c4kyhvx': {
      'en': 'ID CARD NUMBER',
      'af': 'ID-KAARTNOMMER',
      'fr': 'NUMÉRO DE CARTE D\'IDENTITÉ',
    },
    'pyo7t6vl': {
      'en': 'ISSUE DATE',
      'af': 'UITREIKINGSDATUM',
      'fr': 'DATE D\'ÉMISSION',
    },
    'dwdindoj': {
      'en': 'EXPIRATION DATE',
      'af': 'VERVALDATUM',
      'fr': 'DATE D\'EXPIRATION',
    },
    'jbe04dm2': {
      'en': 'Select Gender',
      'af': 'Kies Geslag',
      'fr': 'Sélectionner le sexe',
    },
    'kwg4mtza': {
      'en': 'M',
      'af': 'M',
      'fr': 'M',
    },
    '2y7zroox': {
      'en': 'F',
      'af': 'F',
      'fr': 'F',
    },
    'ep0rd3o4': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    '5i4fon0q': {
      'en': 'Street',
      'af': 'Straat',
      'fr': 'Rue',
    },
    'i6hxo89e': {
      'en': 'City ',
      'af': 'Stad',
      'fr': 'Ville',
    },
    'ic5v5hxk': {
      'en': 'Region',
      'af': 'Streek',
      'fr': 'Région',
    },
    'x1qewwry': {
      'en': 'Zip Code / P.O Box',
      'af': 'Poskode / Posbus',
      'fr': 'Code postal / Boîte postale',
    },
    'exnf528t': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    '4oixifg6': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'mcc57soz': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    'xo58kg0t': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'spzj9ech': {
      'en': 'First Name is required',
      'af': 'Voornaam word vereis',
      'fr': 'Le prénom est requis.',
    },
    'olu1laxv': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'lehrskv5': {
      'en': 'Middle Name is required',
      'af': 'Middelnaam word vereis',
      'fr': 'Le deuxième prénom est obligatoire.',
    },
    'j4fssxht': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'y7c0r26p': {
      'en': 'Last Name is required',
      'af': 'Vannaam word vereis',
      'fr': 'Le nom de famille est obligatoire.',
    },
    '03f7mb0v': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '83omjds9': {
      'en': 'Date OF BIRTH is required',
      'af': 'GEBOORTEDATUM word vereis',
      'fr': 'La date de naissance est requise.',
    },
    'khrd5crz': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'd7zw5fkr': {
      'en': 'ID Card Number Is Required',
      'af': 'ID-kaartnommer word vereis',
      'fr': 'Le numéro de carte d\'identité est requis.',
    },
    'pmlmhqtj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'bkekunkk': {
      'en': 'ID CARD DATE OF ISSUE is required',
      'af': 'ID-KAART DATUM VAN UITREIKING word vereis',
      'fr': 'La date d\'émission de la carte d\'identité est requise.',
    },
    '3khz3708': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '1f2j3z4r': {
      'en': 'ID CARD DATE OF EXPIRATION is required',
      'af': 'ID-KAART VERVALDATUM word vereis',
      'fr': 'La date d\'expiration de la carte d\'identité est requise.',
    },
    'acfzmeuc': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'i8fqfrpu': {
      'en': 'ID CARD PLACE OF ISSUE is required',
      'af': 'ID-KAART PLEK VAN UITREIKING word vereis',
      'fr': 'La carte d\'identité et le lieu de délivrance sont requis.',
    },
    '4xwjr7gp': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'pdv02m2f': {
      'en': 'Select Gender is required',
      'af': 'Kies Geslag is verpligtend',
      'fr': 'Le choix du sexe est obligatoire.',
    },
    'jwnw4yuw': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '2y4u0jyo': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    'bkjvsqp7': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '67v6gsgj': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro de police est requis.',
    },
    'yhg2gc9w': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'icf1oku8': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif) .',
    },
    'ef4ggrh4': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'p45vbtmr': {
      'en': 'Zip Code / P.O Box is required',
      'af': 'Poskode / Posbus word vereis',
      'fr': 'Le code postal ou la boîte postale est requis.',
    },
    '92neenim': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '1tz951of': {
      'en': 'Provider Details',
      'af': 'Verskafferbesonderhede',
      'fr': 'Détails du Médecin',
    },
    'ktmb5jfj': {
      'en': 'Please provide more Details',
      'af': 'Verskaf asseblief meer besonderhede',
      'fr': 'Veuillez fournir plus de détails.',
    },
    'kv2ogzbc': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'ebh6ieqv': {
      'en': 'Insurance Provider',
      'af': 'Versekeringsverskaffer',
      'fr': 'Fournisseur d\'assurance',
    },
    'hv5l0nnp': {
      'en': 'Member ID/Policy Number',
      'af': 'Lid-ID/Polisnommer',
      'fr': 'Numéro d\'identification de membre/Numéro d\'assurance',
    },
    '0uhgw02v': {
      'en': 'Group Number (Optional)',
      'af': 'Groepnommer (Opsioneel)',
      'fr': 'Numéro de groupe (facultatif)',
    },
    'wg56shrm': {
      'en': 'Provider Biography',
      'af': 'Verskaffer Biografie',
      'fr': 'Biographie du Médecin',
    },
    '05p4v6nz': {
      'en': 'Years of Experience',
      'af': 'Jare se ondervinding',
      'fr': 'Années d\'expérience',
    },
    '4g0028n1': {
      'en': 'Years Experience ',
      'af': 'Jare ondervinding',
      'fr': 'Années d\'expérience',
    },
    'qd2psnog': {
      'en': 'Write Short Bio About Yourself',
      'af': 'Skryf \'n Kort Biografie Oor Jouself',
      'fr': 'Rédigez une courte biographie de vous-même',
    },
    'w5evjj0e': {
      'en': 'Upload Photo',
      'af': 'Laai foto op',
      'fr': 'Télécharger une photo',
    },
    'rfg6a8wx': {
      'en': 'Consultation Fee:',
      'af': 'Konsultasiefooi:',
      'fr': 'Frais de consultation :',
    },
    '9gh6907x': {
      'en': 'consultation Fee',
      'af': 'konsultasiefooi',
      'fr': 'Frais de consultation',
    },
    'vas01kzi': {
      'en': 'FCFA',
      'af': 'FCFA',
      'fr': 'FCFA',
    },
    '6hr3kzer': {
      'en': 'Provider Detail',
      'af': 'Verskafferbesonderhede',
      'fr': 'Détails du fournisseur',
    },
    'zrs0ch4w': {
      'en': 'Select Provider.....',
      'af': 'Kies Verskaffer.....',
      'fr': 'Sélectionner un fournisseur...',
    },
    'dvruj1iz': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'n93xpcl2': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'tszxrlfk': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    'vgiv09bo': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    'wczdvee8': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'q05jl3rw': {
      'en': 'Are You Specialist?',
      'af': 'Is jy \'n spesialis?',
      'fr': 'Êtes-vous spécialiste ?',
    },
    'qok6nxut': {
      'en': 'Yes',
      'af': 'Ja',
      'fr': 'Oui',
    },
    '2j0kf69s': {
      'en': 'No',
      'af': 'Nee',
      'fr': 'Non',
    },
    'sbswoibb': {
      'en': 'Select Specialty....',
      'af': 'Kies Spesialiteit....',
      'fr': 'Sélectionnez votre spécialité...',
    },
    'cq8clmve': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '1bmht0yl': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'r7shuavo': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    'fv64zjpi': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    '2q8890sx': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'bbmoehtf': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'dlorn590': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'g4sjk6k4': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    'ttjjfh6c': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'e3msf2co': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro de police est requis.',
    },
    'pgruc7go': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '438vv98o': {
      'en': 'Group Number (Optional) ',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif).',
    },
    'qou1ondm': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'fv6ogqp6': {
      'en': 'Years of Experience is required',
      'af': 'Jare se ondervinding word vereis',
      'fr': 'Plusieurs années d\'expérience sont requises.',
    },
    'fmjx0ahj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'gxzonorh': {
      'en': 'Write Short Bio About Yourself is required',
      'af': 'Skryf \'n kort biografie oor jouself is verpligtend',
      'fr': 'Rédigez une courte biographie.',
    },
    'mgbdwowe': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'uhnilj23': {
      'en': 'consultation Fee is required',
      'af': 'konsultasiefooi word vereis',
      'fr': 'Des frais de consultation sont requis.',
    },
    'jfg2jrl2': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'ufjy41as': {
      'en': 'Select Provider Type is required',
      'af': 'Kies Verskaffertipe is verpligtend',
      'fr': 'Le type de fournisseur doit être sélectionné.',
    },
    'k4vt5noa': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '5nv3to5y': {
      'en': 'Select Specialty Type is required',
      'af': 'Kies Spesialiteitstipe is vereis',
      'fr': 'La sélection du type de spécialité est obligatoire.',
    },
    'mxzs9v4j': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'njfob8pj': {
      'en': 'Field is required',
      'af': 'Veld is verpligtend',
      'fr': 'Ce champ est obligatoire.',
    },
    '5sdv7e6g': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'yn5s7n28': {
      'en': 'Provider Licence',
      'af': 'Verskafferlisensie',
      'fr': 'Licence du Médecin',
    },
    'eg1o44ta': {
      'en': 'Provider Licence',
      'af': 'Verskafferlisensie',
      'fr': 'Licence du Médecin',
    },
    'h3cm4kcr': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'zs06kovi': {
      'en': 'Licence Expiration Date',
      'af': 'Lisensie Vervaldatum',
      'fr': 'Date d\'expiration de la licence',
    },
    'ygfs8z1y': {
      'en': 'Provider Practice Address',
      'af': 'Verskafferpraktykadres',
      'fr': 'Adresse du cabinet du prestataire',
    },
    'ok8b8qf7': {
      'en': 'Select From A List Of Existing Medical Facilities',
      'af': 'Kies uit \'n lys van bestaande mediese fasiliteite',
      'fr': 'Sélectionnez un établissement médical parmi une liste existante.',
    },
    '3hlrbxax': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '77crmdm3': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'xn3zjeaa': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '6i3dunxm': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'vzyq83g8': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    'fr4mv12f': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    'duiropa3': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    '5h7hn4f8': {
      'en': 'OR Enter Your Facility Details Below',
      'af': 'OF Voer u fasiliteitsbesonderhede hieronder in',
      'fr': 'OU saisissez les détails de votre établissement ci-dessous',
    },
    '0q1a398k': {
      'en': 'Practice Name',
      'af': 'Praktyknaam',
      'fr': 'Nom du cabinet',
    },
    '3iiod15i': {
      'en': 'Select Practice Type...',
      'af': 'Kies Oefentipe...',
      'fr': 'Sélectionnez le type de pratique...',
    },
    'bdkamyay': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '9rszit73': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'up3p7g1z': {
      'en': 'Option 2',
      'af': 'Opsie 2',
      'fr': 'Option 2',
    },
    'edfg4fpa': {
      'en': 'Option 3',
      'af': 'Opsie 3',
      'fr': 'Option 3',
    },
    '0eulgldv': {
      'en': 'Practice Type',
      'af': 'Praktyktipe',
      'fr': 'Type de pratique',
    },
    'jx10is2i': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '1wqnuns7': {
      'en': 'Practice Street ',
      'af': 'Oefenstraat / Rue',
      'fr': 'Rue ',
    },
    'gp94u3tr': {
      'en': 'Practice City ',
      'af': 'Oefenstad / dorp',
      'fr': 'Ville ',
    },
    '92hbfq6o': {
      'en': 'Practice Region',
      'af': 'Praktykstreek',
      'fr': 'Région ',
    },
    'kchq0wh3': {
      'en': 'Practice Postal Code',
      'af': 'Praktyk Poskode',
      'fr': 'Code postal ',
    },
    'lty4xlyf': {
      'en': 'Enter Your Availability',
      'af': 'Voer jou beskikbaarheid in',
      'fr': 'Indiquez vos disponibilités',
    },
    'jsnwovtm': {
      'en': 'Monday',
      'af': 'Maandag',
      'fr': 'Lundi',
    },
    'ixhpwjjo': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    '9retgu1s': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'qh1eus13': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'tk5fpl7c': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    '68dmhi4s': {
      'en': 'Tuesday',
      'af': 'Dinsdag',
      'fr': 'Mardi',
    },
    'cgigdgum': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'xqliks87': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'yeg69w5v': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '4nzvh8j6': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'tp2b6u71': {
      'en': 'Wednesday',
      'af': 'Woensdag',
      'fr': 'Mercredi',
    },
    'ersqok3r': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'v2pgzhtx': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heured\'ouverture',
    },
    'pmj0eg28': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '62da1yd8': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'rzh0zqf9': {
      'en': 'Thursday',
      'af': 'Donderdag',
      'fr': 'Jeudi',
    },
    '485zuxce': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'zm277ue9': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'w3n3153r': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'rgnto9o0': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'y21iada6': {
      'en': 'Friday',
      'af': 'Vrydag',
      'fr': 'Vendredi',
    },
    'wo9n3x4s': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'rx936i8v': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'ds60htsh': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'bdwvrin0': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'j6c439vk': {
      'en': 'Saturday',
      'af': 'Saterdag',
      'fr': 'Samedi',
    },
    'urmksclo': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    '9l14bdr2': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'znu6y2jp': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '9vlbd422': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    '10mjfew5': {
      'en': 'Sunday',
      'af': 'Sondag',
      'fr': 'Dimanche',
    },
    'sctb1kza': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'y8rrdki4': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'hz649rq3': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'i7wjzawv': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'phbm29gh': {
      'en': 'Emergency Contact Information',
      'af': 'Noodkontakbesonderhede',
      'fr': 'Informations de contact en cas d\'urgence',
    },
    '54nakun6': {
      'en': 'Emergency Names',
      'af': 'Noodname',
      'fr': 'Noms du contact d\'urgence',
    },
    'wl1yxnqj': {
      'en': 'Select...',
      'af': 'Kies...',
      'fr': 'Sélectionner...',
    },
    'nd1vsxmt': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'avzigupv': {
      'en': 'Wife',
      'af': 'vrou',
      'fr': 'Épouse',
    },
    'fuy8qw35': {
      'en': 'Husband',
      'af': 'Man',
      'fr': 'Mari',
    },
    'kmfohsiv': {
      'en': 'Father',
      'af': 'Vader',
      'fr': 'Père',
    },
    'yajtoxtu': {
      'en': 'Mother',
      'af': 'Moeder',
      'fr': 'Mère',
    },
    'ceozftbc': {
      'en': 'Brother',
      'af': 'Broer',
      'fr': 'Frère',
    },
    '2zegdy61': {
      'en': 'Sister',
      'af': 'Suster',
      'fr': 'Sœur',
    },
    'sem2xt1w': {
      'en': 'Children',
      'af': 'Kinders',
      'fr': 'Enfants',
    },
    'yysiqwaq': {
      'en': 'GrandParents',
      'af': 'Grootouers',
      'fr': 'Grands-parents',
    },
    'cj9d0tf9': {
      'en': 'Friend',
      'af': 'Vriend',
      'fr': 'Ami',
    },
    'moj8xp29': {
      'en': 'Relationship',
      'af': 'Verhouding',
      'fr': 'Relation',
    },
    '157pz5a0': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    '48fgdnqi': {
      'en': 'Continue',
      'af': 'Gaan voort',
      'fr': 'Continuer',
    },
    'icf67usc': {
      'en': 'Insurance Provider is required',
      'af': 'Versekeringsverskaffer word vereis',
      'fr': 'Un fournisseur d\'assurance est requis.',
    },
    '6mqus47h': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'h9dw87f8': {
      'en': 'Member ID/Policy Number is required',
      'af': 'Lid-ID/Polisnommer word vereis',
      'fr':
          'Un numéro d\'identification de membre ou un numéro d\'assurance est requis.',
    },
    '90f1fx9p': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'u6g5ilxc': {
      'en': 'Group Number (Optional) ',
      'af': 'Groepnommer (Opsioneel) word vereis',
      'fr': 'Le numéro de groupe (facultatif) .',
    },
    'pixtidxj': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'kte1hu2c': {
      'en': 'Existing Medical Conditions is required',
      'af': 'Bestaande mediese toestande word vereis',
      'fr': 'Les conditions médicales existantes sont requises',
    },
    'tdnfyxxl': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'udb2ej1i': {
      'en': 'Current Medications is required',
      'af': 'Huidige medikasie word benodig',
      'fr': 'Les médicaments en cours sont requis',
    },
    'c968i9yu': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'd0cnq5mf': {
      'en': 'Allergies is required',
      'af': 'Allergieë is nodig',
      'fr': 'Les allergies sont requises',
    },
    '8hkl82at': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    '1kgcopi0': {
      'en': 'Emergency Names is required',
      'af': 'Noodname word vereis',
      'fr': 'Les noms du contact d\'urgence sont requis',
    },
    't4km6y17': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'hpo0j007': {
      'en': 'Relationship is required',
      'af': 'Verhouding word vereis',
      'fr': 'La nature du contact est nécessaire',
    },
    'jolpqp80': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'myy7u914': {
      'en': 'Provider Account Verification',
      'af': 'Verskafferrekeningverifikasie',
      'fr': 'Vérification du compte fournisseur',
    },
    '5eftqpep': {
      'en':
          'Please review your information below to ensure everything is correct before creating your account.',
      'af':
          'Gaan asseblief u inligting hieronder na om te verseker dat alles korrek is voordat u u rekening skep.',
      'fr':
          'Veuillez vérifier vos informations ci-dessous pour vous assurer qu\'elles sont correctes avant de créer votre compte.',
    },
    'kxhmz15w': {
      'en': 'Personal Information',
      'af': 'Persoonlike Inligting',
      'fr': 'Informations personnelles',
    },
    'g7m3aky2': {
      'en': 'UserRole:',
      'af': 'Gebruikersrol:',
      'fr': 'Rôle de l\'utilisateur :',
    },
    '1xpsaiur': {
      'en': 'medical_provider',
      'af': 'mediese_verskaffer',
      'fr': 'fournisseur de soins médicaux',
    },
    'ihu6653v': {
      'en': 'Prefrerred Language:',
      'af': 'Voorkeurtaal:',
      'fr': 'Langue préférée :',
    },
    'jcrhen3m': {
      'en': 'First Name:',
      'af': 'Voornaam:',
      'fr': 'Prénom:',
    },
    'xmpbe55e': {
      'en': 'Middle Name:',
      'af': 'Middelnaam:',
      'fr': 'Deuxième prénom:',
    },
    '53ebka3m': {
      'en': 'Last Name:',
      'af': 'Van:',
      'fr': 'Nom de famille:',
    },
    'rdxd6diy': {
      'en': 'Date Of Birth:',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance:',
    },
    'j4dtyj8w': {
      'en': 'Gender:',
      'af': 'Geslag:',
      'fr': 'Genre:',
    },
    'ozp20509': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    '3gyq4nhr': {
      'en': 'Street :',
      'af': 'Straat / Rue:',
      'fr': 'Rue :',
    },
    'ilfykp7d': {
      'en': 'City :',
      'af': 'Stad / Dorp:',
      'fr': 'Ville :',
    },
    'go1cck18': {
      'en': 'Region:',
      'af': 'Streek:',
      'fr': 'Région:',
    },
    'at0bfuw4': {
      'en': 'Zip Code / P.O Box:',
      'af': 'Poskode / Posbus:',
      'fr': 'Code postal / Boîte postale :',
    },
    'ugsdceh8': {
      'en': 'Insurance Information',
      'af': 'Versekeringsinligting',
      'fr': 'Informations sur l\'assurance',
    },
    'k0scqx76': {
      'en': 'Insurance Provider:',
      'af': 'Versekeringsverskaffer:',
      'fr': 'Fournisseur d\'assurance :',
    },
    'ik6em3s4': {
      'en': 'PolicyNumber:',
      'af': 'Polisnommer:',
      'fr': 'Numéro d\'assurance :',
    },
    '072w2fxn': {
      'en': 'Group Number:',
      'af': 'Groepnommer:',
      'fr': 'Numéro de groupe :',
    },
    'hdskpx47': {
      'en': 'Provider Licence Detail',
      'af': 'Verskafferlisensiebesonderhede',
      'fr': 'Détails de la licence du fournisseur',
    },
    'jj93q91m': {
      'en': 'ProviderType:',
      'af': 'Verskaffertipe:',
      'fr': 'Type de fournisseur de santé:',
    },
    'u1u8950i': {
      'en': 'Consultation Fee:',
      'af': 'Konsultasiefooi:',
      'fr': 'Honoraires de consultation :',
    },
    'cw6gv8zy': {
      'en': 'Specialist:',
      'af': 'Spesialis:',
      'fr': 'Spécialiste:',
    },
    'qwfsgno7': {
      'en': 'SpecialistType:',
      'af': 'Spesialistipe:',
      'fr': 'Type de spécialiste :',
    },
    'rhsg063b': {
      'en': 'Licence:',
      'af': 'Lisensie:',
      'fr': 'Licence:',
    },
    '4jc7ko5x': {
      'en': 'Licence Exp Date:',
      'af': 'Lisensie Vervaldatum:',
      'fr': 'Date d\'expiration de la licence :',
    },
    '5yyx85hm': {
      'en': 'Emergency Contact Information:',
      'af': 'Noodkontakbesonderhede:',
      'fr': 'Informations de contact en cas d\'urgence :',
    },
    'hvd20cp5': {
      'en': 'Provider Availability',
      'af': 'Verskafferbeskikbaarheid',
      'fr': 'Disponibilité duMedecin',
    },
    's0qcje1c': {
      'en': 'Practice Name:',
      'af': 'Praktyknaam:',
      'fr': 'Nom du cabinet :',
    },
    '6woxvqr1': {
      'en': 'Monday',
      'af': 'Maandag',
      'fr': 'Lundi',
    },
    '76b9ec8t': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    '61nop2dz': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'qby68e0r': {
      'en': 'Tuesday',
      'af': 'Dinsdag',
      'fr': 'Mardi',
    },
    'vybw9mrh': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'zvxs3uxq': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'r34p0t6z': {
      'en': 'Wednesday',
      'af': 'Woensdag',
      'fr': 'Mercredi',
    },
    's7evcy5j': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'kpx3hl61': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'ljl4r27n': {
      'en': 'Thursday',
      'af': 'Donderdag',
      'fr': 'Jeudi',
    },
    '6o0k00v0': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'an67f035': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    '9q5ubssh': {
      'en': 'Friday',
      'af': 'Vrydag',
      'fr': 'Vendredi',
    },
    'wg5yslov': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    '0gi8plnq': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'lusmql1q': {
      'en': 'Saturday',
      'af': 'Saterdag',
      'fr': 'Samedi',
    },
    '8ts5g8gw': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'p88kprwh': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'joncb6ho': {
      'en': 'Sunday',
      'af': 'Sondag',
      'fr': 'Dimanche',
    },
    '9aeupptj': {
      'en': 'Start Time: ',
      'af': 'Begintyd:',
      'fr': 'Heure d\'ouverture :',
    },
    'ol5smb1i': {
      'en': 'End Time:',
      'af': 'Eindtyd:',
      'fr': 'Heure de fermeture :',
    },
    'dg6ws9b3': {
      'en': 'Back',
      'af': 'Terug',
      'fr': 'Retour',
    },
    'vsi9xyzn': {
      'en': 'Submit For Verification',
      'af': 'Dien in vir verifikasie',
      'fr': 'Soumettre pour vérification',
    },
    'vihmujxt': {
      'en': 'Email is required',
      'af': 'E-posadres is vereis',
      'fr': 'L\'adresse électronique est requise.',
    },
    'a7nah4gy': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'qrtq5c6p': {
      'en': 'Password is required',
      'af': 'Wagwoord word vereis',
      'fr': 'Un mot de passe est requis.',
    },
    'h8o8rlrq': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'jn5e744s': {
      'en': 'Confirm Password is required',
      'af': 'Bevestig wagwoord word vereis',
      'fr': 'Confirmer le mot de passe est requis',
    },
    'yz6l509z': {
      'en': 'Please choose an option from the dropdown',
      'af': 'Kies asseblief \'n opsie uit die aftreklys',
      'fr': 'Veuillez choisir une option dans le menu déroulant.',
    },
    'kq4qcu1o': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // FacilityAdminDocumentPage
  {
    'jm8mxn1e': {
      'en': 'My Documents',
      'af': 'My Dokumente',
      'fr': 'Mes documents',
    },
    'eezbhcur': {
      'en': 'Search documents...',
      'af': 'Soek dokumente...',
      'fr': 'Rechercher des documents...',
    },
    'otkaejsj': {
      'en': 'Upload New Document',
      'af': 'Laai Nuwe Dokument Op',
      'fr': 'Ajoutez un nouveau document',
    },
    '5o0rimph': {
      'en': 'Document Title',
      'af': 'Dokumenttitel',
      'fr': 'Titre du document',
    },
    '6ku3fuvm': {
      'en': '  Enter document title',
      'af': 'Voer dokumenttitel in',
      'fr': 'Saisissez le titre du document',
    },
    'gdddq0t6': {
      'en': '     Select Document Type',
      'af': 'Kies Dokumenttipe',
      'fr': 'Sélectionnez le type de document',
    },
    'camg3u5x': {
      'en': '  Lab Result',
      'af': 'Laboratoriumresultaat',
      'fr': 'Résultats de laboratoire',
    },
    'gx9j88b9': {
      'en': '  Prescription',
      'af': 'Voorskrif',
      'fr': 'Ordonnance',
    },
    'wpyngtpm': {
      'en': '  Imaging',
      'af': 'Beeldvorming',
      'fr': 'Imagerie',
    },
    'tgqxxz13': {
      'en': '  Other',
      'af': 'Ander',
      'fr': 'Autre',
    },
    '3y6rvtjk': {
      'en': '      Share with...',
      'af': 'Deel met...',
      'fr': 'Partager avec...',
    },
    'bhkcf6kv': {
      'en': '   medical provider',
      'af': 'mediese verskaffer',
      'fr': 'prestataire de soins médicaux',
    },
    'fl8q0363': {
      'en': '   Admin',
      'af': 'Admin',
      'fr': 'Administrateur',
    },
    'bh3dnfmz': {
      'en': '   Facility',
      'af': 'Fasiliteit',
      'fr': 'Etablissement de santé',
    },
    'u36u1km0': {
      'en': '   Patient',
      'af': 'Pasiënt',
      'fr': 'Patient',
    },
    'xbk6cxoi': {
      'en': 'Click to upload files or drag and drop',
      'af': 'Klik om lêers op te laai of sleep en los',
      'fr': 'Cliquez pour ajouter des fichiers ',
    },
    'mrzzvn5u': {
      'en': 'PDF, DOC, DOCX up to 10MB',
      'af': 'PDF, DOC, DOCX tot 10 MB',
      'fr': 'PDF, DOC, DOCX jusqu\'à 10 MB',
    },
    '8apoqyy7': {
      'en': 'Upload Document',
      'af': 'Laai dokument op',
      'fr': 'Ajouter un document',
    },
    'qw553bwj': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // CareCentersTypes
  {
    'szhbwdne': {
      'en': 'Our Medical Facilities Network',
      'af': 'Ons Mediese Fasiliteitsnetwerk',
      'fr': 'Nos établissements médicaux',
    },
    '9ghbb9hu': {
      'en': 'Hospitals',
      'af': 'Hospitale',
      'fr': 'Hôpitaux',
    },
    'cjucd9bm': {
      'en': 'Pharmacies',
      'af': 'Apteke',
      'fr': 'Pharmacies',
    },
    'b0vqeb02': {
      'en': 'Laboratories',
      'af': 'Laboratoriums',
      'fr': 'Laboratoires',
    },
    '9tdu8qqf': {
      'en': 'Diabetic ',
      'af': 'Diabeet',
      'fr': 'Diabétique',
    },
    'd8hnx5ff': {
      'en': 'Oncology ',
      'af': 'Onkologie',
      'fr': 'Oncologie',
    },
    'bvwfacku': {
      'en': 'Blood Banks',
      'af': 'Bloedbanke',
      'fr': 'Banques de sang',
    },
    'bxyrbqft': {
      'en': 'Clinics',
      'af': 'Klinieke',
      'fr': 'Cliniques',
    },
    '82z0ik8j': {
      'en': 'Rematology',
      'af': 'Rematologie',
      'fr': 'Rématologie',
    },
    '86cbpduc': {
      'en': 'Pediatric',
      'af': 'Pediatriese',
      'fr': 'Pédiatrique',
    },
    '07juttyp': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // CareCenters
  {
    '1j34tagc': {
      'en': 'Search carecenters...',
      'af': 'Soekfasiliteit...',
      'fr': 'Recherche un Etablissement...',
    },
    'q82jdeuz': {
      'en': 'Your health is safe with us',
      'af': 'Jou gesondheid is veilig by ons',
      'fr': 'Votre santé est en sécurité chez nous',
    },
    'c6y7n3do': {
      'en': 'View',
      'af': 'Bekyk',
      'fr': 'Détails',
    },
    'tt2jdzz7': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // CareCenterDetails
  {
    'iihz9yd5': {
      'en': 'Schedule ',
      'af': 'Skedule',
      'fr': 'Calendrier',
    },
    'jshy40sd': {
      'en': 'About',
      'af': 'Oor',
      'fr': 'À propos',
    },
    'wa6hhxq2': {
      'en': 'Short Bio',
      'af': 'Kort Biografie',
      'fr': 'Courte biographie',
    },
    'psstsuym': {
      'en': 'Working Hours',
      'af': 'Werksure',
      'fr': 'Heures de travail',
    },
    't2mm4utw': {
      'en': 'Monday - Friday, 08.00 AM - 20.00 PM',
      'af': 'Maandag - Vrydag, 08:00 - 20:00',
      'fr': 'Du lundi au vendredi, de 8h00 à 20h00',
    },
    '5pmtmaul': {
      'en': 'Departments',
      'af': 'Dienste',
      'fr': 'Services',
    },
    'uijn2jbo': {
      'en': 'Contact',
      'af': 'Kontak',
      'fr': 'Contact',
    },
    'r427hkdz': {
      'en': 'Contact Information',
      'af': 'Kontakbesonderhede',
      'fr': 'Information du point de contact',
    },
    'h7ljnuib': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    '1ed1q3dt': {
      'en': 'Phone',
      'af': 'Foon',
      'fr': 'Téléphone',
    },
    'silzj5a4': {
      'en': 'Hours',
      'af': 'Ure',
      'fr': 'Heures',
    },
    'n68nefx7': {
      'en':
          '24/7 Emergency Services\nOutpatient: Mon-Fri 8AM-6PM\nSaturday: 9AM-4PM',
      'af':
          '24/7 Nooddienste\nBuitepasiënt: Ma-Vr 8:00-18:00\nSaterdag: 9:00-16:00',
      'fr':
          'Urgences 24h/24 et 7j/7\n\nConsultations externes : du lundi au vendredi de 8h à 18h\nSamedi : de 9h à 16h',
    },
    'r3lyv8if': {
      'en': 'Email',
      'af': 'E-pos',
      'fr': 'E-mail',
    },
    '7pwokisf': {
      'en': 'Website',
      'af': 'Webwerf',
      'fr': 'Site web',
    },
    'pxkla5f0': {
      'en': 'Reviews',
      'af': 'Resensies',
      'fr': 'Avis',
    },
    '4b3s61yc': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // chat
  {
    'rou82ufe': {
      'en': 'MedX AI',
      'af': 'MedX KI',
      'fr': 'MedX IA',
    },
    '0x65r5f6': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'n7ocdz6s': {
      'en': 'Type something ...',
      'af': 'Tik iets...',
      'fr': 'Saisissez quelque chose...',
    },
    '8gfwcm6l': {
      'en': '',
      'af': '',
      'fr': '',
    },
    's4ja1fmm': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // AIChatHistoryPage
  {
    'kkxslz4q': {
      'en': 'Previous  AI Conversations',
      'af': 'Vorige Gesprekke',
      'fr': 'Conversations précédentes',
    },
    'wbj8fnc8': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // admin_patientsPage
  {
    'ukjx34q9': {
      'en': 'Patients',
      'af': 'Pasiënte',
      'fr': 'Les patients',
    },
    '6v3dtrbu': {
      'en': 'Search patients...',
      'af': 'Soek pasiënte...',
      'fr': 'Rechercher des patients...',
    },
    's8xuqnys': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'q5haoqtm': {
      'en': 'patient name',
      'af': 'pasiëntnaam',
      'fr': 'nom du patient',
    },
    'jzis4en5': {
      'en': 'DOB: ',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance :',
    },
    'gy9es9s2': {
      'en': 'Status',
      'af': 'Status',
      'fr': 'Statut',
    },
    'lsayler6': {
      'en': 'ID: ',
      'af': 'ID:',
      'fr': 'IDENTIFIANT:',
    },
    '4kxsil5y': {
      'en': 'ID',
      'af': 'ID',
      'fr': 'IDENTIFIANT',
    },
    'sptoz90n': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // provider_landing_page
  {
    '9garqwr8': {
      'en': 'Upcoming Appointment',
      'af': 'Aanstaande afspraak',
      'fr': 'Prochain rendez-vous',
    },
    '3siqexfz': {
      'en': 'View',
      'af': 'Bekyk',
      'fr': 'Détails',
    },
    'erk4pa9e': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    '4rz5lvao': {
      'en': 'Type:',
      'af': 'Tipe:',
      'fr': 'Mode:',
    },
    '0gdht9hs': {
      'en': 'Specialty:',
      'af': 'Spesialiteit:',
      'fr': 'Spécialité:',
    },
    'tz6pjga3': {
      'en': 'Career:',
      'af': 'Loopbaan:',
      'fr': 'Carrière:',
    },
    'rkfuq6u2': {
      'en': 'Years Experience',
      'af': 'Jare ondervinding',
      'fr': 'Années d\'expérience',
    },
    'gyr23soz': {
      'en': 'About',
      'af': 'Oor',
      'fr': 'À propos',
    },
    'c8ofxpe3': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'erpolmrt': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    '7sehfwkv': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'tldq37wi': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'p6551oyd': {
      'en': 'Licence Details',
      'af': 'Lisensiebesonderhede',
      'fr': 'Détails de la licence',
    },
    '4uasjuxz': {
      'en': 'Number:',
      'af': 'Nommer:',
      'fr': 'Nombre:',
    },
    'v8zw41kj': {
      'en': 'Exp Date:',
      'af': 'Vervaldatum:',
      'fr': 'Date d\'expiration :',
    },
    'pdhnlzad': {
      'en': 'Quick Links',
      'af': 'Vinnige skakels',
      'fr': 'Liens rapides',
    },
    '4ta28937': {
      'en': 'Video Call',
      'af': 'Video-oproep',
      'fr': 'appel vidéo',
    },
    '9pq4lrd5': {
      'en': 'Call Support',
      'af': 'Bel Ondersteuning',
      'fr': 'Assistance ',
    },
    'bwtf155t': {
      'en': 'Query',
      'af': 'Navraag',
      'fr': 'Requête',
    },
    'o4hmv5ii': {
      'en': 'Message',
      'af': 'Boodskap',
      'fr': 'Message',
    },
    'q8h0d149': {
      'en': 'Carecenter',
      'af': 'Sorgsentrum',
      'fr': 'centre de soins',
    },
    '03c95rhj': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    '9b5w8359': {
      'en': 'Facility Name',
      'af': 'Fasiliteitsnaam',
      'fr': 'Nom de l\'établissement',
    },
    'i0ypq3el': {
      'en': 'Address: ',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    'i99wqulr': {
      'en': 'address',
      'af': 'adres',
      'fr': 'adresse',
    },
    'gxdk1wry': {
      'en': 'Phone: ',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'ta9qzabx': {
      'en': 'Phone',
      'af': 'Foon',
      'fr': 'Téléphone',
    },
    'r20h57th': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // CareCenterStatusPage
  {
    'ur7toktx': {
      'en': 'Carecenter  Status',
      'af': 'Sorgsentrumstatus',
      'fr': 'Statut du centre de soins',
    },
    'xbrdwyih': {
      'en': 'Search Carecenter.....',
      'af': 'Soekverskaffers...',
      'fr': 'Recherchez un centre de soins...',
    },
    '3y0bjlzh': {
      'en': 'All',
      'af': 'Alles',
      'fr': 'Tout',
    },
    'j2qejnut': {
      'en': 'Approved',
      'af': 'Goedgekeur',
      'fr': 'Approuvé',
    },
    '5fur1s3b': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    'mnueiuun': {
      'en': 'Rejected',
      'af': 'Verwerp',
      'fr': 'Rejeté',
    },
    '6ad8szmc': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'uptonw00': {
      'en': 'Address: ',
      'af': 'Adres:',
      'fr': 'Adresse:',
    },
    '97h9ndna': {
      'en': 'Type',
      'af': 'Tipe',
      'fr': 'Mode',
    },
    'aa4o6iyk': {
      'en': 'Tel: ',
      'af': 'Tel:',
      'fr': 'Tél. :',
    },
    'nwpqbd15': {
      'en': 'Phone',
      'af': 'Foon',
      'fr': 'Téléphone',
    },
    'tmbl96dk': {
      'en': ' Approve',
      'af': 'Goedkeur',
      'fr': 'Approuvé',
    },
    'hb27xqih': {
      'en': 'Reject ',
      'af': 'Verwerp',
      'fr': 'Rejeter',
    },
    '20wybix0': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Admin_providerStatusPage
  {
    'hsz0qm55': {
      'en': 'Provider Status',
      'af': 'Verskafferstatus',
      'fr': 'Statut de l administrateur',
    },
    'mk88gc89': {
      'en': 'Search provider.....',
      'af': 'Soekverskaffers...',
      'fr': 'Fournisseurs de recherche...',
    },
    '59n3fovl': {
      'en': 'Option 1',
      'af': 'Opsie 1',
      'fr': 'Option 1',
    },
    'mxqyj21g': {
      'en': 'All',
      'af': 'Alles',
      'fr': 'Tous',
    },
    'co1d0z18': {
      'en': 'Approved',
      'af': 'Goedgekeur',
      'fr': 'Approuvé',
    },
    '5fdb0i9q': {
      'en': 'Pending',
      'af': 'Hangende',
      'fr': 'En attente',
    },
    'd31ozuwn': {
      'en': 'Rejected',
      'af': 'Verwerp',
      'fr': 'Rejeté',
    },
    '8l29jhqf': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'uqxjf8ro': {
      'en': 'name',
      'af': 'naam',
      'fr': 'nom',
    },
    'ndad0678': {
      'en': 'LN: ',
      'af': 'LN:',
      'fr': 'LN :',
    },
    'p6orujkd': {
      'en': 'LN',
      'af': 'LN',
      'fr': 'LN',
    },
    'wf5f8yud': {
      'en': 'Tel: ',
      'af': 'Tel:',
      'fr': 'Tél. :',
    },
    'wzpjbmhv': {
      'en': 'phone',
      'af': 'foon',
      'fr': 'téléphone',
    },
    'hv7v6pe4': {
      'en': ' Approve',
      'af': 'Goedkeur',
      'fr': 'Approuver',
    },
    'yjbxxxz8': {
      'en': 'Reject ',
      'af': 'Verwerp',
      'fr': 'Rejeter',
    },
    '1awq6b5u': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // ResetPasswordFromLink
  {
    'el6djrvr': {
      'en': 'Change Password',
      'af': 'Verander wagwoord',
      'fr': 'Changer le mot de passe',
    },
    'nt9lsh3c': {
      'en': 'Reset your password to keep your account secure',
      'af': 'Stel jou wagwoord terug om jou rekening veilig te hou',
      'fr': 'Réinitialisez votre mot de passe pour sécuriser votre compte.',
    },
    'yr6quw2m': {
      'en': 'New Password',
      'af': 'Nuwe Wagwoord',
      'fr': 'Nouveau mot de passe',
    },
    '82kfyfmv': {
      'en': 'Minimum 8 characters',
      'af': 'Minimum 8 karakters',
      'fr': 'Minimum 8 caractères',
    },
    '43xdci38': {
      'en':
          'Must contain at least 8 characters, 1 uppercase letter, and 1 number',
      'af': 'Moet ten minste 8 karakters, 1 hoofletter en 1 syfer bevat',
      'fr':
          'Doit contenir au moins 8 caractères, 1 lettre majuscule et 1 chiffre.',
    },
    'xr79jnph': {
      'en': 'Confirm New Password',
      'af': 'Bevestig Nuwe Wagwoord',
      'fr': 'Confirmer le nouveau mot de passe',
    },
    '6escovlb': {
      'en': 'Re-enter new password',
      'af': 'Voer nuwe wagwoord weer in',
      'fr': 'Saisissez à nouveau le nouveau mot de passe',
    },
    'zw6o4ffm': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'fwr0b58q': {
      'en': 'Save Password',
      'af': 'Stoor Wagwoord',
      'fr': 'Enregistrer le mot de passe',
    },
    '95wxa4pp': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Finance
  {
    'q7ih5l6h': {
      'en': 'Sales & Revenue',
      'af': 'Verkope en Inkomste',
      'fr': 'Ventes et revenus',
    },
    '31babho3': {
      'en': 'Total Sales',
      'af': 'Totale Verkope',
      'fr': 'Ventes totales',
    },
    '040k1wn4': {
      'en': 'Service fee',
      'af': 'Diensfooi',
      'fr': 'Frais de service',
    },
    'lmwkjdbt': {
      'en': 'Taxes',
      'af': 'Belasting',
      'fr': 'Impôts',
    },
    'ah1vj1ca': {
      'en': 'payment gateway',
      'af': 'betaalpoort',
      'fr': 'passerelle de paiement',
    },
    'lrpvdf0u': {
      'en': ' Transactions',
      'af': 'Transaksies',
      'fr': 'Transactions',
    },
    'eply2ctp': {
      'en': 'Earnings',
      'af': 'Verdienste',
      'fr': 'Gains',
    },
    '05rg52tp': {
      'en': 'Details',
      'af': 'Besonderhede',
      'fr': 'Détails',
    },
    'ax7lhfkn': {
      'en': 'Withdrawals',
      'af': 'Onttrekkings',
      'fr': 'Retraits',
    },
    'aumwy1w8': {
      'en': 'Details',
      'af': 'Besonderhede',
      'fr': 'Détails',
    },
    '3586jf32': {
      'en': 'Request',
      'af': 'Versoek',
      'fr': 'Demande',
    },
    '6zs4aymn': {
      'en': 'Reject',
      'af': 'Verwerp',
      'fr': 'Rejeter',
    },
    'v5y06fx3': {
      'en': 'mark as paid',
      'af': 'merk as betaal',
      'fr': 'marquer comme payé',
    },
    'o9ku6iby': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Notifications
  {
    'arhqyrik': {
      'en': 'Notifications',
      'af': 'Kennisgewings',
      'fr': 'Notifications',
    },
    '0xyupdfq': {
      'en': 'Stay updated with your reminders',
      'af': 'Bly op hoogte met jou herinneringe',
      'fr': 'Restez informé grâce à vos rappels',
    },
    '8kl2prbu': {
      'en': 'No notification',
      'af': 'Geen kennisgewing nie',
      'fr': 'Aucune notification',
    },
    '6qzvy0i4': {
      'en': 'null',
      'af': 'nul',
      'fr': 'nul',
    },
    'crke4m71': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // ProviderSummary_Page
  {
    'uf674ytm': {
      'en': 'Profile Information',
      'af': 'Profielinligting',
      'fr': 'Informations de profil',
    },
    '6lewflqy': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'knp2lekh': {
      'en': 'Dr Ketum',
      'af': 'Dr. Ketum',
      'fr': 'Dr Ketum',
    },
    '06j3uasd': {
      'en': 'Specialty: ',
      'af': 'Spesialiteit:',
      'fr': 'Spécialité:',
    },
    'zoo64mhj': {
      'en': 'Specialty',
      'af': 'Spesialiteit',
      'fr': 'Spécialité',
    },
    '69hk11jy': {
      'en': 'License #: ',
      'af': 'Lisensienommer:',
      'fr': 'Numéro de licence :',
    },
    'a12tppl2': {
      'en': 'License Number',
      'af': 'Lisensienommer',
      'fr': 'Numéro de licence',
    },
    '7p1huget': {
      'en': 'License Exp: ',
      'af': 'Lisensienommer:',
      'fr': 'Numéro de licence :',
    },
    '46g4ihne': {
      'en': 'License Number',
      'af': 'Lisensienommer',
      'fr': 'Numéro de licence',
    },
    'pyv3ti41': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'f9mvpqcr': {
      'en': 'Emergency Contact',
      'af': 'Noodkontak',
      'fr': 'Contact d\'urgence',
    },
    'v4hyaez1': {
      'en': 'Name:',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'pzwh1w2v': {
      'en': 'Relationship:',
      'af': 'Verhouding:',
      'fr': 'Relation:',
    },
    'nmx14cu4': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'zxjckcnp': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '3n3r80ff': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    'ok7nojg3': {
      'en': 'Phone:',
      'af': 'Foon:',
      'fr': 'Téléphone:',
    },
    'q1z4u2gq': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'jks8ivk6': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'n3cuzxyf': {
      'en': 'TextField',
      'af': 'Teksveld',
      'fr': 'Champ de texte',
    },
    '8da66513': {
      'en': 'Preferences',
      'af': 'Voorkeure',
      'fr': 'Préférences',
    },
    '8k1ueu0b': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    '469njmlj': {
      'en': 'View profile details',
      'af': 'Bekyk profielbesonderhede',
      'fr': 'Voir les détails du profil',
    },
    'qn0uk7s0': {
      'en': 'Dark Mode',
      'af': 'Donkermodus',
      'fr': 'Mode sombre',
    },
    'vun99tdl': {
      'en': 'Switch to dark theme',
      'af': 'Skakel oor na donker tema',
      'fr': 'Passer en mode sombre',
    },
    '7twwltke': {
      'en': 'Notification Sounds',
      'af': 'Kennisgewingklanke',
      'fr': 'Sons de notification',
    },
    'pfd5vgu4': {
      'en': 'Enable audio alerts',
      'af': 'Aktiveer oudio-waarskuwings',
      'fr': 'Activer les alertes audio',
    },
    'bj11pwgd': {
      'en': 'Auto-Refresh',
      'af': 'Outomatiese herlaai',
      'fr': 'Actualisation automatique',
    },
    'orayk4yx': {
      'en': 'Automatically update data',
      'af': 'Dateer data outomaties op',
      'fr': 'Mise à jour automatique des données',
    },
    'iqt1y3c5': {
      'en': 'Appointment Alerts',
      'af': 'Afspraakwaarskuwings',
      'fr': 'Alertes de rendez-vous',
    },
    'lk1e8fcp': {
      'en': 'Get notified about appointments',
      'af': 'Kry kennisgewings oor afsprake',
      'fr': 'Recevez des notifications concernant vos rendez-vous',
    },
    'hkdmawbm': {
      'en': 'Language',
      'af': 'Taal',
      'fr': 'Langue',
    },
    'gtgzll68': {
      'en': 'Choose your language',
      'af': 'Kies jou taal',
      'fr': 'Choisissez votre langue',
    },
    '8y6t4c58': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // chatHistoryPage
  {
    'd6yifo1m': {
      'en': 'Previous Conversations',
      'af': 'Vorige Gesprekke',
      'fr': 'Conversations précédentes',
    },
    '7bicx1hh': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // ChatHistoryDetail
  {
    'k21cr8pp': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // TermsAndConditions
  {
    'l9w3zpj4': {
      'en': 'MedZen Health ',
      'af': 'MedZen Gesondheidskenmerke',
      'fr': 'Fonctionnalités santé de MedZen',
    },
    '1fqvji5w': {
      'en': 'Terms & Conditions of Use',
      'af':
          'Omvattende telehealth-oplossings vir moderne gesondheidsorgbehoeftes',
      'fr':
          'Solutions de télésanté complètes pour les besoins de santé modernes',
    },
    '1z2gacv3': {
      'en': 'Platform: ',
      'af': 'Platform:',
      'fr': 'Plate-forme:',
    },
    'wo9bhlbe': {
      'en': 'MedZen Health (“MedZen”, “the App”, “the Platform”)',
      'af': 'MedZen Health (“MedZen”, “die App”, “die Platform”)',
      'fr': 'MedZen Santé (« MedZen », « l’Application », « la Plateforme »)',
    },
    'hgl76bwl': {
      'en': 'Company: ',
      'af': 'Platform:',
      'fr': 'Plate-forme:',
    },
    'h5p1tb6u': {
      'en': 'MylesTech Solutions LLC (“MylesTech”, “we”, “our”, “us”)',
      'af': 'MedZen Health (“MedZen”, “die App”, “die Platform”)',
      'fr': 'MedZen Santé (« MedZen », « l’Application », « la Plateforme »)',
    },
    '5dkgc1gw': {
      'en': '1. Acceptance of Terms',
      'af': '1. Aanvaarding van Voorwaardes',
      'fr': '1. Acceptation des conditions',
    },
    '2nwxrvit': {
      'en':
          'By downloading, accessing, or using the MedZen Health mobile or web application, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree, you may not use the platform.',
      'af':
          'Deur die MedZen Health mobiele of webtoepassing af te laai, toegang daartoe te verkry of te gebruik, stem u in om gebonde te wees aan hierdie Bepalings en Voorwaardes en ons Privaatheidsbeleid. Indien u nie saamstem nie, mag u nie die platform gebruik nie.',
      'fr':
          'En téléchargeant, en accédant  ou en utilisant l\'application mobile ou web MedZen Health, vous acceptez d\'être lié par les présentes Conditions générales et notre Politique de confidentialité. Si vous n\'acceptez pas ces conditions, vous ne pouvez pas utiliser la plateforme.',
    },
    '9oomi3he': {
      'en': '2. About MedZen',
      'af': '2. Oor MedZen',
      'fr': '2. À propos de MedZen',
    },
    'yrkju5cy': {
      'en':
          'MedZen is a digital health and telemedicine platform developed by MylesTech Solutions LLC to make healthcare more accessible and affordable across Africa. The App enables users to:\nConnect with licensed healthcare professionals via video, voice, or chat.\n - Access electronic health records and      prescriptions.\n- Use AI-powered health tools for symptom   checking and triage.\n- Receive educational health content and connect with community health services.\nMedZen is not a hospital or emergency service and does not replace in-person medical care when required.',
      'af':
          'MedZen is \'n digitale gesondheids- en telemedisyne-platform wat deur MylesTech Solutions LLC ontwikkel is om gesondheidsorg meer toeganklik en bekostigbaar regoor Afrika te maak. Die toepassing stel gebruikers in staat om:\n\nMet gelisensieerde gesondheidsorgpersoneel te skakel via video, stem of klets.\n\n- Toegang tot elektroniese gesondheidsrekords en voorskrifte te kry.\n- KI-aangedrewe gesondheidsinstrumente te gebruik vir simptoomkontrole en triage.\n- Opvoedkundige gesondheidsinhoud te ontvang en met gemeenskapsgesondheidsdienste te skakel.\n\nMedZen is nie \'n hospitaal of nooddiens nie en vervang nie persoonlike mediese sorg wanneer nodig nie.',
      'fr':
          'MedZen est une plateforme de santé numérique et de télémédecine développée par MylesTech Solutions LLC afin de rendre les soins de santé plus accessibles et abordables en Afrique. L\'application permet aux utilisateurs de :\n\n- Communiquer avec des professionnels de santé agréés par vidéo, audio ou messagerie instantanée.\n\n- Accéder à leurs dossiers médicaux et ordonnances électroniques.\n\n- Utiliser des outils de santé basés sur l\'IA pour le dépistage des symptômes et le triage.\n\n- Recevoir du contenu éducatif sur la santé et se connecter aux services de santé communautaires.\n\nMedZen n\'est ni un hôpital ni un service d\'urgence et ne remplace pas les soins médicaux en présentiel lorsque cela est nécessaire.',
    },
    '7c0wnpja': {
      'en': '3.  Eligibility',
      'af': '3. Geskiktheid',
      'fr': '3. Admissibilité',
    },
    '9o7kmwg6': {
      'en': 'You must: ',
      'af': 'Jy moet:',
      'fr': 'Vous devez :',
    },
    'm7e4z4e1': {
      'en':
          'Be at least 18 years old or have parental consent if under 18.\nProvide accurate, current, and complete information during registration.\nAgree to use MedZen only for lawful, personal, and non-commercial purposes.\nHealthcare providers must be licensed and verified before offering consultations on the platform.',
      'af':
          'Wees ten minste 18 jaar oud of hê ouerlike toestemming indien jonger as 18.\nVerskaf akkurate, huidige en volledige inligting tydens registrasie.\nStem in om MedZen slegs vir wettige, persoonlike en nie-kommersiële doeleindes te gebruik.\nGesondheidsorgverskaffers moet gelisensieer en geverifieer wees voordat hulle konsultasies op die platform aanbied.',
      'fr':
          'Avoir au moins 18 ans ou une autorisation parentale si vous êtes mineur.\n\nFournir des informations exactes, à jour et complètes lors de l\'inscription.\n\nS\'engager à utiliser MedZen uniquement à des fins licites, personnelles et non commerciales.\n\nLes professionnels de santé doivent être agréés et vérifiés avant de proposer des consultations sur la plateforme.',
    },
    'fedkz1op': {
      'en': '4.Medical Disclaimer',
      'af': '4. Mediese Vrywaring',
      'fr': '4. Avertissement médical',
    },
    'ylk71kft': {
      'en':
          'MedZen provides telemedicine and health information services but does not guarantee diagnosis or treatment outcomes.\nAll consultations are provided by independent, licensed medical professionals.\nMedZen and MylesTech are not liable for medical decisions made by healthcare providers using the platform.\nIn case of an emergency, users must contact local emergency services immediately and not rely solely on MedZen.',
      'af':
          'MedZen verskaf telemedisyne- en gesondheidsinligtingsdienste, maar waarborg nie diagnose- of behandelingsuitkomste nie. Alle konsultasies word deur onafhanklike, gelisensieerde mediese professionele persone verskaf. MedZen en MylesTech is nie aanspreeklik vir mediese besluite wat deur gesondheidsorgverskaffers geneem word wat die platform gebruik nie. In geval van \'n noodgeval moet gebruikers onmiddellik plaaslike nooddienste kontak en nie uitsluitlik op MedZen staatmaak nie.',
      'fr':
          'MedZen propose des services de télémédecine et d\'information sur la santé, mais ne garantit ni le diagnostic ni les résultats du traitement.\n\nToutes les consultations sont assurées par des professionnels de santé indépendants et agréés.\n\nMedZen et MylesTech déclinent toute responsabilité quant aux décisions médicales prises par les professionnels de santé utilisant la plateforme.\n\nEn cas d\'urgence, les utilisateurs doivent contacter immédiatement les services d\'urgence locaux et ne pas se fier uniquement à MedZen.',
    },
    '7sfpm5c3': {
      'en': '5. User Accounts and Security',
      'af': '5. Gebruikersrekeninge en sekuriteit',
      'fr': '5. Comptes utilisateurs et sécurité',
    },
    'bt6ye060': {
      'en':
          'You are responsible for maintaining the confidentiality of your login credentials. \n\nYou agree to immediately notify us of any unauthorized access or breach of account.\n\nMylesTech reserves the right to suspend or terminate accounts for misuse, fraud, or policy violations.',
      'af':
          'Jy is verantwoordelik vir die handhawing van die vertroulikheid van jou aanmeldbesonderhede.\n\nJy stem in om ons onmiddellik in kennis te stel van enige ongemagtigde toegang of rekeningbreuk.\n\nMylesTech behou die reg voor om rekeninge op te skort of te beëindig vir misbruik, bedrog of beleidsoortredings.',
      'fr':
          'Il vous incombe de préserver la confidentialité de vos identifiants de connexion.\n\nVous vous engagez à nous informer immédiatement de tout accès non autorisé ou de toute violation de votre compte.\n\nMylesTech se réserve le droit de suspendre ou de résilier les comptes en cas d\'utilisation abusive, de fraude ou de non-respect des conditions d\'utilisation.',
    },
    '54974g4n': {
      'en': '6.Consultations, Payments, and Subscriptions',
      'af': '6. Konsultasies, Betalings en Subskripsies',
      'fr': '6. Consultations, paiements et abonnements',
    },
    'pu60hf4w': {
      'en':
          'MedZen offers free and paid subscription plans (Standard, Plus, Premium, and Corporate).\n\nConsultation fees are set by healthcare providers and displayed before booking.\n\nPayments are processed securely through integrated payment gateways (e.g., Mobile Money, Orange Money, or card).\n\nRefunds may be granted only for technical or administrative errors, not for dissatisfaction with a consultation outcome.',
      'af':
          'MedZen bied gratis en betaalde intekenplanne (Standaard, Plus, Premium en Korporatief).\n\nKonsultasiefooie word deur gesondheidsorgverskaffers vasgestel en voor bespreking vertoon.\n\nBetalings word veilig verwerk deur geïntegreerde betalingsportaals (bv. Mobiele Geld, Oranje Geld of kaart).\n\nTerugbetalings mag slegs toegestaan ​​word vir tegniese of administratiewe foute, nie vir ontevredenheid met \'n konsultasie-uitkoms nie.',
      'fr':
          'MedZen propose des abonnements gratuits et payants (Standard, Plus, Premium et Entreprise).\n\nLes tarifs des consultations sont fixés par les professionnels de santé et affichés avant la réservation.\n\nLes paiements sont traités de manière sécurisée via des plateformes de paiement intégrées (par exemple, Mobile Money, Orange Money ou carte bancaire).\n\nLes remboursements ne sont accordés qu\'en cas d\'erreur technique ou administrative, et non en cas d\'insatisfaction quant au résultat d\'une consultation.',
    },
    'egrpj1j9': {
      'en': '7. Use of AI Features',
      'af': '7. Gebruik van KI-funksies',
      'fr': '7. Utilisation des fonctionnalités de l\'IA',
    },
    '48nprfnd': {
      'en':
          'MedZen’s AI-powered tools (symptom checker, transcription, triage) are designed to assist but do not replace professional medical judgment. Data processed by these tools is anonymized and used to improve service quality in line with privacy regulations.',
      'af':
          'MedZen se KI-aangedrewe gereedskap (simptoomkontroleerder, transkripsie, triage) is ontwerp om professionele mediese oordeel te help, maar vervang dit nie. Data wat deur hierdie gereedskap verwerk word, word geanonimiseer en gebruik om diensgehalte te verbeter in ooreenstemming met privaatheidsregulasies.',
      'fr':
          'Les outils d’intelligence artificielle de MedZen (vérificateur de symptômes, transcription, triage) sont conçus pour assister les professionnels de santé, mais ne remplacent pas leur jugement. Les données traitées par ces outils sont anonymisées et utilisées pour améliorer la qualité du service, conformément à la réglementation sur la protection des données.',
    },
    '44q15iwr': {
      'en': '8.Data Privacy and Security',
      'af': '8. Dataprivaatheid en -sekuriteit',
      'fr': '8. Confidentialité et sécurité des données',
    },
    'uu9dihc9': {
      'en':
          'MedZen complies with data protection laws applicable in Africa and international standards such as GDPR and HIPAA principles.\nAll medical and personal data are encrypted and stored securely.\nUsers have the right to request access, correction, or deletion of their data by contacting: privacy@mylestechsolutionsllc.com.',
      'af':
          'MedZen voldoen aan databeskermingswette wat in Afrika van toepassing is en internasionale standaarde soos GDPR- en HIPAA-beginsels. Alle mediese en persoonlike data word geïnkripteer en veilig gestoor. Gebruikers het die reg om toegang, regstelling of verwydering van hul data aan te vra deur kontak te maak met: privacy@mylestechsolutionsllc.com.',
      'fr':
          'MedZen respecte les lois sur la protection des données applicables en Afrique et les normes internationales telles que le RGPD et les principes de la loi HIPAA.\n\nToutes les données médicales et personnelles sont cryptées et stockées en toute sécurité.\n\nLes utilisateurs ont le droit de demander l\'accès à leurs données, leur rectification ou leur suppression en contactant : privacy@mylestechsolutionsllc.com.',
    },
    'lwgwk00g': {
      'en': '9.  User Conduct',
      'af': '9. Gebruikersgedrag',
      'fr': '9. Comportement de l\'utilisateur',
    },
    'vewux6sn': {
      'en': 'You agree not to: ',
      'af': 'Jy stem in om nie:',
      'fr': 'Vous acceptez de ne pas :',
    },
    'tlc2b4rx': {
      'en':
          'Misrepresent your identity or health information.\n\nUse the platform to harass, abuse, or harm others.\n\nUpload or share false or illegal content.\n\nReverse-engineer, copy, or modify the App.\n\nMylesTech reserves the right to remove content or suspend accounts that violate these rules.',
      'af':
          'Jou identiteit of gesondheidsinligting verkeerd voorstel.\n\nGebruik die platform om ander te teister, te misbruik of skade aan te doen.\n\nLaai valse of onwettige inhoud op of deel dit.\n\nOmkeer die toepassing te ontwerp, te kopieer of te wysig.\n\nMylesTech behou die reg voor om inhoud te verwyder of rekeninge op te skort wat hierdie reëls oortree.',
      'fr':
          'Falsifier votre identité ou vos informations de santé.\n\nUtiliser la plateforme pour harceler, maltraiter ou nuire à autrui.\n\nTéléverser ou partager du contenu faux ou illégal.\n\nProcéder à l\'ingénierie inverse, copier ou modifier l\'application.\n\nMylesTech se réserve le droit de supprimer tout contenu ou de suspendre les comptes qui enfreignent ces règles.',
    },
    'b5c85wog': {
      'en': '10. Intellectual Property',
      'af': '10. Intellektuele Eiendom',
      'fr': '10. Propriété intellectuelle',
    },
    'kzmhfvb8': {
      'en':
          'All content, trademarks, and software associated with MedZen are the intellectual property of MylesTech Solutions LLC. Users are granted a limited, non-transferable license to use the App solely for personal health management.',
      'af':
          'Alle inhoud, handelsmerke en sagteware wat met MedZen geassosieer word, is die intellektuele eiendom van MylesTech Solutions LLC. Gebruikers word \'n beperkte, nie-oordraagbare lisensie toegestaan ​​om die toepassing uitsluitlik vir persoonlike gesondheidsbestuur te gebruik.',
      'fr':
          'L\'ensemble du contenu, des marques et des logiciels associés à MedZen sont la propriété intellectuelle de MylesTech Solutions LLC. Les utilisateurs bénéficient d\'une licence limitée et non transférable pour utiliser l\'application exclusivement à des fins de gestion de leur santé personnelle.',
    },
    'z8cmc7oa': {
      'en': '11. Third-Party Services',
      'af': '11. Dienste van Derde Partye',
      'fr': '11. Services tiers',
    },
    '59k4z1cl': {
      'en':
          'MedZen may include links or integrations with third-party services (labs, pharmacies, payment gateways). MylesTech is not responsible for the content, accuracy, or performance of those third-party services.',
      'af':
          'MedZen mag skakels of integrasies met derdepartydienste (laboratoriums, apteke, betalingsportaals) insluit. MylesTech is nie verantwoordelik vir die inhoud, akkuraatheid of prestasie van daardie derdepartydienste nie.',
      'fr':
          'MedZen peut inclure des liens ou des intégrations avec des services tiers (laboratoires, pharmacies, plateformes de paiement). MylesTech décline toute responsabilité quant au contenu, à l\'exactitude ou au fonctionnement de ces services tiers.',
    },
    'ovrs3e1v': {
      'en': '12. Limitation of Liability',
      'af': '12. Beperking van Aanspreeklikheid',
      'fr': '12. Limitation de responsabilité',
    },
    'i05vmegj': {
      'en':
          'To the fullest extent permitted by law:\nMylesTech Solutions LLC shall not be liable for indirect, incidental, or consequential damage arising from the use or inability to use the App.\nMedZen does not guarantee uninterrupted access or error-free functionality.',
      'af':
          'Tot die volle mate wat deur die wet toegelaat word:\nMylesTech Solutions LLC sal nie aanspreeklik wees vir indirekte, toevallige of gevolglike skade wat voortspruit uit die gebruik of onvermoë om die Toepassing te gebruik nie.\nMedZen waarborg nie ononderbroke toegang of foutvrye funksionaliteit nie.',
      'fr':
          'Dans toute la mesure permise par la loi :\n\nMylesTech Solutions LLC ne saurait être tenue responsable des dommages indirects, accessoires ou consécutifs découlant de l’utilisation ou de l’impossibilité d’utiliser l’application.\n\nMedZen ne garantit pas un accès ininterrompu ni un fonctionnement sans erreur.',
    },
    'zhi6uev4': {
      'en': '13. Termination',
      'af': '13. Beëindiging',
      'fr': '13. Résiliation',
    },
    'crb1pdsd': {
      'en':
          'MylesTech may suspend or terminate access to the platform if:\nA user violates these Terms.\nRequired by law or regulatory authority.\nFor technical or maintenance reasons.\nUsers may delete their account at any time from the settings section or by contacting support@mylestechsolutionsllc.com.',
      'af':
          'MylesTech mag toegang tot die platform opskort of beëindig indien:\n\'n Gebruiker hierdie Voorwaardes oortree.\n\nWetlik of deur \'n regulerende owerheid vereis word.\nVir tegniese of onderhoudsredes.\n\nGebruikers kan hul rekening te eniger tyd uit die instellingsafdeling verwyder of deur support@mylestechsolutionsllc.com te kontak.',
      'fr':
          'MylesTech peut suspendre ou résilier l\'accès à la plateforme dans les cas suivants :\n\nEn cas de violation des présentes conditions d\'utilisation.\n\nEn cas d\'obligation légale ou réglementaire.\n\nPour des raisons techniques ou de maintenance.\n\nLes utilisateurs peuvent supprimer leur compte à tout moment depuis la section « Paramètres » ou en contactant support@mylestechsolutionsllc.com.',
    },
    'qechznd6': {
      'en': '14. Governing Law',
      'af': '14. Toepaslike Reg',
      'fr': '14. Droit applicable',
    },
    '8c7u3cuf': {
      'en':
          'These Terms are governed by and construed in accordance with the laws of:\nCameroon, where MylesTech Solutions LLC is registered; and Local laws of the user’s country of residence, to the extent applicable for healthcare regulation and data protection.',
      'af':
          'Hierdie Voorwaardes word beheer deur en geïnterpreteer in ooreenstemming met die wette van: Kameroen, waar MylesTech Solutions LLC geregistreer is; en Plaaslike wette van die gebruiker se land van verblyf, in die mate wat van toepassing is op gesondheidsorgregulering en databeskerming.',
      'fr':
          'Les présentes conditions générales sont régies et interprétées conformément aux lois :\n\ndu Cameroun, où MylesTech Solutions LLC est enregistrée ; et aux lois locales du pays de résidence de l’utilisateur, dans la mesure où elles sont applicables en matière de réglementation des soins de santé et de protection des données.',
    },
    '2gsk8343': {
      'en': '15. Amendments',
      'af': '15. Wysigings',
      'fr': '15. Amendements',
    },
    '88fp9zlb': {
      'en':
          'MylesTech may update these Terms periodically. Continued use of the platform after changes implies acceptance of the revised Terms. The latest version will always be available within the App and on our website.',
      'af':
          'MylesTech mag hierdie Voorwaardes periodiek opdateer. Voortgesette gebruik van die platform na veranderinge impliseer aanvaarding van die hersiene Voorwaardes. Die nuutste weergawe sal altyd binne die Toepassing en op ons webwerf beskikbaar wees.',
      'fr':
          'MylesTech peut mettre à jour les présentes Conditions d\'utilisation périodiquement. L\'utilisation continue de la plateforme après modification implique l\'acceptation des Conditions d\'utilisation révisées. La version la plus récente sera toujours disponible dans l\'application et sur notre site web.',
    },
    '0sprowwm': {
      'en': '16. Contact Information',
      'af': '16. Kontakbesonderhede',
      'fr': '16. Coordonnées',
    },
    'o22c0uy1': {
      'en':
          'For questions, support, or complaints, contact:\nMylesTech Solutions LLC\nEmail: info@mylestechsolutionsllc.com\nWebsite: www.mylestechsolutionsllc.com',
      'af':
          'Vir vrae, ondersteuning of klagtes, kontak: \nMylesTech Solutions LLC \nE-pos: info@mylestechsolutionsllc.com \nWebwerf: www.mylestechsolutionsllc.com',
      'fr':
          'Pour toute question, demande d\'assistance ou réclamation, veuillez contacter :\n\nMylesTech Solutions LLC\n\nCourriel : info@mylestechsolutionsllc.com\n\nSite web : www.mylestechsolutionsllc.com',
    },
    'nqfhnli6': {
      'en': 'Acknowledgment',
      'af': 'Erkenning',
      'fr': 'Reconnaissance',
    },
    'gv37zq1a': {
      'en':
          'By clicking the check box, you acknowledge that you have read, understood, and accepted these Terms and Conditions and agree to abide by them when using MedZen.',
      'af':
          'Deur op die blokkie te klik, erken u dat u hierdie Terme en Voorwaardes gelees, verstaan ​​en aanvaar het en instem om daarby te hou wanneer u MedZen gebruik.',
      'fr':
          'En cochant la case, vous reconnaissez avoir lu, compris et accepté les présentes Conditions générales et vous vous engagez à les respecter lors de l\'utilisation de MedZen.',
    },
    'q6qp87as': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // AboutUsPage
  {
    '7w3jhhv1': {
      'en': 'About US',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    'eq7439na': {
      'en':
          'MedZen is a telemedicine platform designed to provide seamless healthcare services remotely. Whether you need a consultation with a doctor, medical advice from a nurse, or urgent care assistance, MedZen connects you with certified healthcare providers anytime, anywhere.',
      'af':
          'VERBY HINDRINGS, VERBY GRENSE\nMedZen is \'n moderne telehealth-platform wat ontwerp is om pasiënte met gesondheidsorgverskaffers te verbind deur middel van veilige, HIPAA-voldoenende videokonsultasies. Ons funksie-ryke platform bied \'n omvattende reeks gereedskap vir beide pasiënte en verskaffers, wat \'n naatlose virtuele gesondheidsorgervaring skep.',
      'fr':
          'AU-DELÀ DES BARRIÈRES, AU-DELÀ DES LIMITES\nMedZen est une plateforme de télésanté de pointe conçue pour mettre en relation patients et professionnels de santé grâce à des consultations vidéo sécurisées et conformes à la loi HIPAA. Notre plateforme riche en fonctionnalités offre une gamme complète d\'outils pour les patients et les professionnels de santé, créant ainsi une expérience de soins virtuels optimale.',
    },
    'j0hbs958': {
      'en': 'Meet Our Providers',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    '2v1e1npb': {
      'en':
          'Our platform hosts a network of licensed doctors, nurses, and medical professionals ready to assist you. Each provider is vetted and verified to ensure high-quality healthcare services. You can search for specialists, nearby hospitals, and even facilities with incubators or blood banks.',
      'af':
          'VERBY HINDRINGS, VERBY GRENSE\nMedZen is \'n moderne telehealth-platform wat ontwerp is om pasiënte met gesondheidsorgverskaffers te verbind deur middel van veilige, HIPAA-voldoenende videokonsultasies. Ons funksie-ryke platform bied \'n omvattende reeks gereedskap vir beide pasiënte en verskaffers, wat \'n naatlose virtuele gesondheidsorgervaring skep.',
      'fr':
          'AU-DELÀ DES BARRIÈRES, AU-DELÀ DES LIMITES\nMedZen est une plateforme de télésanté de pointe conçue pour mettre en relation patients et professionnels de santé grâce à des consultations vidéo sécurisées et conformes à la loi HIPAA. Notre plateforme riche en fonctionnalités offre une gamme complète d\'outils pour les patients et les professionnels de santé, créant ainsi une expérience de soins virtuels optimale.',
    },
    'xq5zw1fn': {
      'en': 'Key Features',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    'f6beoxb8': {
      'en':
          'Virtual or In-person consultations with doctors, nurses and other healthcare providers.',
      'af':
          'Virtuele of persoonlike konsultasies met dokters, verpleegsters en ander gesondheidsorgverskaffers.',
      'fr':
          'Consultations virtuelles ou en personne avec des médecins, des infirmières et d\'autres professionnels de la santé.',
    },
    'bu296l1g': {
      'en': 'Easy appointment scheduling',
      'af': 'Maklike afspraakskedulering',
      'fr': 'Prise de rendez-vous facile',
    },
    '4pvrxy6e': {
      'en': 'Secure medical records management',
      'af': 'Veilige bestuur van mediese rekords',
      'fr': 'Gestion sécurisée des dossiers médicaux',
    },
    '313sfhrn': {
      'en': 'Search for nearby hospitals, blood banks, and incubators',
      'af': 'Soek vir nabygeleë hospitale, bloedbanke en broeikaste',
      'fr':
          'Recherchez les hôpitaux, les banques de sang et les incubateurs à proximité.',
    },
    'hojuxohd': {
      'en':
          'Seamless payment integration with MTN Mobile Money and Orange Money',
      'af': 'Naatlose betalingsintegrasie met MTN Mobile Money en Orange Money',
      'fr':
          'Intégration fluide des paiements avec MTN Mobile Money et Orange Money',
    },
    'q7xaizm5': {
      'en': 'Real-time notifications for appointments',
      'af': 'Kennisgewings intyds vir afsprake',
      'fr': 'Notifications en temps réel pour les rendez-vous',
    },
    'cj9ved16': {
      'en': 'Off line and Indepth AI functionalitites',
      'af': 'Kennisgewings intyds vir afsprake',
      'fr': 'Notifications en temps réel pour les rendez-vous',
    },
    'pt134tjw': {
      'en': 'Get in Touch',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    'one4cp7u': {
      'en': '📱',
      'af': '📱',
      'fr': '📱',
    },
    'yef39l2z': {
      'en': 'Phone',
      'af': 'Foon',
      'fr': 'Téléphone',
    },
    '98wctfcc': {
      'en': '+1 (800) 555-1234',
      'af': '+1 (800) 555-1234',
      'fr': '+1 (800) 555-1234',
    },
    'gwcvp6gk': {
      'en': 'Mon-Fri: 8AM-8PM EST',
      'af': 'Ma-Vr: 8VM-8NM EST',
      'fr': 'Du Lundi au Vendredi : de 8 h à 20 h',
    },
    'mde1f5hk': {
      'en': '✉️',
      'af': '✉️',
      'fr': '✉️',
    },
    'mkf1gipe': {
      'en': 'Email',
      'af': 'E-pos',
      'fr': 'E-mail',
    },
    't8csncwa': {
      'en': 'support@medihealth.app',
      'af': 'ondersteuning@medihealth.app',
      'fr': 'support@medihealth.app',
    },
    '1ewjvmjh': {
      'en': 'info@medihealth.app',
      'af': 'info@medihealth.app',
      'fr': 'info@medihealth.app',
    },
    'g4755e0a': {
      'en': '📍',
      'af': '📍',
      'fr': '📍',
    },
    'f221hav4': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'jwv0c8pm': {
      'en': '123 Health Avenue, Suite 500',
      'af': '123 Healthlaan, Suite 500',
      'fr': '123, avenue de la Santé, bureau 500',
    },
    'ofe8en6s': {
      'en': 'Boston, MA 02108',
      'af': 'Boston, MA 02108',
      'fr': 'Boston, MA 02108',
    },
    'dp5bisac': {
      'en': '💬',
      'af': '💬',
      'fr': '💬',
    },
    '9v2og40j': {
      'en': 'Live Chat',
      'af': 'Regstreekse klets',
      'fr': 'Chat en direct',
    },
    'nrpbru1s': {
      'en': 'Available in our app ',
      'af': 'Beskikbaar in ons app',
      'fr': 'Disponible dans notre application',
    },
    'd7c4cjlc': {
      'en': '24/7 for urgent matters',
      'af': '24/7 vir dringende sake',
      'fr': 'Service disponible 24h/24 et 7j/7 pour les urgences',
    },
    '424czzza': {
      'en': 'Send a Message',
      'af': 'Platformoorsig',
      'fr': 'Présentation de la plateforme',
    },
    '935m3vxd': {
      'en': 'Full Name',
      'af': 'Volle Naam',
      'fr': 'Nom et prénom',
    },
    '887d21ez': {
      'en': 'Email Address',
      'af': 'E-posadres',
      'fr': 'Adresse email',
    },
    'ofgjaoj4': {
      'en': 'Phone Number (Optional)',
      'af': 'Telefoonnommer (Opsioneel)',
      'fr': 'Numéro de téléphone (facultatif)',
    },
    'q9anpbia': {
      'en': 'Subject',
      'af': 'Onderwerp',
      'fr': 'Sujet',
    },
    'td3ezffm': {
      'en': 'Select a topic',
      'af': 'Kies \'n onderwerp',
      'fr': 'Sélectionnez un sujet',
    },
    '5g8j6t1y': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '0wew1fxk': {
      'en': 'Technical Support',
      'af': 'Tegniese Ondersteuning',
      'fr': 'Assistance technique',
    },
    'hz42yhk3': {
      'en': 'Billing Question',
      'af': 'Faktuurvraag',
      'fr': 'Question de facturation',
    },
    'ussxvm1q': {
      'en': 'Account Management',
      'af': 'Rekeningbestuur',
      'fr': 'Gestion de compte',
    },
    'wwm3tjau': {
      'en': 'App Feedback',
      'af': 'Programterugvoer',
      'fr': 'Commentaires sur l\'application',
    },
    '3948fpk8': {
      'en': 'Partnership Inquiry',
      'af': 'Vennootskapsondersoek',
      'fr': 'Demande de partenariat',
    },
    'punjdg0d': {
      'en': 'Other',
      'af': 'Ander',
      'fr': 'Autre',
    },
    'w856ym32': {
      'en': 'Your Message',
      'af': 'Jou Boodskap',
      'fr': 'Votre message',
    },
    't1161bgd': {
      'en': 'Send Message',
      'af': 'Stuur boodskap',
      'fr': 'Envoyer un message',
    },
    'xm5wq800': {
      'en': 'Full Name is required',
      'af': '',
      'fr': '',
    },
    'dg2v3rtj': {
      'en': 'Please choose an option from the dropdown',
      'af': '',
      'fr': '',
    },
    'nhhdovns': {
      'en': 'Email Address is required',
      'af': '',
      'fr': '',
    },
    'filpoqnd': {
      'en': 'Please choose an option from the dropdown',
      'af': '',
      'fr': '',
    },
    'aipocghq': {
      'en': 'Phone Number (Optional) is required',
      'af': '',
      'fr': '',
    },
    '9pde5mv8': {
      'en': 'Please choose an option from the dropdown',
      'af': '',
      'fr': '',
    },
    'ufbltj8v': {
      'en': 'Field is required',
      'af': '',
      'fr': '',
    },
    '9yy2j7ld': {
      'en': 'Please choose an option from the dropdown',
      'af': '',
      'fr': '',
    },
    '7etkn8vm': {
      'en': 'Frequently Asked Questions',
      'af': 'Gereelde vrae',
      'fr': 'Questions recurrentes',
    },
    'jwp9qc55': {
      'en': 'How quickly can I expect a response?',
      'af': 'Hoe vinnig kan ek \'n reaksie verwag?',
      'fr': 'Quel est le délai d\'attente pour espérer avoir une réponse ?',
    },
    'f5xuphdv': {
      'en':
          'For general inquiries, we aim to respond within 1 business day. Technical support requests are typically addressed within 4-8 hours. For urgent matters, please use the in-app chat support for faster assistance.',
      'af':
          'Vir algemene navrae streef ons daarna om binne 1 werksdag te reageer. Tegniese ondersteuningsversoeke word gewoonlik binne 4-8 uur hanteer. Vir dringende sake, gebruik asseblief die kletsondersteuning in die toepassing vir vinniger hulp.',
      'fr':
          'Pour toute question d\'ordre général, nous nous efforçons de répondre sous 24 heures ouvrables. Les demandes d\'assistance technique sont généralement traitées sous 4 à 8 heures. Pour les urgences, veuillez utiliser le chat intégré à l\'application pour une assistance plus rapide.',
    },
    'bdi4vfkh': {
      'en': 'Is there a way to schedule a meeting with your team?',
      'af': 'Is daar \'n manier om \'n vergadering met jou span te skeduleer?',
      'fr':
          'Existe-t-il un moyen de programmer une réunion avec votre équipe ?',
    },
    '6o56lknw': {
      'en':
          'Yes! For partnership inquiries or detailed technical consultations, you can schedule a meeting with our team by sending an email to meetings@medzenhealth.app with your preferred date and time.',
      'af':
          'Ja! Vir vennootskapsnavrae of gedetailleerde tegniese konsultasies, kan u \'n vergadering met ons span skeduleer deur \'n e-pos te stuur na meetings@medihealth.app met u voorkeurdatum en -tyd.',
      'fr':
          'Oui ! Pour toute demande de partenariat ou consultation technique approfondie, vous pouvez programmer une réunion avec notre équipe en envoyant un courriel à meetings@medzenhealth.app en indiquant la date et l\'heure qui vous conviennent.',
    },
    '6wct1jgp': {
      'en': 'Do you offer phone support on weekends?',
      'af': 'Bied julle telefoniese ondersteuning oor naweke?',
      'fr': 'Proposez-vous une assistance téléphonique le week-end ?',
    },
    'p4eu3atr': {
      'en':
          'Our phone support operates Monday through Friday from 8AM to 8PM EST. For weekend support, please use our in-app chat feature which is available 24/7 for urgent matters.',
      'af':
          'Ons telefoonondersteuning is Maandag tot Vrydag oop van 08:00 tot 20:00 EST. Vir naweekondersteuning, gebruik asseblief ons kletsfunksie in die toepassing wat 24/7 beskikbaar is vir dringende sake.',
      'fr':
          'Notre assistance téléphonique est disponible du lundi au vendredi de 8h à 20h . Pour une assistance le week-end, veuillez utiliser notre messagerie instantanée intégrée à l\'application, disponible 24h/24 et 7j/7 pour les urgences.',
    },
    '2gpg0qzw': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // facilityadmin_patientsPage
  {
    'atlxltq4': {
      'en': 'Patients',
      'af': 'Pasiënte',
      'fr': 'Les patients',
    },
    'zc2nkdra': {
      'en': 'Search patients...',
      'af': 'Soek pasiënte...',
      'fr': 'Rechercher des patients...',
    },
    'ib0a4tgt': {
      'en': 'Name: ',
      'af': 'Naam:',
      'fr': 'Nom:',
    },
    'hy17tasv': {
      'en': 'patient name',
      'af': 'pasiëntnaam',
      'fr': 'nom du patient',
    },
    '4i5fip4u': {
      'en': 'DOB: ',
      'af': 'Geboortedatum:',
      'fr': 'Date de naissance :',
    },
    'yrprcql5': {
      'en': 'Status',
      'af': 'Status',
      'fr': 'Statut',
    },
    'ffdituk2': {
      'en': 'ID: ',
      'af': 'ID:',
      'fr': 'IDENTIFIANT:',
    },
    'nhqolycu': {
      'en': 'ID',
      'af': 'ID',
      'fr': 'IDENTIFIANT',
    },
    '5p08njk5': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // careCenterSettingsPage
  {
    '34ctuphv': {
      'en': 'General Information',
      'af': 'Algemene inligting',
      'fr': 'Informations générales',
    },
    '54tyb3h0': {
      'en': 'Facility Name: ',
      'af': 'Fasiliteitsnaam',
      'fr': 'Nom de l\'établissement',
    },
    'bssej4cm': {
      'en': 'Consultation Fee',
      'af': 'E-posadres',
      'fr': 'Adresse email',
    },
    '75pnr2km': {
      'en': 'Enter email address',
      'af': 'Voer e-posadres in',
      'fr': 'Saisissez votre adresse e-mail',
    },
    'ux3hz2hc': {
      'en': 'Email Address',
      'af': 'E-posadres',
      'fr': 'Adresse email',
    },
    '7ohq7vuj': {
      'en': 'Enter email address',
      'af': 'Voer e-posadres in',
      'fr': 'Saisissez votre adresse e-mail',
    },
    'ui4fa12j': {
      'en': 'Phone Number',
      'af': 'Telefoonnommer',
      'fr': 'Numéro de téléphone',
    },
    'zjl7wa3t': {
      'en': 'Enter phone number',
      'af': 'Voer telefoonnommer in',
      'fr': 'Saisissez le numéro de téléphone',
    },
    'sxk49owj': {
      'en': 'Address',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'l9dxcfkn': {
      'en': 'Enter facility address',
      'af': 'Voer die fasiliteit se adres in',
      'fr': 'Saisissez l\'adresse de l\'établissement',
    },
    '3tmnxyxi': {
      'en': 'Website',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'tciuhgsr': {
      'en': 'Enter facility address',
      'af': 'Voer die fasiliteit se adres in',
      'fr': 'Saisissez l\'adresse de l\'établissement',
    },
    'yakuqj25': {
      'en': 'About',
      'af': 'Adres',
      'fr': 'Adresse',
    },
    'jeo75ze3': {
      'en': 'Enter facility address',
      'af': 'Voer die fasiliteit se adres in',
      'fr': 'Saisissez l\'adresse de l\'établissement',
    },
    'h56ztmay': {
      'en': 'Country',
      'af': 'Land',
      'fr': 'Pays',
    },
    '6zc83nv3': {
      'en': '   Cameroon',
      'af': 'Kameroen',
      'fr': 'Cameroun',
    },
    'zo6aga8q': {
      'en': '   Select country',
      'af': 'Kies land',
      'fr': 'Sélectionnez un pays',
    },
    'grufi4tl': {
      'en': '   Cameroon',
      'af': 'Kameroen',
      'fr': 'Cameroun',
    },
    '41y4mu8y': {
      'en': '   Gabon',
      'af': 'Gaboen',
      'fr': 'Gabon',
    },
    'im79ggs3': {
      'en': '  CAR',
      'af': 'KAR',
      'fr': 'RCA',
    },
    '3omzmzn1': {
      'en': 'Timezone',
      'af': 'Tydsone',
      'fr': 'Fuseau horaire',
    },
    '2rsuhxjh': {
      'en': '   EST (UTC-5)',
      'af': 'EST (UTC-5)',
      'fr': 'EST (UTC-5)',
    },
    'w354azmn': {
      'en': '   Select timezone',
      'af': 'Kies tydsone',
      'fr': 'Sélectionnez le fuseau horaire',
    },
    'lvqewvrq': {
      'en': '   EST (UTC-5)',
      'af': 'EST (UTC-5)',
      'fr': 'EST (UTC-5)',
    },
    '04x3am65': {
      'en': '   PST (UTC-8)',
      'af': 'PST (UTC-8)',
      'fr': 'PST (UTC-8)',
    },
    'gd26gp7i': {
      'en': '   CST (UTC-6)',
      'af': 'CST (UTC-6)',
      'fr': 'CST (UTC-6)',
    },
    'ygbzcvvn': {
      'en': '   WAT',
      'af': 'WAT',
      'fr': 'HAO',
    },
    'x4k1ejsi': {
      'en': 'Facility Departments',
      'af': 'Bestuur Fasiliteitsafdelings',
      'fr': 'Gérer les services de l\'établissement',
    },
    'rvqoorb8': {
      'en': 'Preferences',
      'af': 'Voorkeure',
      'fr': 'Préférences',
    },
    'j356qaxm': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'kvzuvb8g': {
      'en': 'View profile details',
      'af': 'Bekyk profielbesonderhede',
      'fr': 'Voir les détails du profil',
    },
    '40h5fp76': {
      'en': 'Dark Mode',
      'af': 'Donkermodus',
      'fr': 'Mode sombre',
    },
    'ad6yl6bo': {
      'en': 'Switch to dark theme',
      'af': 'Skakel oor na donker tema',
      'fr': 'Passer en mode sombre',
    },
    'rx0gga7h': {
      'en': 'Notification Sounds',
      'af': 'Kennisgewingklanke',
      'fr': 'Sons de notification',
    },
    'z564i0d4': {
      'en': 'Enable audio alerts',
      'af': 'Aktiveer oudio-waarskuwings',
      'fr': 'Activer les alertes audio',
    },
    'yqoyf9vg': {
      'en': 'Auto-Refresh',
      'af': 'Outomatiese herlaai',
      'fr': 'Actualisation automatique',
    },
    '8u32p4ms': {
      'en': 'Automatically update data',
      'af': 'Dateer data outomaties op',
      'fr': 'Mise à jour automatique des données',
    },
    'nwjhyhxg': {
      'en': 'Appointment Alerts',
      'af': 'Afspraakwaarskuwings',
      'fr': 'Alertes de rendez-vous',
    },
    '3xzei4l1': {
      'en': 'Get notified about appointments',
      'af': 'Kry kennisgewings oor afsprake',
      'fr': 'Recevez des notifications concernant vos rendez-vous',
    },
    'oybfwylp': {
      'en': 'Language',
      'af': 'Taal',
      'fr': 'Langue',
    },
    'be2ran0u': {
      'en': 'Choose your language',
      'af': 'Kies jou taal',
      'fr': 'Choisissez votre langue',
    },
    'uehi9r6p': {
      'en': 'Add New Departments',
      'af': 'Bestuur Fasiliteitsafdelings',
      'fr': 'Gérer les services de l\'établissement',
    },
    '5358l00l': {
      'en': 'Department Name',
      'af': 'Departement Naam',
      'fr': 'Nom du département',
    },
    '8o8domjo': {
      'en': 'Enter department name, one a time',
      'af': 'Voer departementsnaam in',
      'fr': 'Saisissez le nom du département',
    },
    'f9lb2vaz': {
      'en': 'Edit Your Availability',
      'af': 'Wysig jou beskikbaarheid',
      'fr': 'Modifier vos disponibilités',
    },
    'b2kdrkoz': {
      'en': 'Monday',
      'af': 'Maandag',
      'fr': 'Lundi',
    },
    'shjk52yv': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    '3uwbp77a': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '7woz26s7': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'ui4w5o1q': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'tbjd9t65': {
      'en': 'Tuesday',
      'af': 'Dinsdag',
      'fr': 'Mardi',
    },
    'mfribvqb': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'catswusq': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverteure',
    },
    'gvqiqpjo': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'vd9wrjyb': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'c3i8dd1c': {
      'en': 'Wednesday',
      'af': 'Woensdag',
      'fr': 'Mercredi',
    },
    'xthzm16t': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'brqog8ul': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '18dzmz4c': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'rbcaedva': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    '7x7fz6ty': {
      'en': 'Thursday',
      'af': 'Donderdag',
      'fr': 'Jeudi',
    },
    '2w2cjkg0': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    's7x0sdmg': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '6hjkv73t': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'vd9ynyfz': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'wdh7vc9s': {
      'en': 'Friday',
      'af': 'Vrydag',
      'fr': 'Vendredi',
    },
    'g7lnpdfh': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'kwnadwre': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'uzkh13ci': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    'mm54myzf': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'xp2ufds8': {
      'en': 'Saturday',
      'af': 'Saterdag',
      'fr': 'Samedi',
    },
    'xlpbako4': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'jm7yo2ga': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    '4je4f3tj': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '0hlgemmg': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    '4e0rs4jc': {
      'en': 'Sunday',
      'af': 'Sondag',
      'fr': 'Dimanche',
    },
    'xlpgbx2g': {
      'en': 'Operating Hours (24hr)',
      'af': 'Bedryfsure (24 uur)',
      'fr': 'Horaires d\'ouverture (24h/24)',
    },
    'wkwrnd0u': {
      'en': 'Start Time',
      'af': 'Begintyd',
      'fr': 'Heure d\'ouverture',
    },
    'jm3mvfa7': {
      'en': '-',
      'af': '-',
      'fr': '-',
    },
    '6wdxwdm9': {
      'en': 'End Time',
      'af': 'Eindtyd',
      'fr': 'Heure de fermeture',
    },
    'm93cju9y': {
      'en': 'Save Changes',
      'af': 'Stoor veranderinge',
      'fr': 'Enregistrer les modifications',
    },
    '2hpmy9h8': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    '948weaw8': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Acceuil',
    },
  },
  // Reset_password
  {
    'chz89xln': {
      'en': 'Reset Password',
      'af': 'Herstel wagwoord',
      'fr': 'Réinitialiser le mot de passe',
    },
    'fpdxp95t': {
      'en':
          'We will send you a reset link via sms for you to use and reset your password',
      'af':
          'Ons sal vir jou \'n terugstelskakel per SMS stuur sodat jy jou wagwoord kan gebruik en terugstel.',
      'fr':
          'Nous vous enverrons un lien de réinitialisation par SMS pour que vous puissiez réinitialiser votre mot de passe.',
    },
    '6549a6ub': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'g75ka7ic': {
      'en': 'Send Link',
      'af': 'Stuur skakel',
      'fr': 'Envoyer le lien',
    },
  },
  // medzen_mobile_footer
  {
    'j2g1zx32': {
      'en': 'MedZen Health',
      'af': 'MedZen Gesondheid',
      'fr': 'MedZen Santé',
    },
    '17kjcck3': {
      'en':
          'Connect with  medical Providers from the comfort of your home. Our telemedicine platform makes healthcare accessible to everyone,  anywhere at anytime.\n+237-691-95-9357   or   info@medzenhealth.app',
      'af':
          'Maak kontak met mediese verskaffers vanuit die gemak van jou huis. Ons telemedisyne-platform maak gesondheidsorg toeganklik vir almal, enige plek en enige tyd.\n+237-691-95-9357 of info@medzenhealth.app',
      'fr':
          'Faites vous consultez par des professionnels de la santé  à partir de votre domicile . Notre plateforme de télémédecine rend les soins accessibles à tous, partout et à tout moment.\n\n+237-691-95-9357 ou info@medzenhealth.app',
    },
    'do47tfr5': {
      'en': 'Resources',
      'af': 'Hulpbronne',
      'fr': 'Ressources',
    },
    'm1ycdzyj': {
      'en': 'Contacts',
      'af': 'Kontakte',
      'fr': 'Contacts',
    },
    'bmdfyzab': {
      'en': 'Terms And Conditions',
      'af': 'Terme en Voorwaardes',
      'fr': 'Termes et conditions',
    },
    'eb8dztjy': {
      'en': 'Privacy Policy',
      'af': 'Privaatheidsbeleid',
      'fr': 'politique de confidentialité',
    },
    'k9q1kagd': {
      'en': 'Quick Links',
      'af': 'Vinnige skakels',
      'fr': 'Racourcis',
    },
    'g5akzt0s': {
      'en': 'About',
      'af': 'Oor',
      'fr': 'À propos',
    },
    '5kp899nq': {
      'en': 'Mylestechsolutions© 2025. All Rights Reserved',
      'af': 'Mylestechsolutions© 2025. Alle regte voorbehou.',
      'fr': 'Mylestechsolutions© 2025. Tous droits réservés.',
    },
  },
  // medzen_footer
  {
    'obbcrwdf': {
      'en': 'MedZen Health',
      'af': 'MedZen Gesondheid',
      'fr': 'MedZen Santé',
    },
    'edvxk2kz': {
      'en':
          'Connect with  medical Providers from the comfort of your home. Our telemedicine platform makes healthcare accessible to everyone,  anywhere at anytime.\n+237-555-66-888   or   info@medzenhealth.app',
      'af':
          'Maak kontak met mediese verskaffers vanuit die gemak van jou huis. Ons telemedisyne-platform maak gesondheidsorg toeganklik vir almal, enige plek en enige tyd.\n+237-555-66-888 of info@medzenhealth.app',
      'fr':
          'Consultez des professionnels de santé depuis chez vous. Notre plateforme de télémédecine rend les soins accessibles à tous, partout et à tout moment.\n\n+237-555-66-888 ou info@medzenhealth.app',
    },
    'tp0yquya': {
      'en': 'Resources',
      'af': 'Hulpbronne',
      'fr': 'Ressources',
    },
    '85pdlt66': {
      'en': 'Contacts',
      'af': 'Kontakte',
      'fr': 'Contacts',
    },
    '2iwaqlgc': {
      'en': 'Terms And Conditions',
      'af': 'Terme en Voorwaardes',
      'fr': 'Termes et Conditions',
    },
    'hkwntn3v': {
      'en': 'Privacy Policy',
      'af': 'Privaatheidsbeleid',
      'fr': 'politique de confidentialité',
    },
    '76fv7dvu': {
      'en': 'Quick Links',
      'af': 'Vinnige skakels',
      'fr': 'Liens rapides',
    },
    'jeqt13u9': {
      'en': 'About',
      'af': 'Oor',
      'fr': 'À propos',
    },
    '06ehtd2r': {
      'en': 'Download Our Mobile App',
      'af': 'Laai ons mobiele toepassing af',
      'fr': 'Téléchargez notre application mobile',
    },
    '2ubysxdd': {
      'en': 'Download on ',
      'af': 'Laai af op',
      'fr': 'Télécharger sur',
    },
    'anib1fc8': {
      'en': 'App Store',
      'af': 'App Winkel',
      'fr': 'App Store',
    },
    'cujfzprs': {
      'en': 'Download on ',
      'af': 'Laai af op',
      'fr': 'Télécharger sur',
    },
    'g2na66fk': {
      'en': 'Google play',
      'af': 'Google Play',
      'fr': 'Google Play',
    },
    '66n4tqsl': {
      'en': 'Mylestechsolutions© 2025. All Rights Reserved',
      'af': 'Mylestechsolutions© 2025. Alle regte voorbehou.',
      'fr': 'Mylestechsolutions© 2025. Tous droits réservés.',
    },
  },
  // OTP
  {
    'y7ntty50': {
      'en': 'Enter your PIN below',
      'af': '',
      'fr': 'Veuillez saisir votre PIN ',
    },
    'w8r48o7z': {
      'en': 'Please help us verify your phone number ',
      'af': 'Help ons asseblief om u telefoonnommer te verifieer',
      'fr': 'Veuillez nous aider à vérifier votre numéro de téléphone.',
    },
    'nilo3c4h': {
      'en': 'No code yet ? You can resend in ',
      'af': '',
      'fr': 'Pas de code? Renvoyez un nouveau',
    },
    '1hzczhk7': {
      'en': 'Resend code',
      'af': 'Het nie kode ontvang nie',
      'fr': 'Renvoyez un nouveau code',
    },
    '8h5p2uxl': {
      'en': 'Verify Code',
      'af': 'Verifieer Kode',
      'fr': 'Vérifier le code',
    },
  },
  // logout
  {
    '6ni2fgnn': {
      'en': 'Logout',
      'af': 'Uitteken',
      'fr': 'Déconnexion',
    },
  },
  // ComingSoon
  {
    'lifvdop1': {
      'en': ' Coming Soon',
      'af': 'Kom binnekort',
      'fr': 'À venir',
    },
    '12u1h1wf': {
      'en': 'We\'re crafting this feature. Please Stay tuned.',
      'af':
          'Ons is besig om hierdie funksie te ontwikkel. Bly asseblief ingeskakel.',
      'fr':
          'Nous travaillons actuellement sur cette fonctionnalité. Restez connecter.',
    },
    'for0qhrk': {
      'en': 'Done',
      'af': 'Klaar',
      'fr': 'Fait',
    },
  },
  // Payment
  {
    'ouwo7td1': {
      'en': 'Check Out',
      'af': 'Uitcheck',
      'fr': 'Procéder au paiement',
    },
    'ru0ay34f': {
      'en': 'Fill in the information below to confirm your order.',
      'af': 'Vul die inligting hieronder in om jou bestelling te bevestig.',
      'fr':
          'Veuillez compléter les informations ci-dessous pour confirmer votre commande.',
    },
    'aocyeiko': {
      'en': 'Select Payment method...',
      'af': 'Kies betaalmetode...',
      'fr': 'Sélectionnez un mode de paiement...',
    },
    'svgyrf8i': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    '81m6y43n': {
      'en': 'MTN',
      'af': 'MTN',
      'fr': 'MTN',
    },
    'g61zr6qp': {
      'en': 'ORANGE',
      'af': 'ORANJE',
      'fr': 'ORANGE',
    },
    'mvpnsup5': {
      'en': 'CARD',
      'af': 'KAART',
      'fr': 'CARTE',
    },
    'dy2pzba5': {
      'en': 'Card details are required only after  you click  \"Pay Now\"',
      'af':
          'Indien u met \'n kaart wil betaal, gaan asseblief voort na Betaal Nou en volg die instruksies.',
      'fr':
          'Les informations de la carte sont requises uniquement après avoir cliqué sur \"Payer maintenant\".',
    },
    'sficywx1': {
      'en': 'Service : ',
      'af': 'Diens:',
      'fr': 'Service :',
    },
    'm7u4dnbs': {
      'en': 'Amount  : ',
      'af': 'Bedrag:',
      'fr': 'Montant  :',
    },
    'gax980qf': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'rpcrguni': {
      'en': 'Pay Now',
      'af': 'Betaal Nou',
      'fr': 'Payer ',
    },
    '6sdfyf7a': {
      'en': 'Help Me Pay',
      'af': 'Help my betaal',
      'fr': 'Aidez-moi à payer',
    },
  },
  // PaymentReferal
  {
    'effddxsg': {
      'en': 'Help Me pay',
      'af': 'Help my betaal',
      'fr': 'Aidez-moi à payer',
    },
    'pxcptbex': {
      'en':
          'Please insert the phone number of the person you wish he/she should help pay your bill.',
      'af':
          'Voer asseblief die telefoonnommer in van die persoon wat u wil hê hy/sy moet help om u rekening te betaal.',
      'fr':
          'Veuillez indiquer le numéro de téléphone de votre garant/bienfaiteur',
    },
    'uoqwh0pk': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'uzjl28zl': {
      'en': 'Send ',
      'af': 'Stuur',
      'fr': 'Envoyer',
    },
  },
  // BookingSummary
  {
    'qh2aqnrc': {
      'en': '5',
      'af': '5',
      'fr': '5',
    },
    'du3qij2t': {
      'en': '60',
      'af': '60',
      'fr': '60',
    },
    '6fzn3gs7': {
      'en': 'Date :',
      'af': 'Datum:',
      'fr': 'Date :',
    },
    'ixziu4v7': {
      'en': 'Time : ',
      'af': 'Tyd',
      'fr': 'Temps',
    },
    'tfuhvv0x': {
      'en': 'Booking for : ',
      'af': 'Bespreking vir',
      'fr': 'Réservation pour',
    },
    'l12v869l': {
      'en': 'Type : ',
      'af': 'Tipe',
      'fr': 'Mode',
    },
    'qisjckwx': {
      'en': 'In person',
      'af': '',
      'fr': 'En personne',
    },
    'l8ifvluj': {
      'en': '',
      'af': 'Kies...',
      'fr': '',
    },
    'bhfb98s8': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'h2pu4dmm': {
      'en': 'Online',
      'af': 'Aanlyn',
      'fr': 'En ligne',
    },
    'cc9bqmuh': {
      'en': 'In person',
      'af': 'Persoonlik',
      'fr': 'En personne',
    },
    'rbpqlgzv': {
      'en': 'Amount',
      'af': 'Bedrag',
      'fr': 'Montant',
    },
    'k9hbg8gl': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'qpbhjmvl': {
      'en': 'Confirm',
      'af': 'Bevestig',
      'fr': 'Confirmer',
    },
  },
  // FilterPractitioners
  {
    '3bya2bxn': {
      'en': 'Apply filters',
      'af': 'Pas filters toe',
      'fr': 'Filtrez',
    },
    'u7q0fvtm': {
      'en': 'Gender',
      'af': 'Geslag',
      'fr': 'Genre',
    },
    'hgxdg8zi': {
      'en': 'female',
      'af': 'vroulik',
      'fr': 'féminin',
    },
    'b7q928jp': {
      'en': 'male',
      'af': 'manlik',
      'fr': 'masculin',
    },
    'hp9ym5nl': {
      'en': 'Specialty',
      'af': 'Spesialiteit',
      'fr': 'Spécialité',
    },
    'ztivqu5p': {
      'en': 'Select specialty..',
      'af': 'Kies spesialiteit..',
      'fr': 'Sélectionnez votre spécialité...',
    },
    'wuxgntiu': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'kbocdrp9': {
      'en': 'General practitioner',
      'af': 'Algemene praktisyn',
      'fr': 'Généraliste',
    },
    'h9a9ilb5': {
      'en': 'Nurse',
      'af': 'Verpleegster',
      'fr': 'Infirmière',
    },
    'wgwgldsl': {
      'en': 'Medzen',
      'af': 'Medzen',
      'fr': 'Medzen',
    },
    'rwfl9gm5': {
      'en': 'Close to me',
      'af': 'Naby my',
      'fr': 'À proximité',
    },
    'uj30otb3': {
      'en': 'Clear all',
      'af': 'Vee alles uit',
      'fr': 'Effacer tout',
    },
    '9k75943v': {
      'en': 'Apply filters',
      'af': 'Pas filters toe',
      'fr': 'Filtrez',
    },
  },
  // practitioner_Details_header_back
  {
    'h490xh30': {
      'en': 'Medical Practitioners',
      'af': 'Mediese Praktisyns',
      'fr': 'Personnel de Santé',
    },
  },
  // PasswordResetForSettingsPage
  {
    'sr5zgzze': {
      'en': 'Change Password',
      'af': 'Verander wagwoord',
      'fr': 'Changer le mot de passe',
    },
    '42oyyexq': {
      'en': 'Enter current password',
      'af': 'Voer huidige wagwoord in',
      'fr': 'Saisissez le mot de passe actuel',
    },
    'wlcsw9d2': {
      'en': 'New Password',
      'af': 'Minimum 8 karakters',
      'fr': 'Minimum 8 caractères',
    },
    '9jf7gnqp': {
      'en':
          'Must contain at least 8 characters, 1 uppercase letter, and 1 number',
      'af': 'Moet ten minste 8 karakters, 1 hoofletter en 1 syfer bevat',
      'fr':
          'Doit contenir au moins 8 caractères, 1 lettre majuscule et 1 chiffre.',
    },
    '3qh9mata': {
      'en': 'Re-enter new password',
      'af': 'Voer nuwe wagwoord weer in',
      'fr': 'Saisissez à nouveau le nouveau mot de passe',
    },
    'khq96d2k': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'l9gtnlyy': {
      'en': 'Save Password',
      'af': 'Stoor Wagwoord',
      'fr': 'Enregistrer le mot de passe',
    },
  },
  // Adminrejection_dialogue
  {
    'qzcqu7e0': {
      'en': 'Reject Applicant',
      'af': 'Verwerp aansoeker',
      'fr': 'Rejeter l\'application',
    },
    '4wtdj8yf': {
      'en': 'Please provide reason for rejection',
      'af': 'Verskaf asseblief rede vir verwerping',
      'fr': 'Veuillez indiquer le motif du refus.',
    },
    'gbeknbiv': {
      'en': 'ID Invalid',
      'af': 'ID Ongeldig',
      'fr': 'Identifiant invalide',
    },
    'ft1w7cjf': {
      'en': 'ID Expired',
      'af': 'ID het verval',
      'fr': 'Carte d\'identité expirée',
    },
    'sll7x6wj': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'azqrz1fm': {
      'en': 'Submit Rejection',
      'af': 'Dien verwerping in',
      'fr': 'Soumettre le refus',
    },
  },
  // FacilityRejectionDIalogue
  {
    'uqysa70f': {
      'en': 'Reject Applicant',
      'af': 'Verwerp aansoeker',
      'fr': 'Rejeter l\'application',
    },
    '5rb6im9g': {
      'en': 'Please provide reason for rejection',
      'af': 'Verskaf asseblief rede vir verwerping',
      'fr': 'Veuillez indiquer le motif du refus.',
    },
    '9n5po4kt': {
      'en': 'facilit Invalid',
      'af': 'fasiliteit Ongeldig',
      'fr': 'Centre Invalide',
    },
    'uayffepr': {
      'en': 'facility not found',
      'af': 'fasiliteit nie gevind nie',
      'fr': 'Centre introuvable',
    },
    'anxbgkw5': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'gdqcyqh8': {
      'en': 'Submit Rejection',
      'af': 'Dien verwerping in',
      'fr': 'Soumettre le refus',
    },
  },
  // ProviderRejectionDialogue
  {
    'ef002p3a': {
      'en': 'Reject Applicant',
      'af': 'Verwerp aansoeker',
      'fr': 'Rejeter l\'application',
    },
    'a41qq2s9': {
      'en': 'Please provide reason for rejection',
      'af': 'Verskaf asseblief rede vir verwerping',
      'fr': 'Veuillez indiquer le motif du refus.',
    },
    '8r8hsn2x': {
      'en': 'License Invalid',
      'af': 'Lisensie Ongeldig',
      'fr': 'Licence invalide',
    },
    'ueqdthpm': {
      'en': 'License Expired',
      'af': 'Lisensie het verval',
      'fr': 'Licence expirée',
    },
    'b2iok722': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    '1s0lwab8': {
      'en': 'Submit Rejection',
      'af': 'Dien verwerping in',
      'fr': 'Soumettre le refus',
    },
  },
  // paymentmethods
  {
    'bqco3c7l': {
      'en': 'Set Payment Methods',
      'af': 'Stel betaalmetodes in',
      'fr': 'Définir les modes de paiement',
    },
    'qqdz5ikv': {
      'en': 'Mobile Money',
      'af': 'Mobiele Geld',
      'fr': 'MoMo',
    },
    'jtgiolxh': {
      'en': 'Enter MTN number',
      'af': 'Voer MTN-nommer in',
      'fr': 'Saisissez le numéro MTN',
    },
    'x9max6vw': {
      'en': 'Orange Money',
      'af': 'Oranje Geld',
      'fr': 'Orange Money',
    },
    'fjryvfxy': {
      'en': 'Enter Orange number',
      'af': 'Voer Oranje-nommer in',
      'fr': 'Saisissez le numéro orange',
    },
    'wrw707dk': {
      'en': 'Card Payments ( Visa, Master )',
      'af': 'Kaartbetalings (Visa, Master)',
      'fr': 'Paiements par carte (Visa, Mastercard)',
    },
    'ocz3a79x': {
      'en': 'Name on Card',
      'af': 'Naam op Kaart',
      'fr': 'Nom sur la carte',
    },
    't4gurw52': {
      'en': 'Enter cardholder name',
      'af': 'Voer kaarthouer se naam in',
      'fr': 'Saisissez le nom du titulaire de la carte',
    },
    'vzduii37': {
      'en': 'Card Number',
      'af': 'Kaartnommer',
      'fr': 'Numéro de carte',
    },
    'te8w0ofu': {
      'en': 'Enter card number',
      'af': 'Voer kaartnommer in',
      'fr': 'Saisissez le numéro de carte',
    },
    'dw0j4dnw': {
      'en': 'Expiry Date',
      'af': 'Vervaldatum',
      'fr': 'Date d\'expiration',
    },
    '8iiv3mdc': {
      'en': 'MM/YY',
      'af': 'MM/JJ',
      'fr': 'MM/AA',
    },
    'guhhznji': {
      'en': 'CVV',
      'af': 'CVV',
      'fr': 'CVV',
    },
    'chlkxe1b': {
      'en': 'CVV',
      'af': 'CVV',
      'fr': 'CVV',
    },
    '14flslte': {
      'en': 'PIN',
      'af': 'PIN',
      'fr': 'Code PIN',
    },
    '6tsmfhgl': {
      'en': 'Enter PIN',
      'af': 'Voer PIN in',
      'fr': 'Saisissez le code PIN',
    },
    'xuhhxcko': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'y9ve4hvq': {
      'en': 'Save Changes',
      'af': 'Stoor veranderinge',
      'fr': 'Enregistrer les modifications',
    },
  },
  // SideNav
  {
    't13n0ih3': {
      'en': 'Dashboard',
      'af': 'Dashboard',
      'fr': 'Tableau de bord',
    },
    'y1c1tzqx': {
      'en': 'Profile',
      'af': 'Profiel',
      'fr': 'Profil',
    },
    'j98a5oae': {
      'en': 'Appointments',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    's391uc63': {
      'en': 'CareCenters',
      'af': 'Sorgsentrums',
      'fr': 'Centres de soins',
    },
    'ftf09tjo': {
      'en': 'Payments',
      'af': 'Betalings',
      'fr': 'Paiements',
    },
    '1ixs9as7': {
      'en': 'Medications',
      'af': 'Medikasie',
      'fr': 'Médicaments',
    },
    '6c82378w': {
      'en': 'Documents',
      'af': 'Dokumente',
      'fr': 'Documents',
    },
    'ibev39n6': {
      'en': 'Notifications',
      'af': 'Kennisgewings',
      'fr': 'Notifications',
    },
    '2te9fxry': {
      'en': 'Settings',
      'af': 'Instellings',
      'fr': 'Paramètres',
    },
    '1nb2dnns': {
      'en': 'Log Out',
      'af': 'Meld af',
      'fr': 'Déconnexion',
    },
  },
  // TopBar
  {
    'uyo03zjx': {
      'en': '3',
      'af': '3',
      'fr': '3',
    },
  },
  // MedDoc
  {
    'ald7ebkk': {
      'en': 'MedZen DOC',
      'af': 'MedZen DOC',
      'fr': 'MedZen DOC',
    },
  },
  // RetryPayment
  {
    'xh258znc': {
      'en': 'Check Out',
      'af': 'Uitcheck',
      'fr': 'Procéder au paiement',
    },
    'xv6qfk64': {
      'en': 'Fill in the information below to confirm your order.',
      'af': 'Vul die inligting hieronder in om jou bestelling te bevestig.',
      'fr':
          'Veuillez compléter les informations ci-dessous pour confirmer votre commande.',
    },
    'r65j5t10': {
      'en': 'Select Payment method...',
      'af': 'Kies betaalmetode...',
      'fr': 'Sélectionnez un mode de paiement...',
    },
    '0ea3ihhp': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'ou5zn170': {
      'en': 'MTN',
      'af': 'MTN',
      'fr': 'MTN',
    },
    '3r6p5p65': {
      'en': 'ORANGE',
      'af': 'ORANJE',
      'fr': 'ORANGE',
    },
    'v5nkmx59': {
      'en': 'CARD',
      'af': 'KAART',
      'fr': 'CARTE',
    },
    'jsssds81': {
      'en': 'Card details are required only after  you click  \"Pay Now\"',
      'af':
          'Indien u met \'n kaart wil betaal, gaan asseblief voort na Betaal Nou en volg die instruksies.',
      'fr':
          'Les informations de la carte sont requises uniquement après avoir cliqué sur \"Payer maintenant\".',
    },
    'ahku9pex': {
      'en': 'Service : ',
      'af': 'Diens:',
      'fr': 'Service :',
    },
    'bslvsfk7': {
      'en': 'Amount  : ',
      'af': 'Bedrag:',
      'fr': 'Montant  :',
    },
    '0ibnti32': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    '6i14sc3d': {
      'en': 'Pay Now',
      'af': 'Betaal Nou',
      'fr': 'Payer maintenant',
    },
    'o05i5xa1': {
      'en': 'Help Me Pay',
      'af': 'Help my betaal',
      'fr': 'Aidez-moi à payer',
    },
  },
  // PaymentProgress
  {
    '8p1nign6': {
      'en': 'PROCESSING',
      'af': 'VERWERKING',
      'fr': 'TRAITEMENT',
    },
    'uj0an8mf': {
      'en': 'Refresh',
      'af': 'Verfris',
      'fr': 'Actualiser',
    },
  },
  // StartChat
  {
    '87i3ro56': {
      'en': 'MedX AI',
      'af': 'MedX AI',
      'fr': 'MedX AI',
    },
    'wrgmmm7x': {
      'en':
          'MedX is an AI-powered assistant that supports patients, medical providers, facility administrators, and system administrators. It provides informational, clinical support, and operational guidance only. MedX does not replace licensed medical care, professional judgment, or institutional policies. All outputs must be independently reviewed and validated before use.',
      'af':
          'MedX is \'n KI-gesondheidsassistent en nie \'n plaasvervanger vir \'n mediese professionele nie. Verifieer altyd inligting of advies met \'n gelisensieerde gesondheidsorgverskaffer voordat jy aksie neem.',
      'fr':
          'MedX est un assistant de santé IA et ne remplace pas un professionnel de santé. Vérifiez toujours les informations ou conseils auprès d’un professionnel de santé agréé avant d’agir.',
    },
    'he7mm6zy': {
      'en': 'History',
      'af': 'Kanselleer',
      'fr': 'Historique',
    },
    'mhh4f0gr': {
      'en': 'Chat',
      'af': 'Gesels',
      'fr': 'Chat',
    },
  },
  // main_bottom_nav
  {
    'u4coqb6k': {
      'en': 'Home',
      'af': 'Tuis',
      'fr': 'Maison',
    },
    'hbqowqj4': {
      'en': 'Appts',
      'af': 'Afsprake',
      'fr': 'Rendez-vous',
    },
    'ra7oarnn': {
      'en': 'Docs',
      'af': 'Dokumente',
      'fr': 'Docs',
    },
    'c21fqmlg': {
      'en': 'Profile',
      'af': 'Dokumente',
      'fr': 'Profil',
    },
    's7hz2fm0': {
      'en': 'Payments',
      'af': 'Dokumente',
      'fr': 'Paiements',
    },
    'p9vdjgx8': {
      'en': 'Meds',
      'af': 'Medisyne',
      'fr': 'Médicaments',
    },
    'x25my10u': {
      'en': 'Settings',
      'af': 'Instellings',
      'fr': 'Paramètres',
    },
  },
  // AppointmentStatus
  {
    '0u3dkg3p': {
      'en': 'Update Appointment Status',
      'af': 'Opdateer Afspraakstatus',
      'fr': 'Mise à jour du statut du rendez-vous',
    },
    'k9wbois8': {
      'en': 'Apointment Status..',
      'af': 'Afspraakstatus..',
      'fr': 'Statut du rendez-vous...',
    },
    'bk7vobej': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'fo1bfpmy': {
      'en': 'completed',
      'af': 'voltooi',
      'fr': 'Terminé ',
    },
    '6ihy2pos': {
      'en': 'no_show',
      'af': 'geen_vertoning',
      'fr': 'Absence ',
    },
    'ycb0xin6': {
      'en': 'rescheduled',
      'af': 'herskeduleer',
      'fr': 'Replanifié/Reporté',
    },
    'g54l7d4g': {
      'en': 'Notes',
      'af': 'Notas',
      'fr': 'Notes',
    },
    'gf7yoon4': {
      'en': 'Date :',
      'af': 'Datum:',
      'fr': 'Date :',
    },
    'btmawo4h': {
      'en': 'Time :',
      'af': 'Tyd:',
      'fr': 'Temps :',
    },
    'ozvuldwn': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'wdue42an': {
      'en': 'Save',
      'af': 'Stoor',
      'fr': 'Sauvegarder',
    },
  },
  // SummaryNotes
  {
    'tghtxqif': {
      'en': '5',
      'af': '5',
      'fr': '5',
    },
    '9urelsf2': {
      'en': '60',
      'af': '60',
      'fr': '60',
    },
    'hkl5wxvm': {
      'en': 'Close',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    '18znqqe6': {
      'en': 'Save',
      'af': 'Stoor',
      'fr': 'Sauvegarder',
    },
  },
  // WithdrawRequest
  {
    'f48oj4zm': {
      'en': 'Request Withdrawal',
      'af': 'Uitcheck',
      'fr': 'Faire un Retrait',
    },
    'o4fclupt': {
      'en': 'Select Withdrawal method...',
      'af': 'Kies Onttrekkingsmetode...',
      'fr': 'Sélectionnez le mode de retrait...',
    },
    '82s2x9ex': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'wdn8z38r': {
      'en': 'MTN',
      'af': 'MTN',
      'fr': 'MTN',
    },
    'hotczorw': {
      'en': 'ORANGE',
      'af': 'ORANJE',
      'fr': 'ORANGE',
    },
    '2uxrg915': {
      'en': 'Requested Amount',
      'af': '',
      'fr': 'Montant',
    },
    'beearmmz': {
      'en': 'Requested amount must not be greater than your current balance',
      'af': 'Die versoekte bedrag mag nie groter wees as u huidige saldo nie',
      'fr':
          'Le montant demandé ne doit pas être supérieur à votre solde actuel.',
    },
    '06e7vpkz': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    '4kijfhjm': {
      'en': 'Submit',
      'af': 'Dien in',
      'fr': 'Soumettre',
    },
  },
  // PaymentDetails
  {
    'yv5c8s6d': {
      'en': '5',
      'af': '5',
      'fr': '5',
    },
    'b7hevjcm': {
      'en': '60',
      'af': '60',
      'fr': '60',
    },
    'vttxh63w': {
      'en': 'Close',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
  },
  // Support
  {
    'ieakguix': {
      'en': 'Welcome to support',
      'af': 'Uitcheck',
      'fr': 'Bienvenue au service d\'assistance !',
    },
    'xctwhtj1': {
      'en':
          'We are sorry you facing some issues with the app. \nPlease provide as much info you can to help us resolve or improve our services',
      'af': 'Vul die inligting hieronder in om jou bestelling te bevestig.',
      'fr':
          'Nous sommes désolés pour tout inconvenient. Merci de nous fournir autant d\'informations que possible pour nous aider à améliorer nos services.',
    },
    'nkowamwl': {
      'en': 'Select  the  type of issue are you facing..',
      'af': 'Kies betaalmetode...',
      'fr': 'A quel type de probleme faites-vous face?',
    },
    'vlo44qqb': {
      'en': 'Search...',
      'af': 'Soek...',
      'fr': 'Recherche...',
    },
    'rsslseoq': {
      'en': 'FeedBack',
      'af': '',
      'fr': 'Suggestions/Commentaires',
    },
    'gmrcsahj': {
      'en': 'Payments',
      'af': '',
      'fr': 'Paiements',
    },
    'rmu9y3sb': {
      'en': 'Others',
      'af': 'KAART',
      'fr': 'Autres',
    },
    'hi1qfla6': {
      'en':
          'Provide a Short Description of the issue you facing. If payment query, please include transaction ID',
      'af': 'Kort beskrywing van wat aangaan...',
      'fr': 'Brève description de la situation...',
    },
    'k43i4gjw': {
      'en': 'Upload Screenshot if any',
      'af': 'Laai skermkiekie op',
      'fr': 'Ajouter une capture d\'écran',
    },
    'v1f3i85v': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'c8nc614t': {
      'en': 'Submit',
      'af': 'Betaal Nou',
      'fr': 'Envoyer',
    },
    'g2zhqzj5': {
      'en': 'or Call Us',
      'af': 'Betaal Nou',
      'fr': 'Appel',
    },
  },
  // LogoutConfirmation
  {
    '1nuxft14': {
      'en': 'Are you sure you want to logout? ',
      'af': 'Is jy seker jy wil uitmeld?',
      'fr': 'Êtes-vous sûr de vouloir vous déconnecter ?',
    },
    '3rwf6mr5': {
      'en': 'Cancel',
      'af': 'Kanselleer',
      'fr': 'Annuler',
    },
    'w7xrnkrc': {
      'en': 'Yes',
      'af': 'Ja',
      'fr': 'Oui',
    },
  },
  // Miscellaneous
  {
    'hgnpvwsk': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'c1067c26': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    '6j2pq2zg': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'maunli0x': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'unn8hdsy': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'elcll6o3': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'z8wdgga5': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    '498wwwhz': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'kwaqx30u': {
      'en': 'allow usage ',
      'af': 'laat gebruik toe',
      'fr': 'autoriser l\'utilisation',
    },
    'ngumc0gf': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'y74zu0gp': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'x122t1tl': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'rmxxuxne': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'sp0y85o2': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '130fjuu3': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'zgj09pf5': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'euy72t0f': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '1cxba9eo': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'kl9iio81': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'xx56wxxy': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '25ymlbn3': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'd1zjapjh': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '3agicd4v': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '9o8e1ojf': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'ayv8k3cd': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'a5yg4if5': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'ub4dwkow': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '6xxdxf6y': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '5xlmohb0': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '8epwygfp': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'zpbl2j5m': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'vqvqvbhz': {
      'en': '',
      'af': '',
      'fr': '',
    },
    'hszv9kbm': {
      'en': '',
      'af': '',
      'fr': '',
    },
    '3g6a1dip': {
      'en': '',
      'af': '',
      'fr': '',
    },
  },
].reduce((a, b) => a..addAll(b));
