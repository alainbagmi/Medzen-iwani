import '../database.dart';

class VitalSignsTable extends SupabaseTable<VitalSignsRow> {
  @override
  String get tableName => 'vital_signs';

  @override
  VitalSignsRow createRow(Map<String, dynamic> data) => VitalSignsRow(data);
}

class VitalSignsRow extends SupabaseDataRow {
  VitalSignsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VitalSignsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get recordedById => getField<String>('recorded_by_id');
  set recordedById(String? value) => setField<String>('recorded_by_id', value);

  double? get temperatureCelsius => getField<double>('temperature_celsius');
  set temperatureCelsius(double? value) =>
      setField<double>('temperature_celsius', value);

  int? get bloodPressureSystolic => getField<int>('blood_pressure_systolic');
  set bloodPressureSystolic(int? value) =>
      setField<int>('blood_pressure_systolic', value);

  int? get bloodPressureDiastolic => getField<int>('blood_pressure_diastolic');
  set bloodPressureDiastolic(int? value) =>
      setField<int>('blood_pressure_diastolic', value);

  int? get heartRateBpm => getField<int>('heart_rate_bpm');
  set heartRateBpm(int? value) => setField<int>('heart_rate_bpm', value);

  int? get respiratoryRate => getField<int>('respiratory_rate');
  set respiratoryRate(int? value) => setField<int>('respiratory_rate', value);

  double? get oxygenSaturation => getField<double>('oxygen_saturation');
  set oxygenSaturation(double? value) =>
      setField<double>('oxygen_saturation', value);

  double? get bloodGlucoseMgDl => getField<double>('blood_glucose_mg_dl');
  set bloodGlucoseMgDl(double? value) =>
      setField<double>('blood_glucose_mg_dl', value);

  double? get weightKg => getField<double>('weight_kg');
  set weightKg(double? value) => setField<double>('weight_kg', value);

  double? get heightCm => getField<double>('height_cm');
  set heightCm(double? value) => setField<double>('height_cm', value);

  double? get bmi => getField<double>('bmi');
  set bmi(double? value) => setField<double>('bmi', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  DateTime? get recordedAt => getField<DateTime>('recorded_at');
  set recordedAt(DateTime? value) => setField<DateTime>('recorded_at', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

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
}
