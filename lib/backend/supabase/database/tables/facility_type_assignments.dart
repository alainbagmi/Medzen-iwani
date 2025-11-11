import '../database.dart';

class FacilityTypeAssignmentsTable
    extends SupabaseTable<FacilityTypeAssignmentsRow> {
  @override
  String get tableName => 'facility_type_assignments';

  @override
  FacilityTypeAssignmentsRow createRow(Map<String, dynamic> data) =>
      FacilityTypeAssignmentsRow(data);
}

class FacilityTypeAssignmentsRow extends SupabaseDataRow {
  FacilityTypeAssignmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityTypeAssignmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get facilityTypeId => getField<String>('facility_type_id');
  set facilityTypeId(String? value) =>
      setField<String>('facility_type_id', value);

  bool? get isPrimary => getField<bool>('is_primary');
  set isPrimary(bool? value) => setField<bool>('is_primary', value);

  String? get accreditationNumber => getField<String>('accreditation_number');
  set accreditationNumber(String? value) =>
      setField<String>('accreditation_number', value);

  DateTime? get accreditationDate => getField<DateTime>('accreditation_date');
  set accreditationDate(DateTime? value) =>
      setField<DateTime>('accreditation_date', value);

  DateTime? get accreditationExpiry =>
      getField<DateTime>('accreditation_expiry');
  set accreditationExpiry(DateTime? value) =>
      setField<DateTime>('accreditation_expiry', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
