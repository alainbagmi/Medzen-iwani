import '../database.dart';

class UssdActionsTable extends SupabaseTable<UssdActionsRow> {
  @override
  String get tableName => 'ussd_actions';

  @override
  UssdActionsRow createRow(Map<String, dynamic> data) => UssdActionsRow(data);
}

class UssdActionsRow extends SupabaseDataRow {
  UssdActionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UssdActionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get actionType => getField<String>('action_type')!;
  set actionType(String value) => setField<String>('action_type', value);

  dynamic? get actionData => getField<dynamic>('action_data');
  set actionData(dynamic? value) => setField<dynamic>('action_data', value);

  String? get result => getField<String>('result');
  set result(String? value) => setField<String>('result', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get executedAt => getField<DateTime>('executed_at');
  set executedAt(DateTime? value) => setField<DateTime>('executed_at', value);
}
