import '../database.dart';

class AppointmentsTable extends SupabaseTable<AppointmentsRow> {
  @override
  String get tableName => 'appointments';

  @override
  AppointmentsRow createRow(Map<String, dynamic> data) => AppointmentsRow(data);
}

class AppointmentsRow extends SupabaseDataRow {
  AppointmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppointmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get appointmentNumber => getField<String>('appointment_number')!;
  set appointmentNumber(String value) =>
      setField<String>('appointment_number', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String get appointmentType => getField<String>('appointment_type')!;
  set appointmentType(String value) =>
      setField<String>('appointment_type', value);

  String? get specialty => getField<String>('specialty');
  set specialty(String? value) => setField<String>('specialty', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get consultationMode => getField<String>('consultation_mode');
  set consultationMode(String? value) =>
      setField<String>('consultation_mode', value);

  DateTime get scheduledStart => getField<DateTime>('scheduled_start')!;
  set scheduledStart(DateTime value) =>
      setField<DateTime>('scheduled_start', value);

  DateTime get scheduledEnd => getField<DateTime>('scheduled_end')!;
  set scheduledEnd(DateTime value) =>
      setField<DateTime>('scheduled_end', value);

  DateTime? get actualStart => getField<DateTime>('actual_start');
  set actualStart(DateTime? value) => setField<DateTime>('actual_start', value);

  DateTime? get actualEnd => getField<DateTime>('actual_end');
  set actualEnd(DateTime? value) => setField<DateTime>('actual_end', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  String? get cancellationReason => getField<String>('cancellation_reason');
  set cancellationReason(String? value) =>
      setField<String>('cancellation_reason', value);

  String? get cancelledById => getField<String>('cancelled_by_id');
  set cancelledById(String? value) =>
      setField<String>('cancelled_by_id', value);

  DateTime? get cancelledAt => getField<DateTime>('cancelled_at');
  set cancelledAt(DateTime? value) => setField<DateTime>('cancelled_at', value);

  bool? get reminderSent => getField<bool>('reminder_sent');
  set reminderSent(bool? value) => setField<bool>('reminder_sent', value);

  DateTime? get reminderSentAt => getField<DateTime>('reminder_sent_at');
  set reminderSentAt(DateTime? value) =>
      setField<DateTime>('reminder_sent_at', value);

  String? get videoCallId => getField<String>('video_call_id');
  set videoCallId(String? value) => setField<String>('video_call_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  PostgresTime? get startTime => getField<PostgresTime>('start_time');
  set startTime(PostgresTime? value) =>
      setField<PostgresTime>('start_time', value);

  String? get videoCallStatus => getField<String>('video_call_status');
  set videoCallStatus(String? value) =>
      setField<String>('video_call_status', value);

  DateTime? get providerJoinedAt => getField<DateTime>('provider_joined_at');
  set providerJoinedAt(DateTime? value) =>
      setField<DateTime>('provider_joined_at', value);

  DateTime? get patientJoinedAt => getField<DateTime>('patient_joined_at');
  set patientJoinedAt(DateTime? value) =>
      setField<DateTime>('patient_joined_at', value);

  String? get videoCallUrl => getField<String>('video_call_url');
  set videoCallUrl(String? value) => setField<String>('video_call_url', value);

  DateTime? get sessionCreatedAt => getField<DateTime>('session_created_at');
  set sessionCreatedAt(DateTime? value) =>
      setField<DateTime>('session_created_at', value);

  bool? get requiresVideoConsent => getField<bool>('requires_video_consent');
  set requiresVideoConsent(bool? value) =>
      setField<bool>('requires_video_consent', value);

  bool? get videoEnabled => getField<bool>('video_enabled');
  set videoEnabled(bool? value) => setField<bool>('video_enabled', value);
}
