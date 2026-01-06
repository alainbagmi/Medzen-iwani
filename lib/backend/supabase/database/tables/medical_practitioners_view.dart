import '../database.dart';

class MedicalPractitionersViewTable
    extends SupabaseTable<MedicalPractitionersViewRow> {
  @override
  String get tableName => 'medical_practitioners_view';

  @override
  MedicalPractitionersViewRow createRow(Map<String, dynamic> data) =>
      MedicalPractitionersViewRow(data);
}

class MedicalPractitionersViewRow extends SupabaseDataRow {
  MedicalPractitionersViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalPractitionersViewTable();

  String? get providerid => getField<String>('providerid');
  set providerid(String? value) => setField<String>('providerid', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get picture => getField<String>('picture');
  set picture(String? value) => setField<String>('picture', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get specialization => getField<String>('specialization');
  set specialization(String? value) =>
      setField<String>('specialization', value);

  int? get experience => getField<int>('experience');
  set experience(int? value) => setField<int>('experience', value);

  double? get fees => getField<double>('fees');
  set fees(double? value) => setField<double>('fees', value);

  String? get licenseNumber => getField<String>('license_number');
  set licenseNumber(String? value) => setField<String>('license_number', value);

  String? get licenseIssuingAuthority =>
      getField<String>('license_issuing_authority');
  set licenseIssuingAuthority(String? value) =>
      setField<String>('license_issuing_authority', value);

  DateTime? get licenseExpiryDate => getField<DateTime>('license_expiry_date');
  set licenseExpiryDate(DateTime? value) =>
      setField<DateTime>('license_expiry_date', value);

  DateTime? get applicationDate => getField<DateTime>('application_date');
  set applicationDate(DateTime? value) =>
      setField<DateTime>('application_date', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);

  String? get rejectionReasons => getField<String>('rejection_reasons');
  set rejectionReasons(String? value) =>
      setField<String>('rejection_reasons', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get emergencyContactName =>
      getField<String>('emergency_contact_name');
  set emergencyContactName(String? value) =>
      setField<String>('emergency_contact_name', value);

  String? get emergencyContactPhone =>
      getField<String>('emergency_contact_phone');
  set emergencyContactPhone(String? value) =>
      setField<String>('emergency_contact_phone', value);

  String? get emergencyContactRelationship =>
      getField<String>('emergency_contact_relationship');
  set emergencyContactRelationship(String? value) =>
      setField<String>('emergency_contact_relationship', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);
}
