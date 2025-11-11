import '../database.dart';

class SystemAdminClinicalStatsTable
    extends SupabaseTable<SystemAdminClinicalStatsRow> {
  @override
  String get tableName => 'system_admin_clinical_stats';

  @override
  SystemAdminClinicalStatsRow createRow(Map<String, dynamic> data) =>
      SystemAdminClinicalStatsRow(data);
}

class SystemAdminClinicalStatsRow extends SupabaseDataRow {
  SystemAdminClinicalStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemAdminClinicalStatsTable();

  int? get totalPrescriptions => getField<int>('total_prescriptions');
  set totalPrescriptions(int? value) =>
      setField<int>('total_prescriptions', value);

  int? get prescriptionsLast30Days =>
      getField<int>('prescriptions_last_30_days');
  set prescriptionsLast30Days(int? value) =>
      setField<int>('prescriptions_last_30_days', value);

  int? get prescriptionsLast7Days => getField<int>('prescriptions_last_7_days');
  set prescriptionsLast7Days(int? value) =>
      setField<int>('prescriptions_last_7_days', value);

  int? get activePrescriptions => getField<int>('active_prescriptions');
  set activePrescriptions(int? value) =>
      setField<int>('active_prescriptions', value);

  int? get completedPrescriptions => getField<int>('completed_prescriptions');
  set completedPrescriptions(int? value) =>
      setField<int>('completed_prescriptions', value);

  int? get totalLabOrders => getField<int>('total_lab_orders');
  set totalLabOrders(int? value) => setField<int>('total_lab_orders', value);

  int? get pendingLabOrders => getField<int>('pending_lab_orders');
  set pendingLabOrders(int? value) =>
      setField<int>('pending_lab_orders', value);

  int? get inProgressLabOrders => getField<int>('in_progress_lab_orders');
  set inProgressLabOrders(int? value) =>
      setField<int>('in_progress_lab_orders', value);

  int? get completedLabOrders => getField<int>('completed_lab_orders');
  set completedLabOrders(int? value) =>
      setField<int>('completed_lab_orders', value);

  int? get totalLabResults => getField<int>('total_lab_results');
  set totalLabResults(int? value) => setField<int>('total_lab_results', value);

  int? get labResultsLast7Days => getField<int>('lab_results_last_7_days');
  set labResultsLast7Days(int? value) =>
      setField<int>('lab_results_last_7_days', value);

  int? get totalVitalSignsRecords => getField<int>('total_vital_signs_records');
  set totalVitalSignsRecords(int? value) =>
      setField<int>('total_vital_signs_records', value);

  int? get vitalSignsLast7Days => getField<int>('vital_signs_last_7_days');
  set vitalSignsLast7Days(int? value) =>
      setField<int>('vital_signs_last_7_days', value);

  int? get totalImmunizations => getField<int>('total_immunizations');
  set totalImmunizations(int? value) =>
      setField<int>('total_immunizations', value);

  int? get immunizationsLast30Days =>
      getField<int>('immunizations_last_30_days');
  set immunizationsLast30Days(int? value) =>
      setField<int>('immunizations_last_30_days', value);

  int? get totalMedicalRecords => getField<int>('total_medical_records');
  set totalMedicalRecords(int? value) =>
      setField<int>('total_medical_records', value);

  int? get medicalRecordsLast30Days =>
      getField<int>('medical_records_last_30_days');
  set medicalRecordsLast30Days(int? value) =>
      setField<int>('medical_records_last_30_days', value);
}
