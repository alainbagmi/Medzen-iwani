import '../database.dart';

class SearchIndexesTable extends SupabaseTable<SearchIndexesRow> {
  @override
  String get tableName => 'search_indexes';

  @override
  SearchIndexesRow createRow(Map<String, dynamic> data) =>
      SearchIndexesRow(data);
}

class SearchIndexesRow extends SupabaseDataRow {
  SearchIndexesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SearchIndexesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get entityType => getField<String>('entity_type')!;
  set entityType(String value) => setField<String>('entity_type', value);

  String get entityId => getField<String>('entity_id')!;
  set entityId(String value) => setField<String>('entity_id', value);

  String? get typesenseId => getField<String>('typesense_id');
  set typesenseId(String? value) => setField<String>('typesense_id', value);

  dynamic get indexedData => getField<dynamic>('indexed_data')!;
  set indexedData(dynamic value) => setField<dynamic>('indexed_data', value);

  DateTime? get lastSyncedAt => getField<DateTime>('last_synced_at');
  set lastSyncedAt(DateTime? value) =>
      setField<DateTime>('last_synced_at', value);

  String? get syncStatus => getField<String>('sync_status');
  set syncStatus(String? value) => setField<String>('sync_status', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
