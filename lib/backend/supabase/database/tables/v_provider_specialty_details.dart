import '../database.dart';

class VProviderSpecialtyDetailsTable
    extends SupabaseTable<VProviderSpecialtyDetailsRow> {
  @override
  String get tableName => 'v_provider_specialty_details';

  @override
  VProviderSpecialtyDetailsRow createRow(Map<String, dynamic> data) =>
      VProviderSpecialtyDetailsRow(data);
}

class VProviderSpecialtyDetailsRow extends SupabaseDataRow {
  VProviderSpecialtyDetailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VProviderSpecialtyDetailsTable();

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get primarySpecialtyId => getField<String>('primary_specialty_id');
  set primarySpecialtyId(String? value) =>
      setField<String>('primary_specialty_id', value);

  String? get primarySpecialtyCode =>
      getField<String>('primary_specialty_code');
  set primarySpecialtyCode(String? value) =>
      setField<String>('primary_specialty_code', value);

  String? get primarySpecialtyName =>
      getField<String>('primary_specialty_name');
  set primarySpecialtyName(String? value) =>
      setField<String>('primary_specialty_name', value);

  String? get primarySpecialtyTextLegacy =>
      getField<String>('primary_specialty_text_legacy');
  set primarySpecialtyTextLegacy(String? value) =>
      setField<String>('primary_specialty_text_legacy', value);

  int? get totalSpecialties => getField<int>('total_specialties');
  set totalSpecialties(int? value) => setField<int>('total_specialties', value);

  int? get yearsOfExperience => getField<int>('years_of_experience');
  set yearsOfExperience(int? value) =>
      setField<int>('years_of_experience', value);

  String? get professionalRole => getField<String>('professional_role');
  set professionalRole(String? value) =>
      setField<String>('professional_role', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);
}
