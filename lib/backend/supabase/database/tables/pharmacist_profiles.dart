import '../database.dart';

class PharmacistProfilesTable extends SupabaseTable<PharmacistProfilesRow> {
  @override
  String get tableName => 'pharmacist_profiles';

  @override
  PharmacistProfilesRow createRow(Map<String, dynamic> data) =>
      PharmacistProfilesRow(data);
}

class PharmacistProfilesRow extends SupabaseDataRow {
  PharmacistProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PharmacistProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get pharmacistNumber => getField<String>('pharmacist_number')!;
  set pharmacistNumber(String value) =>
      setField<String>('pharmacist_number', value);

  String get pharmacyLicenseNumber =>
      getField<String>('pharmacy_license_number')!;
  set pharmacyLicenseNumber(String value) =>
      setField<String>('pharmacy_license_number', value);

  DateTime get licenseExpiry => getField<DateTime>('license_expiry')!;
  set licenseExpiry(DateTime value) =>
      setField<DateTime>('license_expiry', value);

  List<String> get specializations => getListField<String>('specializations');
  set specializations(List<String>? value) =>
      setListField<String>('specializations', value);

  String? get pharmacyId => getField<String>('pharmacy_id');
  set pharmacyId(String? value) => setField<String>('pharmacy_id', value);

  bool? get canPrescribe => getField<bool>('can_prescribe');
  set canPrescribe(bool? value) => setField<bool>('can_prescribe', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
