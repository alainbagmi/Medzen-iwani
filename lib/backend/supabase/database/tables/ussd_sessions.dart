import '../database.dart';

class UssdSessionsTable extends SupabaseTable<UssdSessionsRow> {
  @override
  String get tableName => 'ussd_sessions';

  @override
  UssdSessionsRow createRow(Map<String, dynamic> data) => UssdSessionsRow(data);
}

class UssdSessionsRow extends SupabaseDataRow {
  UssdSessionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UssdSessionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get sessionId => getField<String>('session_id')!;
  set sessionId(String value) => setField<String>('session_id', value);

  String get phoneNumber => getField<String>('phone_number')!;
  set phoneNumber(String value) => setField<String>('phone_number', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get currentMenu => getField<String>('current_menu')!;
  set currentMenu(String value) => setField<String>('current_menu', value);

  List<String> get menuHistory => getListField<String>('menu_history');
  set menuHistory(List<String>? value) =>
      setListField<String>('menu_history', value);

  dynamic? get context => getField<dynamic>('context');
  set context(dynamic? value) => setField<dynamic>('context', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get startedAt => getField<DateTime>('started_at');
  set startedAt(DateTime? value) => setField<DateTime>('started_at', value);

  DateTime? get lastActivityAt => getField<DateTime>('last_activity_at');
  set lastActivityAt(DateTime? value) =>
      setField<DateTime>('last_activity_at', value);

  DateTime? get endedAt => getField<DateTime>('ended_at');
  set endedAt(DateTime? value) => setField<DateTime>('ended_at', value);

  int? get timeoutMinutes => getField<int>('timeout_minutes');
  set timeoutMinutes(int? value) => setField<int>('timeout_minutes', value);
}
