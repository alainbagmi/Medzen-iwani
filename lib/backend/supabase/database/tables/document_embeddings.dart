import '../database.dart';

class DocumentEmbeddingsTable extends SupabaseTable<DocumentEmbeddingsRow> {
  @override
  String get tableName => 'document_embeddings';

  @override
  DocumentEmbeddingsRow createRow(Map<String, dynamic> data) =>
      DocumentEmbeddingsRow(data);
}

class DocumentEmbeddingsRow extends SupabaseDataRow {
  DocumentEmbeddingsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DocumentEmbeddingsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get documentId => getField<String>('document_id');
  set documentId(String? value) => setField<String>('document_id', value);

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
