import '../database.dart';

class EdgeFunctionLogsTable extends SupabaseTable<EdgeFunctionLogsRow> {
  @override
  String get tableName => 'edge_function_logs';

  @override
  EdgeFunctionLogsRow createRow(Map<String, dynamic> data) =>
      EdgeFunctionLogsRow(data);
}

class EdgeFunctionLogsRow extends SupabaseDataRow {
  EdgeFunctionLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EdgeFunctionLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get functionName => getField<String>('function_name')!;
  set functionName(String value) => setField<String>('function_name', value);

  DateTime? get timestamp => getField<DateTime>('timestamp');
  set timestamp(DateTime? value) => setField<DateTime>('timestamp', value);

  String get level => getField<String>('level')!;
  set level(String value) => setField<String>('level', value);

  String? get message => getField<String>('message');
  set message(String? value) => setField<String>('message', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get firebaseUid => getField<String>('firebase_uid');
  set firebaseUid(String? value) => setField<String>('firebase_uid', value);

  String? get requestId => getField<String>('request_id');
  set requestId(String? value) => setField<String>('request_id', value);

  int? get statusCode => getField<int>('status_code');
  set statusCode(int? value) => setField<int>('status_code', value);

  String? get errorDetails => getField<String>('error_details');
  set errorDetails(String? value) => setField<String>('error_details', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
