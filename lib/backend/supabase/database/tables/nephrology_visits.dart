import '../database.dart';

class NephrologyVisitsTable extends SupabaseTable<NephrologyVisitsRow> {
  @override
  String get tableName => 'nephrology_visits';

  @override
  NephrologyVisitsRow createRow(Map<String, dynamic> data) =>
      NephrologyVisitsRow(data);
}

class NephrologyVisitsRow extends SupabaseDataRow {
  NephrologyVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NephrologyVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get nephrologistId => getField<String>('nephrologist_id');
  set nephrologistId(String? value) =>
      setField<String>('nephrologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get visitDate => getField<DateTime>('visit_date')!;
  set visitDate(DateTime value) => setField<DateTime>('visit_date', value);

  String? get ckdStage => getField<String>('ckd_stage');
  set ckdStage(String? value) => setField<String>('ckd_stage', value);

  double? get egfrValue => getField<double>('egfr_value');
  set egfrValue(double? value) => setField<double>('egfr_value', value);

  double? get creatinineMgDl => getField<double>('creatinine_mg_dl');
  set creatinineMgDl(double? value) =>
      setField<double>('creatinine_mg_dl', value);

  double? get bunMgDl => getField<double>('bun_mg_dl');
  set bunMgDl(double? value) => setField<double>('bun_mg_dl', value);

  double? get proteinuriaGDay => getField<double>('proteinuria_g_day');
  set proteinuriaGDay(double? value) =>
      setField<double>('proteinuria_g_day', value);

  int? get bloodPressureSystolic => getField<int>('blood_pressure_systolic');
  set bloodPressureSystolic(int? value) =>
      setField<int>('blood_pressure_systolic', value);

  int? get bloodPressureDiastolic => getField<int>('blood_pressure_diastolic');
  set bloodPressureDiastolic(int? value) =>
      setField<int>('blood_pressure_diastolic', value);

  bool? get onDialysis => getField<bool>('on_dialysis');
  set onDialysis(bool? value) => setField<bool>('on_dialysis', value);

  String? get dialysisType => getField<String>('dialysis_type');
  set dialysisType(String? value) => setField<String>('dialysis_type', value);

  String? get dialysisFrequency => getField<String>('dialysis_frequency');
  set dialysisFrequency(String? value) =>
      setField<String>('dialysis_frequency', value);

  String? get vascularAccessType => getField<String>('vascular_access_type');
  set vascularAccessType(String? value) =>
      setField<String>('vascular_access_type', value);

  double? get dialysisAdequacyKtV => getField<double>('dialysis_adequacy_kt_v');
  set dialysisAdequacyKtV(double? value) =>
      setField<double>('dialysis_adequacy_kt_v', value);

  bool? get transplantCandidate => getField<bool>('transplant_candidate');
  set transplantCandidate(bool? value) =>
      setField<bool>('transplant_candidate', value);

  bool? get postTransplant => getField<bool>('post_transplant');
  set postTransplant(bool? value) => setField<bool>('post_transplant', value);

  DateTime? get transplantDate => getField<DateTime>('transplant_date');
  set transplantDate(DateTime? value) =>
      setField<DateTime>('transplant_date', value);

  List<String> get immunosuppressionRegimen =>
      getListField<String>('immunosuppression_regimen');
  set immunosuppressionRegimen(List<String>? value) =>
      setListField<String>('immunosuppression_regimen', value);

  List<String> get diagnoses => getListField<String>('diagnoses');
  set diagnoses(List<String>? value) =>
      setListField<String>('diagnoses', value);

  String? get treatmentPlan => getField<String>('treatment_plan');
  set treatmentPlan(String? value) => setField<String>('treatment_plan', value);

  List<String> get medicationsPrescribed =>
      getListField<String>('medications_prescribed');
  set medicationsPrescribed(List<String>? value) =>
      setListField<String>('medications_prescribed', value);

  DateTime? get nextDialysisDate => getField<DateTime>('next_dialysis_date');
  set nextDialysisDate(DateTime? value) =>
      setField<DateTime>('next_dialysis_date', value);

  DateTime? get nextFollowUpDate => getField<DateTime>('next_follow_up_date');
  set nextFollowUpDate(DateTime? value) =>
      setField<DateTime>('next_follow_up_date', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  bool? get ehrbaseSynced => getField<bool>('ehrbase_synced');
  set ehrbaseSynced(bool? value) => setField<bool>('ehrbase_synced', value);

  DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
  set ehrbaseSyncedAt(DateTime? value) =>
      setField<DateTime>('ehrbase_synced_at', value);

  String? get ehrbaseSyncError => getField<String>('ehrbase_sync_error');
  set ehrbaseSyncError(String? value) =>
      setField<String>('ehrbase_sync_error', value);

  int? get ehrbaseRetryCount => getField<int>('ehrbase_retry_count');
  set ehrbaseRetryCount(int? value) =>
      setField<int>('ehrbase_retry_count', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
