import '../database.dart';

class FacilityAdminDetailsTable extends SupabaseTable<FacilityAdminDetailsRow> {
  @override
  String get tableName => 'facility_admin_details';

  @override
  FacilityAdminDetailsRow createRow(Map<String, dynamic> data) =>
      FacilityAdminDetailsRow(data);
}

class FacilityAdminDetailsRow extends SupabaseDataRow {
  FacilityAdminDetailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityAdminDetailsTable();

  String? get facilityAdminId => getField<String>('facility_admin_id');
  set facilityAdminId(String? value) =>
      setField<String>('facility_admin_id', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  String? get idCardNumber => getField<String>('id_card_number');
  set idCardNumber(String? value) => setField<String>('id_card_number', value);

  String? get rejectionReason => getField<String>('rejection_reason');
  set rejectionReason(String? value) =>
      setField<String>('rejection_reason', value);

  String? get primaryFacilityId => getField<String>('primary_facility_id');
  set primaryFacilityId(String? value) =>
      setField<String>('primary_facility_id', value);

  String? get facilityCode => getField<String>('facility_code');
  set facilityCode(String? value) => setField<String>('facility_code', value);

  String? get facilityName => getField<String>('facility_name');
  set facilityName(String? value) => setField<String>('facility_name', value);

  String? get facilityType => getField<String>('facility_type');
  set facilityType(String? value) => setField<String>('facility_type', value);

  String? get city => getField<String>('city');
  set city(String? value) => setField<String>('city', value);

  String? get state => getField<String>('state');
  set state(String? value) => setField<String>('state', value);

  String? get country => getField<String>('country');
  set country(String? value) => setField<String>('country', value);

  String? get address => getField<String>('address');
  set address(String? value) => setField<String>('address', value);

  String? get facilityImageUrl => getField<String>('facility_image_url');
  set facilityImageUrl(String? value) =>
      setField<String>('facility_image_url', value);
}
