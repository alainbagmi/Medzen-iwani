import '../database.dart';

class AdminProfilesTable extends SupabaseTable<AdminProfilesRow> {
  @override
  String get tableName => 'admin_profiles';

  @override
  AdminProfilesRow createRow(Map<String, dynamic> data) =>
      AdminProfilesRow(data);
}

class AdminProfilesRow extends SupabaseDataRow {
  AdminProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AdminProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get adminNumber => getField<String>('admin_number')!;
  set adminNumber(String value) => setField<String>('admin_number', value);

  String? get adminLevel => getField<String>('admin_level');
  set adminLevel(String? value) => setField<String>('admin_level', value);

  dynamic? get permissions => getField<dynamic>('permissions');
  set permissions(dynamic? value) => setField<dynamic>('permissions', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get department => getField<String>('department');
  set department(String? value) => setField<String>('department', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
