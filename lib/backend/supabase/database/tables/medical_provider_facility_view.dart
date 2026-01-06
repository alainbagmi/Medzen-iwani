import '../database.dart';

class MedicalProviderFacilityViewTable
    extends SupabaseTable<MedicalProviderFacilityViewRow> {
  @override
  String get tableName => 'medical_provider_facility_view';

  @override
  MedicalProviderFacilityViewRow createRow(Map<String, dynamic> data) =>
      MedicalProviderFacilityViewRow(data);
}

class MedicalProviderFacilityViewRow extends SupabaseDataRow {
  MedicalProviderFacilityViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalProviderFacilityViewTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get facilityName => getField<String>('facility_name');
  set facilityName(String? value) => setField<String>('facility_name', value);

  String? get facilityCode => getField<String>('facility_code');
  set facilityCode(String? value) => setField<String>('facility_code', value);

  String? get facilityPictureUrl => getField<String>('facility_picture_url');
  set facilityPictureUrl(String? value) =>
      setField<String>('facility_picture_url', value);

  String? get facilityAddress => getField<String>('facility_address');
  set facilityAddress(String? value) =>
      setField<String>('facility_address', value);

  String? get facilityCity => getField<String>('facility_city');
  set facilityCity(String? value) => setField<String>('facility_city', value);

  String? get facilityState => getField<String>('facility_state');
  set facilityState(String? value) => setField<String>('facility_state', value);

  String? get facilityCountry => getField<String>('facility_country');
  set facilityCountry(String? value) =>
      setField<String>('facility_country', value);

  String? get facilityPhone => getField<String>('facility_phone');
  set facilityPhone(String? value) => setField<String>('facility_phone', value);
}
