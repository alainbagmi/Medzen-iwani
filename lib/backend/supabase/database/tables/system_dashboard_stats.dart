import '../database.dart';

class SystemDashboardStatsTable extends SupabaseTable<SystemDashboardStatsRow> {
  @override
  String get tableName => 'system_dashboard_stats';

  @override
  SystemDashboardStatsRow createRow(Map<String, dynamic> data) =>
      SystemDashboardStatsRow(data);
}

class SystemDashboardStatsRow extends SupabaseDataRow {
  SystemDashboardStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemDashboardStatsTable();

  int? get totalUsers => getField<int>('total_users');
  set totalUsers(int? value) => setField<int>('total_users', value);

  int? get totalAppointments => getField<int>('total_appointments');
  set totalAppointments(int? value) =>
      setField<int>('total_appointments', value);

  int? get totalPatients => getField<int>('total_patients');
  set totalPatients(int? value) => setField<int>('total_patients', value);

  int? get totalPractitioners => getField<int>('total_practitioners');
  set totalPractitioners(int? value) =>
      setField<int>('total_practitioners', value);

  int? get totalFacilities => getField<int>('total_facilities');
  set totalFacilities(int? value) => setField<int>('total_facilities', value);

  int? get scheduledAppointments => getField<int>('scheduled_appointments');
  set scheduledAppointments(int? value) =>
      setField<int>('scheduled_appointments', value);

  int? get pendingAppointments => getField<int>('pending_appointments');
  set pendingAppointments(int? value) =>
      setField<int>('pending_appointments', value);

  int? get completedAppointments => getField<int>('completed_appointments');
  set completedAppointments(int? value) =>
      setField<int>('completed_appointments', value);

  double? get totalApprovedPractitionersAndFacilities =>
      getField<double>('total_approved_practitioners_and_facilities');
  set totalApprovedPractitionersAndFacilities(double? value) =>
      setField<double>('total_approved_practitioners_and_facilities', value);

  double? get totalPendingPractitionersAndFacilities =>
      getField<double>('total_pending_practitioners_and_facilities');
  set totalPendingPractitionersAndFacilities(double? value) =>
      setField<double>('total_pending_practitioners_and_facilities', value);

  double? get totalRejectedPractitionersAndFacilities =>
      getField<double>('total_rejected_practitioners_and_facilities');
  set totalRejectedPractitionersAndFacilities(double? value) =>
      setField<double>('total_rejected_practitioners_and_facilities', value);
}
