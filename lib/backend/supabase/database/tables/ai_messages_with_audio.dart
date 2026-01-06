import '../database.dart';

class AiMessagesWithAudioTable extends SupabaseTable<AiMessagesWithAudioRow> {
  @override
  String get tableName => 'ai_messages_with_audio';

  @override
  AiMessagesWithAudioRow createRow(Map<String, dynamic> data) =>
      AiMessagesWithAudioRow(data);
}

class AiMessagesWithAudioRow extends SupabaseDataRow {
  AiMessagesWithAudioRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiMessagesWithAudioTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get conversationId => getField<String>('conversation_id');
  set conversationId(String? value) =>
      setField<String>('conversation_id', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  int? get tokensUsed => getField<int>('tokens_used');
  set tokensUsed(int? value) => setField<int>('tokens_used', value);

  String? get modelVersion => getField<String>('model_version');
  set modelVersion(String? value) => setField<String>('model_version', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  dynamic? get messageMetadata => getField<dynamic>('message_metadata');
  set messageMetadata(dynamic? value) =>
      setField<dynamic>('message_metadata', value);

  double? get confidenceScore => getField<double>('confidence_score');
  set confidenceScore(double? value) =>
      setField<double>('confidence_score', value);

  List<String> get sources => getListField<String>('sources');
  set sources(List<String>? value) => setListField<String>('sources', value);

  dynamic? get actionItems => getField<dynamic>('action_items');
  set actionItems(dynamic? value) => setField<dynamic>('action_items', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  dynamic? get speechConfig => getField<dynamic>('speech_config');
  set speechConfig(dynamic? value) => setField<dynamic>('speech_config', value);

  double? get languageConfidence => getField<double>('language_confidence');
  set languageConfidence(double? value) =>
      setField<double>('language_confidence', value);

  bool? get detectedCodeMixing => getField<bool>('detected_code_mixing');
  set detectedCodeMixing(bool? value) =>
      setField<bool>('detected_code_mixing', value);

  dynamic? get languageAlternatives =>
      getField<dynamic>('language_alternatives');
  set languageAlternatives(dynamic? value) =>
      setField<dynamic>('language_alternatives', value);

  String? get audioUrl => getField<String>('audio_url');
  set audioUrl(String? value) => setField<String>('audio_url', value);

  String? get ttsVoiceId => getField<String>('tts_voice_id');
  set ttsVoiceId(String? value) => setField<String>('tts_voice_id', value);

  double? get audioDurationSeconds =>
      getField<double>('audio_duration_seconds');
  set audioDurationSeconds(double? value) =>
      setField<double>('audio_duration_seconds', value);

  DateTime? get audioGeneratedAt => getField<DateTime>('audio_generated_at');
  set audioGeneratedAt(DateTime? value) =>
      setField<DateTime>('audio_generated_at', value);

  bool? get audioExpired => getField<bool>('audio_expired');
  set audioExpired(bool? value) => setField<bool>('audio_expired', value);
}
