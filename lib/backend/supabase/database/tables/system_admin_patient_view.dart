import '../database.dart';

class SystemAdminPatientViewTable
    extends SupabaseTable<SystemAdminPatientViewRow> {
  @override
  String get tableName => 'system_admin_patient_view';

  @override
  SystemAdminPatientViewRow createRow(Map<String, dynamic> data) =>
      SystemAdminPatientViewRow(data);
}

class SystemAdminPatientViewRow extends SupabaseDataRow {
  SystemAdminPatientViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemAdminPatientViewTable();

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

  DateTime? get patientSince => getField<DateTime>('patient_since');
  set patientSince(DateTime? value) =>
      setField<DateTime>('patient_since', value);

  DateTime? get accountCreatedAt => getField<DateTime>('account_created_at');
  set accountCreatedAt(DateTime? value) =>
      setField<DateTime>('account_created_at', value);
}
