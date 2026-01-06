import '../database.dart';

class AiAssistantsTable extends SupabaseTable<AiAssistantsRow> {
  @override
  String get tableName => 'ai_assistants';

  @override
  AiAssistantsRow createRow(Map<String, dynamic> data) => AiAssistantsRow(data);
}

class AiAssistantsRow extends SupabaseDataRow {
  AiAssistantsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiAssistantsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get assistantName => getField<String>('assistant_name')!;
  set assistantName(String value) => setField<String>('assistant_name', value);

  String get assistantType => getField<String>('assistant_type')!;
  set assistantType(String value) => setField<String>('assistant_type', value);

  String? get modelVersion => getField<String>('model_version');
  set modelVersion(String? value) => setField<String>('model_version', value);

  String get systemPrompt => getField<String>('system_prompt')!;
  set systemPrompt(String value) => setField<String>('system_prompt', value);

  List<String> get capabilities => getListField<String>('capabilities');
  set capabilities(List<String>? value) =>
      setListField<String>('capabilities', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get iconUrl => getField<String>('icon_url');
  set iconUrl(String? value) => setField<String>('icon_url', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  int? get responseTimeAvgMs => getField<int>('response_time_avg_ms');
  set responseTimeAvgMs(int? value) =>
      setField<int>('response_time_avg_ms', value);

  double? get accuracyScore => getField<double>('accuracy_score');
  set accuracyScore(double? value) => setField<double>('accuracy_score', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  dynamic? get modelConfig => getField<dynamic>('model_config');
  set modelConfig(dynamic? value) => setField<dynamic>('model_config', value);
}
