import '../database.dart';

class EmailLogsTable extends SupabaseTable<EmailLogsRow> {
  @override
  String get tableName => 'email_logs';

  @override
  EmailLogsRow createRow(Map<String, dynamic> data) => EmailLogsRow(data);
}

class EmailLogsRow extends SupabaseDataRow {
  EmailLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EmailLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get emailAddress => getField<String>('email_address')!;
  set emailAddress(String value) => setField<String>('email_address', value);

  String get subject => getField<String>('subject')!;
  set subject(String value) => setField<String>('subject', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  String? get templateId => getField<String>('template_id');
  set templateId(String? value) => setField<String>('template_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get provider => getField<String>('provider');
  set provider(String? value) => setField<String>('provider', value);

  String? get providerMessageId => getField<String>('provider_message_id');
  set providerMessageId(String? value) =>
      setField<String>('provider_message_id', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get sentAt => getField<DateTime>('sent_at');
  set sentAt(DateTime? value) => setField<DateTime>('sent_at', value);

  DateTime? get deliveredAt => getField<DateTime>('delivered_at');
  set deliveredAt(DateTime? value) => setField<DateTime>('delivered_at', value);

  DateTime? get openedAt => getField<DateTime>('opened_at');
  set openedAt(DateTime? value) => setField<DateTime>('opened_at', value);

  DateTime? get clickedAt => getField<DateTime>('clicked_at');
  set clickedAt(DateTime? value) => setField<DateTime>('clicked_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
