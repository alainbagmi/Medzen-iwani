import '../database.dart';

class UserActivityLogsTable extends SupabaseTable<UserActivityLogsRow> {
  @override
  String get tableName => 'user_activity_logs';

  @override
  UserActivityLogsRow createRow(Map<String, dynamic> data) =>
      UserActivityLogsRow(data);
}

class UserActivityLogsRow extends SupabaseDataRow {
  UserActivityLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserActivityLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get activityType => getField<String>('activity_type')!;
  set activityType(String value) => setField<String>('activity_type', value);

  String? get activityDescription => getField<String>('activity_description');
  set activityDescription(String? value) =>
      setField<String>('activity_description', value);

  String? get entityType => getField<String>('entity_type');
  set entityType(String? value) => setField<String>('entity_type', value);

  String? get entityId => getField<String>('entity_id');
  set entityId(String? value) => setField<String>('entity_id', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  String? get userAgent => getField<String>('user_agent');
  set userAgent(String? value) => setField<String>('user_agent', value);

  dynamic? get deviceInfo => getField<dynamic>('device_info');
  set deviceInfo(dynamic? value) => setField<dynamic>('device_info', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
