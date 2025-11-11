import '../database.dart';

class MedicalProviderTypesTable extends SupabaseTable<MedicalProviderTypesRow> {
  @override
  String get tableName => 'medical_provider_types';

  @override
  MedicalProviderTypesRow createRow(Map<String, dynamic> data) =>
      MedicalProviderTypesRow(data);
}

class MedicalProviderTypesRow extends SupabaseDataRow {
  MedicalProviderTypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalProviderTypesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get providerTypeCode => getField<String>('provider_type_code')!;
  set providerTypeCode(String value) =>
      setField<String>('provider_type_code', value);

  String get providerTypeName => getField<String>('provider_type_name')!;
  set providerTypeName(String value) =>
      setField<String>('provider_type_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get requiredQualifications =>
      getListField<String>('required_qualifications');
  set requiredQualifications(List<String>? value) =>
      setListField<String>('required_qualifications', value);

  String? get scopeOfPractice => getField<String>('scope_of_practice');
  set scopeOfPractice(String? value) =>
      setField<String>('scope_of_practice', value);

  List<String> get licenseRequirements =>
      getListField<String>('license_requirements');
  set licenseRequirements(List<String>? value) =>
      setListField<String>('license_requirements', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
