import '../database.dart';

class LabTestCategoriesTable extends SupabaseTable<LabTestCategoriesRow> {
  @override
  String get tableName => 'lab_test_categories';

  @override
  LabTestCategoriesRow createRow(Map<String, dynamic> data) =>
      LabTestCategoriesRow(data);
}

class LabTestCategoriesRow extends SupabaseDataRow {
  LabTestCategoriesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LabTestCategoriesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get categoryCode => getField<String>('category_code')!;
  set categoryCode(String value) => setField<String>('category_code', value);

  String get categoryName => getField<String>('category_name')!;
  set categoryName(String value) => setField<String>('category_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
