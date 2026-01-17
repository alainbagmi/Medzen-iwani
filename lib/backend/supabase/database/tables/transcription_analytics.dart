import '../database.dart';

class TranscriptionAnalyticsTable
    extends SupabaseTable<TranscriptionAnalyticsRow> {
  @override
  String get tableName => 'transcription_analytics';

  @override
  TranscriptionAnalyticsRow createRow(Map<String, dynamic> data) =>
      TranscriptionAnalyticsRow(data);
}

class TranscriptionAnalyticsRow extends SupabaseDataRow {
  TranscriptionAnalyticsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TranscriptionAnalyticsTable();

  DateTime? get usageDate => getField<DateTime>('usage_date');
  set usageDate(DateTime? value) => setField<DateTime>('usage_date', value);

  int? get totalSessions => getField<int>('total_sessions');
  set totalSessions(int? value) => setField<int>('total_sessions', value);

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

  double? get totalDurationMinutes =>
      getField<double>('total_duration_minutes');
  set totalDurationMinutes(double? value) =>
      setField<double>('total_duration_minutes', value);

  double? get avgDurationMinutes => getField<double>('avg_duration_minutes');
  set avgDurationMinutes(double? value) =>
      setField<double>('avg_duration_minutes', value);

  double? get maxDurationMinutes => getField<double>('max_duration_minutes');
  set maxDurationMinutes(double? value) =>
      setField<double>('max_duration_minutes', value);

  double? get totalCostUsd => getField<double>('total_cost_usd');
  set totalCostUsd(double? value) => setField<double>('total_cost_usd', value);

  double? get successRatePercent => getField<double>('success_rate_percent');
  set successRatePercent(double? value) =>
      setField<double>('success_rate_percent', value);

  double? get timeoutRatePercent => getField<double>('timeout_rate_percent');
  set timeoutRatePercent(double? value) =>
      setField<double>('timeout_rate_percent', value);
}
