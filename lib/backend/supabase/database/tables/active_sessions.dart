import '../database.dart';

class ActiveSessionsTable extends SupabaseTable<ActiveSessionsRow> {
  @override
  String get tableName => 'active_sessions';

  @override
  ActiveSessionsRow createRow(Map<String, dynamic> data) =>
      ActiveSessionsRow(data);
}

class ActiveSessionsRow extends SupabaseDataRow {
  ActiveSessionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ActiveSessionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get deviceId => getField<String>('device_id')!;
  set deviceId(String value) => setField<String>('device_id', value);

  String? get deviceName => getField<String>('device_name');
  set deviceName(String? value) => setField<String>('device_name', value);

  String? get devicePlatform => getField<String>('device_platform');
  set devicePlatform(String? value) =>
      setField<String>('device_platform', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  String get firebaseUid => getField<String>('firebase_uid')!;
  set firebaseUid(String value) => setField<String>('firebase_uid', value);

  String get sessionToken => getField<String>('session_token')!;
  set sessionToken(String value) => setField<String>('session_token', value);

  DateTime get lastActivityAt => getField<DateTime>('last_activity_at')!;
  set lastActivityAt(DateTime value) =>
      setField<DateTime>('last_activity_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get expiresAt => getField<DateTime>('expires_at')!;
  set expiresAt(DateTime value) => setField<DateTime>('expires_at', value);

  bool get isActive => getField<bool>('is_active')!;
  set isActive(bool value) => setField<bool>('is_active', value);

  bool get isVideoCallActive => getField<bool>('is_video_call_active')!;
  set isVideoCallActive(bool value) =>
      setField<bool>('is_video_call_active', value);
}
