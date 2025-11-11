import '../database.dart';

class ProviderSpecialtiesTable extends SupabaseTable<ProviderSpecialtiesRow> {
  @override
  String get tableName => 'provider_specialties';

  @override
  ProviderSpecialtiesRow createRow(Map<String, dynamic> data) =>
      ProviderSpecialtiesRow(data);
}

class ProviderSpecialtiesRow extends SupabaseDataRow {
  ProviderSpecialtiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProviderSpecialtiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get providerId => getField<String>('provider_id')!;
  set providerId(String value) => setField<String>('provider_id', value);

  String get specialtyId => getField<String>('specialty_id')!;
  set specialtyId(String value) => setField<String>('specialty_id', value);

  String get specialtyType => getField<String>('specialty_type')!;
  set specialtyType(String value) => setField<String>('specialty_type', value);

  DateTime? get certificationDate => getField<DateTime>('certification_date');
  set certificationDate(DateTime? value) =>
      setField<DateTime>('certification_date', value);

  bool? get boardCertified => getField<bool>('board_certified');
  set boardCertified(bool? value) => setField<bool>('board_certified', value);

  int? get yearsExperience => getField<int>('years_experience');
  set yearsExperience(int? value) => setField<int>('years_experience', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
