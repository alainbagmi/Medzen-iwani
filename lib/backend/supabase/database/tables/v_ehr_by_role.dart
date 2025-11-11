import '../database.dart';

class VEhrByRoleTable extends SupabaseTable<VEhrByRoleRow> {
  @override
  String get tableName => 'v_ehr_by_role';

  @override
  VEhrByRoleRow createRow(Map<String, dynamic> data) => VEhrByRoleRow(data);
}

class VEhrByRoleRow extends SupabaseDataRow {
  VEhrByRoleRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VEhrByRoleTable();

  String? get userRole => getField<String>('user_role');
  set userRole(String? value) => setField<String>('user_role', value);

  int? get ehrCount => getField<int>('ehr_count');
  set ehrCount(int? value) => setField<int>('ehr_count', value);

  int? get uniqueTemplates => getField<int>('unique_templates');
  set uniqueTemplates(int? value) => setField<int>('unique_templates', value);

  int? get activeCount => getField<int>('active_count');
  set activeCount(int? value) => setField<int>('active_count', value);

  int? get createdLastWeek => getField<int>('created_last_week');
  set createdLastWeek(int? value) => setField<int>('created_last_week', value);

  DateTime? get firstCreated => getField<DateTime>('first_created');
  set firstCreated(DateTime? value) =>
      setField<DateTime>('first_created', value);

  DateTime? get lastCreated => getField<DateTime>('last_created');
  set lastCreated(DateTime? value) => setField<DateTime>('last_created', value);
}
