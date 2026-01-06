import '../database.dart';

class CustomVocabularyAnalyticsTable
    extends SupabaseTable<CustomVocabularyAnalyticsRow> {
  @override
  String get tableName => 'custom_vocabulary_analytics';

  @override
  CustomVocabularyAnalyticsRow createRow(Map<String, dynamic> data) =>
      CustomVocabularyAnalyticsRow(data);
}

class CustomVocabularyAnalyticsRow extends SupabaseDataRow {
  CustomVocabularyAnalyticsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CustomVocabularyAnalyticsTable();

  String? get languageCode => getField<String>('language_code');
  set languageCode(String? value) => setField<String>('language_code', value);

  String? get languageName => getField<String>('language_name');
  set languageName(String? value) => setField<String>('language_name', value);

  String? get vocabularyType => getField<String>('vocabulary_type');
  set vocabularyType(String? value) =>
      setField<String>('vocabulary_type', value);

  String? get region => getField<String>('region');
  set region(String? value) => setField<String>('region', value);

  int? get totalVocabularies => getField<int>('total_vocabularies');
  set totalVocabularies(int? value) =>
      setField<int>('total_vocabularies', value);

  int? get readyVocabularies => getField<int>('ready_vocabularies');
  set readyVocabularies(int? value) =>
      setField<int>('ready_vocabularies', value);

  int? get pendingVocabularies => getField<int>('pending_vocabularies');
  set pendingVocabularies(int? value) =>
      setField<int>('pending_vocabularies', value);

  int? get failedVocabularies => getField<int>('failed_vocabularies');
  set failedVocabularies(int? value) =>
      setField<int>('failed_vocabularies', value);

  int? get totalUsage => getField<int>('total_usage');
  set totalUsage(int? value) => setField<int>('total_usage', value);

  DateTime? get lastUsedAt => getField<DateTime>('last_used_at');
  set lastUsedAt(DateTime? value) => setField<DateTime>('last_used_at', value);

  int? get uniqueCreators => getField<int>('unique_creators');
  set uniqueCreators(int? value) => setField<int>('unique_creators', value);
}
