import '../database.dart';

class CardiologyVisitsTable extends SupabaseTable<CardiologyVisitsRow> {
  @override
  String get tableName => 'cardiology_visits';

  @override
  CardiologyVisitsRow createRow(Map<String, dynamic> data) =>
      CardiologyVisitsRow(data);
}

class CardiologyVisitsRow extends SupabaseDataRow {
  CardiologyVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CardiologyVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get cardiologistId => getField<String>('cardiologist_id');
  set cardiologistId(String? value) =>
      setField<String>('cardiologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get visitDate => getField<DateTime>('visit_date')!;
  set visitDate(DateTime value) => setField<DateTime>('visit_date', value);

  String? get visitType => getField<String>('visit_type');
  set visitType(String? value) => setField<String>('visit_type', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  List<String> get cardiacHistory => getListField<String>('cardiac_history');
  set cardiacHistory(List<String>? value) =>
      setListField<String>('cardiac_history', value);

  List<String> get riskFactors => getListField<String>('risk_factors');
  set riskFactors(List<String>? value) =>
      setListField<String>('risk_factors', value);

  List<String> get currentMedications =>
      getListField<String>('current_medications');
  set currentMedications(List<String>? value) =>
      setListField<String>('current_medications', value);

  int? get heartRate => getField<int>('heart_rate');
  set heartRate(int? value) => setField<int>('heart_rate', value);

  int? get bloodPressureSystolic => getField<int>('blood_pressure_systolic');
  set bloodPressureSystolic(int? value) =>
      setField<int>('blood_pressure_systolic', value);

  int? get bloodPressureDiastolic => getField<int>('blood_pressure_diastolic');
  set bloodPressureDiastolic(int? value) =>
      setField<int>('blood_pressure_diastolic', value);

  String? get cardiacRhythm => getField<String>('cardiac_rhythm');
  set cardiacRhythm(String? value) => setField<String>('cardiac_rhythm', value);

  String? get heartSounds => getField<String>('heart_sounds');
  set heartSounds(String? value) => setField<String>('heart_sounds', value);

  String? get murmurs => getField<String>('murmurs');
  set murmurs(String? value) => setField<String>('murmurs', value);

  String? get ecgFindings => getField<String>('ecg_findings');
  set ecgFindings(String? value) => setField<String>('ecg_findings', value);

  String? get ecgInterpretation => getField<String>('ecg_interpretation');
  set ecgInterpretation(String? value) =>
      setField<String>('ecg_interpretation', value);

  String? get echocardiogramFindings =>
      getField<String>('echocardiogram_findings');
  set echocardiogramFindings(String? value) =>
      setField<String>('echocardiogram_findings', value);

  double? get ejectionFractionPercent =>
      getField<double>('ejection_fraction_percent');
  set ejectionFractionPercent(double? value) =>
      setField<double>('ejection_fraction_percent', value);

  String? get stressTestResults => getField<String>('stress_test_results');
  set stressTestResults(String? value) =>
      setField<String>('stress_test_results', value);

  dynamic? get cardiacBiomarkers => getField<dynamic>('cardiac_biomarkers');
  set cardiacBiomarkers(dynamic? value) =>
      setField<dynamic>('cardiac_biomarkers', value);

  String? get imagingResults => getField<String>('imaging_results');
  set imagingResults(String? value) =>
      setField<String>('imaging_results', value);

  List<String> get diagnoses => getListField<String>('diagnoses');
  set diagnoses(List<String>? value) =>
      setListField<String>('diagnoses', value);

  int? get nyhaClass => getField<int>('nyha_class');
  set nyhaClass(int? value) => setField<int>('nyha_class', value);

  List<String> get medicationsPrescribed =>
      getListField<String>('medications_prescribed');
  set medicationsPrescribed(List<String>? value) =>
      setListField<String>('medications_prescribed', value);

  List<String> get lifestyleModifications =>
      getListField<String>('lifestyle_modifications');
  set lifestyleModifications(List<String>? value) =>
      setListField<String>('lifestyle_modifications', value);

  List<String> get proceduresRecommended =>
      getListField<String>('procedures_recommended');
  set proceduresRecommended(List<String>? value) =>
      setListField<String>('procedures_recommended', value);

  bool? get procedureScheduled => getField<bool>('procedure_scheduled');
  set procedureScheduled(bool? value) =>
      setField<bool>('procedure_scheduled', value);

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
