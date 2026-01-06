import '../database.dart';

class ClinicalNotesTable extends SupabaseTable<ClinicalNotesRow> {
  @override
  String get tableName => 'clinical_notes';

  @override
  ClinicalNotesRow createRow(Map<String, dynamic> data) =>
      ClinicalNotesRow(data);
}

class ClinicalNotesRow extends SupabaseDataRow {
  ClinicalNotesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ClinicalNotesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get appointmentId => getField<String>('appointment_id')!;
  set appointmentId(String value) => setField<String>('appointment_id', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  String get providerId => getField<String>('provider_id')!;
  set providerId(String value) => setField<String>('provider_id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get subjective => getField<String>('subjective');
  set subjective(String? value) => setField<String>('subjective', value);

  String? get objective => getField<String>('objective');
  set objective(String? value) => setField<String>('objective', value);

  String? get assessment => getField<String>('assessment');
  set assessment(String? value) => setField<String>('assessment', value);

  String? get plan => getField<String>('plan');
  set plan(String? value) => setField<String>('plan', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  String? get historyOfPresentIllness =>
      getField<String>('history_of_present_illness');
  set historyOfPresentIllness(String? value) =>
      setField<String>('history_of_present_illness', value);

  dynamic? get reviewOfSystems => getField<dynamic>('review_of_systems');
  set reviewOfSystems(dynamic? value) =>
      setField<dynamic>('review_of_systems', value);

  dynamic? get physicalExamination => getField<dynamic>('physical_examination');
  set physicalExamination(dynamic? value) =>
      setField<dynamic>('physical_examination', value);

  dynamic? get icd10Codes => getField<dynamic>('icd10_codes');
  set icd10Codes(dynamic? value) => setField<dynamic>('icd10_codes', value);

  dynamic? get cptCodes => getField<dynamic>('cpt_codes');
  set cptCodes(dynamic? value) => setField<dynamic>('cpt_codes', value);

  String? get noteType => getField<String>('note_type');
  set noteType(String? value) => setField<String>('note_type', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get signedAt => getField<DateTime>('signed_at');
  set signedAt(DateTime? value) => setField<DateTime>('signed_at', value);

  String? get signedBy => getField<String>('signed_by');
  set signedBy(String? value) => setField<String>('signed_by', value);

  String? get signatureHash => getField<String>('signature_hash');
  set signatureHash(String? value) => setField<String>('signature_hash', value);

  String? get providerSignature => getField<String>('provider_signature');
  set providerSignature(String? value) =>
      setField<String>('provider_signature', value);

  bool? get aiGenerated => getField<bool>('ai_generated');
  set aiGenerated(bool? value) => setField<bool>('ai_generated', value);

  String? get aiModel => getField<String>('ai_model');
  set aiModel(String? value) => setField<String>('ai_model', value);

  double? get aiConfidenceScore => getField<double>('ai_confidence_score');
  set aiConfidenceScore(double? value) =>
      setField<double>('ai_confidence_score', value);

  int? get aiGenerationTimeMs => getField<int>('ai_generation_time_ms');
  set aiGenerationTimeMs(int? value) =>
      setField<int>('ai_generation_time_ms', value);

  String? get originalTranscriptId =>
      getField<String>('original_transcript_id');
  set originalTranscriptId(String? value) =>
      setField<String>('original_transcript_id', value);

  String? get transcriptLanguage => getField<String>('transcript_language');
  set transcriptLanguage(String? value) =>
      setField<String>('transcript_language', value);

  dynamic? get medicalEntities => getField<dynamic>('medical_entities');
  set medicalEntities(dynamic? value) =>
      setField<dynamic>('medical_entities', value);

  String? get ehrbaseCompositionUid =>
      getField<String>('ehrbase_composition_uid');
  set ehrbaseCompositionUid(String? value) =>
      setField<String>('ehrbase_composition_uid', value);

  DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
  set ehrbaseSyncedAt(DateTime? value) =>
      setField<DateTime>('ehrbase_synced_at', value);

  String? get ehrbaseSyncStatus => getField<String>('ehrbase_sync_status');
  set ehrbaseSyncStatus(String? value) =>
      setField<String>('ehrbase_sync_status', value);

  String? get ehrbaseSyncError => getField<String>('ehrbase_sync_error');
  set ehrbaseSyncError(String? value) =>
      setField<String>('ehrbase_sync_error', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get lastEditedBy => getField<String>('last_edited_by');
  set lastEditedBy(String? value) => setField<String>('last_edited_by', value);

  int? get version => getField<int>('version');
  set version(int? value) => setField<int>('version', value);

  String? get previousVersionId => getField<String>('previous_version_id');
  set previousVersionId(String? value) =>
      setField<String>('previous_version_id', value);

  String? get ehrbaseCompositionId =>
      getField<String>('ehrbase_composition_id');
  set ehrbaseCompositionId(String? value) =>
      setField<String>('ehrbase_composition_id', value);
}
