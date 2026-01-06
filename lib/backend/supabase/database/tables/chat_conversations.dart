import '../database.dart';

class ChatConversationsTable extends SupabaseTable<ChatConversationsRow> {
  @override
  String get tableName => 'chat_conversations';

  @override
  ChatConversationsRow createRow(Map<String, dynamic> data) =>
      ChatConversationsRow(data);
}

class ChatConversationsRow extends SupabaseDataRow {
  ChatConversationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChatConversationsTable();

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  DateTime? get appointmentDate => getField<DateTime>('appointment_date');
  set appointmentDate(DateTime? value) =>
      setField<DateTime>('appointment_date', value);

  String? get appointmentStatus => getField<String>('appointment_status');
  set appointmentStatus(String? value) =>
      setField<String>('appointment_status', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get patientName => getField<String>('patient_name');
  set patientName(String? value) => setField<String>('patient_name', value);

  String? get patientPhoto => getField<String>('patient_photo');
  set patientPhoto(String? value) => setField<String>('patient_photo', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get providerName => getField<String>('provider_name');
  set providerName(String? value) => setField<String>('provider_name', value);

  String? get providerPhoto => getField<String>('provider_photo');
  set providerPhoto(String? value) => setField<String>('provider_photo', value);

  String? get providerRole => getField<String>('provider_role');
  set providerRole(String? value) => setField<String>('provider_role', value);

  int? get totalMessages => getField<int>('total_messages');
  set totalMessages(int? value) => setField<int>('total_messages', value);

  DateTime? get lastMessageAt => getField<DateTime>('last_message_at');
  set lastMessageAt(DateTime? value) =>
      setField<DateTime>('last_message_at', value);

  String? get lastMessagePreview => getField<String>('last_message_preview');
  set lastMessagePreview(String? value) =>
      setField<String>('last_message_preview', value);
}
