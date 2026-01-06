import '../database.dart';

class UnreadMessageCountsTable extends SupabaseTable<UnreadMessageCountsRow> {
  @override
  String get tableName => 'unread_message_counts';

  @override
  UnreadMessageCountsRow createRow(Map<String, dynamic> data) =>
      UnreadMessageCountsRow(data);
}

class UnreadMessageCountsRow extends SupabaseDataRow {
  UnreadMessageCountsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UnreadMessageCountsTable();

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get senderId => getField<String>('sender_id');
  set senderId(String? value) => setField<String>('sender_id', value);

  int? get unreadCount => getField<int>('unread_count');
  set unreadCount(int? value) => setField<int>('unread_count', value);
}
