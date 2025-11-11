import '../database.dart';

class SpeechToTextLogsTable extends SupabaseTable<SpeechToTextLogsRow> {
  @override
  String get tableName => 'speech_to_text_logs';

  @override
  SpeechToTextLogsRow createRow(Map<String, dynamic> data) =>
      SpeechToTextLogsRow(data);
}

class SpeechToTextLogsRow extends SupabaseDataRow {
  SpeechToTextLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SpeechToTextLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get audioFileUrl => getField<String>('audio_file_url');
  set audioFileUrl(String? value) => setField<String>('audio_file_url', value);

  String get transcription => getField<String>('transcription')!;
  set transcription(String value) => setField<String>('transcription', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  double? get confidenceScore => getField<double>('confidence_score');
  set confidenceScore(double? value) =>
      setField<double>('confidence_score', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  String? get serviceProvider => getField<String>('service_provider');
  set serviceProvider(String? value) =>
      setField<String>('service_provider', value);

  String? get contextType => getField<String>('context_type');
  set contextType(String? value) => setField<String>('context_type', value);

  String? get relatedEntityType => getField<String>('related_entity_type');
  set relatedEntityType(String? value) =>
      setField<String>('related_entity_type', value);

  String? get relatedEntityId => getField<String>('related_entity_id');
  set relatedEntityId(String? value) =>
      setField<String>('related_entity_id', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
