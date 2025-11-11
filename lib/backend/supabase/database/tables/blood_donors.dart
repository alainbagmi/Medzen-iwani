import '../database.dart';

class BloodDonorsTable extends SupabaseTable<BloodDonorsRow> {
  @override
  String get tableName => 'blood_donors';

  @override
  BloodDonorsRow createRow(Map<String, dynamic> data) => BloodDonorsRow(data);
}

class BloodDonorsRow extends SupabaseDataRow {
  BloodDonorsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => BloodDonorsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get bloodType => getField<String>('blood_type')!;
  set bloodType(String value) => setField<String>('blood_type', value);

  double? get weightKg => getField<double>('weight_kg');
  set weightKg(double? value) => setField<double>('weight_kg', value);

  DateTime? get lastDonationDate => getField<DateTime>('last_donation_date');
  set lastDonationDate(DateTime? value) =>
      setField<DateTime>('last_donation_date', value);

  DateTime? get nextEligibleDate => getField<DateTime>('next_eligible_date');
  set nextEligibleDate(DateTime? value) =>
      setField<DateTime>('next_eligible_date', value);

  int? get totalDonations => getField<int>('total_donations');
  set totalDonations(int? value) => setField<int>('total_donations', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  List<String> get medicalConditions =>
      getListField<String>('medical_conditions');
  set medicalConditions(List<String>? value) =>
      setListField<String>('medical_conditions', value);

  List<String> get medications => getListField<String>('medications');
  set medications(List<String>? value) =>
      setListField<String>('medications', value);

  List<String> get allergies => getListField<String>('allergies');
  set allergies(List<String>? value) =>
      setListField<String>('allergies', value);

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

  String? get preferredDonationLocation =>
      getField<String>('preferred_donation_location');
  set preferredDonationLocation(String? value) =>
      setField<String>('preferred_donation_location', value);

  List<String> get preferredDonationTimes =>
      getListField<String>('preferred_donation_times');
  set preferredDonationTimes(List<String>? value) =>
      setListField<String>('preferred_donation_times', value);

  String? get availabilityStatus => getField<String>('availability_status');
  set availabilityStatus(String? value) =>
      setField<String>('availability_status', value);

  String? get donorCardNumber => getField<String>('donor_card_number');
  set donorCardNumber(String? value) =>
      setField<String>('donor_card_number', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  bool? get consentGiven => getField<bool>('consent_given');
  set consentGiven(bool? value) => setField<bool>('consent_given', value);

  DateTime? get consentDate => getField<DateTime>('consent_date');
  set consentDate(DateTime? value) => setField<DateTime>('consent_date', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
