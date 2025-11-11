import '../database.dart';

class EmergencyVisitsTable extends SupabaseTable<EmergencyVisitsRow> {
  @override
  String get tableName => 'emergency_visits';

  @override
  EmergencyVisitsRow createRow(Map<String, dynamic> data) =>
      EmergencyVisitsRow(data);
}

class EmergencyVisitsRow extends SupabaseDataRow {
  EmergencyVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EmergencyVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get emergencyPhysicianId =>
      getField<String>('emergency_physician_id');
  set emergencyPhysicianId(String? value) =>
      setField<String>('emergency_physician_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get arrivalTime => getField<DateTime>('arrival_time')!;
  set arrivalTime(DateTime value) => setField<DateTime>('arrival_time', value);

  DateTime? get departureTime => getField<DateTime>('departure_time');
  set departureTime(DateTime? value) =>
      setField<DateTime>('departure_time', value);

  int? get lengthOfStayMinutes => getField<int>('length_of_stay_minutes');
  set lengthOfStayMinutes(int? value) =>
      setField<int>('length_of_stay_minutes', value);

  String? get triageCategory => getField<String>('triage_category');
  set triageCategory(String? value) =>
      setField<String>('triage_category', value);

  DateTime? get triageTime => getField<DateTime>('triage_time');
  set triageTime(DateTime? value) => setField<DateTime>('triage_time', value);

  String get chiefComplaint => getField<String>('chief_complaint')!;
  set chiefComplaint(String value) =>
      setField<String>('chief_complaint', value);

  String? get modeOfArrival => getField<String>('mode_of_arrival');
  set modeOfArrival(String? value) =>
      setField<String>('mode_of_arrival', value);

  dynamic? get initialVitalSigns => getField<dynamic>('initial_vital_signs');
  set initialVitalSigns(dynamic? value) =>
      setField<dynamic>('initial_vital_signs', value);

  int? get glasgowComaScore => getField<int>('glasgow_coma_score');
  set glasgowComaScore(int? value) =>
      setField<int>('glasgow_coma_score', value);

  int? get painScore => getField<int>('pain_score');
  set painScore(int? value) => setField<int>('pain_score', value);

  bool? get trauma => getField<bool>('trauma');
  set trauma(bool? value) => setField<bool>('trauma', value);

  String? get mechanismOfInjury => getField<String>('mechanism_of_injury');
  set mechanismOfInjury(String? value) =>
      setField<String>('mechanism_of_injury', value);

  bool? get resuscitationPerformed => getField<bool>('resuscitation_performed');
  set resuscitationPerformed(bool? value) =>
      setField<bool>('resuscitation_performed', value);

  bool? get cprPerformed => getField<bool>('cpr_performed');
  set cprPerformed(bool? value) => setField<bool>('cpr_performed', value);

  bool? get defibrillationPerformed =>
      getField<bool>('defibrillation_performed');
  set defibrillationPerformed(bool? value) =>
      setField<bool>('defibrillation_performed', value);

  String? get airwayManagement => getField<String>('airway_management');
  set airwayManagement(String? value) =>
      setField<String>('airway_management', value);

  int? get fluidsAdministeredMl => getField<int>('fluids_administered_ml');
  set fluidsAdministeredMl(int? value) =>
      setField<int>('fluids_administered_ml', value);

  bool? get bloodProductsGiven => getField<bool>('blood_products_given');
  set bloodProductsGiven(bool? value) =>
      setField<bool>('blood_products_given', value);

  List<String> get labTestsOrdered => getListField<String>('lab_tests_ordered');
  set labTestsOrdered(List<String>? value) =>
      setListField<String>('lab_tests_ordered', value);

  List<String> get imagingPerformed =>
      getListField<String>('imaging_performed');
  set imagingPerformed(List<String>? value) =>
      setListField<String>('imaging_performed', value);

  List<String> get proceduresPerformed =>
      getListField<String>('procedures_performed');
  set proceduresPerformed(List<String>? value) =>
      setListField<String>('procedures_performed', value);

  List<String> get emergencyDiagnosis =>
      getListField<String>('emergency_diagnosis');
  set emergencyDiagnosis(List<String>? value) =>
      setListField<String>('emergency_diagnosis', value);

  List<String> get medicationsAdministered =>
      getListField<String>('medications_administered');
  set medicationsAdministered(List<String>? value) =>
      setListField<String>('medications_administered', value);

  List<String> get interventions => getListField<String>('interventions');
  set interventions(List<String>? value) =>
      setListField<String>('interventions', value);

  String? get disposition => getField<String>('disposition');
  set disposition(String? value) => setField<String>('disposition', value);

  String? get admittedToWard => getField<String>('admitted_to_ward');
  set admittedToWard(String? value) =>
      setField<String>('admitted_to_ward', value);

  String? get dischargeInstructions =>
      getField<String>('discharge_instructions');
  set dischargeInstructions(String? value) =>
      setField<String>('discharge_instructions', value);

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
