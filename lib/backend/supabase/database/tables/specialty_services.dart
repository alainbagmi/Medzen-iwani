import '../database.dart';

class SpecialtyServicesTable extends SupabaseTable<SpecialtyServicesRow> {
  @override
  String get tableName => 'specialty_services';

  @override
  SpecialtyServicesRow createRow(Map<String, dynamic> data) =>
      SpecialtyServicesRow(data);
}

class SpecialtyServicesRow extends SupabaseDataRow {
  SpecialtyServicesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SpecialtyServicesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get specialtyId => getField<String>('specialty_id');
  set specialtyId(String? value) => setField<String>('specialty_id', value);

  String get serviceName => getField<String>('service_name')!;
  set serviceName(String value) => setField<String>('service_name', value);

  String? get serviceCode => getField<String>('service_code');
  set serviceCode(String? value) => setField<String>('service_code', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  int? get typicalDurationMinutes => getField<int>('typical_duration_minutes');
  set typicalDurationMinutes(int? value) =>
      setField<int>('typical_duration_minutes', value);

  double? get basePrice => getField<double>('base_price');
  set basePrice(double? value) => setField<double>('base_price', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  bool? get requiresReferral => getField<bool>('requires_referral');
  set requiresReferral(bool? value) =>
      setField<bool>('requires_referral', value);

  String? get preparationInstructions =>
      getField<String>('preparation_instructions');
  set preparationInstructions(String? value) =>
      setField<String>('preparation_instructions', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
