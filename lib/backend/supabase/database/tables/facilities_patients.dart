import '../database.dart';

class FacilitiesPatientsTable extends SupabaseTable<FacilitiesPatientsRow> {
  @override
  String get tableName => 'facilities_patients';

  @override
  FacilitiesPatientsRow createRow(Map<String, dynamic> data) =>
      FacilitiesPatientsRow(data);
}

class FacilitiesPatientsRow extends SupabaseDataRow {
  FacilitiesPatientsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilitiesPatientsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get patientNumber => getField<String>('patient_number');
  set patientNumber(String? value) => setField<String>('patient_number', value);

  String? get primaryPhysicianId => getField<String>('primary_physician_id');
  set primaryPhysicianId(String? value) =>
      setField<String>('primary_physician_id', value);

  String? get preferredHospitalId => getField<String>('preferred_hospital_id');
  set preferredHospitalId(String? value) =>
      setField<String>('preferred_hospital_id', value);

  String? get medicalRecordNumber => getField<String>('medical_record_number');
  set medicalRecordNumber(String? value) =>
      setField<String>('medical_record_number', value);

  List<String> get allergies => getListField<String>('allergies');
  set allergies(List<String>? value) =>
      setListField<String>('allergies', value);

  List<String> get chronicConditions =>
      getListField<String>('chronic_conditions');
  set chronicConditions(List<String>? value) =>
      setListField<String>('chronic_conditions', value);

  List<String> get currentMedications =>
      getListField<String>('current_medications');
  set currentMedications(List<String>? value) =>
      setListField<String>('current_medications', value);

  bool? get hasChronicCondition => getField<bool>('has_chronic_condition');
  set hasChronicCondition(bool? value) =>
      setField<bool>('has_chronic_condition', value);

  bool? get requiresSpecialCare => getField<bool>('requires_special_care');
  set requiresSpecialCare(bool? value) =>
      setField<bool>('requires_special_care', value);

  String? get diabetesType => getField<String>('diabetes_type');
  set diabetesType(String? value) => setField<String>('diabetes_type', value);

  DateTime? get diabetesDiagnosisDate =>
      getField<DateTime>('diabetes_diagnosis_date');
  set diabetesDiagnosisDate(DateTime? value) =>
      setField<DateTime>('diabetes_diagnosis_date', value);

  bool? get hypertension => getField<bool>('hypertension');
  set hypertension(bool? value) => setField<bool>('hypertension', value);

  bool? get kidneyIssue => getField<bool>('kidney_issue');
  set kidneyIssue(bool? value) => setField<bool>('kidney_issue', value);

  bool? get isPregnant => getField<bool>('is_pregnant');
  set isPregnant(bool? value) => setField<bool>('is_pregnant', value);

  DateTime? get pregnancyDueDate => getField<DateTime>('pregnancy_due_date');
  set pregnancyDueDate(DateTime? value) =>
      setField<DateTime>('pregnancy_due_date', value);

  double? get lastBloodSugar => getField<double>('last_blood_sugar');
  set lastBloodSugar(double? value) =>
      setField<double>('last_blood_sugar', value);

  int? get lastBloodPressureSystolic =>
      getField<int>('last_blood_pressure_systolic');
  set lastBloodPressureSystolic(int? value) =>
      setField<int>('last_blood_pressure_systolic', value);

  int? get lastBloodPressureDiastolic =>
      getField<int>('last_blood_pressure_diastolic');
  set lastBloodPressureDiastolic(int? value) =>
      setField<int>('last_blood_pressure_diastolic', value);

  DateTime? get lastVitalsDate => getField<DateTime>('last_vitals_date');
  set lastVitalsDate(DateTime? value) =>
      setField<DateTime>('last_vitals_date', value);

  bool? get isBloodDonor => getField<bool>('is_blood_donor');
  set isBloodDonor(bool? value) => setField<bool>('is_blood_donor', value);

  String? get bloodDonorStatus => getField<String>('blood_donor_status');
  set bloodDonorStatus(String? value) =>
      setField<String>('blood_donor_status', value);

  DateTime? get lastDonationDate => getField<DateTime>('last_donation_date');
  set lastDonationDate(DateTime? value) =>
      setField<DateTime>('last_donation_date', value);

  List<String> get disabilityAccommodations =>
      getListField<String>('disability_accommodations');
  set disabilityAccommodations(List<String>? value) =>
      setListField<String>('disability_accommodations', value);

