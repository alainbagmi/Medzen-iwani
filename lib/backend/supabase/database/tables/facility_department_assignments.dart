import '../database.dart';

class FacilityDepartmentAssignmentsTable
    extends SupabaseTable<FacilityDepartmentAssignmentsRow> {
  @override
  String get tableName => 'facility_department_assignments';

  @override
  FacilityDepartmentAssignmentsRow createRow(Map<String, dynamic> data) =>
      FacilityDepartmentAssignmentsRow(data);
}

class FacilityDepartmentAssignmentsRow extends SupabaseDataRow {
  FacilityDepartmentAssignmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityDepartmentAssignmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentHeadId => getField<String>('department_head_id');
  set departmentHeadId(String? value) =>
      setField<String>('department_head_id', value);

  int? get bedCapacity => getField<int>('bed_capacity');
  set bedCapacity(int? value) => setField<int>('bed_capacity', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get locationWithinFacility =>
      getField<String>('location_within_facility');
  set locationWithinFacility(String? value) =>
      setField<String>('location_within_facility', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
