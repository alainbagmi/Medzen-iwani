import '../database.dart';

class SystemAdminAppointmentStatsTable
    extends SupabaseTable<SystemAdminAppointmentStatsRow> {
  @override
  String get tableName => 'system_admin_appointment_stats';

  @override
  SystemAdminAppointmentStatsRow createRow(Map<String, dynamic> data) =>
      SystemAdminAppointmentStatsRow(data);
}

class SystemAdminAppointmentStatsRow extends SupabaseDataRow {
  SystemAdminAppointmentStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemAdminAppointmentStatsTable();

  int? get totalAppointmentsAllTime =>
      getField<int>('total_appointments_all_time');
  set totalAppointmentsAllTime(int? value) =>
      setField<int>('total_appointments_all_time', value);

  int? get appointmentsLast30Days => getField<int>('appointments_last_30_days');
  set appointmentsLast30Days(int? value) =>
      setField<int>('appointments_last_30_days', value);

  int? get appointmentsLast7Days => getField<int>('appointments_last_7_days');
  set appointmentsLast7Days(int? value) =>
      setField<int>('appointments_last_7_days', value);

  int? get appointmentsToday => getField<int>('appointments_today');
  set appointmentsToday(int? value) =>
      setField<int>('appointments_today', value);

  int? get upcomingAppointments => getField<int>('upcoming_appointments');
  set upcomingAppointments(int? value) =>
      setField<int>('upcoming_appointments', value);

  int? get pendingApprovals => getField<int>('pending_approvals');
  set pendingApprovals(int? value) => setField<int>('pending_approvals', value);

  int? get completedAppointments => getField<int>('completed_appointments');
  set completedAppointments(int? value) =>
      setField<int>('completed_appointments', value);

  int? get cancelledAppointments => getField<int>('cancelled_appointments');
  set cancelledAppointments(int? value) =>
      setField<int>('cancelled_appointments', value);

  int? get videoConsultations => getField<int>('video_consultations');
  set videoConsultations(int? value) =>
      setField<int>('video_consultations', value);

  int? get inPersonConsultations => getField<int>('in_person_consultations');
  set inPersonConsultations(int? value) =>
      setField<int>('in_person_consultations', value);

  int? get chatConsultations => getField<int>('chat_consultations');
  set chatConsultations(int? value) =>
      setField<int>('chat_consultations', value);

  int? get regularConsultations => getField<int>('regular_consultations');
  set regularConsultations(int? value) =>
      setField<int>('regular_consultations', value);

  int? get followUps => getField<int>('follow_ups');
  set followUps(int? value) => setField<int>('follow_ups', value);

  int? get emergencyAppointments => getField<int>('emergency_appointments');
  set emergencyAppointments(int? value) =>
      setField<int>('emergency_appointments', value);
}
