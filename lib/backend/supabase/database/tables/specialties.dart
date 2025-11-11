import '../database.dart';

class SpecialtiesTable extends SupabaseTable<SpecialtiesRow> {
  @override
  String get tableName => 'specialties';

  @override
  SpecialtiesRow createRow(Map<String, dynamic> data) => SpecialtiesRow(data);
}

class SpecialtiesRow extends SupabaseDataRow {
  SpecialtiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SpecialtiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get specialtyCode => getField<String>('specialty_code')!;
  set specialtyCode(String value) => setField<String>('specialty_code', value);

  String get specialtyName => getField<String>('specialty_name')!;
  set specialtyName(String value) => setField<String>('specialty_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get parentSpecialtyId => getField<String>('parent_specialty_id');
  set parentSpecialtyId(String? value) =>
      setField<String>('parent_specialty_id', value);

  String? get icon => getField<String>('icon');
  set icon(String? value) => setField<String>('icon', value);

  String? get color => getField<String>('color');
  set color(String? value) => setField<String>('color', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  int? get displayOrder => getField<int>('display_order');
  set displayOrder(int? value) => setField<int>('display_order', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  int get primaryCount => getField<int>('primary_count')!;
  set primaryCount(int value) => setField<int>('primary_count', value);

  int get secondaryCount => getField<int>('secondary_count')!;
  set secondaryCount(int value) => setField<int>('secondary_count', value);

  int get totalProviderCount => getField<int>('total_provider_count')!;
  set totalProviderCount(int value) =>
      setField<int>('total_provider_count', value);
}
