import '../database.dart';

class SmsLogsTable extends SupabaseTable<SmsLogsRow> {
  @override
  String get tableName => 'sms_logs';

  @override
  SmsLogsRow createRow(Map<String, dynamic> data) => SmsLogsRow(data);
}

class SmsLogsRow extends SupabaseDataRow {
  SmsLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SmsLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get phoneNumber => getField<String>('phone_number')!;
  set phoneNumber(String value) => setField<String>('phone_number', value);

  String get message => getField<String>('message')!;
  set message(String value) => setField<String>('message', value);

  String? get direction => getField<String>('direction');
  set direction(String? value) => setField<String>('direction', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get twilioSid => getField<String>('twilio_sid');
  set twilioSid(String? value) => setField<String>('twilio_sid', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get sentAt => getField<DateTime>('sent_at');
  set sentAt(DateTime? value) => setField<DateTime>('sent_at', value);

  DateTime? get deliveredAt => getField<DateTime>('delivered_at');
  set deliveredAt(DateTime? value) => setField<DateTime>('delivered_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
