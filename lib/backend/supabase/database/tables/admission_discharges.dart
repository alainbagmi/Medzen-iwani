import '../database.dart';

class AdmissionDischargesTable extends SupabaseTable<AdmissionDischargesRow> {
  @override
  String get tableName => 'admission_discharges';

  @override
  AdmissionDischargesRow createRow(Map<String, dynamic> data) =>
      AdmissionDischargesRow(data);
}

class AdmissionDischargesRow extends SupabaseDataRow {
  AdmissionDischargesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AdmissionDischargesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get admittingProviderId => getField<String>('admitting_provider_id');
  set admittingProviderId(String? value) =>
      setField<String>('admitting_provider_id', value);

  String? get dischargeProviderId => getField<String>('discharge_provider_id');
  set dischargeProviderId(String? value) =>
      setField<String>('discharge_provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get admissionDate => getField<DateTime>('admission_date')!;
  set admissionDate(DateTime value) =>
      setField<DateTime>('admission_date', value);

  String? get admissionType => getField<String>('admission_type');
  set admissionType(String? value) => setField<String>('admission_type', value);

  String? get admissionSource => getField<String>('admission_source');
  set admissionSource(String? value) =>
      setField<String>('admission_source', value);

  String get admissionDiagnosis => getField<String>('admission_diagnosis')!;
  set admissionDiagnosis(String value) =>
      setField<String>('admission_diagnosis', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  dynamic? get admissionVitalSigns =>
      getField<dynamic>('admission_vital_signs');
  set admissionVitalSigns(dynamic? value) =>
      setField<dynamic>('admission_vital_signs', value);

  int? get admissionGlasgowComaScore =>
      getField<int>('admission_glasgow_coma_score');
  set admissionGlasgowComaScore(int? value) =>
      setField<int>('admission_glasgow_coma_score', value);

  String? get admissionConsciousnessLevel =>
      getField<String>('admission_consciousness_level');
  set admissionConsciousnessLevel(String? value) =>
      setField<String>('admission_consciousness_level', value);

  String? get wardType => getField<String>('ward_type');
  set wardType(String? value) => setField<String>('ward_type', value);

  String? get bedNumber => getField<String>('bed_number');
  set bedNumber(String? value) => setField<String>('bed_number', value);

  int? get lengthOfStayDays => getField<int>('length_of_stay_days');
  set lengthOfStayDays(int? value) =>
      setField<int>('length_of_stay_days', value);

  List<String> get complicationsDuringStay =>
      getListField<String>('complications_during_stay');
  set complicationsDuringStay(List<String>? value) =>
      setListField<String>('complications_during_stay', value);

  List<String> get proceduresPerformed =>
      getListField<String>('procedures_performed');
  set proceduresPerformed(List<String>? value) =>
      setListField<String>('procedures_performed', value);

  List<String> get medicationsAdministered =>
      getListField<String>('medications_administered');
  set medicationsAdministered(List<String>? value) =>
      setListField<String>('medications_administered', value);

  List<String> get investigationsDone =>
      getListField<String>('investigations_done');
  set investigationsDone(List<String>? value) =>
      setListField<String>('investigations_done', value);

  List<String> get consultationsRequested =>
      getListField<String>('consultations_requested');
  set consultationsRequested(List<String>? value) =>
      setListField<String>('consultations_requested', value);

  DateTime? get dischargeDate => getField<DateTime>('discharge_date');
  set dischargeDate(DateTime? value) =>
      setField<DateTime>('discharge_date', value);

  String? get dischargeType => getField<String>('discharge_type');
  set dischargeType(String? value) => setField<String>('discharge_type', value);

  String? get dischargeDiagnosis => getField<String>('discharge_diagnosis');
  set dischargeDiagnosis(String? value) =>
      setField<String>('discharge_diagnosis', value);

  String? get dischargeCondition => getField<String>('discharge_condition');
  set dischargeCondition(String? value) =>
      setField<String>('discharge_condition', value);

  String? get dischargeDestination => getField<String>('discharge_destination');
  set dischargeDestination(String? value) =>
      setField<String>('discharge_destination', value);

  List<String> get dischargeMedications =>
      getListField<String>('discharge_medications');
  set dischargeMedications(List<String>? value) =>
      setListField<String>('discharge_medications', value);

  String? get dischargeInstructions =>
      getField<String>('discharge_instructions');
  set dischargeInstructions(String? value) =>
      setField<String>('discharge_instructions', value);

  String? get activityRestrictions => getField<String>('activity_restrictions');
  set activityRestrictions(String? value) =>
      setField<String>('activity_restrictions', value);

  String? get dietInstructions => getField<String>('diet_instructions');
  set dietInstructions(String? value) =>
      setField<String>('diet_instructions', value);

  DateTime? get followUpDate => getField<DateTime>('follow_up_date');
  set followUpDate(DateTime? value) =>
      setField<DateTime>('follow_up_date', value);

  String? get followUpProviderId => getField<String>('follow_up_provider_id');
  set followUpProviderId(String? value) =>
      setField<String>('follow_up_provider_id', value);

  DateTime? get deathDate => getField<DateTime>('death_date');
  set deathDate(DateTime? value) => setField<DateTime>('death_date', value);

  String? get causeOfDeath => getField<String>('cause_of_death');
  set causeOfDeath(String? value) => setField<String>('cause_of_death', value);

  bool? get autopsyPerformed => getField<bool>('autopsy_performed');
  set autopsyPerformed(bool? value) =>
      setField<bool>('autopsy_performed', value);

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
