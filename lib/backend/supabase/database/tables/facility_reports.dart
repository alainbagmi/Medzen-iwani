import '../database.dart';

class FacilityReportsTable extends SupabaseTable<FacilityReportsRow> {
  @override
  String get tableName => 'facility_reports';

  @override
  FacilityReportsRow createRow(Map<String, dynamic> data) =>
      FacilityReportsRow(data);
}

class FacilityReportsRow extends SupabaseDataRow {
  FacilityReportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityReportsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get reportType => getField<String>('report_type');
  set reportType(String? value) => setField<String>('report_type', value);

  DateTime get reportPeriodStart => getField<DateTime>('report_period_start')!;
  set reportPeriodStart(DateTime value) =>
      setField<DateTime>('report_period_start', value);

  DateTime get reportPeriodEnd => getField<DateTime>('report_period_end')!;
  set reportPeriodEnd(DateTime value) =>
      setField<DateTime>('report_period_end', value);

  int? get totalAppointments => getField<int>('total_appointments');
  set totalAppointments(int? value) =>
      setField<int>('total_appointments', value);

  int? get totalPatients => getField<int>('total_patients');
  set totalPatients(int? value) => setField<int>('total_patients', value);

  double? get totalRevenue => getField<double>('total_revenue');
  set totalRevenue(double? value) => setField<double>('total_revenue', value);

  double? get patientSatisfactionScore =>
      getField<double>('patient_satisfaction_score');
  set patientSatisfactionScore(double? value) =>
      setField<double>('patient_satisfaction_score', value);

  int? get averageWaitTimeMinutes => getField<int>('average_wait_time_minutes');
  set averageWaitTimeMinutes(int? value) =>
      setField<int>('average_wait_time_minutes', value);

  double? get bedOccupancyRate => getField<double>('bed_occupancy_rate');
  set bedOccupancyRate(double? value) =>
      setField<double>('bed_occupancy_rate', value);

  double? get staffUtilizationRate =>
      getField<double>('staff_utilization_rate');
  set staffUtilizationRate(double? value) =>
      setField<double>('staff_utilization_rate', value);

  dynamic? get reportData => getField<dynamic>('report_data');
  set reportData(dynamic? value) => setField<dynamic>('report_data', value);

  String? get generatedById => getField<String>('generated_by_id');
  set generatedById(String? value) =>
      setField<String>('generated_by_id', value);

  String? get fileUrl => getField<String>('file_url');
  set fileUrl(String? value) => setField<String>('file_url', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
