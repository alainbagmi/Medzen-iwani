import '../database.dart';

class FacilitiesTable extends SupabaseTable<FacilitiesRow> {
  @override
  String get tableName => 'facilities';

  @override
  FacilitiesRow createRow(Map<String, dynamic> data) => FacilitiesRow(data);
}

class FacilitiesRow extends SupabaseDataRow {
  FacilitiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilitiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get facilityCode => getField<String>('facility_code')!;
  set facilityCode(String value) => setField<String>('facility_code', value);

  String get facilityName => getField<String>('facility_name')!;
  set facilityName(String value) => setField<String>('facility_name', value);

  String? get facilityType => getField<String>('facility_type');
  set facilityType(String? value) => setField<String>('facility_type', value);

  String get address => getField<String>('address')!;
  set address(String value) => setField<String>('address', value);

  String get city => getField<String>('city')!;
  set city(String value) => setField<String>('city', value);

  String? get state => getField<String>('state');
  set state(String? value) => setField<String>('state', value);

  String get country => getField<String>('country')!;
  set country(String value) => setField<String>('country', value);

  String? get postalCode => getField<String>('postal_code');
  set postalCode(String? value) => setField<String>('postal_code', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get website => getField<String>('website');
  set website(String? value) => setField<String>('website', value);

  dynamic? get operatingHours => getField<dynamic>('operating_hours');
  set operatingHours(dynamic? value) =>
      setField<dynamic>('operating_hours', value);

  bool? get emergencyServices => getField<bool>('emergency_services');
  set emergencyServices(bool? value) =>
      setField<bool>('emergency_services', value);

  List<String> get specialties => getListField<String>('specialties');
  set specialties(List<String>? value) =>
      setListField<String>('specialties', value);

  List<String> get certifications => getListField<String>('certifications');
  set certifications(List<String>? value) =>
      setListField<String>('certifications', value);

  int? get bedCapacity => getField<int>('bed_capacity');
  set bedCapacity(int? value) => setField<int>('bed_capacity', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  double? get consultationFee => getField<double>('consultation_fee');
  set consultationFee(double? value) =>
      setField<double>('consultation_fee', value);
}
