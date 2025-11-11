import '../database.dart';

class MessagesTable extends SupabaseTable<MessagesRow> {
  @override
  String get tableName => 'messages';

  @override
  MessagesRow createRow(Map<String, dynamic> data) => MessagesRow(data);
}

class MessagesRow extends SupabaseDataRow {
  MessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MessagesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get conversationId => getField<String>('conversation_id');
  set conversationId(String? value) =>
      setField<String>('conversation_id', value);

  String? get senderId => getField<String>('sender_id');
  set senderId(String? value) => setField<String>('sender_id', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  String? get messageType => getField<String>('message_type');
  set messageType(String? value) => setField<String>('message_type', value);

  List<String> get attachments => getListField<String>('attachments');
  set attachments(List<String>? value) =>
      setListField<String>('attachments', value);

  String? get replyToMessageId => getField<String>('reply_to_message_id');
  set replyToMessageId(String? value) =>
      setField<String>('reply_to_message_id', value);

  bool? get isEdited => getField<bool>('is_edited');
  set isEdited(bool? value) => setField<bool>('is_edited', value);

  DateTime? get editedAt => getField<DateTime>('edited_at');
  set editedAt(DateTime? value) => setField<DateTime>('edited_at', value);

  bool? get isDeleted => getField<bool>('is_deleted');
  set isDeleted(bool? value) => setField<bool>('is_deleted', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

  List<String> get readBy => getListField<String>('read_by');
  set readBy(List<String>? value) => setListField<String>('read_by', value);

  List<String> get deliveredTo => getListField<String>('delivered_to');
  set deliveredTo(List<String>? value) =>
      setListField<String>('delivered_to', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
