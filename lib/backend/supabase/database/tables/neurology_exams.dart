import '../database.dart';

class NeurologyExamsTable extends SupabaseTable<NeurologyExamsRow> {
  @override
  String get tableName => 'neurology_exams';

  @override
  NeurologyExamsRow createRow(Map<String, dynamic> data) =>
      NeurologyExamsRow(data);
}

class NeurologyExamsRow extends SupabaseDataRow {
  NeurologyExamsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NeurologyExamsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get neurologistId => getField<String>('neurologist_id');
  set neurologistId(String? value) => setField<String>('neurologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get examDate => getField<DateTime>('exam_date')!;
  set examDate(DateTime value) => setField<DateTime>('exam_date', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  List<String> get neurologicalSymptoms =>
      getListField<String>('neurological_symptoms');
  set neurologicalSymptoms(List<String>? value) =>
      setListField<String>('neurological_symptoms', value);

  List<String> get neurologicalConditions =>
      getListField<String>('neurological_conditions');
  set neurologicalConditions(List<String>? value) =>
      setListField<String>('neurological_conditions', value);

  bool? get seizureHistory => getField<bool>('seizure_history');
  set seizureHistory(bool? value) => setField<bool>('seizure_history', value);

  DateTime? get lastSeizureDate => getField<DateTime>('last_seizure_date');
  set lastSeizureDate(DateTime? value) =>
      setField<DateTime>('last_seizure_date', value);

  String? get seizureFrequency => getField<String>('seizure_frequency');
  set seizureFrequency(String? value) =>
      setField<String>('seizure_frequency', value);

  int? get glasgowComaScore => getField<int>('glasgow_coma_score');
  set glasgowComaScore(int? value) =>
      setField<int>('glasgow_coma_score', value);

  String? get mentalStatus => getField<String>('mental_status');
  set mentalStatus(String? value) => setField<String>('mental_status', value);

  String? get cranialNerves => getField<String>('cranial_nerves');
  set cranialNerves(String? value) => setField<String>('cranial_nerves', value);

  String? get motorExamination => getField<String>('motor_examination');
  set motorExamination(String? value) =>
      setField<String>('motor_examination', value);

  String? get sensoryExamination => getField<String>('sensory_examination');
  set sensoryExamination(String? value) =>
      setField<String>('sensory_examination', value);

  String? get reflexes => getField<String>('reflexes');
  set reflexes(String? value) => setField<String>('reflexes', value);

  String? get coordination => getField<String>('coordination');
  set coordination(String? value) => setField<String>('coordination', value);

  String? get gait => getField<String>('gait');
  set gait(String? value) => setField<String>('gait', value);

  String? get eegResults => getField<String>('eeg_results');
  set eegResults(String? value) => setField<String>('eeg_results', value);

  String? get mriFindings => getField<String>('mri_findings');
  set mriFindings(String? value) => setField<String>('mri_findings', value);

  String? get ctFindings => getField<String>('ct_findings');
  set ctFindings(String? value) => setField<String>('ct_findings', value);

  String? get nerveConductionStudies =>
      getField<String>('nerve_conduction_studies');
  set nerveConductionStudies(String? value) =>
      setField<String>('nerve_conduction_studies', value);

  String? get lumbarPunctureResults =>
      getField<String>('lumbar_puncture_results');
  set lumbarPunctureResults(String? value) =>
      setField<String>('lumbar_puncture_results', value);

  List<String> get diagnoses => getListField<String>('diagnoses');
  set diagnoses(List<String>? value) =>
      setListField<String>('diagnoses', value);

  String? get strokeType => getField<String>('stroke_type');
  set strokeType(String? value) => setField<String>('stroke_type', value);

  int? get nihssScore => getField<int>('nihss_score');
  set nihssScore(int? value) => setField<int>('nihss_score', value);

  List<String> get medicationsPrescribed =>
      getListField<String>('medications_prescribed');
  set medicationsPrescribed(List<String>? value) =>
      setListField<String>('medications_prescribed', value);

  bool? get rehabilitationRecommended =>
      getField<bool>('rehabilitation_recommended');
  set rehabilitationRecommended(bool? value) =>
      setField<bool>('rehabilitation_recommended', value);

  bool? get neurosurgeryConsulted => getField<bool>('neurosurgery_consulted');
  set neurosurgeryConsulted(bool? value) =>
      setField<bool>('neurosurgery_consulted', value);

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
