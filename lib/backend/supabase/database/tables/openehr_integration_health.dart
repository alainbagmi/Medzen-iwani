import '../database.dart';

class OpenehrIntegrationHealthTable
    extends SupabaseTable<OpenehrIntegrationHealthRow> {
  @override
  String get tableName => 'openehr_integration_health';

  @override
  OpenehrIntegrationHealthRow createRow(Map<String, dynamic> data) =>
      OpenehrIntegrationHealthRow(data);
}

class OpenehrIntegrationHealthRow extends SupabaseDataRow {
  OpenehrIntegrationHealthRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OpenehrIntegrationHealthTable();

  int? get totalEhrsCreated => getField<int>('total_ehrs_created');
  set totalEhrsCreated(int? value) =>
      setField<int>('total_ehrs_created', value);

  int? get ehrsCreatedLast7Days => getField<int>('ehrs_created_last_7_days');
  set ehrsCreatedLast7Days(int? value) =>
      setField<int>('ehrs_created_last_7_days', value);

  int? get ehrsCreatedLast30Days => getField<int>('ehrs_created_last_30_days');
  set ehrsCreatedLast30Days(int? value) =>
      setField<int>('ehrs_created_last_30_days', value);

  int? get pendingSyncItems => getField<int>('pending_sync_items');
  set pendingSyncItems(int? value) =>
      setField<int>('pending_sync_items', value);

  int? get completedSyncItems => getField<int>('completed_sync_items');
  set completedSyncItems(int? value) =>
      setField<int>('completed_sync_items', value);

  int? get failedRetrying => getField<int>('failed_retrying');
  set failedRetrying(int? value) => setField<int>('failed_retrying', value);

  int? get failedMaxRetriesNeedsReview =>
      getField<int>('failed_max_retries_needs_review');
  set failedMaxRetriesNeedsReview(int? value) =>
      setField<int>('failed_max_retries_needs_review', value);

  int? get vitalSignsSynced => getField<int>('vital_signs_synced');
  set vitalSignsSynced(int? value) =>
      setField<int>('vital_signs_synced', value);

  int? get prescriptionsSynced => getField<int>('prescriptions_synced');
  set prescriptionsSynced(int? value) =>
      setField<int>('prescriptions_synced', value);

  int? get labResultsSynced => getField<int>('lab_results_synced');
  set labResultsSynced(int? value) =>
      setField<int>('lab_results_synced', value);

  int? get immunizationsSynced => getField<int>('immunizations_synced');
  set immunizationsSynced(int? value) =>
      setField<int>('immunizations_synced', value);

  int? get medicalRecordsSynced => getField<int>('medical_records_synced');
  set medicalRecordsSynced(int? value) =>
      setField<int>('medical_records_synced', value);

  DateTime? get lastSuccessfulSync =>
      getField<DateTime>('last_successful_sync');
  set lastSuccessfulSync(DateTime? value) =>
      setField<DateTime>('last_successful_sync', value);

  double? get avgSyncTimeSeconds => getField<double>('avg_sync_time_seconds');
  set avgSyncTimeSeconds(double? value) =>
      setField<double>('avg_sync_time_seconds', value);

  String? get integrationStatus => getField<String>('integration_status');
  set integrationStatus(String? value) =>
      setField<String>('integration_status', value);
}
