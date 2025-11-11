import '../database.dart';

class VPendingProviderApplicationsTable
    extends SupabaseTable<VPendingProviderApplicationsRow> {
  @override
  String get tableName => 'v_pending_provider_applications';

  @override
  VPendingProviderApplicationsRow createRow(Map<String, dynamic> data) =>
      VPendingProviderApplicationsRow(data);
}

class VPendingProviderApplicationsRow extends SupabaseDataRow {
  VPendingProviderApplicationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VPendingProviderApplicationsTable();

  String? get providerProfileId => getField<String>('provider_profile_id');
  set providerProfileId(String? value) =>
      setField<String>('provider_profile_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get providerNumber => getField<String>('provider_number');
  set providerNumber(String? value) =>
      setField<String>('provider_number', value);

  String? get medicalLicenseNumber =>
      getField<String>('medical_license_number');
  set medicalLicenseNumber(String? value) =>
      setField<String>('medical_license_number', value);

  String? get professionalRole => getField<String>('professional_role');
  set professionalRole(String? value) =>
      setField<String>('professional_role', value);

  String? get primarySpecialization =>
      getField<String>('primary_specialization');
  set primarySpecialization(String? value) =>
      setField<String>('primary_specialization', value);

  int? get yearsOfExperience => getField<int>('years_of_experience');
  set yearsOfExperience(int? value) =>
      setField<int>('years_of_experience', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get facilityName => getField<String>('facility_name');
  set facilityName(String? value) => setField<String>('facility_name', value);

  String? get facilityType => getField<String>('facility_type');
  set facilityType(String? value) => setField<String>('facility_type', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);

  DateTime? get applicationSubmittedAt =>
      getField<DateTime>('application_submitted_at');
  set applicationSubmittedAt(DateTime? value) =>
      setField<DateTime>('application_submitted_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
