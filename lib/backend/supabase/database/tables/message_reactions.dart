import '../database.dart';

class MessageReactionsTable extends SupabaseTable<MessageReactionsRow> {
  @override
  String get tableName => 'message_reactions';

  @override
  MessageReactionsRow createRow(Map<String, dynamic> data) =>
      MessageReactionsRow(data);
}

class MessageReactionsRow extends SupabaseDataRow {
  MessageReactionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MessageReactionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get messageId => getField<String>('message_id');
  set messageId(String? value) => setField<String>('message_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get reaction => getField<String>('reaction')!;
  set reaction(String value) => setField<String>('reaction', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
