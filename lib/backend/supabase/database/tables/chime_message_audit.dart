import '../database.dart';

class ChimeMessageAuditTable extends SupabaseTable<ChimeMessageAuditRow> {
  @override
  String get tableName => 'chime_message_audit';

  @override
  ChimeMessageAuditRow createRow(Map<String, dynamic> data) =>
      ChimeMessageAuditRow(data);
}

class ChimeMessageAuditRow extends SupabaseDataRow {
  ChimeMessageAuditRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChimeMessageAuditTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get channelId => getField<String>('channel_id')!;
  set channelId(String value) => setField<String>('channel_id', value);

  String get channelArn => getField<String>('channel_arn')!;
  set channelArn(String value) => setField<String>('channel_arn', value);

  String? get messageId => getField<String>('message_id');
  set messageId(String? value) => setField<String>('message_id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get userRole => getField<String>('user_role')!;
  set userRole(String value) => setField<String>('user_role', value);

  String get actionType => getField<String>('action_type')!;
  set actionType(String value) => setField<String>('action_type', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  String? get userAgent => getField<String>('user_agent');
  set userAgent(String? value) => setField<String>('user_agent', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
