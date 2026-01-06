import '../database.dart';

class MedicalProviderProfilesTable
    extends SupabaseTable<MedicalProviderProfilesRow> {
  @override
  String get tableName => 'medical_provider_profiles';

  @override
  MedicalProviderProfilesRow createRow(Map<String, dynamic> data) =>
      MedicalProviderProfilesRow(data);
}

class MedicalProviderProfilesRow extends SupabaseDataRow {
  MedicalProviderProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalProviderProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get providerNumber => getField<String>('provider_number')!;
  set providerNumber(String value) =>
      setField<String>('provider_number', value);

  String? get uniqueIdentifier => getField<String>('unique_identifier');
  set uniqueIdentifier(String? value) =>
      setField<String>('unique_identifier', value);

  String get medicalLicenseNumber =>
      getField<String>('medical_license_number')!;
  set medicalLicenseNumber(String value) =>
      setField<String>('medical_license_number', value);

  String? get professionalRegistrationNumber =>
      getField<String>('professional_registration_number');
  set professionalRegistrationNumber(String? value) =>
      setField<String>('professional_registration_number', value);

  String? get licenseIssuingAuthority =>
      getField<String>('license_issuing_authority');
  set licenseIssuingAuthority(String? value) =>
      setField<String>('license_issuing_authority', value);

  DateTime get licenseExpiryDate => getField<DateTime>('license_expiry_date')!;
  set licenseExpiryDate(DateTime value) =>
      setField<DateTime>('license_expiry_date', value);

  String get professionalRole => getField<String>('professional_role')!;
  set professionalRole(String value) =>
      setField<String>('professional_role', value);

  String? get primarySpecialization =>
      getField<String>('primary_specialization');
  set primarySpecialization(String? value) =>
      setField<String>('primary_specialization', value);

  List<String> get secondarySpecializations =>
      getListField<String>('secondary_specializations');
  set secondarySpecializations(List<String>? value) =>
      setListField<String>('secondary_specializations', value);

  List<String> get subSpecialties => getListField<String>('sub_specialties');
  set subSpecialties(List<String>? value) =>
      setListField<String>('sub_specialties', value);

  List<String> get areasOfExpertise =>
      getListField<String>('areas_of_expertise');
  set areasOfExpertise(List<String>? value) =>
      setListField<String>('areas_of_expertise', value);

  bool? get isSpecialist => getField<bool>('is_specialist');
  set isSpecialist(bool? value) => setField<bool>('is_specialist', value);

  String? get medicalSchool => getField<String>('medical_school');
  set medicalSchool(String? value) => setField<String>('medical_school', value);

  int? get graduationYear => getField<int>('graduation_year');
  set graduationYear(int? value) => setField<int>('graduation_year', value);

  List<String> get qualifications => getListField<String>('qualifications');
  set qualifications(List<String>? value) =>
      setListField<String>('qualifications', value);

  List<String> get residencyPrograms =>
      getListField<String>('residency_programs');
  set residencyPrograms(List<String>? value) =>
      setListField<String>('residency_programs', value);

  List<String> get fellowshipPrograms =>
      getListField<String>('fellowship_programs');
  set fellowshipPrograms(List<String>? value) =>
      setListField<String>('fellowship_programs', value);

  List<String> get boardCertifications =>
      getListField<String>('board_certifications');
  set boardCertifications(List<String>? value) =>
      setListField<String>('board_certifications', value);

  int? get continuingEducationCredits =>
      getField<int>('continuing_education_credits');
  set continuingEducationCredits(int? value) =>
      setField<int>('continuing_education_credits', value);

  int? get yearsOfExperience => getField<int>('years_of_experience');
  set yearsOfExperience(int? value) =>
      setField<int>('years_of_experience', value);

  dynamic? get previousPositions => getField<dynamic>('previous_positions');
  set previousPositions(dynamic? value) =>
      setField<dynamic>('previous_positions', value);

  List<String> get hospitalAffiliations =>
      getListField<String>('hospital_affiliations');
  set hospitalAffiliations(List<String>? value) =>
      setListField<String>('hospital_affiliations', value);

  List<String> get professionalMemberships =>
      getListField<String>('professional_memberships');
  set professionalMemberships(List<String>? value) =>
      setListField<String>('professional_memberships', value);

  List<String> get awards => getListField<String>('awards');
  set awards(List<String>? value) => setListField<String>('awards', value);

  List<String> get researchInterests =>
      getListField<String>('research_interests');
  set researchInterests(List<String>? value) =>
      setListField<String>('research_interests', value);

  String? get practiceType => getField<String>('practice_type');
  set practiceType(String? value) => setField<String>('practice_type', value);

  double? get consultationFee => getField<double>('consultation_fee');
  set consultationFee(double? value) =>
      setField<double>('consultation_fee', value);

  String? get consultationFeeRange =>
      getField<String>('consultation_fee_range');
  set consultationFeeRange(String? value) =>
      setField<String>('consultation_fee_range', value);

  int? get consultationDurationMinutes =>
      getField<int>('consultation_duration_minutes');
  set consultationDurationMinutes(int? value) =>
      setField<int>('consultation_duration_minutes', value);

