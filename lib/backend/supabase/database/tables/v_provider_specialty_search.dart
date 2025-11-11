import '../database.dart';

class VProviderSpecialtySearchTable
    extends SupabaseTable<VProviderSpecialtySearchRow> {
  @override
  String get tableName => 'v_provider_specialty_search';

  @override
  VProviderSpecialtySearchRow createRow(Map<String, dynamic> data) =>
      VProviderSpecialtySearchRow(data);
}

class VProviderSpecialtySearchRow extends SupabaseDataRow {
  VProviderSpecialtySearchRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VProviderSpecialtySearchTable();

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

  String? get providerNumber => getField<String>('provider_number');
  set providerNumber(String? value) =>
      setField<String>('provider_number', value);

  String? get professionalRole => getField<String>('professional_role');
  set professionalRole(String? value) =>
      setField<String>('professional_role', value);

  int? get yearsOfExperience => getField<int>('years_of_experience');
  set yearsOfExperience(int? value) =>
      setField<int>('years_of_experience', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);

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

  List<String> get allSpecialtyIds => getListField<String>('all_specialty_ids');
  set allSpecialtyIds(List<String>? value) =>
      setListField<String>('all_specialty_ids', value);

  List<String> get allSpecialtyNames =>
      getListField<String>('all_specialty_names');
  set allSpecialtyNames(List<String>? value) =>
      setListField<String>('all_specialty_names', value);

  int? get secondarySpecialtyCount =>
      getField<int>('secondary_specialty_count');
  set secondarySpecialtyCount(int? value) =>
      setField<int>('secondary_specialty_count', value);

  int? get boardCertificationCount =>
      getField<int>('board_certification_count');
  set boardCertificationCount(int? value) =>
      setField<int>('board_certification_count', value);
}
