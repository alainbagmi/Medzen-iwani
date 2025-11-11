import '../database.dart';

class ReviewsTable extends SupabaseTable<ReviewsRow> {
  @override
  String get tableName => 'reviews';

  @override
  ReviewsRow createRow(Map<String, dynamic> data) => ReviewsRow(data);
}

class ReviewsRow extends SupabaseDataRow {
  ReviewsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReviewsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get reviewerId => getField<String>('reviewer_id');
  set reviewerId(String? value) => setField<String>('reviewer_id', value);

  String? get reviewedEntityType => getField<String>('reviewed_entity_type');
  set reviewedEntityType(String? value) =>
      setField<String>('reviewed_entity_type', value);

  String get reviewedEntityId => getField<String>('reviewed_entity_id')!;
  set reviewedEntityId(String value) =>
      setField<String>('reviewed_entity_id', value);

  int? get rating => getField<int>('rating');
  set rating(int? value) => setField<int>('rating', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get comment => getField<String>('comment');
  set comment(String? value) => setField<String>('comment', value);

  bool? get isVerified => getField<bool>('is_verified');
  set isVerified(bool? value) => setField<bool>('is_verified', value);

  bool? get isAnonymous => getField<bool>('is_anonymous');
  set isAnonymous(bool? value) => setField<bool>('is_anonymous', value);

  int? get helpfulCount => getField<int>('helpful_count');
  set helpfulCount(int? value) => setField<int>('helpful_count', value);

  int? get reportedCount => getField<int>('reported_count');
  set reportedCount(int? value) => setField<int>('reported_count', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get moderatedById => getField<String>('moderated_by_id');
  set moderatedById(String? value) =>
      setField<String>('moderated_by_id', value);

  DateTime? get moderatedAt => getField<DateTime>('moderated_at');
  set moderatedAt(DateTime? value) => setField<DateTime>('moderated_at', value);

  String? get moderationNotes => getField<String>('moderation_notes');
  set moderationNotes(String? value) =>
      setField<String>('moderation_notes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
