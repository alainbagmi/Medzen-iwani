import '../database.dart';

class SystemAuditLogsTable extends SupabaseTable<SystemAuditLogsRow> {
  @override
  String get tableName => 'system_audit_logs';

  @override
  SystemAuditLogsRow createRow(Map<String, dynamic> data) =>
      SystemAuditLogsRow(data);
}

class SystemAuditLogsRow extends SupabaseDataRow {
  SystemAuditLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemAuditLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get action => getField<String>('action')!;
  set action(String value) => setField<String>('action', value);

  String? get entityType => getField<String>('entity_type');
  set entityType(String? value) => setField<String>('entity_type', value);

  String? get entityId => getField<String>('entity_id');
  set entityId(String? value) => setField<String>('entity_id', value);

  dynamic? get changes => getField<dynamic>('changes');
  set changes(dynamic? value) => setField<dynamic>('changes', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  String? get userAgent => getField<String>('user_agent');
  set userAgent(String? value) => setField<String>('user_agent', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
