import '../database.dart';

class ConversationParticipantsTable
    extends SupabaseTable<ConversationParticipantsRow> {
  @override
  String get tableName => 'conversation_participants';

  @override
  ConversationParticipantsRow createRow(Map<String, dynamic> data) =>
      ConversationParticipantsRow(data);
}

class ConversationParticipantsRow extends SupabaseDataRow {
  ConversationParticipantsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationParticipantsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get conversationId => getField<String>('conversation_id')!;
  set conversationId(String value) =>
      setField<String>('conversation_id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get participantRole => getField<String>('participant_role')!;
  set participantRole(String value) =>
      setField<String>('participant_role', value);

  DateTime? get joinedAt => getField<DateTime>('joined_at');
  set joinedAt(DateTime? value) => setField<DateTime>('joined_at', value);

  DateTime? get leftAt => getField<DateTime>('left_at');
  set leftAt(DateTime? value) => setField<DateTime>('left_at', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  bool? get canSendMessages => getField<bool>('can_send_messages');
  set canSendMessages(bool? value) =>
      setField<bool>('can_send_messages', value);

  String? get lastReadMessageId => getField<String>('last_read_message_id');
  set lastReadMessageId(String? value) =>
      setField<String>('last_read_message_id', value);

  int? get unreadCount => getField<int>('unread_count');
  set unreadCount(int? value) => setField<int>('unread_count', value);

  dynamic? get notificationSettings =>
      getField<dynamic>('notification_settings');
  set notificationSettings(dynamic? value) =>
      setField<dynamic>('notification_settings', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
