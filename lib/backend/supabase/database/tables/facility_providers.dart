import '../database.dart';

class FacilityProvidersTable extends SupabaseTable<FacilityProvidersRow> {
  @override
  String get tableName => 'facility_providers';

  @override
  FacilityProvidersRow createRow(Map<String, dynamic> data) =>
      FacilityProvidersRow(data);
}

class FacilityProvidersRow extends SupabaseDataRow {
  FacilityProvidersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityProvidersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String? get department => getField<String>('department');
  set department(String? value) => setField<String>('department', value);

  DateTime get startDate => getField<DateTime>('start_date')!;
  set startDate(DateTime value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  bool? get isPrimaryFacility => getField<bool>('is_primary_facility');
  set isPrimaryFacility(bool? value) =>
      setField<bool>('is_primary_facility', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
