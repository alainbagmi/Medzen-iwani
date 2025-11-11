import '../database.dart';

class WaitlistTable extends SupabaseTable<WaitlistRow> {
  @override
  String get tableName => 'waitlist';

  @override
  WaitlistRow createRow(Map<String, dynamic> data) => WaitlistRow(data);
}

class WaitlistRow extends SupabaseDataRow {
  WaitlistRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WaitlistTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get specialty => getField<String>('specialty');
  set specialty(String? value) => setField<String>('specialty', value);

  List<DateTime> get preferredDates =>
      getListField<DateTime>('preferred_dates');
  set preferredDates(List<DateTime>? value) =>
      setListField<DateTime>('preferred_dates', value);

  List<String> get preferredTimes => getListField<String>('preferred_times');
  set preferredTimes(List<String>? value) =>
      setListField<String>('preferred_times', value);

  int? get priority => getField<int>('priority');
  set priority(int? value) => setField<int>('priority', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
