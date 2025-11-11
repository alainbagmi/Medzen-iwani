import '../database.dart';

class DocumentsTable extends SupabaseTable<DocumentsRow> {
  @override
  String get tableName => 'documents';

  @override
  DocumentsRow createRow(Map<String, dynamic> data) => DocumentsRow(data);
}

class DocumentsRow extends SupabaseDataRow {
  DocumentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DocumentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get uploadedById => getField<String>('uploaded_by_id');
  set uploadedById(String? value) => setField<String>('uploaded_by_id', value);

  String? get documentType => getField<String>('document_type');
  set documentType(String? value) => setField<String>('document_type', value);

  String get fileName => getField<String>('file_name')!;
  set fileName(String value) => setField<String>('file_name', value);

  String get filePath => getField<String>('file_path')!;
  set filePath(String value) => setField<String>('file_path', value);

  String get fileUrl => getField<String>('file_url')!;
  set fileUrl(String value) => setField<String>('file_url', value);

  int? get fileSizeBytes => getField<int>('file_size_bytes');
  set fileSizeBytes(int? value) => setField<int>('file_size_bytes', value);

  String? get mimeType => getField<String>('mime_type');
  set mimeType(String? value) => setField<String>('mime_type', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  List<String> get tags => getListField<String>('tags');
  set tags(List<String>? value) => setListField<String>('tags', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  bool? get isSensitive => getField<bool>('is_sensitive');
  set isSensitive(bool? value) => setField<bool>('is_sensitive', value);

  String? get encryptionKey => getField<String>('encryption_key');
  set encryptionKey(String? value) => setField<String>('encryption_key', value);

  String? get relatedAppointmentId =>
      getField<String>('related_appointment_id');
  set relatedAppointmentId(String? value) =>
      setField<String>('related_appointment_id', value);

  String? get relatedMedicalRecordId =>
      getField<String>('related_medical_record_id');
  set relatedMedicalRecordId(String? value) =>
      setField<String>('related_medical_record_id', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get uploadedAt => getField<DateTime>('uploaded_at');
  set uploadedAt(DateTime? value) => setField<DateTime>('uploaded_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

  String? get bucketName => getField<String>('bucket_name');
  set bucketName(String? value) => setField<String>('bucket_name', value);

  String? get storagePath => getField<String>('storage_path');
  set storagePath(String? value) => setField<String>('storage_path', value);
}
