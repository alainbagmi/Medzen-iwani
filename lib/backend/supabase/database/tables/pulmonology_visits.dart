import '../database.dart';

class PulmonologyVisitsTable extends SupabaseTable<PulmonologyVisitsRow> {
  @override
  String get tableName => 'pulmonology_visits';

  @override
  PulmonologyVisitsRow createRow(Map<String, dynamic> data) =>
      PulmonologyVisitsRow(data);
}

class PulmonologyVisitsRow extends SupabaseDataRow {
  PulmonologyVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PulmonologyVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get pulmonologistId => getField<String>('pulmonologist_id');
  set pulmonologistId(String? value) =>
      setField<String>('pulmonologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get visitDate => getField<DateTime>('visit_date')!;
  set visitDate(DateTime value) => setField<DateTime>('visit_date', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  List<String> get respiratorySymptoms =>
      getListField<String>('respiratory_symptoms');
  set respiratorySymptoms(List<String>? value) =>
      setListField<String>('respiratory_symptoms', value);

  List<String> get chronicConditions =>
      getListField<String>('chronic_conditions');
  set chronicConditions(List<String>? value) =>
      setListField<String>('chronic_conditions', value);

  String? get smokingStatus => getField<String>('smoking_status');
  set smokingStatus(String? value) => setField<String>('smoking_status', value);

  double? get packYears => getField<double>('pack_years');
  set packYears(double? value) => setField<double>('pack_years', value);

  int? get respiratoryRate => getField<int>('respiratory_rate');
  set respiratoryRate(int? value) => setField<int>('respiratory_rate', value);

  double? get oxygenSaturation => getField<double>('oxygen_saturation');
  set oxygenSaturation(double? value) =>
      setField<double>('oxygen_saturation', value);

  String? get breathSounds => getField<String>('breath_sounds');
  set breathSounds(String? value) => setField<String>('breath_sounds', value);

  bool? get useOfAccessoryMuscles => getField<bool>('use_of_accessory_muscles');
  set useOfAccessoryMuscles(bool? value) =>
      setField<bool>('use_of_accessory_muscles', value);

  dynamic? get spirometryResults => getField<dynamic>('spirometry_results');
  set spirometryResults(dynamic? value) =>
      setField<dynamic>('spirometry_results', value);

  String? get chestXrayFindings => getField<String>('chest_xray_findings');
  set chestXrayFindings(String? value) =>
      setField<String>('chest_xray_findings', value);

  String? get ctScanFindings => getField<String>('ct_scan_findings');
  set ctScanFindings(String? value) =>
      setField<String>('ct_scan_findings', value);

  dynamic? get arterialBloodGas => getField<dynamic>('arterial_blood_gas');
  set arterialBloodGas(dynamic? value) =>
      setField<dynamic>('arterial_blood_gas', value);

  List<String> get inhalerTherapy => getListField<String>('inhaler_therapy');
  set inhalerTherapy(List<String>? value) =>
      setListField<String>('inhaler_therapy', value);

  bool? get oxygenTherapy => getField<bool>('oxygen_therapy');
  set oxygenTherapy(bool? value) => setField<bool>('oxygen_therapy', value);

  double? get oxygenFlowRateLpm => getField<double>('oxygen_flow_rate_lpm');
  set oxygenFlowRateLpm(double? value) =>
      setField<double>('oxygen_flow_rate_lpm', value);

  List<String> get medicationsPrescribed =>
      getListField<String>('medications_prescribed');
  set medicationsPrescribed(List<String>? value) =>
      setListField<String>('medications_prescribed', value);

  bool? get pulmonaryRehabilitationRecommended =>
      getField<bool>('pulmonary_rehabilitation_recommended');
  set pulmonaryRehabilitationRecommended(bool? value) =>
      setField<bool>('pulmonary_rehabilitation_recommended', value);

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