  int? get maxPatientsPerDay => getField<int>('max_patients_per_day');
  set maxPatientsPerDay(int? value) =>
      setField<int>('max_patients_per_day', value);

  bool? get acceptsNewPatients => getField<bool>('accepts_new_patients');
  set acceptsNewPatients(bool? value) =>
      setField<bool>('accepts_new_patients', value);

  bool? get acceptsEmergencyCalls => getField<bool>('accepts_emergency_calls');
  set acceptsEmergencyCalls(bool? value) =>
      setField<bool>('accepts_emergency_calls', value);

  List<String> get languagesSpoken => getListField<String>('languages_spoken');
  set languagesSpoken(List<String>? value) =>
      setListField<String>('languages_spoken', value);

  bool? get telemedicineSetupComplete =>
      getField<bool>('telemedicine_setup_complete');
  set telemedicineSetupComplete(bool? value) =>
      setField<bool>('telemedicine_setup_complete', value);

  bool? get videoConsultationEnabled =>
      getField<bool>('video_consultation_enabled');
  set videoConsultationEnabled(bool? value) =>
      setField<bool>('video_consultation_enabled', value);

  bool? get audioConsultationEnabled =>
      getField<bool>('audio_consultation_enabled');
  set audioConsultationEnabled(bool? value) =>
      setField<bool>('audio_consultation_enabled', value);

  bool? get chatConsultationEnabled =>
      getField<bool>('chat_consultation_enabled');
  set chatConsultationEnabled(bool? value) =>
      setField<bool>('chat_consultation_enabled', value);

  bool? get ussdConsultationEnabled =>
      getField<bool>('ussd_consultation_enabled');
  set ussdConsultationEnabled(bool? value) =>
      setField<bool>('ussd_consultation_enabled', value);

  int? get totalConsultations => getField<int>('total_consultations');
  set totalConsultations(int? value) =>
      setField<int>('total_consultations', value);

  double? get patientSatisfactionAvg =>
      getField<double>('patient_satisfaction_avg');
  set patientSatisfactionAvg(double? value) =>
      setField<double>('patient_satisfaction_avg', value);

  int? get responseTimeAvgMinutes => getField<int>('response_time_avg_minutes');
  set responseTimeAvgMinutes(int? value) =>
      setField<int>('response_time_avg_minutes', value);

  double? get consultationCompletionRate =>
      getField<double>('consultation_completion_rate');
  set consultationCompletionRate(double? value) =>
      setField<double>('consultation_completion_rate', value);

  bool? get contentCreatorStatus => getField<bool>('content_creator_status');
  set contentCreatorStatus(bool? value) =>
      setField<bool>('content_creator_status', value);

  int? get totalPostsCreated => getField<int>('total_posts_created');
  set totalPostsCreated(int? value) =>
      setField<int>('total_posts_created', value);

  int? get totalFollowers => getField<int>('total_followers');
  set totalFollowers(int? value) => setField<int>('total_followers', value);

  double? get contentEngagementScore =>
      getField<double>('content_engagement_score');
  set contentEngagementScore(double? value) =>
      setField<double>('content_engagement_score', value);

  bool? get backgroundCheckCompleted =>
      getField<bool>('background_check_completed');
  set backgroundCheckCompleted(bool? value) =>
      setField<bool>('background_check_completed', value);

  DateTime? get backgroundCheckDate =>
      getField<DateTime>('background_check_date');
  set backgroundCheckDate(DateTime? value) =>
      setField<DateTime>('background_check_date', value);

  bool? get malpracticeInsuranceValid =>
      getField<bool>('malpractice_insurance_valid');
  set malpracticeInsuranceValid(bool? value) =>
      setField<bool>('malpractice_insurance_valid', value);

  DateTime? get malpracticeInsuranceExpiry =>
      getField<DateTime>('malpractice_insurance_expiry');
  set malpracticeInsuranceExpiry(DateTime? value) =>
      setField<DateTime>('malpractice_insurance_expiry', value);

  String? get availabilityStatus => getField<String>('availability_status');
  set availabilityStatus(String? value) =>
      setField<String>('availability_status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String get applicationStatus => getField<String>('application_status')!;
  set applicationStatus(String value) =>
      setField<String>('application_status', value);

  String? get rejectionReason => getField<String>('rejection_reason');
  set rejectionReason(String? value) =>
      setField<String>('rejection_reason', value);

  DateTime? get approvedAt => getField<DateTime>('approved_at');
  set approvedAt(DateTime? value) => setField<DateTime>('approved_at', value);

  String? get approvedById => getField<String>('approved_by_id');
  set approvedById(String? value) => setField<String>('approved_by_id', value);

  DateTime? get revokedAt => getField<DateTime>('revoked_at');
  set revokedAt(DateTime? value) => setField<DateTime>('revoked_at', value);

  String? get revokedById => getField<String>('revoked_by_id');
  set revokedById(String? value) => setField<String>('revoked_by_id', value);

  String? get primarySpecialtyId => getField<String>('primary_specialty_id');
  set primarySpecialtyId(String? value) =>
      setField<String>('primary_specialty_id', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get professionalRoleLegacy =>
      getField<String>('professional_role_legacy');
  set professionalRoleLegacy(String? value) =>
      setField<String>('professional_role_legacy', value);
}
