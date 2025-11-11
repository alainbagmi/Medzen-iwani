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
}
