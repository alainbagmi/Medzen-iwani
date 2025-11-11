import '../database.dart';

class FacilityTypesTable extends SupabaseTable<FacilityTypesRow> {
  @override
  String get tableName => 'facility_types';

  @override
  FacilityTypesRow createRow(Map<String, dynamic> data) =>
      FacilityTypesRow(data);
}

class FacilityTypesRow extends SupabaseDataRow {
  FacilityTypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityTypesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get facilityTypeCode => getField<String>('facility_type_code')!;
  set facilityTypeCode(String value) =>
      setField<String>('facility_type_code', value);

  String get facilityTypeName => getField<String>('facility_type_name')!;
  set facilityTypeName(String value) =>
      setField<String>('facility_type_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get typicalServices => getListField<String>('typical_services');
  set typicalServices(List<String>? value) =>
      setListField<String>('typical_services', value);

  List<String> get accreditationRequirements =>
      getListField<String>('accreditation_requirements');
  set accreditationRequirements(List<String>? value) =>
      setListField<String>('accreditation_requirements', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
