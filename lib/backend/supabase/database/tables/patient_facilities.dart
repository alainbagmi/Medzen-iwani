import '../database.dart';

class PatientFacilitiesTable extends SupabaseTable<PatientFacilitiesRow> {
  @override
  String get tableName => 'patient_facilities';

  @override
  PatientFacilitiesRow createRow(Map<String, dynamic> data) =>
      PatientFacilitiesRow(data);
}

class PatientFacilitiesRow extends SupabaseDataRow {
  PatientFacilitiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PatientFacilitiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientProfileId => getField<String>('patient_profile_id')!;
  set patientProfileId(String value) =>
      setField<String>('patient_profile_id', value);

  String get facilityId => getField<String>('facility_id')!;
  set facilityId(String value) => setField<String>('facility_id', value);

  bool? get isPrimary => getField<bool>('is_primary');
  set isPrimary(bool? value) => setField<bool>('is_primary', value);

  DateTime? get linkedAt => getField<DateTime>('linked_at');
  set linkedAt(DateTime? value) => setField<DateTime>('linked_at', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);
}
