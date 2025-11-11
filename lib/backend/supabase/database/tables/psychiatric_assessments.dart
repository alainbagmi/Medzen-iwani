import '../database.dart';

class PsychiatricAssessmentsTable
    extends SupabaseTable<PsychiatricAssessmentsRow> {
  @override
  String get tableName => 'psychiatric_assessments';

  @override
  PsychiatricAssessmentsRow createRow(Map<String, dynamic> data) =>
      PsychiatricAssessmentsRow(data);
}

class PsychiatricAssessmentsRow extends SupabaseDataRow {
  PsychiatricAssessmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PsychiatricAssessmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get psychiatristId => getField<String>('psychiatrist_id');
  set psychiatristId(String? value) =>
      setField<String>('psychiatrist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get assessmentDate => getField<DateTime>('assessment_date')!;
  set assessmentDate(DateTime value) =>
      setField<DateTime>('assessment_date', value);

  String? get assessmentType => getField<String>('assessment_type');
  set assessmentType(String? value) =>
      setField<String>('assessment_type', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  String? get appearance => getField<String>('appearance');
  set appearance(String? value) => setField<String>('appearance', value);

  String? get behavior => getField<String>('behavior');
  set behavior(String? value) => setField<String>('behavior', value);

  String? get speech => getField<String>('speech');
  set speech(String? value) => setField<String>('speech', value);

  String? get mood => getField<String>('mood');
  set mood(String? value) => setField<String>('mood', value);

  String? get affect => getField<String>('affect');
  set affect(String? value) => setField<String>('affect', value);

  String? get thoughtProcess => getField<String>('thought_process');
  set thoughtProcess(String? value) =>
      setField<String>('thought_process', value);

  String? get thoughtContent => getField<String>('thought_content');
  set thoughtContent(String? value) =>
      setField<String>('thought_content', value);

  String? get perceptions => getField<String>('perceptions');
  set perceptions(String? value) => setField<String>('perceptions', value);

  String? get cognition => getField<String>('cognition');
  set cognition(String? value) => setField<String>('cognition', value);

  String? get insight => getField<String>('insight');
  set insight(String? value) => setField<String>('insight', value);

  String? get judgment => getField<String>('judgment');
  set judgment(String? value) => setField<String>('judgment', value);

  String? get suicideRisk => getField<String>('suicide_risk');
  set suicideRisk(String? value) => setField<String>('suicide_risk', value);

  String? get homicideRisk => getField<String>('homicide_risk');
  set homicideRisk(String? value) => setField<String>('homicide_risk', value);

  String? get selfHarmRisk => getField<String>('self_harm_risk');
  set selfHarmRisk(String? value) => setField<String>('self_harm_risk', value);

  List<String> get riskFactors => getListField<String>('risk_factors');
  set riskFactors(List<String>? value) =>
      setListField<String>('risk_factors', value);

  List<String> get protectiveFactors =>
      getListField<String>('protective_factors');
  set protectiveFactors(List<String>? value) =>
      setListField<String>('protective_factors', value);

  List<String> get psychiatricDiagnoses =>
      getListField<String>('psychiatric_diagnoses');
  set psychiatricDiagnoses(List<String>? value) =>
      setListField<String>('psychiatric_diagnoses', value);

  List<String> get dsmVCodes => getListField<String>('dsm_v_codes');
  set dsmVCodes(List<String>? value) =>
      setListField<String>('dsm_v_codes', value);

  List<String> get icdCodes => getListField<String>('icd_codes');
  set icdCodes(List<String>? value) => setListField<String>('icd_codes', value);

  int? get phq9Score => getField<int>('phq9_score');
  set phq9Score(int? value) => setField<int>('phq9_score', value);

  int? get gad7Score => getField<int>('gad7_score');
  set gad7Score(int? value) => setField<int>('gad7_score', value);

  bool? get moodDisorderQuestionnairePositive =>
      getField<bool>('mood_disorder_questionnaire_positive');
  set moodDisorderQuestionnairePositive(bool? value) =>
      setField<bool>('mood_disorder_questionnaire_positive', value);

  String? get psychotherapyType => getField<String>('psychotherapy_type');
  set psychotherapyType(String? value) =>
      setField<String>('psychotherapy_type', value);

  List<String> get medicationsPrescribed =>
      getListField<String>('medications_prescribed');
  set medicationsPrescribed(List<String>? value) =>
      setListField<String>('medications_prescribed', value);

  bool? get hospitalizationRecommended =>
      getField<bool>('hospitalization_recommended');
  set hospitalizationRecommended(bool? value) =>
      setField<bool>('hospitalization_recommended', value);

  String? get safetyPlan => getField<String>('safety_plan');
  set safetyPlan(String? value) => setField<String>('safety_plan', value);

  DateTime? get nextAppointmentDate =>
      getField<DateTime>('next_appointment_date');
  set nextAppointmentDate(DateTime? value) =>
      setField<DateTime>('next_appointment_date', value);

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
