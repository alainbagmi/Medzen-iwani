import '../database.dart';

class VSpecialtiesByCategoryTable
    extends SupabaseTable<VSpecialtiesByCategoryRow> {
  @override
  String get tableName => 'v_specialties_by_category';

  @override
  VSpecialtiesByCategoryRow createRow(Map<String, dynamic> data) =>
      VSpecialtiesByCategoryRow(data);
}

class VSpecialtiesByCategoryRow extends SupabaseDataRow {
  VSpecialtiesByCategoryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VSpecialtiesByCategoryTable();

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get priority => getField<String>('priority');
  set priority(String? value) => setField<String>('priority', value);

  int? get specialtyCount => getField<int>('specialty_count');
  set specialtyCount(int? value) => setField<int>('specialty_count', value);

  dynamic? get specialties => getField<dynamic>('specialties');
  set specialties(dynamic? value) => setField<dynamic>('specialties', value);
}
