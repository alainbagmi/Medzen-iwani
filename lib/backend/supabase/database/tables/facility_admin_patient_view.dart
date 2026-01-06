import '../database.dart';

class FacilityAdminPatientViewTable
    extends SupabaseTable<FacilityAdminPatientViewRow> {
  @override
  String get tableName => 'facility_admin_patient_view';

  @override
  FacilityAdminPatientViewRow createRow(Map<String, dynamic> data) =>
      FacilityAdminPatientViewRow(data);
}

class FacilityAdminPatientViewRow extends SupabaseDataRow {
  FacilityAdminPatientViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityAdminPatientViewTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  String? get idCardNumber => getField<String>('id_card_number');
  set idCardNumber(String? value) => setField<String>('id_card_number', value);

  String? get patientNumber => getField<String>('patient_number');
  set patientNumber(String? value) => setField<String>('patient_number', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  DateTime? get dateOfBirth => getField<DateTime>('date_of_birth');
  set dateOfBirth(DateTime? value) =>
      setField<DateTime>('date_of_birth', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get accountStatus => getField<String>('account_status');
  set accountStatus(String? value) => setField<String>('account_status', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  bool? get isVerified => getField<bool>('is_verified');
  set isVerified(bool? value) => setField<bool>('is_verified', value);

  bool? get emailVerified => getField<bool>('email_verified');
  set emailVerified(bool? value) => setField<bool>('email_verified', value);

  bool? get phoneVerified => getField<bool>('phone_verified');
  set phoneVerified(bool? value) => setField<bool>('phone_verified', value);

  String? get verificationStatus => getField<String>('verification_status');
  set verificationStatus(String? value) =>
      setField<String>('verification_status', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get facilityName => getField<String>('facility_name');
  set facilityName(String? value) => setField<String>('facility_name', value);

  String? get facilityCode => getField<String>('facility_code');
  set facilityCode(String? value) => setField<String>('facility_code', value);

  List<String> get connectionTypes => getListField<String>('connection_types');
  set connectionTypes(List<String>? value) =>
      setListField<String>('connection_types', value);

  DateTime? get mostRecentInteraction =>
      getField<DateTime>('most_recent_interaction');
  set mostRecentInteraction(DateTime? value) =>
      setField<DateTime>('most_recent_interaction', value);

  DateTime? get patientSince => getField<DateTime>('patient_since');
  set patientSince(DateTime? value) =>
      setField<DateTime>('patient_since', value);

  DateTime? get accountCreatedAt => getField<DateTime>('account_created_at');
  set accountCreatedAt(DateTime? value) =>
      setField<DateTime>('account_created_at', value);

  DateTime? get lastLoginAt => getField<DateTime>('last_login_at');
  set lastLoginAt(DateTime? value) =>
      setField<DateTime>('last_login_at', value);
}
