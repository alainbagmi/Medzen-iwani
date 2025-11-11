import '../database.dart';

class SearchAnalyticsTable extends SupabaseTable<SearchAnalyticsRow> {
  @override
  String get tableName => 'search_analytics';

  @override
  SearchAnalyticsRow createRow(Map<String, dynamic> data) =>
      SearchAnalyticsRow(data);
}

class SearchAnalyticsRow extends SupabaseDataRow {
  SearchAnalyticsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SearchAnalyticsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get searchQuery => getField<String>('search_query')!;
  set searchQuery(String value) => setField<String>('search_query', value);

  String? get searchType => getField<String>('search_type');
  set searchType(String? value) => setField<String>('search_type', value);

  dynamic? get filters => getField<dynamic>('filters');
  set filters(dynamic? value) => setField<dynamic>('filters', value);

  int? get resultsCount => getField<int>('results_count');
  set resultsCount(int? value) => setField<int>('results_count', value);

  String? get clickedResultId => getField<String>('clicked_result_id');
  set clickedResultId(String? value) =>
      setField<String>('clicked_result_id', value);

  int? get clickedResultPosition => getField<int>('clicked_result_position');
  set clickedResultPosition(int? value) =>
      setField<int>('clicked_result_position', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
