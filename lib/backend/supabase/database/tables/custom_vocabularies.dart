import '../database.dart';

class CustomVocabulariesTable extends SupabaseTable<CustomVocabulariesRow> {
  @override
  String get tableName => 'custom_vocabularies';

  @override
  CustomVocabulariesRow createRow(Map<String, dynamic> data) =>
      CustomVocabulariesRow(data);
}

class CustomVocabulariesRow extends SupabaseDataRow {
  CustomVocabulariesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CustomVocabulariesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get displayName => getField<String>('display_name')!;
  set displayName(String value) => setField<String>('display_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String get languageCode => getField<String>('language_code')!;
  set languageCode(String value) => setField<String>('language_code', value);

  String get languageName => getField<String>('language_name')!;
  set languageName(String value) => setField<String>('language_name', value);

  dynamic get phrases => getField<dynamic>('phrases')!;
  set phrases(dynamic value) => setField<dynamic>('phrases', value);

  String? get awsVocabularyName => getField<String>('aws_vocabulary_name');
  set awsVocabularyName(String? value) =>
      setField<String>('aws_vocabulary_name', value);

  String? get vocabularyStatus => getField<String>('vocabulary_status');
  set vocabularyStatus(String? value) =>
      setField<String>('vocabulary_status', value);

  String? get awsVocabularyArn => getField<String>('aws_vocabulary_arn');
  set awsVocabularyArn(String? value) =>
      setField<String>('aws_vocabulary_arn', value);

  DateTime? get lastModifiedByAws => getField<DateTime>('last_modified_by_aws');
  set lastModifiedByAws(DateTime? value) =>
      setField<DateTime>('last_modified_by_aws', value);

  String? get failureReason => getField<String>('failure_reason');
  set failureReason(String? value) => setField<String>('failure_reason', value);

  String? get vocabularyType => getField<String>('vocabulary_type');
  set vocabularyType(String? value) =>
      setField<String>('vocabulary_type', value);

  String? get specialty => getField<String>('specialty');
  set specialty(String? value) => setField<String>('specialty', value);

  String? get region => getField<String>('region');
  set region(String? value) => setField<String>('region', value);

  int? get timesUsed => getField<int>('times_used');
  set timesUsed(int? value) => setField<int>('times_used', value);

  DateTime? get lastUsedAt => getField<DateTime>('last_used_at');
  set lastUsedAt(DateTime? value) => setField<DateTime>('last_used_at', value);

  int? get version => getField<int>('version');
  set version(int? value) => setField<int>('version', value);

  String? get parentVocabularyId => getField<String>('parent_vocabulary_id');
  set parentVocabularyId(String? value) =>
      setField<String>('parent_vocabulary_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);
}
