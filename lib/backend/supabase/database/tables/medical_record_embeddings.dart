import '../database.dart';

class MedicalRecordEmbeddingsTable
    extends SupabaseTable<MedicalRecordEmbeddingsRow> {
  @override
  String get tableName => 'medical_record_embeddings';

  @override
  MedicalRecordEmbeddingsRow createRow(Map<String, dynamic> data) =>
      MedicalRecordEmbeddingsRow(data);
}

class MedicalRecordEmbeddingsRow extends SupabaseDataRow {
  MedicalRecordEmbeddingsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalRecordEmbeddingsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get medicalRecordId => getField<String>('medical_record_id');
  set medicalRecordId(String? value) =>
      setField<String>('medical_record_id', value);

  String get contentChunk => getField<String>('content_chunk')!;
  set contentChunk(String value) => setField<String>('content_chunk', value);

  int? get chunkIndex => getField<int>('chunk_index');
  set chunkIndex(int? value) => setField<int>('chunk_index', value);

  String? get embedding => getField<String>('embedding');
  set embedding(String? value) => setField<String>('embedding', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
