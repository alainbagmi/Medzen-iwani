import '../database.dart';

class ClinicalNotesOverviewTable
    extends SupabaseTable<ClinicalNotesOverviewRow> {
  @override
  String get tableName => 'clinical_notes_overview';

  @override
  ClinicalNotesOverviewRow createRow(Map<String, dynamic> data) =>
      ClinicalNotesOverviewRow(data);
}

class ClinicalNotesOverviewRow extends SupabaseDataRow {
  ClinicalNotesOverviewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ClinicalNotesOverviewTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get noteType => getField<String>('note_type');
  set noteType(String? value) => setField<String>('note_type', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  String? get assessment => getField<String>('assessment');
  set assessment(String? value) => setField<String>('assessment', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get signedAt => getField<DateTime>('signed_at');
  set signedAt(DateTime? value) => setField<DateTime>('signed_at', value);

  String? get ehrbaseCompositionId =>
      getField<String>('ehrbase_composition_id');
  set ehrbaseCompositionId(String? value) =>
      setField<String>('ehrbase_composition_id', value);

  DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
  set ehrbaseSyncedAt(DateTime? value) =>
      setField<DateTime>('ehrbase_synced_at', value);

  String? get ehrbaseSyncStatus => getField<String>('ehrbase_sync_status');
  set ehrbaseSyncStatus(String? value) =>
      setField<String>('ehrbase_sync_status', value);

  String? get providerName => getField<String>('provider_name');
  set providerName(String? value) => setField<String>('provider_name', value);

  String? get providerSpecialty => getField<String>('provider_specialty');
  set providerSpecialty(String? value) =>
      setField<String>('provider_specialty', value);

  String? get patientName => getField<String>('patient_name');
  set patientName(String? value) => setField<String>('patient_name', value);

  String? get appointmentNumber => getField<String>('appointment_number');
  set appointmentNumber(String? value) =>
      setField<String>('appointment_number', value);

  DateTime? get appointmentDate => getField<DateTime>('appointment_date');
  set appointmentDate(DateTime? value) =>
      setField<DateTime>('appointment_date', value);

  int? get icd10Count => getField<int>('icd10_count');
  set icd10Count(int? value) => setField<int>('icd10_count', value);

  int? get entityCount => getField<int>('entity_count');
  set entityCount(int? value) => setField<int>('entity_count', value);
}
