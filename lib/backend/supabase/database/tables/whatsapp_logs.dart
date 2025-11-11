import '../database.dart';

class WhatsappLogsTable extends SupabaseTable<WhatsappLogsRow> {
  @override
  String get tableName => 'whatsapp_logs';

  @override
  WhatsappLogsRow createRow(Map<String, dynamic> data) => WhatsappLogsRow(data);
}

class WhatsappLogsRow extends SupabaseDataRow {
  WhatsappLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WhatsappLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get whatsappNumber => getField<String>('whatsapp_number')!;
  set whatsappNumber(String value) =>
      setField<String>('whatsapp_number', value);

  String get message => getField<String>('message')!;
  set message(String value) => setField<String>('message', value);

  String? get direction => getField<String>('direction');
  set direction(String? value) => setField<String>('direction', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get twilioSid => getField<String>('twilio_sid');
  set twilioSid(String? value) => setField<String>('twilio_sid', value);

  List<String> get mediaUrls => getListField<String>('media_urls');
  set mediaUrls(List<String>? value) =>
      setListField<String>('media_urls', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get sentAt => getField<DateTime>('sent_at');
  set sentAt(DateTime? value) => setField<DateTime>('sent_at', value);

  DateTime? get deliveredAt => getField<DateTime>('delivered_at');
  set deliveredAt(DateTime? value) => setField<DateTime>('delivered_at', value);

  DateTime? get readAt => getField<DateTime>('read_at');
  set readAt(DateTime? value) => setField<DateTime>('read_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
