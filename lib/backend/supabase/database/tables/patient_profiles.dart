import '../database.dart';

class PatientProfilesTable extends SupabaseTable<PatientProfilesRow> {
  @override
  String get tableName => 'patient_profiles';

  @override
  PatientProfilesRow createRow(Map<String, dynamic> data) =>
      PatientProfilesRow(data);
}

class PatientProfilesRow extends SupabaseDataRow {
  PatientProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PatientProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get patientNumber => getField<String>('patient_number')!;
  set patientNumber(String value) => setField<String>('patient_number', value);

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

  dynamic? get cumulativeMedicalRecord =>
      getField<dynamic>('cumulative_medical_record');
  set cumulativeMedicalRecord(dynamic? value) =>
      setField<dynamic>('cumulative_medical_record', value);

  DateTime? get medicalRecordLastUpdatedAt =>
      getField<DateTime>('medical_record_last_updated_at');
  set medicalRecordLastUpdatedAt(DateTime? value) =>
      setField<DateTime>('medical_record_last_updated_at', value);

  String? get medicalRecordLastSoapNoteId =>
      getField<String>('medical_record_last_soap_note_id');
  set medicalRecordLastSoapNoteId(String? value) =>
      setField<String>('medical_record_last_soap_note_id', value);
}
