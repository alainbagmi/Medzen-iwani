import '../database.dart';

class AllReviewsTable extends SupabaseTable<AllReviewsRow> {
  @override
  String get tableName => 'all_reviews';

  @override
  AllReviewsRow createRow(Map<String, dynamic> data) => AllReviewsRow(data);
}

class AllReviewsRow extends SupabaseDataRow {
  AllReviewsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AllReviewsTable();

  String? get reviewerName => getField<String>('reviewer_name');
  set reviewerName(String? value) => setField<String>('reviewer_name', value);

  String? get reviewerPicture => getField<String>('reviewer_picture');
  set reviewerPicture(String? value) =>
      setField<String>('reviewer_picture', value);

  String? get comment => getField<String>('comment');
  set comment(String? value) => setField<String>('comment', value);

  int? get rating => getField<int>('rating');
  set rating(int? value) => setField<int>('rating', value);

  DateTime? get commentedDate => getField<DateTime>('commented_date');
  set commentedDate(DateTime? value) =>
      setField<DateTime>('commented_date', value);

  String? get practitionerid => getField<String>('practitionerid');
  set practitionerid(String? value) =>
      setField<String>('practitionerid', value);

  String? get facilityid => getField<String>('facilityid');
  set facilityid(String? value) => setField<String>('facilityid', value);
}
