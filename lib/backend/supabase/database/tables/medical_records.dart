import '../database.dart';

class MedicalRecordsTable extends SupabaseTable<MedicalRecordsRow> {
  @override
  String get tableName => 'medical_records';

  @override
  MedicalRecordsRow createRow(Map<String, dynamic> data) =>
      MedicalRecordsRow(data);
}

class MedicalRecordsRow extends SupabaseDataRow {
  MedicalRecordsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalRecordsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String get recordType => getField<String>('record_type')!;
  set recordType(String value) => setField<String>('record_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get diagnosisCodes => getListField<String>('diagnosis_codes');
  set diagnosisCodes(List<String>? value) =>
      setListField<String>('diagnosis_codes', value);

  List<String> get procedureCodes => getListField<String>('procedure_codes');
  set procedureCodes(List<String>? value) =>
      setListField<String>('procedure_codes', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  List<String> get attachments => getListField<String>('attachments');
  set attachments(List<String>? value) =>
      setListField<String>('attachments', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  DateTime? get encounterDate => getField<DateTime>('encounter_date');
  set encounterDate(DateTime? value) =>
      setField<DateTime>('encounter_date', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

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
