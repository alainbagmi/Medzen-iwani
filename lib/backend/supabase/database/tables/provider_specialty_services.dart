import '../database.dart';

class ProviderSpecialtyServicesTable
    extends SupabaseTable<ProviderSpecialtyServicesRow> {
  @override
  String get tableName => 'provider_specialty_services';

  @override
  ProviderSpecialtyServicesRow createRow(Map<String, dynamic> data) =>
      ProviderSpecialtyServicesRow(data);
}

class ProviderSpecialtyServicesRow extends SupabaseDataRow {
  ProviderSpecialtyServicesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProviderSpecialtyServicesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get specialtyServiceId => getField<String>('specialty_service_id');
  set specialtyServiceId(String? value) =>
      setField<String>('specialty_service_id', value);

  double? get customPrice => getField<double>('custom_price');
  set customPrice(double? value) => setField<double>('custom_price', value);

  int? get customDurationMinutes => getField<int>('custom_duration_minutes');
  set customDurationMinutes(int? value) =>
      setField<int>('custom_duration_minutes', value);

  bool? get isAvailable => getField<bool>('is_available');
  set isAvailable(bool? value) => setField<bool>('is_available', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
