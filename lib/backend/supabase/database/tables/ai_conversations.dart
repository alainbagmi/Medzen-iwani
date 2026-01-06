import '../database.dart';

class AiConversationsTable extends SupabaseTable<AiConversationsRow> {
  @override
  String get tableName => 'ai_conversations';

  @override
  AiConversationsRow createRow(Map<String, dynamic> data) =>
      AiConversationsRow(data);
}

class AiConversationsRow extends SupabaseDataRow {
  AiConversationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiConversationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get conversationTitle => getField<String>('conversation_title');
  set conversationTitle(String? value) =>
      setField<String>('conversation_title', value);

  String? get modelVersion => getField<String>('model_version');
  set modelVersion(String? value) => setField<String>('model_version', value);

  dynamic? get context => getField<dynamic>('context');
  set context(dynamic? value) => setField<dynamic>('context', value);

  int? get totalMessages => getField<int>('total_messages');
  set totalMessages(int? value) => setField<int>('total_messages', value);

  int? get totalTokens => getField<int>('total_tokens');
  set totalTokens(int? value) => setField<int>('total_tokens', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get assistantId => getField<String>('assistant_id');
  set assistantId(String? value) => setField<String>('assistant_id', value);

  String? get conversationCategory => getField<String>('conversation_category');
  set conversationCategory(String? value) =>
      setField<String>('conversation_category', value);

  String? get relatedAppointmentId =>
      getField<String>('related_appointment_id');
  set relatedAppointmentId(String? value) =>
      setField<String>('related_appointment_id', value);

  String? get urgencyLevel => getField<String>('urgency_level');
  set urgencyLevel(String? value) => setField<String>('urgency_level', value);

  dynamic? get triageResult => getField<dynamic>('triage_result');
  set triageResult(dynamic? value) => setField<dynamic>('triage_result', value);

  dynamic? get appointmentSuggestions =>
      getField<dynamic>('appointment_suggestions');
  set appointmentSuggestions(dynamic? value) =>
      setField<dynamic>('appointment_suggestions', value);

  bool? get escalatedToProvider => getField<bool>('escalated_to_provider');
  set escalatedToProvider(bool? value) =>
      setField<bool>('escalated_to_provider', value);

  String? get escalatedProviderId => getField<String>('escalated_provider_id');
  set escalatedProviderId(String? value) =>
      setField<String>('escalated_provider_id', value);

  String? get defaultLanguage => getField<String>('default_language');
  set defaultLanguage(String? value) =>
      setField<String>('default_language', value);

  String? get detectedLanguage => getField<String>('detected_language');
  set detectedLanguage(String? value) =>
      setField<String>('detected_language', value);

  String? get languageRegion => getField<String>('language_region');
  set languageRegion(String? value) =>
      setField<String>('language_region', value);

  bool? get ttsEnabled => getField<bool>('tts_enabled');
  set ttsEnabled(bool? value) => setField<bool>('tts_enabled', value);

  String? get preferredVoiceId => getField<String>('preferred_voice_id');
  set preferredVoiceId(String? value) =>
      setField<String>('preferred_voice_id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get preferredLanguage => getField<String>('preferred_language');
  set preferredLanguage(String? value) =>
      setField<String>('preferred_language', value);

  String? get senderId => getField<String>('sender_id');
  set senderId(String? value) => setField<String>('sender_id', value);

  String? get receiverId => getField<String>('receiver_id');
  set receiverId(String? value) => setField<String>('receiver_id', value);
}
