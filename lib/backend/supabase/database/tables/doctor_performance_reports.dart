import '../database.dart';

class DoctorPerformanceReportsTable
    extends SupabaseTable<DoctorPerformanceReportsRow> {
  @override
  String get tableName => 'doctor_performance_reports';

  @override
  DoctorPerformanceReportsRow createRow(Map<String, dynamic> data) =>
      DoctorPerformanceReportsRow(data);
}

class DoctorPerformanceReportsRow extends SupabaseDataRow {
  DoctorPerformanceReportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DoctorPerformanceReportsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get doctorId => getField<String>('doctor_id');
  set doctorId(String? value) => setField<String>('doctor_id', value);

  DateTime get reportPeriodStart => getField<DateTime>('report_period_start')!;
  set reportPeriodStart(DateTime value) =>
      setField<DateTime>('report_period_start', value);

  DateTime get reportPeriodEnd => getField<DateTime>('report_period_end')!;
  set reportPeriodEnd(DateTime value) =>
      setField<DateTime>('report_period_end', value);

  int? get totalConsultations => getField<int>('total_consultations');
  set totalConsultations(int? value) =>
      setField<int>('total_consultations', value);

  int? get totalPatientsTreated => getField<int>('total_patients_treated');
  set totalPatientsTreated(int? value) =>
      setField<int>('total_patients_treated', value);

  int? get averageConsultationDurationMinutes =>
      getField<int>('average_consultation_duration_minutes');
  set averageConsultationDurationMinutes(int? value) =>
      setField<int>('average_consultation_duration_minutes', value);

  double? get patientSatisfactionScore =>
      getField<double>('patient_satisfaction_score');
  set patientSatisfactionScore(double? value) =>
      setField<double>('patient_satisfaction_score', value);

  double? get averageRating => getField<double>('average_rating');
  set averageRating(double? value) => setField<double>('average_rating', value);

  double? get totalRevenue => getField<double>('total_revenue');
  set totalRevenue(double? value) => setField<double>('total_revenue', value);

  int? get prescriptionsIssued => getField<int>('prescriptions_issued');
  set prescriptionsIssued(int? value) =>
      setField<int>('prescriptions_issued', value);

  int? get referralsMade => getField<int>('referrals_made');
  set referralsMade(int? value) => setField<int>('referrals_made', value);

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
