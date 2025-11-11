import '../database.dart';

class FacilityDepartmentsTable extends SupabaseTable<FacilityDepartmentsRow> {
  @override
  String get tableName => 'facility_departments';

  @override
  FacilityDepartmentsRow createRow(Map<String, dynamic> data) =>
      FacilityDepartmentsRow(data);
}

class FacilityDepartmentsRow extends SupabaseDataRow {
  FacilityDepartmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityDepartmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get departmentCode => getField<String>('department_code')!;
  set departmentCode(String value) =>
      setField<String>('department_code', value);

  String get departmentName => getField<String>('department_name')!;
  set departmentName(String value) =>
      setField<String>('department_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get commonServices => getListField<String>('common_services');
  set commonServices(List<String>? value) =>
      setListField<String>('common_services', value);

  List<String> get typicalSpecialties =>
      getListField<String>('typical_specialties');
  set typicalSpecialties(List<String>? value) =>
      setListField<String>('typical_specialties', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
