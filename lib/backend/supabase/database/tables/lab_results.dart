import '../database.dart';

class LabResultsTable extends SupabaseTable<LabResultsRow> {
  @override
  String get tableName => 'lab_results';

  @override
  LabResultsRow createRow(Map<String, dynamic> data) => LabResultsRow(data);
}

class LabResultsRow extends SupabaseDataRow {
  LabResultsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LabResultsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get labOrderId => getField<String>('lab_order_id');
  set labOrderId(String? value) => setField<String>('lab_order_id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String get testName => getField<String>('test_name')!;
  set testName(String value) => setField<String>('test_name', value);

  String? get testCode => getField<String>('test_code');
  set testCode(String? value) => setField<String>('test_code', value);

  String get resultValue => getField<String>('result_value')!;
  set resultValue(String value) => setField<String>('result_value', value);

  String? get unit => getField<String>('unit');
  set unit(String? value) => setField<String>('unit', value);

  String? get referenceRange => getField<String>('reference_range');
  set referenceRange(String? value) =>
      setField<String>('reference_range', value);

  String? get abnormalFlag => getField<String>('abnormal_flag');
  set abnormalFlag(String? value) => setField<String>('abnormal_flag', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  String? get performedById => getField<String>('performed_by_id');
  set performedById(String? value) =>
      setField<String>('performed_by_id', value);

  String? get verifiedById => getField<String>('verified_by_id');
  set verifiedById(String? value) => setField<String>('verified_by_id', value);

  DateTime? get resultDate => getField<DateTime>('result_date');
  set resultDate(DateTime? value) => setField<DateTime>('result_date', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get labTestTypeId => getField<String>('lab_test_type_id');
  set labTestTypeId(String? value) =>
      setField<String>('lab_test_type_id', value);

  bool? get ehrbaseSynced => getField<bool>('ehrbase_synced');
  set ehrbaseSynced(bool? value) => setField<bool>('ehrbase_synced', value);

  DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
  set ehrbaseSyncedAt(DateTime? value) =>
      setField<DateTime>('ehrbase_synced_at', value);

  String? get ehrbaseSyncError => getField<String>('ehrbase_sync_error');
  set ehrbaseSyncError(String? value) =>
      setField<String>('ehrbase_sync_error', value);

  int? get ehrbaseRetryCount => getField<int>('ehrbase_retry_count');
  set ehrbaseRetryCount(int? value) =>
      setField<int>('ehrbase_retry_count', value);
}
