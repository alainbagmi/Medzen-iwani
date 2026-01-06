import '../database.dart';

class PushNotificationTargetsTable
    extends SupabaseTable<PushNotificationTargetsRow> {
  @override
  String get tableName => 'push_notification_targets';

  @override
  PushNotificationTargetsRow createRow(Map<String, dynamic> data) =>
      PushNotificationTargetsRow(data);
}

class PushNotificationTargetsRow extends SupabaseDataRow {
  PushNotificationTargetsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PushNotificationTargetsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get firebaseUid => getField<String>('firebase_uid');
  set firebaseUid(String? value) => setField<String>('firebase_uid', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get fcmToken => getField<String>('fcm_token');
  set fcmToken(String? value) => setField<String>('fcm_token', value);

  String? get deviceType => getField<String>('device_type');
  set deviceType(String? value) => setField<String>('device_type', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
