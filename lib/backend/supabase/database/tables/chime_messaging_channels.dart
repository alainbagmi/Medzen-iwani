import '../database.dart';

class ChimeMessagingChannelsTable
    extends SupabaseTable<ChimeMessagingChannelsRow> {
  @override
  String get tableName => 'chime_messaging_channels';

  @override
  ChimeMessagingChannelsRow createRow(Map<String, dynamic> data) =>
      ChimeMessagingChannelsRow(data);
}

class ChimeMessagingChannelsRow extends SupabaseDataRow {
  ChimeMessagingChannelsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChimeMessagingChannelsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get channelArn => getField<String>('channel_arn')!;
  set channelArn(String value) => setField<String>('channel_arn', value);

  String get channelName => getField<String>('channel_name')!;
  set channelName(String value) => setField<String>('channel_name', value);

  String get providerId => getField<String>('provider_id')!;
  set providerId(String value) => setField<String>('provider_id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get channelMode => getField<String>('channel_mode');
  set channelMode(String? value) => setField<String>('channel_mode', value);

  String? get privacy => getField<String>('privacy');
  set privacy(String? value) => setField<String>('privacy', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get lastMessageAt => getField<DateTime>('last_message_at');
  set lastMessageAt(DateTime? value) =>
      setField<DateTime>('last_message_at', value);
}
