import '../database.dart';

class PhysiotherapySessionsTable
    extends SupabaseTable<PhysiotherapySessionsRow> {
  @override
  String get tableName => 'physiotherapy_sessions';

  @override
  PhysiotherapySessionsRow createRow(Map<String, dynamic> data) =>
      PhysiotherapySessionsRow(data);
}

class PhysiotherapySessionsRow extends SupabaseDataRow {
  PhysiotherapySessionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PhysiotherapySessionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get physiotherapistId => getField<String>('physiotherapist_id');
  set physiotherapistId(String? value) =>
      setField<String>('physiotherapist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get sessionDate => getField<DateTime>('session_date')!;
  set sessionDate(DateTime value) => setField<DateTime>('session_date', value);

  int? get sessionNumber => getField<int>('session_number');
  set sessionNumber(int? value) => setField<int>('session_number', value);

  int? get sessionDurationMinutes => getField<int>('session_duration_minutes');
  set sessionDurationMinutes(int? value) =>
      setField<int>('session_duration_minutes', value);

  String? get referringCondition => getField<String>('referring_condition');
  set referringCondition(String? value) =>
      setField<String>('referring_condition', value);

  String? get referralDiagnosis => getField<String>('referral_diagnosis');
  set referralDiagnosis(String? value) =>
      setField<String>('referral_diagnosis', value);

  List<String> get treatmentGoals => getListField<String>('treatment_goals');
  set treatmentGoals(List<String>? value) =>
      setListField<String>('treatment_goals', value);

  String? get subjectiveAssessment => getField<String>('subjective_assessment');
  set subjectiveAssessment(String? value) =>
      setField<String>('subjective_assessment', value);

  String? get objectiveFindings => getField<String>('objective_findings');
  set objectiveFindings(String? value) =>
      setField<String>('objective_findings', value);

  int? get painLevel => getField<int>('pain_level');
  set painLevel(int? value) => setField<int>('pain_level', value);

  String? get painLocation => getField<String>('pain_location');
  set painLocation(String? value) => setField<String>('pain_location', value);

  dynamic? get rangeOfMotion => getField<dynamic>('range_of_motion');
  set rangeOfMotion(dynamic? value) =>
      setField<dynamic>('range_of_motion', value);

  dynamic? get muscleStrength => getField<dynamic>('muscle_strength');
  set muscleStrength(dynamic? value) =>
      setField<dynamic>('muscle_strength', value);

  String? get balanceAssessment => getField<String>('balance_assessment');
  set balanceAssessment(String? value) =>
      setField<String>('balance_assessment', value);

  String? get gaitAssessment => getField<String>('gait_assessment');
  set gaitAssessment(String? value) =>
      setField<String>('gait_assessment', value);

  int? get functionalMobilityScore =>
      getField<int>('functional_mobility_score');
  set functionalMobilityScore(int? value) =>
      setField<int>('functional_mobility_score', value);

  List<String> get modalitiesUsed => getListField<String>('modalities_used');
  set modalitiesUsed(List<String>? value) =>
      setListField<String>('modalities_used', value);

  List<String> get exercisesPrescribed =>
      getListField<String>('exercises_prescribed');
  set exercisesPrescribed(List<String>? value) =>
      setListField<String>('exercises_prescribed', value);

  String? get homeExerciseProgram => getField<String>('home_exercise_program');
  set homeExerciseProgram(String? value) =>
      setField<String>('home_exercise_program', value);

  List<String> get equipmentUsed => getListField<String>('equipment_used');
  set equipmentUsed(List<String>? value) =>
      setListField<String>('equipment_used', value);

  String? get progressNotes => getField<String>('progress_notes');
  set progressNotes(String? value) => setField<String>('progress_notes', value);

  String? get functionalImprovements =>
      getField<String>('functional_improvements');
  set functionalImprovements(String? value) =>
      setField<String>('functional_improvements', value);

  List<String> get barriersToProgress =>
      getListField<String>('barriers_to_progress');
  set barriersToProgress(List<String>? value) =>
      setListField<String>('barriers_to_progress', value);

  DateTime? get nextSessionDate => getField<DateTime>('next_session_date');
  set nextSessionDate(DateTime? value) =>
      setField<DateTime>('next_session_date', value);

  int? get sessionsRemaining => getField<int>('sessions_remaining');
  set sessionsRemaining(int? value) =>
      setField<int>('sessions_remaining', value);

  bool? get dischargePlanned => getField<bool>('discharge_planned');
  set dischargePlanned(bool? value) =>
      setField<bool>('discharge_planned', value);

  String? get dischargeCriteria => getField<String>('discharge_criteria');
  set dischargeCriteria(String? value) =>
      setField<String>('discharge_criteria', value);

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
