import '../database.dart';

class VSpecialtyProviderCountsTable
    extends SupabaseTable<VSpecialtyProviderCountsRow> {
  @override
  String get tableName => 'v_specialty_provider_counts';

  @override
  VSpecialtyProviderCountsRow createRow(Map<String, dynamic> data) =>
      VSpecialtyProviderCountsRow(data);
}

class VSpecialtyProviderCountsRow extends SupabaseDataRow {
  VSpecialtyProviderCountsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VSpecialtyProviderCountsTable();

  String? get specialtyId => getField<String>('specialty_id');
  set specialtyId(String? value) => setField<String>('specialty_id', value);

  String? get specialtyCode => getField<String>('specialty_code');
  set specialtyCode(String? value) => setField<String>('specialty_code', value);

  String? get specialtyName => getField<String>('specialty_name');
  set specialtyName(String? value) => setField<String>('specialty_name', value);

  int? get primaryCount => getField<int>('primary_count');
  set primaryCount(int? value) => setField<int>('primary_count', value);

  int? get secondaryCount => getField<int>('secondary_count');
  set secondaryCount(int? value) => setField<int>('secondary_count', value);

  int? get totalProviderCount => getField<int>('total_provider_count');
  set totalProviderCount(int? value) =>
      setField<int>('total_provider_count', value);
}
