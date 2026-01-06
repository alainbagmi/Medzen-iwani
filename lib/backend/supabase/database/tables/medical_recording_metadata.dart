import '../database.dart';

class MedicalRecordingMetadataTable
    extends SupabaseTable<MedicalRecordingMetadataRow> {
  @override
  String get tableName => 'medical_recording_metadata';

  @override
  MedicalRecordingMetadataRow createRow(Map<String, dynamic> data) =>
      MedicalRecordingMetadataRow(data);
}

class MedicalRecordingMetadataRow extends SupabaseDataRow {
  MedicalRecordingMetadataRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalRecordingMetadataTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get sessionId => getField<String>('session_id')!;
  set sessionId(String value) => setField<String>('session_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String get recordingBucket => getField<String>('recording_bucket')!;
  set recordingBucket(String value) =>
      setField<String>('recording_bucket', value);

  String get recordingKey => getField<String>('recording_key')!;
  set recordingKey(String value) => setField<String>('recording_key', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  int? get fileSizeBytes => getField<int>('file_size_bytes');
  set fileSizeBytes(int? value) => setField<int>('file_size_bytes', value);

  String? get format => getField<String>('format');
  set format(String? value) => setField<String>('format', value);

  String get encryptionType => getField<String>('encryption_type')!;
  set encryptionType(String value) =>
      setField<String>('encryption_type', value);

  DateTime get retentionUntil => getField<DateTime>('retention_until')!;
  set retentionUntil(DateTime value) =>
      setField<DateTime>('retention_until', value);

  bool? get deletionScheduled => getField<bool>('deletion_scheduled');
  set deletionScheduled(bool? value) =>
      setField<bool>('deletion_scheduled', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
