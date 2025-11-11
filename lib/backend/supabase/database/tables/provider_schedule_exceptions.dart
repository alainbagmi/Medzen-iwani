import '../database.dart';

class ProviderScheduleExceptionsTable
    extends SupabaseTable<ProviderScheduleExceptionsRow> {
  @override
  String get tableName => 'provider_schedule_exceptions';

  @override
  ProviderScheduleExceptionsRow createRow(Map<String, dynamic> data) =>
      ProviderScheduleExceptionsRow(data);
}

class ProviderScheduleExceptionsRow extends SupabaseDataRow {
  ProviderScheduleExceptionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProviderScheduleExceptionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  DateTime get exceptionDate => getField<DateTime>('exception_date')!;
  set exceptionDate(DateTime value) =>
      setField<DateTime>('exception_date', value);

  PostgresTime? get startTime => getField<PostgresTime>('start_time');
  set startTime(PostgresTime? value) =>
      setField<PostgresTime>('start_time', value);

  PostgresTime? get endTime => getField<PostgresTime>('end_time');
  set endTime(PostgresTime? value) => setField<PostgresTime>('end_time', value);

  String? get exceptionType => getField<String>('exception_type');
  set exceptionType(String? value) => setField<String>('exception_type', value);

  String? get reason => getField<String>('reason');
  set reason(String? value) => setField<String>('reason', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
