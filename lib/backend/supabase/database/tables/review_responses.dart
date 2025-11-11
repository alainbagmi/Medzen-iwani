import '../database.dart';

class ReviewResponsesTable extends SupabaseTable<ReviewResponsesRow> {
  @override
  String get tableName => 'review_responses';

  @override
  ReviewResponsesRow createRow(Map<String, dynamic> data) =>
      ReviewResponsesRow(data);
}

class ReviewResponsesRow extends SupabaseDataRow {
  ReviewResponsesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReviewResponsesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get reviewId => getField<String>('review_id');
  set reviewId(String? value) => setField<String>('review_id', value);

  String? get responderId => getField<String>('responder_id');
  set responderId(String? value) => setField<String>('responder_id', value);

  String get responseText => getField<String>('response_text')!;
  set responseText(String value) => setField<String>('response_text', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
