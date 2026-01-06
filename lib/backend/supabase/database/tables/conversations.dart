import '../database.dart';

class ConversationsTable extends SupabaseTable<ConversationsRow> {
  @override
  String get tableName => 'conversations';

  @override
  ConversationsRow createRow(Map<String, dynamic> data) =>
      ConversationsRow(data);
}

class ConversationsRow extends SupabaseDataRow {
  ConversationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get conversationType => getField<String>('conversation_type');
  set conversationType(String? value) =>
      setField<String>('conversation_type', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  List<String> get participantIds => getListField<String>('participant_ids')!;
  set participantIds(List<String> value) =>
      setListField<String>('participant_ids', value);

  String? get createdById => getField<String>('created_by_id');
  set createdById(String? value) => setField<String>('created_by_id', value);

  bool? get isArchived => getField<bool>('is_archived');
  set isArchived(bool? value) => setField<bool>('is_archived', value);

  DateTime? get lastMessageAt => getField<DateTime>('last_message_at');
  set lastMessageAt(DateTime? value) =>
      setField<DateTime>('last_message_at', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get conversationCategory => getField<String>('conversation_category');
  set conversationCategory(String? value) =>
      setField<String>('conversation_category', value);

  String? get initiatedByRole => getField<String>('initiated_by_role');
  set initiatedByRole(String? value) =>
      setField<String>('initiated_by_role', value);

  bool? get requiresAppointment => getField<bool>('requires_appointment');
  set requiresAppointment(bool? value) =>
      setField<bool>('requires_appointment', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);
}
