import '../database.dart';

class VProviderSecondarySpecialtiesTable
    extends SupabaseTable<VProviderSecondarySpecialtiesRow> {
  @override
  String get tableName => 'v_provider_secondary_specialties';

  @override
  VProviderSecondarySpecialtiesRow createRow(Map<String, dynamic> data) =>
      VProviderSecondarySpecialtiesRow(data);
}

class VProviderSecondarySpecialtiesRow extends SupabaseDataRow {
  VProviderSecondarySpecialtiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VProviderSecondarySpecialtiesTable();

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get specialtyId => getField<String>('specialty_id');
  set specialtyId(String? value) => setField<String>('specialty_id', value);

  String? get specialtyCode => getField<String>('specialty_code');
  set specialtyCode(String? value) => setField<String>('specialty_code', value);

  String? get specialtyName => getField<String>('specialty_name');
  set specialtyName(String? value) => setField<String>('specialty_name', value);

  String? get specialtyDescription => getField<String>('specialty_description');
  set specialtyDescription(String? value) =>
      setField<String>('specialty_description', value);

  String? get specialtyType => getField<String>('specialty_type');
  set specialtyType(String? value) => setField<String>('specialty_type', value);

  bool? get boardCertified => getField<bool>('board_certified');
  set boardCertified(bool? value) => setField<bool>('board_certified', value);

  DateTime? get certificationDate => getField<DateTime>('certification_date');
  set certificationDate(DateTime? value) =>
      setField<DateTime>('certification_date', value);

  int? get yearsExperience => getField<int>('years_experience');
  set yearsExperience(int? value) => setField<int>('years_experience', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
