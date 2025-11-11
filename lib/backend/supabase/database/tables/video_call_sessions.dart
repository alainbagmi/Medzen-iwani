import '../database.dart';

class VideoCallSessionsTable extends SupabaseTable<VideoCallSessionsRow> {
  @override
  String get tableName => 'video_call_sessions';

  @override
  VideoCallSessionsRow createRow(Map<String, dynamic> data) =>
      VideoCallSessionsRow(data);
}

class VideoCallSessionsRow extends SupabaseDataRow {
  VideoCallSessionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideoCallSessionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String get channelName => getField<String>('channel_name')!;
  set channelName(String value) => setField<String>('channel_name', value);

  String? get agoraAppId => getField<String>('agora_app_id');
  set agoraAppId(String? value) => setField<String>('agora_app_id', value);

  List<String> get participants => getListField<String>('participants')!;
  set participants(List<String> value) =>
      setListField<String>('participants', value);

  String? get initiatorId => getField<String>('initiator_id');
  set initiatorId(String? value) => setField<String>('initiator_id', value);

  String? get callType => getField<String>('call_type');
  set callType(String? value) => setField<String>('call_type', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get startedAt => getField<DateTime>('started_at');
  set startedAt(DateTime? value) => setField<DateTime>('started_at', value);

  DateTime? get endedAt => getField<DateTime>('ended_at');
  set endedAt(DateTime? value) => setField<DateTime>('ended_at', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  String? get recordingUrl => getField<String>('recording_url');
  set recordingUrl(String? value) => setField<String>('recording_url', value);

  int? get recordingDurationSeconds =>
      getField<int>('recording_duration_seconds');
  set recordingDurationSeconds(int? value) =>
      setField<int>('recording_duration_seconds', value);

  dynamic? get qualityMetrics => getField<dynamic>('quality_metrics');
  set qualityMetrics(dynamic? value) =>
      setField<dynamic>('quality_metrics', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
