import '../database.dart';

class ProviderAvailabilityTable extends SupabaseTable<ProviderAvailabilityRow> {
  @override
  String get tableName => 'provider_availability';

  @override
  ProviderAvailabilityRow createRow(Map<String, dynamic> data) =>
      ProviderAvailabilityRow(data);
}

class ProviderAvailabilityRow extends SupabaseDataRow {
  ProviderAvailabilityRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProviderAvailabilityTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  int? get dayOfWeek => getField<int>('day_of_week');
  set dayOfWeek(int? value) => setField<int>('day_of_week', value);

  PostgresTime get startTime => getField<PostgresTime>('start_time')!;
  set startTime(PostgresTime value) =>
      setField<PostgresTime>('start_time', value);

  PostgresTime get endTime => getField<PostgresTime>('end_time')!;
  set endTime(PostgresTime value) => setField<PostgresTime>('end_time', value);

  int? get slotDurationMinutes => getField<int>('slot_duration_minutes');
  set slotDurationMinutes(int? value) =>
      setField<int>('slot_duration_minutes', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
