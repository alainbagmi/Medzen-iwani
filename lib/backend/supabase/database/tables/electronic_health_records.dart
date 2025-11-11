import '../database.dart';

class ElectronicHealthRecordsTable
    extends SupabaseTable<ElectronicHealthRecordsRow> {
  @override
  String get tableName => 'electronic_health_records';

  @override
  ElectronicHealthRecordsRow createRow(Map<String, dynamic> data) =>
      ElectronicHealthRecordsRow(data);
}

class ElectronicHealthRecordsRow extends SupabaseDataRow {
  ElectronicHealthRecordsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ElectronicHealthRecordsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String get ehrId => getField<String>('ehr_id')!;
  set ehrId(String value) => setField<String>('ehr_id', value);

  String? get ehrStatus => getField<String>('ehr_status');
  set ehrStatus(String? value) => setField<String>('ehr_status', value);

  String? get systemId => getField<String>('system_id');
  set systemId(String? value) => setField<String>('system_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get userRole => getField<String>('user_role');
  set userRole(String? value) => setField<String>('user_role', value);

  String? get primaryTemplateId => getField<String>('primary_template_id');
  set primaryTemplateId(String? value) =>
      setField<String>('primary_template_id', value);
}
