import '../database.dart';

class LiveCaptionSegmentsTable extends SupabaseTable<LiveCaptionSegmentsRow> {
  @override
  String get tableName => 'live_caption_segments';

  @override
  LiveCaptionSegmentsRow createRow(Map<String, dynamic> data) =>
      LiveCaptionSegmentsRow(data);
}

class LiveCaptionSegmentsRow extends SupabaseDataRow {
  LiveCaptionSegmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LiveCaptionSegmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  String? get attendeeId => getField<String>('attendee_id');
  set attendeeId(String? value) => setField<String>('attendee_id', value);

  String? get speakerName => getField<String>('speaker_name');
  set speakerName(String? value) => setField<String>('speaker_name', value);

  String get transcriptText => getField<String>('transcript_text')!;
  set transcriptText(String value) =>
      setField<String>('transcript_text', value);

  bool? get isPartial => getField<bool>('is_partial');
  set isPartial(bool? value) => setField<bool>('is_partial', value);

  String? get languageCode => getField<String>('language_code');
  set languageCode(String? value) => setField<String>('language_code', value);

  double? get confidence => getField<double>('confidence');
  set confidence(double? value) => setField<double>('confidence', value);

  int? get startTimeMs => getField<int>('start_time_ms');
  set startTimeMs(int? value) => setField<int>('start_time_ms', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
