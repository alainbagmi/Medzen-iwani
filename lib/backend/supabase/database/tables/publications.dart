import '../database.dart';

class PublicationsTable extends SupabaseTable<PublicationsRow> {
  @override
  String get tableName => 'publications';

  @override
  PublicationsRow createRow(Map<String, dynamic> data) => PublicationsRow(data);
}

class PublicationsRow extends SupabaseDataRow {
  PublicationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PublicationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get authorId => getField<String>('author_id');
  set authorId(String? value) => setField<String>('author_id', value);

  String? get publicationType => getField<String>('publication_type');
  set publicationType(String? value) =>
      setField<String>('publication_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get slug => getField<String>('slug')!;
  set slug(String value) => setField<String>('slug', value);

  String? get summary => getField<String>('summary');
  set summary(String? value) => setField<String>('summary', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  String? get coverImageUrl => getField<String>('cover_image_url');
  set coverImageUrl(String? value) =>
      setField<String>('cover_image_url', value);

  List<String> get tags => getListField<String>('tags');
  set tags(List<String>? value) => setListField<String>('tags', value);

  List<String> get categories => getListField<String>('categories');
  set categories(List<String>? value) =>
      setListField<String>('categories', value);

  String? get specialty => getField<String>('specialty');
  set specialty(String? value) => setField<String>('specialty', value);

  int? get readingTimeMinutes => getField<int>('reading_time_minutes');
  set readingTimeMinutes(int? value) =>
      setField<int>('reading_time_minutes', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get publishDate => getField<DateTime>('publish_date');
  set publishDate(DateTime? value) => setField<DateTime>('publish_date', value);

  DateTime? get scheduledPublishDate =>
      getField<DateTime>('scheduled_publish_date');
  set scheduledPublishDate(DateTime? value) =>
      setField<DateTime>('scheduled_publish_date', value);

  int? get viewsCount => getField<int>('views_count');
  set viewsCount(int? value) => setField<int>('views_count', value);

  int? get likesCount => getField<int>('likes_count');
  set likesCount(int? value) => setField<int>('likes_count', value);

  int? get commentsCount => getField<int>('comments_count');
  set commentsCount(int? value) => setField<int>('comments_count', value);

  bool? get isFeatured => getField<bool>('is_featured');
  set isFeatured(bool? value) => setField<bool>('is_featured', value);

  bool? get isPremium => getField<bool>('is_premium');
  set isPremium(bool? value) => setField<bool>('is_premium', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