  String? get literacyLevel => getField<String>('literacy_level');
  set literacyLevel(String? value) => setField<String>('literacy_level', value);

  bool? get interpreterNeeded => getField<bool>('interpreter_needed');
  set interpreterNeeded(bool? value) =>
      setField<bool>('interpreter_needed', value);

  bool? get hasSmartphone => getField<bool>('has_smartphone');
  set hasSmartphone(bool? value) => setField<bool>('has_smartphone', value);

  String? get internetAccessQuality =>
      getField<String>('internet_access_quality');
  set internetAccessQuality(String? value) =>
      setField<String>('internet_access_quality', value);

  bool? get prefersUssd => getField<bool>('prefers_ussd');
  set prefersUssd(bool? value) => setField<bool>('prefers_ussd', value);

  String? get preferredCommunication =>
      getField<String>('preferred_communication');
  set preferredCommunication(String? value) =>
      setField<String>('preferred_communication', value);

  bool? get hasInsurance => getField<bool>('has_insurance');
  set hasInsurance(bool? value) => setField<bool>('has_insurance', value);

  dynamic? get insuranceDetails => getField<dynamic>('insurance_details');
  set insuranceDetails(dynamic? value) =>
      setField<dynamic>('insurance_details', value);

  bool? get dataSharingConsent => getField<bool>('data_sharing_consent');
  set dataSharingConsent(bool? value) =>
      setField<bool>('data_sharing_consent', value);

  DateTime? get dataSharingConsentDate =>
      getField<DateTime>('data_sharing_consent_date');
  set dataSharingConsentDate(DateTime? value) =>
      setField<DateTime>('data_sharing_consent_date', value);

  bool? get marketingConsent => getField<bool>('marketing_consent');
  set marketingConsent(bool? value) =>
      setField<bool>('marketing_consent', value);

  DateTime? get marketingConsentDate =>
      getField<DateTime>('marketing_consent_date');
  set marketingConsentDate(DateTime? value) =>
      setField<DateTime>('marketing_consent_date', value);

  bool? get researchParticipationConsent =>
      getField<bool>('research_participation_consent');
  set researchParticipationConsent(bool? value) =>
      setField<bool>('research_participation_consent', value);

