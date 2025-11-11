import '../database.dart';

class PublicationCommentsTable extends SupabaseTable<PublicationCommentsRow> {
  @override
  String get tableName => 'publication_comments';

  @override
  PublicationCommentsRow createRow(Map<String, dynamic> data) =>
      PublicationCommentsRow(data);
}

class PublicationCommentsRow extends SupabaseDataRow {
  PublicationCommentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PublicationCommentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get publicationId => getField<String>('publication_id');
  set publicationId(String? value) => setField<String>('publication_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get parentCommentId => getField<String>('parent_comment_id');
  set parentCommentId(String? value) =>
      setField<String>('parent_comment_id', value);

  String get commentText => getField<String>('comment_text')!;
  set commentText(String value) => setField<String>('comment_text', value);

  bool? get isEdited => getField<bool>('is_edited');
  set isEdited(bool? value) => setField<bool>('is_edited', value);

  DateTime? get editedAt => getField<DateTime>('edited_at');
  set editedAt(DateTime? value) => setField<DateTime>('edited_at', value);

  int? get likesCount => getField<int>('likes_count');
  set likesCount(int? value) => setField<int>('likes_count', value);

  bool? get isFlagged => getField<bool>('is_flagged');
  set isFlagged(bool? value) => setField<bool>('is_flagged', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
