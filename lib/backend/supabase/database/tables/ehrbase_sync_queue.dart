import '../database.dart';

class EhrbaseSyncQueueTable extends SupabaseTable<EhrbaseSyncQueueRow> {
  @override
  String get tableName => 'ehrbase_sync_queue';

  @override
  EhrbaseSyncQueueRow createRow(Map<String, dynamic> data) =>
      EhrbaseSyncQueueRow(data);
}

class EhrbaseSyncQueueRow extends SupabaseDataRow {
  EhrbaseSyncQueueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EhrbaseSyncQueueTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get tableNameField => getField<String>('table_name')!;
  set tableNameField(String value) => setField<String>('table_name', value);

  String get recordId => getField<String>('record_id')!;
  set recordId(String value) => setField<String>('record_id', value);

  String get templateId => getField<String>('template_id')!;
  set templateId(String value) => setField<String>('template_id', value);

  String? get syncStatus => getField<String>('sync_status');
  set syncStatus(String? value) => setField<String>('sync_status', value);

  int? get retryCount => getField<int>('retry_count');
  set retryCount(int? value) => setField<int>('retry_count', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  String? get ehrbaseCompositionId =>
      getField<String>('ehrbase_composition_id');
  set ehrbaseCompositionId(String? value) =>
      setField<String>('ehrbase_composition_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get processedAt => getField<DateTime>('processed_at');
  set processedAt(DateTime? value) => setField<DateTime>('processed_at', value);

  String? get userRole => getField<String>('user_role');
  set userRole(String? value) => setField<String>('user_role', value);

  String? get compositionCategory => getField<String>('composition_category');
  set compositionCategory(String? value) =>
      setField<String>('composition_category', value);

  String? get syncType => getField<String>('sync_type');
  set syncType(String? value) => setField<String>('sync_type', value);

  dynamic? get dataSnapshot => getField<dynamic>('data_snapshot');
  set dataSnapshot(dynamic? value) => setField<dynamic>('data_snapshot', value);

  DateTime? get lastRetryAt => getField<DateTime>('last_retry_at');
  set lastRetryAt(DateTime? value) =>
      setField<DateTime>('last_retry_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get ehrId => getField<String>('ehr_id');
  set ehrId(String? value) => setField<String>('ehr_id', value);
}
