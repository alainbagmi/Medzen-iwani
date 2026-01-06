import '../database.dart';

class ChimeMessagesTable extends SupabaseTable<ChimeMessagesRow> {
  @override
  String get tableName => 'chime_messages';

  @override
  ChimeMessagesRow createRow(Map<String, dynamic> data) =>
      ChimeMessagesRow(data);
}

class ChimeMessagesRow extends SupabaseDataRow {
  ChimeMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChimeMessagesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get channelArn => getField<String>('channel_arn');
  set channelArn(String? value) => setField<String>('channel_arn', value);

  String get message => getField<String>('message')!;
  set message(String value) => setField<String>('message', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String? get messageId => getField<String>('message_id');
  set messageId(String? value) => setField<String>('message_id', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get channelId => getField<String>('channel_id');
  set channelId(String? value) => setField<String>('channel_id', value);

  String? get messageType => getField<String>('message_type');
  set messageType(String? value) => setField<String>('message_type', value);

  String? get messageContent => getField<String>('message_content');
  set messageContent(String? value) =>
      setField<String>('message_content', value);

  String? get senderName => getField<String>('sender_name');
  set senderName(String? value) => setField<String>('sender_name', value);

  String? get senderId => getField<String>('sender_id');
  set senderId(String? value) => setField<String>('sender_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  bool? get isRead => getField<bool>('is_read');
  set isRead(bool? value) => setField<bool>('is_read', value);

  DateTime? get readAt => getField<DateTime>('read_at');
  set readAt(DateTime? value) => setField<DateTime>('read_at', value);

  String? get senderAvatarUrl => getField<String>('sender_avatar_url');
  set senderAvatarUrl(String? value) =>
      setField<String>('sender_avatar_url', value);

  String? get senderAvatar => getField<String>('sender_avatar');
  set senderAvatar(String? value) => setField<String>('sender_avatar', value);
}
