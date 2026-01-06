import '../database.dart';

class VideoCallParticipantsTable
    extends SupabaseTable<VideoCallParticipantsRow> {
  @override
  String get tableName => 'video_call_participants';

  @override
  VideoCallParticipantsRow createRow(Map<String, dynamic> data) =>
      VideoCallParticipantsRow(data);
}

class VideoCallParticipantsRow extends SupabaseDataRow {
  VideoCallParticipantsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideoCallParticipantsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get videoCallId => getField<String>('video_call_id')!;
  set videoCallId(String value) => setField<String>('video_call_id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get role => getField<String>('role')!;
  set role(String value) => setField<String>('role', value);

  String? get chimeAttendeeId => getField<String>('chime_attendee_id');
  set chimeAttendeeId(String? value) =>
      setField<String>('chime_attendee_id', value);

  String? get chimeJoinToken => getField<String>('chime_join_token');
  set chimeJoinToken(String? value) =>
      setField<String>('chime_join_token', value);

  String? get chimeExternalUserId => getField<String>('chime_external_user_id');
  set chimeExternalUserId(String? value) =>
      setField<String>('chime_external_user_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get joinedAt => getField<DateTime>('joined_at');
  set joinedAt(DateTime? value) => setField<DateTime>('joined_at', value);

  DateTime? get leftAt => getField<DateTime>('left_at');
  set leftAt(DateTime? value) => setField<DateTime>('left_at', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  dynamic? get qualityMetrics => getField<dynamic>('quality_metrics');
  set qualityMetrics(dynamic? value) =>
      setField<dynamic>('quality_metrics', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
