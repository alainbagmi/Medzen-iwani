import '../database.dart';

class DoctorProfilesTable extends SupabaseTable<DoctorProfilesRow> {
  @override
  String get tableName => 'doctor_profiles';

  @override
  DoctorProfilesRow createRow(Map<String, dynamic> data) =>
      DoctorProfilesRow(data);
}

class DoctorProfilesRow extends SupabaseDataRow {
  DoctorProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DoctorProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get doctorNumber => getField<String>('doctor_number')!;
  set doctorNumber(String value) => setField<String>('doctor_number', value);

  String get medicalLicenseNumber =>
      getField<String>('medical_license_number')!;
  set medicalLicenseNumber(String value) =>
      setField<String>('medical_license_number', value);

  DateTime get licenseExpiry => getField<DateTime>('license_expiry')!;
  set licenseExpiry(DateTime value) =>
      setField<DateTime>('license_expiry', value);

  String? get licenseIssuingAuthority =>
      getField<String>('license_issuing_authority');
  set licenseIssuingAuthority(String? value) =>
      setField<String>('license_issuing_authority', value);

  List<String> get specialties => getListField<String>('specialties')!;
  set specialties(List<String> value) =>
      setListField<String>('specialties', value);

  List<String> get subSpecialties => getListField<String>('sub_specialties');
  set subSpecialties(List<String>? value) =>
      setListField<String>('sub_specialties', value);

  List<String> get qualifications => getListField<String>('qualifications')!;
  set qualifications(List<String> value) =>
      setListField<String>('qualifications', value);

  int? get yearsOfExperience => getField<int>('years_of_experience');
  set yearsOfExperience(int? value) =>
      setField<int>('years_of_experience', value);

  double? get consultationFee => getField<double>('consultation_fee');
  set consultationFee(double? value) =>
      setField<double>('consultation_fee', value);

  int? get consultationDurationMinutes =>
      getField<int>('consultation_duration_minutes');
  set consultationDurationMinutes(int? value) =>
      setField<int>('consultation_duration_minutes', value);

  bool? get acceptsNewPatients => getField<bool>('accepts_new_patients');
  set acceptsNewPatients(bool? value) =>
      setField<bool>('accepts_new_patients', value);

  List<String> get languagesSpoken => getListField<String>('languages_spoken');
  set languagesSpoken(List<String>? value) =>
      setListField<String>('languages_spoken', value);

  List<String> get awards => getListField<String>('awards');
  set awards(List<String>? value) => setListField<String>('awards', value);

  List<String> get researchInterests =>
      getListField<String>('research_interests');
  set researchInterests(List<String>? value) =>
      setListField<String>('research_interests', value);

  List<String> get boardCertifications =>
      getListField<String>('board_certifications');
  set boardCertifications(List<String>? value) =>
      setListField<String>('board_certifications', value);

  List<String> get hospitalAffiliations =>
      getListField<String>('hospital_affiliations');
  set hospitalAffiliations(List<String>? value) =>
      setListField<String>('hospital_affiliations', value);

  String? get availabilityStatus => getField<String>('availability_status');
  set availabilityStatus(String? value) =>
      setField<String>('availability_status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
