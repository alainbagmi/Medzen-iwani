import '../database.dart';

class AppointmentRemindersTable extends SupabaseTable<AppointmentRemindersRow> {
  @override
  String get tableName => 'appointment_reminders';

  @override
  AppointmentRemindersRow createRow(Map<String, dynamic> data) =>
      AppointmentRemindersRow(data);
}

class AppointmentRemindersRow extends SupabaseDataRow {
  AppointmentRemindersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppointmentRemindersTable();

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);

  String? get time => getField<String>('time');
  set time(String? value) => setField<String>('time', value);

  String? get dueWhen => getField<String>('due_when');
  set dueWhen(String? value) => setField<String>('due_when', value);
}
