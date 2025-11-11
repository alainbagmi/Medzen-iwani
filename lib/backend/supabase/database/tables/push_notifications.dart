import '../database.dart';

class PushNotificationsTable extends SupabaseTable<PushNotificationsRow> {
  @override
  String get tableName => 'push_notifications';

  @override
  PushNotificationsRow createRow(Map<String, dynamic> data) =>
      PushNotificationsRow(data);
}

class PushNotificationsRow extends SupabaseDataRow {
  PushNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PushNotificationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get fcmToken => getField<String>('fcm_token')!;
  set fcmToken(String value) => setField<String>('fcm_token', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  dynamic? get dataField => getField<dynamic>('data');
  set dataField(dynamic? value) => setField<dynamic>('data', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get fcmMessageId => getField<String>('fcm_message_id');
  set fcmMessageId(String? value) => setField<String>('fcm_message_id', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get sentAt => getField<DateTime>('sent_at');
  set sentAt(DateTime? value) => setField<DateTime>('sent_at', value);

  DateTime? get deliveredAt => getField<DateTime>('delivered_at');
  set deliveredAt(DateTime? value) => setField<DateTime>('delivered_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
