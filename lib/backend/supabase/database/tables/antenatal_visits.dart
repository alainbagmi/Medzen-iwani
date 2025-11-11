import '../database.dart';

class AntenatalVisitsTable extends SupabaseTable<AntenatalVisitsRow> {
  @override
  String get tableName => 'antenatal_visits';

  @override
  AntenatalVisitsRow createRow(Map<String, dynamic> data) =>
      AntenatalVisitsRow(data);
}

class AntenatalVisitsRow extends SupabaseDataRow {
  AntenatalVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AntenatalVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  int get visitNumber => getField<int>('visit_number')!;
  set visitNumber(int value) => setField<int>('visit_number', value);

  int? get gestationalAgeWeeks => getField<int>('gestational_age_weeks');
  set gestationalAgeWeeks(int? value) =>
      setField<int>('gestational_age_weeks', value);

  int? get gestationalAgeDays => getField<int>('gestational_age_days');
  set gestationalAgeDays(int? value) =>
      setField<int>('gestational_age_days', value);

  DateTime get visitDate => getField<DateTime>('visit_date')!;
  set visitDate(DateTime value) => setField<DateTime>('visit_date', value);

  String? get visitType => getField<String>('visit_type');
  set visitType(String? value) => setField<String>('visit_type', value);

  double? get weightKg => getField<double>('weight_kg');
  set weightKg(double? value) => setField<double>('weight_kg', value);

  int? get bloodPressureSystolic => getField<int>('blood_pressure_systolic');
  set bloodPressureSystolic(int? value) =>
      setField<int>('blood_pressure_systolic', value);

  int? get bloodPressureDiastolic => getField<int>('blood_pressure_diastolic');
  set bloodPressureDiastolic(int? value) =>
      setField<int>('blood_pressure_diastolic', value);

  double? get fundalHeightCm => getField<double>('fundal_height_cm');
  set fundalHeightCm(double? value) =>
      setField<double>('fundal_height_cm', value);

  int? get fetalHeartRate => getField<int>('fetal_heart_rate');
  set fetalHeartRate(int? value) => setField<int>('fetal_heart_rate', value);

  String? get fetalPresentation => getField<String>('fetal_presentation');
  set fetalPresentation(String? value) =>
      setField<String>('fetal_presentation', value);

  String? get fetalMovement => getField<String>('fetal_movement');
  set fetalMovement(String? value) => setField<String>('fetal_movement', value);

  bool? get multiplePregnancy => getField<bool>('multiple_pregnancy');
  set multiplePregnancy(bool? value) =>
      setField<bool>('multiple_pregnancy', value);

  int? get numberOfFetuses => getField<int>('number_of_fetuses');
  set numberOfFetuses(int? value) => setField<int>('number_of_fetuses', value);

  String? get edemaStatus => getField<String>('edema_status');
  set edemaStatus(String? value) => setField<String>('edema_status', value);

  String? get proteinuria => getField<String>('proteinuria');
  set proteinuria(String? value) => setField<String>('proteinuria', value);

  String? get urineGlucose => getField<String>('urine_glucose');
  set urineGlucose(String? value) => setField<String>('urine_glucose', value);

  String? get riskLevel => getField<String>('risk_level');
  set riskLevel(String? value) => setField<String>('risk_level', value);

  List<String> get riskFactors => getListField<String>('risk_factors');
  set riskFactors(List<String>? value) =>
      setListField<String>('risk_factors', value);

  List<String> get complications => getListField<String>('complications');
  set complications(List<String>? value) =>
      setListField<String>('complications', value);

  List<String> get labTestsOrdered => getListField<String>('lab_tests_ordered');
  set labTestsOrdered(List<String>? value) =>
      setListField<String>('lab_tests_ordered', value);

  bool? get ultrasoundOrdered => getField<bool>('ultrasound_ordered');
  set ultrasoundOrdered(bool? value) =>
      setField<bool>('ultrasound_ordered', value);

  DateTime? get ultrasoundDate => getField<DateTime>('ultrasound_date');
  set ultrasoundDate(DateTime? value) =>
      setField<DateTime>('ultrasound_date', value);

  List<String> get medicationsPrescribed =>
      getListField<String>('medications_prescribed');
  set medicationsPrescribed(List<String>? value) =>
      setListField<String>('medications_prescribed', value);

  List<String> get supplementsPrescribed =>
      getListField<String>('supplements_prescribed');
  set supplementsPrescribed(List<String>? value) =>
      setListField<String>('supplements_prescribed', value);

  String? get adviceGiven => getField<String>('advice_given');
  set adviceGiven(String? value) => setField<String>('advice_given', value);

  DateTime? get nextVisitDate => getField<DateTime>('next_visit_date');
  set nextVisitDate(DateTime? value) =>
      setField<DateTime>('next_visit_date', value);

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
