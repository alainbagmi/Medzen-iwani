import '../database.dart';

class NurseProfilesTable extends SupabaseTable<NurseProfilesRow> {
  @override
  String get tableName => 'nurse_profiles';

  @override
  NurseProfilesRow createRow(Map<String, dynamic> data) =>
      NurseProfilesRow(data);
}

class NurseProfilesRow extends SupabaseDataRow {
  NurseProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NurseProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get nurseNumber => getField<String>('nurse_number')!;
  set nurseNumber(String value) => setField<String>('nurse_number', value);

  String get nursingLicenseNumber =>
      getField<String>('nursing_license_number')!;
  set nursingLicenseNumber(String value) =>
      setField<String>('nursing_license_number', value);

  DateTime get licenseExpiry => getField<DateTime>('license_expiry')!;
  set licenseExpiry(DateTime value) =>
      setField<DateTime>('license_expiry', value);

  String? get nursingType => getField<String>('nursing_type');
  set nursingType(String? value) => setField<String>('nursing_type', value);

  List<String> get specializations => getListField<String>('specializations');
  set specializations(List<String>? value) =>
      setListField<String>('specializations', value);

  List<String> get certifications => getListField<String>('certifications');
  set certifications(List<String>? value) =>
      setListField<String>('certifications', value);

  String? get department => getField<String>('department');
  set department(String? value) => setField<String>('department', value);

  String? get shiftPreference => getField<String>('shift_preference');
  set shiftPreference(String? value) =>
      setField<String>('shift_preference', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
