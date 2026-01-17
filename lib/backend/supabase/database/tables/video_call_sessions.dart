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

  String get appointmentId => getField<String>('appointment_id')!;
  set appointmentId(String value) => setField<String>('appointment_id', value);

  String get channelName => getField<String>('channel_name')!;
  set channelName(String value) => setField<String>('channel_name', value);

  String? get agoraAppId => getField<String>('agora_app_id');
  set agoraAppId(String? value) => setField<String>('agora_app_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get providerRtcToken => getField<String>('provider_rtc_token');
  set providerRtcToken(String? value) =>
      setField<String>('provider_rtc_token', value);

  String? get patientRtcToken => getField<String>('patient_rtc_token');
  set patientRtcToken(String? value) =>
      setField<String>('patient_rtc_token', value);

  DateTime? get tokenExpiresAt => getField<DateTime>('token_expires_at');
  set tokenExpiresAt(DateTime? value) =>
      setField<DateTime>('token_expires_at', value);

  DateTime? get callWindowStart => getField<DateTime>('call_window_start');
  set callWindowStart(DateTime? value) =>
      setField<DateTime>('call_window_start', value);

  DateTime? get callWindowEnd => getField<DateTime>('call_window_end');
  set callWindowEnd(DateTime? value) =>
      setField<DateTime>('call_window_end', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime? get startedAt => getField<DateTime>('started_at');
  set startedAt(DateTime? value) => setField<DateTime>('started_at', value);

  DateTime? get endedAt => getField<DateTime>('ended_at');
  set endedAt(DateTime? value) => setField<DateTime>('ended_at', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  bool? get recordingEnabled => getField<bool>('recording_enabled');
  set recordingEnabled(bool? value) =>
      setField<bool>('recording_enabled', value);

  String? get recordingUrl => getField<String>('recording_url');
  set recordingUrl(String? value) => setField<String>('recording_url', value);

  int? get recordingDurationSeconds =>
      getField<int>('recording_duration_seconds');
  set recordingDurationSeconds(int? value) =>
      setField<int>('recording_duration_seconds', value);

  dynamic? get qualityMetrics => getField<dynamic>('quality_metrics');
  set qualityMetrics(dynamic? value) =>
      setField<dynamic>('quality_metrics', value);

  String? get groupChatId => getField<String>('group_chat_id');
  set groupChatId(String? value) => setField<String>('group_chat_id', value);

  List<String> get participants => getListField<String>('participants');
  set participants(List<String>? value) =>
      setListField<String>('participants', value);

  String? get initiatorId => getField<String>('initiator_id');
  set initiatorId(String? value) => setField<String>('initiator_id', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime? get errorOccurredAt => getField<DateTime>('error_occurred_at');
  set errorOccurredAt(DateTime? value) =>
      setField<DateTime>('error_occurred_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  String? get meetingId => getField<String>('meeting_id');
  set meetingId(String? value) => setField<String>('meeting_id', value);

  dynamic? get meetingData => getField<dynamic>('meeting_data');
  set meetingData(dynamic? value) => setField<dynamic>('meeting_data', value);

  dynamic? get attendeeTokens => getField<dynamic>('attendee_tokens');
  set attendeeTokens(dynamic? value) =>
      setField<dynamic>('attendee_tokens', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get transcriptionJobName =>
      getField<String>('transcription_job_name');
  set transcriptionJobName(String? value) =>
      setField<String>('transcription_job_name', value);

  String? get transcriptionStatus => getField<String>('transcription_status');
  set transcriptionStatus(String? value) =>
      setField<String>('transcription_status', value);

  String? get transcript => getField<String>('transcript');
  set transcript(String? value) => setField<String>('transcript', value);

  dynamic? get speakerSegments => getField<dynamic>('speaker_segments');
  set speakerSegments(dynamic? value) =>
      setField<dynamic>('speaker_segments', value);

  dynamic? get medicalEntities => getField<dynamic>('medical_entities');
  set medicalEntities(dynamic? value) =>
      setField<dynamic>('medical_entities', value);

  dynamic? get icd10Codes => getField<dynamic>('icd10_codes');
  set icd10Codes(dynamic? value) => setField<dynamic>('icd10_codes', value);

  dynamic? get extractedMedications =>
      getField<dynamic>('extracted_medications');
  set extractedMedications(dynamic? value) =>
      setField<dynamic>('extracted_medications', value);

  DateTime? get entityExtractionCompletedAt =>
      getField<DateTime>('entity_extraction_completed_at');
  set entityExtractionCompletedAt(DateTime? value) =>
      setField<DateTime>('entity_extraction_completed_at', value);

  String? get recordingBucket => getField<String>('recording_bucket');
  set recordingBucket(String? value) =>
      setField<String>('recording_bucket', value);

  String? get recordingKey => getField<String>('recording_key');
  set recordingKey(String? value) => setField<String>('recording_key', value);

  int? get recordingFileSize => getField<int>('recording_file_size');
  set recordingFileSize(int? value) =>
      setField<int>('recording_file_size', value);

  String? get recordingFormat => getField<String>('recording_format');
  set recordingFormat(String? value) =>
      setField<String>('recording_format', value);

  DateTime? get recordingCompletedAt =>
      getField<DateTime>('recording_completed_at');
  set recordingCompletedAt(DateTime? value) =>
      setField<DateTime>('recording_completed_at', value);

  String? get externalMeetingId => getField<String>('external_meeting_id');
  set externalMeetingId(String? value) =>
      setField<String>('external_meeting_id', value);

  String? get mediaRegion => getField<String>('media_region');
  set mediaRegion(String? value) => setField<String>('media_region', value);

  String? get attendeeId => getField<String>('attendee_id');
  set attendeeId(String? value) => setField<String>('attendee_id', value);

  String? get joinToken => getField<String>('join_token');
  set joinToken(String? value) => setField<String>('join_token', value);

  String? get transcriptLanguage => getField<String>('transcript_language');
  set transcriptLanguage(String? value) =>
      setField<String>('transcript_language', value);

  dynamic? get detectedLanguages => getField<dynamic>('detected_languages');
  set detectedLanguages(dynamic? value) =>
      setField<dynamic>('detected_languages', value);

  dynamic? get transcriptSegments => getField<dynamic>('transcript_segments');
  set transcriptSegments(dynamic? value) =>
      setField<dynamic>('transcript_segments', value);

  bool? get ttsEnabled => getField<bool>('tts_enabled');
  set ttsEnabled(bool? value) => setField<bool>('tts_enabled', value);

  String? get ttsLanguage => getField<String>('tts_language');
  set ttsLanguage(String? value) => setField<String>('tts_language', value);

  String? get customVocabularyName =>
      getField<String>('custom_vocabulary_name');
  set customVocabularyName(String? value) =>
      setField<String>('custom_vocabulary_name', value);

  double? get languageConfidence => getField<double>('language_confidence');
  set languageConfidence(double? value) =>
      setField<double>('language_confidence', value);

  bool? get autoLanguageDetect => getField<bool>('auto_language_detect');
  set autoLanguageDetect(bool? value) =>
      setField<bool>('auto_language_detect', value);

  int? get totalParticipants => getField<int>('total_participants');
  set totalParticipants(int? value) =>
      setField<int>('total_participants', value);

  int? get maxParticipantsReached => getField<int>('max_participants_reached');
  set maxParticipantsReached(int? value) =>
      setField<int>('max_participants_reached', value);

  bool? get isRecording => getField<bool>('is_recording');
  set isRecording(bool? value) => setField<bool>('is_recording', value);

  String? get recordingPipelineId => getField<String>('recording_pipeline_id');
  set recordingPipelineId(String? value) =>
      setField<String>('recording_pipeline_id', value);

  bool? get transcriptionEnabled => getField<bool>('transcription_enabled');
  set transcriptionEnabled(bool? value) =>
      setField<bool>('transcription_enabled', value);

  String? get transcriptionLanguage =>
      getField<String>('transcription_language');
  set transcriptionLanguage(String? value) =>
      setField<String>('transcription_language', value);

  dynamic? get mediaPlacement => getField<dynamic>('media_placement');
  set mediaPlacement(dynamic? value) =>
      setField<dynamic>('media_placement', value);

  String? get endedBy => getField<String>('ended_by');
  set endedBy(String? value) => setField<String>('ended_by', value);

  String? get transcriptionOutputKey =>
      getField<String>('transcription_output_key');
  set transcriptionOutputKey(String? value) =>
      setField<String>('transcription_output_key', value);

  DateTime? get transcriptionCompletedAt =>
      getField<DateTime>('transcription_completed_at');
  set transcriptionCompletedAt(DateTime? value) =>
      setField<DateTime>('transcription_completed_at', value);

  String? get transcriptionError => getField<String>('transcription_error');
  set transcriptionError(String? value) =>
      setField<String>('transcription_error', value);

  dynamic? get medicalCodes => getField<dynamic>('medical_codes');
  set medicalCodes(dynamic? value) => setField<dynamic>('medical_codes', value);

  dynamic? get medicalSummary => getField<dynamic>('medical_summary');
  set medicalSummary(dynamic? value) =>
      setField<dynamic>('medical_summary', value);

  bool? get isCallActive => getField<bool>('is_call_active');
  set isCallActive(bool? value) => setField<bool>('is_call_active', value);

  bool? get liveTranscriptionEnabled =>
      getField<bool>('live_transcription_enabled');
  set liveTranscriptionEnabled(bool? value) =>
      setField<bool>('live_transcription_enabled', value);

  String? get liveTranscriptionLanguage =>
      getField<String>('live_transcription_language');
  set liveTranscriptionLanguage(String? value) =>
      setField<String>('live_transcription_language', value);

  DateTime? get liveTranscriptionStartedAt =>
      getField<DateTime>('live_transcription_started_at');
  set liveTranscriptionStartedAt(DateTime? value) =>
      setField<DateTime>('live_transcription_started_at', value);

  int? get transcriptionDurationSeconds =>
      getField<int>('transcription_duration_seconds');
  set transcriptionDurationSeconds(int? value) =>
      setField<int>('transcription_duration_seconds', value);

  double? get transcriptionEstimatedCostUsd =>
      getField<double>('transcription_estimated_cost_usd');
  set transcriptionEstimatedCostUsd(double? value) =>
      setField<double>('transcription_estimated_cost_usd', value);

  int? get transcriptionMaxDurationMinutes =>
      getField<int>('transcription_max_duration_minutes');
  set transcriptionMaxDurationMinutes(int? value) =>
      setField<int>('transcription_max_duration_minutes', value);

  bool? get transcriptionAutoStopped =>
      getField<bool>('transcription_auto_stopped');
  set transcriptionAutoStopped(bool? value) =>
      setField<bool>('transcription_auto_stopped', value);

  String? get transcriptionMode => getField<String>('transcription_mode');
  set transcriptionMode(String? value) =>
      setField<String>('transcription_mode', value);
}
