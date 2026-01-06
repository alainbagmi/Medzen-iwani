import '../database.dart';

class AiLanguageUsageStatsTable extends SupabaseTable<AiLanguageUsageStatsRow> {
  @override
  String get tableName => 'ai_language_usage_stats';

  @override
  AiLanguageUsageStatsRow createRow(Map<String, dynamic> data) =>
      AiLanguageUsageStatsRow(data);
}

class AiLanguageUsageStatsRow extends SupabaseDataRow {
  AiLanguageUsageStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiLanguageUsageStatsTable();

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  int? get totalMessages => getField<int>('total_messages');
  set totalMessages(int? value) => setField<int>('total_messages', value);

  int? get uniqueConversations => getField<int>('unique_conversations');
  set uniqueConversations(int? value) =>
      setField<int>('unique_conversations', value);

  double? get avgConfidence => getField<double>('avg_confidence');
  set avgConfidence(double? value) => setField<double>('avg_confidence', value);

  int? get codeMixingMessages => getField<int>('code_mixing_messages');
  set codeMixingMessages(int? value) =>
      setField<int>('code_mixing_messages', value);

  int? get messagesWithAudio => getField<int>('messages_with_audio');
  set messagesWithAudio(int? value) =>
      setField<int>('messages_with_audio', value);

  DateTime? get firstUsed => getField<DateTime>('first_used');
  set firstUsed(DateTime? value) => setField<DateTime>('first_used', value);

  DateTime? get lastUsed => getField<DateTime>('last_used');
  set lastUsed(DateTime? value) => setField<DateTime>('last_used', value);
}
