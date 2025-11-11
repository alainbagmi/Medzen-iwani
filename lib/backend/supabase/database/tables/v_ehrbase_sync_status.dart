import '../database.dart';

class VEhrbaseSyncStatusTable extends SupabaseTable<VEhrbaseSyncStatusRow> {
  @override
  String get tableName => 'v_ehrbase_sync_status';

  @override
  VEhrbaseSyncStatusRow createRow(Map<String, dynamic> data) =>
      VEhrbaseSyncStatusRow(data);
}

class VEhrbaseSyncStatusRow extends SupabaseDataRow {
  VEhrbaseSyncStatusRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VEhrbaseSyncStatusTable();

  String? get tableNameField => getField<String>('table_name');
  set tableNameField(String? value) => setField<String>('table_name', value);

  String? get syncStatus => getField<String>('sync_status');
  set syncStatus(String? value) => setField<String>('sync_status', value);

  int? get count => getField<int>('count');
  set count(int? value) => setField<int>('count', value);

  DateTime? get oldestPending => getField<DateTime>('oldest_pending');
  set oldestPending(DateTime? value) =>
      setField<DateTime>('oldest_pending', value);
}
