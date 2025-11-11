import '../database.dart';

class UserProfilesTable extends SupabaseTable<UserProfilesRow> {
  @override
  String get tableName => 'user_profiles';

  @override
  UserProfilesRow createRow(Map<String, dynamic> data) => UserProfilesRow(data);
}

class UserProfilesRow extends SupabaseDataRow {
  UserProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get address => getField<String>('address');
  set address(String? value) => setField<String>('address', value);

  String? get city => getField<String>('city');
  set city(String? value) => setField<String>('city', value);

  String? get state => getField<String>('state');
  set state(String? value) => setField<String>('state', value);

  String? get country => getField<String>('country');
  set country(String? value) => setField<String>('country', value);

  String? get postalCode => getField<String>('postal_code');
  set postalCode(String? value) => setField<String>('postal_code', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

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

  String? get insuranceProvider => getField<String>('insurance_provider');
  set insuranceProvider(String? value) =>
      setField<String>('insurance_provider', value);

  String? get insuranceNumber => getField<String>('insurance_number');
  set insuranceNumber(String? value) =>
      setField<String>('insurance_number', value);

  DateTime? get insuranceExpiry => getField<DateTime>('insurance_expiry');
  set insuranceExpiry(DateTime? value) =>
      setField<DateTime>('insurance_expiry', value);

  String? get bloodType => getField<String>('blood_type');
  set bloodType(String? value) => setField<String>('blood_type', value);

  List<String> get allergies => getListField<String>('allergies');
  set allergies(List<String>? value) =>
      setListField<String>('allergies', value);

  List<String> get chronicConditions =>
      getListField<String>('chronic_conditions');
  set chronicConditions(List<String>? value) =>
      setListField<String>('chronic_conditions', value);

  List<String> get currentMedications =>
      getListField<String>('current_medications');
  set currentMedications(List<String>? value) =>
      setListField<String>('current_medications', value);

  double? get heightCm => getField<double>('height_cm');
  set heightCm(double? value) => setField<double>('height_cm', value);

  double? get weightKg => getField<double>('weight_kg');
  set weightKg(double? value) => setField<double>('weight_kg', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get displayName => getField<String>('display_name');
  set displayName(String? value) => setField<String>('display_name', value);

  int? get profileCompletionPercentage =>
      getField<int>('profile_completion_percentage');
  set profileCompletionPercentage(int? value) =>
      setField<int>('profile_completion_percentage', value);

  String? get streetAddress => getField<String>('street_address');
  set streetAddress(String? value) => setField<String>('street_address', value);

  String? get buildingName => getField<String>('building_name');
  set buildingName(String? value) => setField<String>('building_name', value);

  String? get apartmentUnit => getField<String>('apartment_unit');
  set apartmentUnit(String? value) => setField<String>('apartment_unit', value);

  String? get regionCode => getField<String>('region_code');
  set regionCode(String? value) => setField<String>('region_code', value);

  String? get landmarkDescription => getField<String>('landmark_description');
  set landmarkDescription(String? value) =>
      setField<String>('landmark_description', value);

  String? get divisionCode => getField<String>('division_code');
  set divisionCode(String? value) => setField<String>('division_code', value);

  String? get subdivisionCode => getField<String>('subdivision_code');
  set subdivisionCode(String? value) =>
      setField<String>('subdivision_code', value);

  String? get communityCode => getField<String>('community_code');
  set communityCode(String? value) => setField<String>('community_code', value);

  String? get neighborhood => getField<String>('neighborhood');
  set neighborhood(String? value) => setField<String>('neighborhood', value);

  String? get coordinates => getField<String>('coordinates');
  set coordinates(String? value) => setField<String>('coordinates', value);

  String? get emergencyContact2Name =>
      getField<String>('emergency_contact_2_name');
  set emergencyContact2Name(String? value) =>
      setField<String>('emergency_contact_2_name', value);

  String? get emergencyContact2Phone =>
      getField<String>('emergency_contact_2_phone');
  set emergencyContact2Phone(String? value) =>
      setField<String>('emergency_contact_2_phone', value);

  String? get emergencyContact2Relationship =>
      getField<String>('emergency_contact_2_relationship');
  set emergencyContact2Relationship(String? value) =>
      setField<String>('emergency_contact_2_relationship', value);

  String? get insurancePolicyNumber =>
      getField<String>('insurance_policy_number');
  set insurancePolicyNumber(String? value) =>
      setField<String>('insurance_policy_number', value);

  String? get idCardNumber => getField<String>('id_card_number');
  set idCardNumber(String? value) => setField<String>('id_card_number', value);

  DateTime? get idCardIssueDate => getField<DateTime>('id_card_issue_date');
  set idCardIssueDate(DateTime? value) =>
      setField<DateTime>('id_card_issue_date', value);

  DateTime? get idCardExpirationDate =>
      getField<DateTime>('id_card_expiration_date');
  set idCardExpirationDate(DateTime? value) =>
      setField<DateTime>('id_card_expiration_date', value);

  String? get nationalId => getField<String>('national_id');
  set nationalId(String? value) => setField<String>('national_id', value);

  String? get nationalIdEncrypted => getField<String>('national_id_encrypted');
  set nationalIdEncrypted(String? value) =>
      setField<String>('national_id_encrypted', value);

  String? get passportNumber => getField<String>('passport_number');
  set passportNumber(String? value) =>
      setField<String>('passport_number', value);

  String? get religion => getField<String>('religion');
  set religion(String? value) => setField<String>('religion', value);

  String? get ethnicity => getField<String>('ethnicity');
  set ethnicity(String? value) => setField<String>('ethnicity', value);

  String? get verificationStatus => getField<String>('verification_status');
  set verificationStatus(String? value) =>
      setField<String>('verification_status', value);

  DateTime? get verifiedAt => getField<DateTime>('verified_at');
  set verifiedAt(DateTime? value) => setField<DateTime>('verified_at', value);

  String? get verifiedBy => getField<String>('verified_by');
  set verifiedBy(String? value) => setField<String>('verified_by', value);

  dynamic? get verificationDocuments =>
      getField<dynamic>('verification_documents');
  set verificationDocuments(dynamic? value) =>
      setField<dynamic>('verification_documents', value);

  dynamic? get notificationPreferences =>
      getField<dynamic>('notification_preferences');
  set notificationPreferences(dynamic? value) =>
      setField<dynamic>('notification_preferences', value);

  dynamic? get privacySettings => getField<dynamic>('privacy_settings');
  set privacySettings(dynamic? value) =>
      setField<dynamic>('privacy_settings', value);

  String get role => getField<String>('role')!;
  set role(String value) => setField<String>('role', value);
}
