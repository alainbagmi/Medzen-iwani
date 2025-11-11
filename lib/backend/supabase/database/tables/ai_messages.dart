import '../database.dart';

class AiMessagesTable extends SupabaseTable<AiMessagesRow> {
  @override
  String get tableName => 'ai_messages';

  @override
  AiMessagesRow createRow(Map<String, dynamic> data) => AiMessagesRow(data);
}

class AiMessagesRow extends SupabaseDataRow {
  AiMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiMessagesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get conversationId => getField<String>('conversation_id');
  set conversationId(String? value) =>
      setField<String>('conversation_id', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  int? get tokensUsed => getField<int>('tokens_used');
  set tokensUsed(int? value) => setField<int>('tokens_used', value);

  String? get modelVersion => getField<String>('model_version');
  set modelVersion(String? value) => setField<String>('model_version', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
