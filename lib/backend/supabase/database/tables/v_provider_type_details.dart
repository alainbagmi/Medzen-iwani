import '../database.dart';

class VProviderTypeDetailsTable extends SupabaseTable<VProviderTypeDetailsRow> {
  @override
  String get tableName => 'v_provider_type_details';

  @override
  VProviderTypeDetailsRow createRow(Map<String, dynamic> data) =>
      VProviderTypeDetailsRow(data);
}

class VProviderTypeDetailsRow extends SupabaseDataRow {
  VProviderTypeDetailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VProviderTypeDetailsTable();

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get professionalRole => getField<String>('professional_role');
  set professionalRole(String? value) =>
      setField<String>('professional_role', value);

  String? get professionalRoleLegacy =>
      getField<String>('professional_role_legacy');
  set professionalRoleLegacy(String? value) =>
      setField<String>('professional_role_legacy', value);

  String? get typeCode => getField<String>('type_code');
  set typeCode(String? value) => setField<String>('type_code', value);

  String? get roleDescription => getField<String>('role_description');
  set roleDescription(String? value) =>
      setField<String>('role_description', value);

  bool? get requiresMedicalLicense =>
      getField<bool>('requires_medical_license');
  set requiresMedicalLicense(bool? value) =>
      setField<bool>('requires_medical_license', value);

  bool? get requiresBoardCertification =>
      getField<bool>('requires_board_certification');
  set requiresBoardCertification(bool? value) =>
      setField<bool>('requires_board_certification', value);

  bool? get canPrescribeMedication =>
      getField<bool>('can_prescribe_medication');
  set canPrescribeMedication(bool? value) =>
      setField<bool>('can_prescribe_medication', value);

  bool? get supervisionRequired => getField<bool>('supervision_required');
  set supervisionRequired(bool? value) =>
      setField<bool>('supervision_required', value);

  String? get medicalLicenseNumber =>
      getField<String>('medical_license_number');
  set medicalLicenseNumber(String? value) =>
      setField<String>('medical_license_number', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);

  int? get yearsOfExperience => getField<int>('years_of_experience');
  set yearsOfExperience(int? value) =>
      setField<int>('years_of_experience', value);
}
