import '../database.dart';

class OncologyTreatmentsTable extends SupabaseTable<OncologyTreatmentsRow> {
  @override
  String get tableName => 'oncology_treatments';

  @override
  OncologyTreatmentsRow createRow(Map<String, dynamic> data) =>
      OncologyTreatmentsRow(data);
}

class OncologyTreatmentsRow extends SupabaseDataRow {
  OncologyTreatmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OncologyTreatmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get oncologistId => getField<String>('oncologist_id');
  set oncologistId(String? value) => setField<String>('oncologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String get cancerType => getField<String>('cancer_type')!;
  set cancerType(String value) => setField<String>('cancer_type', value);

  String? get cancerIcdCode => getField<String>('cancer_icd_code');
  set cancerIcdCode(String? value) =>
      setField<String>('cancer_icd_code', value);

  String? get primarySite => getField<String>('primary_site');
  set primarySite(String? value) => setField<String>('primary_site', value);

  String? get histology => getField<String>('histology');
  set histology(String? value) => setField<String>('histology', value);

  DateTime get diagnosisDate => getField<DateTime>('diagnosis_date')!;
  set diagnosisDate(DateTime value) =>
      setField<DateTime>('diagnosis_date', value);

  String? get tnmStaging => getField<String>('tnm_staging');
  set tnmStaging(String? value) => setField<String>('tnm_staging', value);

  String? get clinicalStage => getField<String>('clinical_stage');
  set clinicalStage(String? value) => setField<String>('clinical_stage', value);

  String? get grade => getField<String>('grade');
  set grade(String? value) => setField<String>('grade', value);

  String? get treatmentIntent => getField<String>('treatment_intent');
  set treatmentIntent(String? value) =>
      setField<String>('treatment_intent', value);

  List<String> get treatmentModalities =>
      getListField<String>('treatment_modalities');
  set treatmentModalities(List<String>? value) =>
      setListField<String>('treatment_modalities', value);

  String? get treatmentProtocol => getField<String>('treatment_protocol');
  set treatmentProtocol(String? value) =>
      setField<String>('treatment_protocol', value);

  DateTime? get treatmentStartDate =>
      getField<DateTime>('treatment_start_date');
  set treatmentStartDate(DateTime? value) =>
      setField<DateTime>('treatment_start_date', value);

  DateTime? get expectedEndDate => getField<DateTime>('expected_end_date');
  set expectedEndDate(DateTime? value) =>
      setField<DateTime>('expected_end_date', value);

  String? get chemotherapyRegimen => getField<String>('chemotherapy_regimen');
  set chemotherapyRegimen(String? value) =>
      setField<String>('chemotherapy_regimen', value);

  int? get cycleNumber => getField<int>('cycle_number');
  set cycleNumber(int? value) => setField<int>('cycle_number', value);

  int? get totalCyclesPlanned => getField<int>('total_cycles_planned');
  set totalCyclesPlanned(int? value) =>
      setField<int>('total_cycles_planned', value);

  DateTime? get currentCycleStartDate =>
      getField<DateTime>('current_cycle_start_date');
  set currentCycleStartDate(DateTime? value) =>
      setField<DateTime>('current_cycle_start_date', value);

  List<String> get chemotherapyDrugs =>
      getListField<String>('chemotherapy_drugs');
  set chemotherapyDrugs(List<String>? value) =>
      setListField<String>('chemotherapy_drugs', value);

  String? get radiationSite => getField<String>('radiation_site');
  set radiationSite(String? value) => setField<String>('radiation_site', value);

  double? get totalDoseGy => getField<double>('total_dose_gy');
  set totalDoseGy(double? value) => setField<double>('total_dose_gy', value);

  int? get fractionsCompleted => getField<int>('fractions_completed');
  set fractionsCompleted(int? value) =>
      setField<int>('fractions_completed', value);

  int? get totalFractionsPlanned => getField<int>('total_fractions_planned');
  set totalFractionsPlanned(int? value) =>
      setField<int>('total_fractions_planned', value);

  int? get ecogPerformanceStatus => getField<int>('ecog_performance_status');
  set ecogPerformanceStatus(int? value) =>
      setField<int>('ecog_performance_status', value);

  int? get karnofskyScore => getField<int>('karnofsky_score');
  set karnofskyScore(int? value) => setField<int>('karnofsky_score', value);

  String? get responseToTreatment => getField<String>('response_to_treatment');
  set responseToTreatment(String? value) =>
      setField<String>('response_to_treatment', value);

  dynamic? get tumorMarkers => getField<dynamic>('tumor_markers');
  set tumorMarkers(dynamic? value) => setField<dynamic>('tumor_markers', value);

  String? get imagingResults => getField<String>('imaging_results');
  set imagingResults(String? value) =>
      setField<String>('imaging_results', value);

  List<String> get sideEffects => getListField<String>('side_effects');
  set sideEffects(List<String>? value) =>
      setListField<String>('side_effects', value);

  List<String> get complications => getListField<String>('complications');
  set complications(List<String>? value) =>
      setListField<String>('complications', value);

  List<String> get supportiveCareNeeded =>
      getListField<String>('supportive_care_needed');
  set supportiveCareNeeded(List<String>? value) =>
      setListField<String>('supportive_care_needed', value);

  DateTime? get nextTreatmentDate => getField<DateTime>('next_treatment_date');
  set nextTreatmentDate(DateTime? value) =>
      setField<DateTime>('next_treatment_date', value);

  DateTime? get nextImagingDate => getField<DateTime>('next_imaging_date');
  set nextImagingDate(DateTime? value) =>
      setField<DateTime>('next_imaging_date', value);

  String? get followUpInstructions =>
      getField<String>('follow_up_instructions');
  set followUpInstructions(String? value) =>
      setField<String>('follow_up_instructions', value);

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
