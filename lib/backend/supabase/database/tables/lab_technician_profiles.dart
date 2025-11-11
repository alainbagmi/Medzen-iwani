import '../database.dart';

class LabTechnicianProfilesTable
    extends SupabaseTable<LabTechnicianProfilesRow> {
  @override
  String get tableName => 'lab_technician_profiles';

  @override
  LabTechnicianProfilesRow createRow(Map<String, dynamic> data) =>
      LabTechnicianProfilesRow(data);
}

class LabTechnicianProfilesRow extends SupabaseDataRow {
  LabTechnicianProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LabTechnicianProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get technicianNumber => getField<String>('technician_number')!;
  set technicianNumber(String value) =>
      setField<String>('technician_number', value);

  String get certificationNumber => getField<String>('certification_number')!;
  set certificationNumber(String value) =>
      setField<String>('certification_number', value);

  DateTime get certificationExpiry =>
      getField<DateTime>('certification_expiry')!;
  set certificationExpiry(DateTime value) =>
      setField<DateTime>('certification_expiry', value);

  List<String> get labSpecialties => getListField<String>('lab_specialties');
  set labSpecialties(List<String>? value) =>
      setListField<String>('lab_specialties', value);

  List<String> get equipmentCertifications =>
      getListField<String>('equipment_certifications');
  set equipmentCertifications(List<String>? value) =>
      setListField<String>('equipment_certifications', value);

  String? get labFacilityId => getField<String>('lab_facility_id');
  set labFacilityId(String? value) =>
      setField<String>('lab_facility_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
