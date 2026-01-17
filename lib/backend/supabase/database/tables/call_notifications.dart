import '../database.dart';

class CallNotificationsTable extends SupabaseTable<CallNotificationsRow> {
  @override
  String get tableName => 'call_notifications';

  @override
  CallNotificationsRow createRow(Map<String, dynamic> data) =>
      CallNotificationsRow(data);
}

class CallNotificationsRow extends SupabaseDataRow {
  CallNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CallNotificationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get recipientId => getField<String>('recipient_id')!;
  set recipientId(String value) => setField<String>('recipient_id', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  dynamic get payload => getField<dynamic>('payload')!;
  set payload(dynamic value) => setField<dynamic>('payload', value);

  DateTime? get readAt => getField<DateTime>('read_at');
  set readAt(DateTime? value) => setField<DateTime>('read_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
