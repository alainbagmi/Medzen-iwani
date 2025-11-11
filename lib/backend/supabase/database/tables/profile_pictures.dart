import '../database.dart';

class ProfilePicturesTable extends SupabaseTable<ProfilePicturesRow> {
  @override
  String get tableName => 'profile_pictures';

  @override
  ProfilePicturesRow createRow(Map<String, dynamic> data) =>
      ProfilePicturesRow(data);
}

class ProfilePicturesRow extends SupabaseDataRow {
  ProfilePicturesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfilePicturesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

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

  bool? get isCurrent => getField<bool>('is_current');
  set isCurrent(bool? value) => setField<bool>('is_current', value);

  DateTime? get uploadedAt => getField<DateTime>('uploaded_at');
  set uploadedAt(DateTime? value) => setField<DateTime>('uploaded_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
