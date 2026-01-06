import '../database.dart';

class AiConversationLanguageStatsTable
    extends SupabaseTable<AiConversationLanguageStatsRow> {
  @override
  String get tableName => 'ai_conversation_language_stats';

  @override
  AiConversationLanguageStatsRow createRow(Map<String, dynamic> data) =>
      AiConversationLanguageStatsRow(data);
}

class AiConversationLanguageStatsRow extends SupabaseDataRow {
  AiConversationLanguageStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiConversationLanguageStatsTable();

  String? get detectedLanguage => getField<String>('detected_language');
  set detectedLanguage(String? value) =>
      setField<String>('detected_language', value);

  String? get languageRegion => getField<String>('language_region');
  set languageRegion(String? value) =>
      setField<String>('language_region', value);

  int? get conversationCount => getField<int>('conversation_count');
  set conversationCount(int? value) =>
      setField<int>('conversation_count', value);

  int? get uniqueUsers => getField<int>('unique_users');
  set uniqueUsers(int? value) => setField<int>('unique_users', value);

  double? get avgMessagesPerConversation =>
      getField<double>('avg_messages_per_conversation');
  set avgMessagesPerConversation(double? value) =>
      setField<double>('avg_messages_per_conversation', value);

  DateTime? get lastConversationDate =>
      getField<DateTime>('last_conversation_date');
  set lastConversationDate(DateTime? value) =>
      setField<DateTime>('last_conversation_date', value);

  DateTime? get firstConversationDate =>
      getField<DateTime>('first_conversation_date');
  set firstConversationDate(DateTime? value) =>
      setField<DateTime>('first_conversation_date', value);
}