  DateTime? get researchParticipationConsentDate =>
      getField<DateTime>('research_participation_consent_date');
  set researchParticipationConsentDate(DateTime? value) =>
      setField<DateTime>('research_participation_consent_date', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get bloodType => getField<String>('blood_type');
  set bloodType(String? value) => setField<String>('blood_type', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get address => getField<String>('address');
  set address(String? value) => setField<String>('address', value);

  String? get city => getField<String>('city');
  set city(String? value) => setField<String>('city', value);

  String? get state => getField<String>('state');
  set state(String? value) => setField<String>('state', value);

  String? get country => getField<String>('country');
  set country(String? value) => setField<String>('country', value);

  String? get postalCode => getField<String>('postal_code');
  set postalCode(String? value) => setField<String>('postal_code', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  String? get emergencyContactName =>
      getField<String>('emergency_contact_name');
  set emergencyContactName(String? value) =>
      setField<String>('emergency_contact_name', value);

  String? get emergencyContactPhone =>
      getField<String>('emergency_contact_phone');
  set emergencyContactPhone(String? value) =>
      setField<String>('emergency_contact_phone', value);

  String? get emergencyContactRelationship =>
      getField<String>('emergency_contact_relationship');
  set emergencyContactRelationship(String? value) =>
      setField<String>('emergency_contact_relationship', value);

  String? get insuranceProvider => getField<String>('insurance_provider');
  set insuranceProvider(String? value) =>
      setField<String>('insurance_provider', value);

  String? get insuranceNumber => getField<String>('insurance_number');
  set insuranceNumber(String? value) =>
      setField<String>('insurance_number', value);

  DateTime? get insuranceExpiry => getField<DateTime>('insurance_expiry');
  set insuranceExpiry(DateTime? value) =>
      setField<DateTime>('insurance_expiry', value);

  double? get heightCm => getField<double>('height_cm');
  set heightCm(double? value) => setField<double>('height_cm', value);

  double? get weightKg => getField<double>('weight_kg');
  set weightKg(double? value) => setField<double>('weight_kg', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  String? get displayName => getField<String>('display_name');
  set displayName(String? value) => setField<String>('display_name', value);

  int? get profileCompletionPercentage =>
      getField<int>('profile_completion_percentage');
  set profileCompletionPercentage(int? value) =>
      setField<int>('profile_completion_percentage', value);

  String? get streetAddress => getField<String>('street_address');
  set streetAddress(String? value) => setField<String>('street_address', value);

  String? get buildingName => getField<String>('building_name');
  set buildingName(String? value) => setField<String>('building_name', value);

  String? get apartmentUnit => getField<String>('apartment_unit');
  set apartmentUnit(String? value) => setField<String>('apartment_unit', value);

  String? get regionCode => getField<String>('region_code');
  set regionCode(String? value) => setField<String>('region_code', value);

  String? get landmarkDescription => getField<String>('landmark_description');
  set landmarkDescription(String? value) =>
      setField<String>('landmark_description', value);

  String? get divisionCode => getField<String>('division_code');
  set divisionCode(String? value) => setField<String>('division_code', value);

  String? get subdivisionCode => getField<String>('subdivision_code');
  set subdivisionCode(String? value) =>
      setField<String>('subdivision_code', value);

  String? get communityCode => getField<String>('community_code');
  set communityCode(String? value) => setField<String>('community_code', value);

  String? get neighborhood => getField<String>('neighborhood');
  set neighborhood(String? value) => setField<String>('neighborhood', value);

  String? get coordinates => getField<String>('coordinates');
  set coordinates(String? value) => setField<String>('coordinates', value);

  String? get emergencyContact2Name =>
      getField<String>('emergency_contact_2_name');
  set emergencyContact2Name(String? value) =>
      setField<String>('emergency_contact_2_name', value);

  String? get emergencyContact2Phone =>
      getField<String>('emergency_contact_2_phone');
  set emergencyContact2Phone(String? value) =>
      setField<String>('emergency_contact_2_phone', value);

  String? get emergencyContact2Relationship =>
      getField<String>('emergency_contact_2_relationship');
  set emergencyContact2Relationship(String? value) =>
      setField<String>('emergency_contact_2_relationship', value);

  String? get insurancePolicyNumber =>
      getField<String>('insurance_policy_number');
  set insurancePolicyNumber(String? value) =>
      setField<String>('insurance_policy_number', value);

  String? get idCardNumber => getField<String>('id_card_number');
  set idCardNumber(String? value) => setField<String>('id_card_number', value);

  DateTime? get idCardIssueDate => getField<DateTime>('id_card_issue_date');
  set idCardIssueDate(DateTime? value) =>
      setField<DateTime>('id_card_issue_date', value);

  DateTime? get idCardExpirationDate =>
      getField<DateTime>('id_card_expiration_date');
  set idCardExpirationDate(DateTime? value) =>
      setField<DateTime>('id_card_expiration_date', value);

  String? get nationalId => getField<String>('national_id');
  set nationalId(String? value) => setField<String>('national_id', value);

  String? get nationalIdEncrypted => getField<String>('national_id_encrypted');
  set nationalIdEncrypted(String? value) =>
      setField<String>('national_id_encrypted', value);

  String? get passportNumber => getField<String>('passport_number');
  set passportNumber(String? value) =>
      setField<String>('passport_number', value);

  String? get religion => getField<String>('religion');
  set religion(String? value) => setField<String>('religion', value);

  String? get ethnicity => getField<String>('ethnicity');
  set ethnicity(String? value) => setField<String>('ethnicity', value);

  String? get verificationStatus => getField<String>('verification_status');
  set verificationStatus(String? value) =>
      setField<String>('verification_status', value);

  DateTime? get verifiedAt => getField<DateTime>('verified_at');
  set verifiedAt(DateTime? value) => setField<DateTime>('verified_at', value);

  String? get verifiedBy => getField<String>('verified_by');
  set verifiedBy(String? value) => setField<String>('verified_by', value);

  dynamic? get verificationDocuments =>
      getField<dynamic>('verification_documents');
  set verificationDocuments(dynamic? value) =>
      setField<dynamic>('verification_documents', value);

  dynamic? get notificationPreferences =>
      getField<dynamic>('notification_preferences');
  set notificationPreferences(dynamic? value) =>
      setField<dynamic>('notification_preferences', value);

  dynamic? get privacySettings => getField<dynamic>('privacy_settings');
  set privacySettings(dynamic? value) =>
      setField<dynamic>('privacy_settings', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String? get profilePictureUrl => getField<String>('profile_picture_url');
  set profilePictureUrl(String? value) =>
      setField<String>('profile_picture_url', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);
}
