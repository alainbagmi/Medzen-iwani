import '../database.dart';

class MediaLibraryTable extends SupabaseTable<MediaLibraryRow> {
  @override
  String get tableName => 'media_library';

  @override
  MediaLibraryRow createRow(Map<String, dynamic> data) => MediaLibraryRow(data);
}

class MediaLibraryRow extends SupabaseDataRow {
  MediaLibraryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MediaLibraryTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get uploadedById => getField<String>('uploaded_by_id');
  set uploadedById(String? value) => setField<String>('uploaded_by_id', value);

  String? get mediaType => getField<String>('media_type');
  set mediaType(String? value) => setField<String>('media_type', value);

  String get fileName => getField<String>('file_name')!;
  set fileName(String value) => setField<String>('file_name', value);

  String get filePath => getField<String>('file_path')!;
  set filePath(String value) => setField<String>('file_path', value);

  String get fileUrl => getField<String>('file_url')!;
  set fileUrl(String value) => setField<String>('file_url', value);

  String? get thumbnailUrl => getField<String>('thumbnail_url');
  set thumbnailUrl(String? value) => setField<String>('thumbnail_url', value);

  int? get fileSizeBytes => getField<int>('file_size_bytes');
  set fileSizeBytes(int? value) => setField<int>('file_size_bytes', value);

  String? get mimeType => getField<String>('mime_type');
  set mimeType(String? value) => setField<String>('mime_type', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  int? get width => getField<int>('width');
  set width(int? value) => setField<int>('width', value);

  int? get height => getField<int>('height');
  set height(int? value) => setField<int>('height', value);

  List<String> get tags => getListField<String>('tags');
  set tags(List<String>? value) => setListField<String>('tags', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get usageContext => getField<String>('usage_context');
  set usageContext(String? value) => setField<String>('usage_context', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
