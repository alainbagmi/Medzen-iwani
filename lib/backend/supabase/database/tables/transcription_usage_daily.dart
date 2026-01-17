import '../database.dart';

class TranscriptionUsageDailyTable
    extends SupabaseTable<TranscriptionUsageDailyRow> {
  @override
  String get tableName => 'transcription_usage_daily';

  @override
  TranscriptionUsageDailyRow createRow(Map<String, dynamic> data) =>
      TranscriptionUsageDailyRow(data);
}

class TranscriptionUsageDailyRow extends SupabaseDataRow {
  TranscriptionUsageDailyRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TranscriptionUsageDailyTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get usageDate => getField<DateTime>('usage_date')!;
  set usageDate(DateTime value) => setField<DateTime>('usage_date', value);

  int? get totalSessions => getField<int>('total_sessions');
  set totalSessions(int? value) => setField<int>('total_sessions', value);

  int? get totalDurationSeconds => getField<int>('total_duration_seconds');
  set totalDurationSeconds(int? value) =>
      setField<int>('total_duration_seconds', value);

  double? get totalCostUsd => getField<double>('total_cost_usd');
  set totalCostUsd(double? value) => setField<double>('total_cost_usd', value);

  int? get successfulTranscriptions =>
      getField<int>('successful_transcriptions');
  set successfulTranscriptions(int? value) =>
      setField<int>('successful_transcriptions', value);

  int? get failedTranscriptions => getField<int>('failed_transcriptions');
  set failedTranscriptions(int? value) =>
      setField<int>('failed_transcriptions', value);

  int? get timeoutTranscriptions => getField<int>('timeout_transcriptions');
  set timeoutTranscriptions(int? value) =>
      setField<int>('timeout_transcriptions', value);

  int? get avgDurationSeconds => getField<int>('avg_duration_seconds');
  set avgDurationSeconds(int? value) =>
      setField<int>('avg_duration_seconds', value);

  int? get maxDurationSeconds => getField<int>('max_duration_seconds');
  set maxDurationSeconds(int? value) =>
      setField<int>('max_duration_seconds', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
