import '../database.dart';

class PublicationBookmarksTable extends SupabaseTable<PublicationBookmarksRow> {
  @override
  String get tableName => 'publication_bookmarks';

  @override
  PublicationBookmarksRow createRow(Map<String, dynamic> data) =>
      PublicationBookmarksRow(data);
}

class PublicationBookmarksRow extends SupabaseDataRow {
  PublicationBookmarksRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PublicationBookmarksTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get publicationId => getField<String>('publication_id');
  set publicationId(String? value) => setField<String>('publication_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
