import '../database.dart';

class AppointmentOverviewTable extends SupabaseTable<AppointmentOverviewRow> {
  @override
  String get tableName => 'appointment_overview';

  @override
  AppointmentOverviewRow createRow(Map<String, dynamic> data) =>
      AppointmentOverviewRow(data);
}

class AppointmentOverviewRow extends SupabaseDataRow {
  AppointmentOverviewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppointmentOverviewTable();

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get appointmentNumber => getField<String>('appointment_number');
  set appointmentNumber(String? value) =>
      setField<String>('appointment_number', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime? get scheduledStart => getField<DateTime>('scheduled_start');
  set scheduledStart(DateTime? value) =>
      setField<DateTime>('scheduled_start', value);

  DateTime? get scheduledEnd => getField<DateTime>('scheduled_end');
  set scheduledEnd(DateTime? value) =>
      setField<DateTime>('scheduled_end', value);

  DateTime? get appointmentStartDate =>
      getField<DateTime>('appointment_start_date');
  set appointmentStartDate(DateTime? value) =>
      setField<DateTime>('appointment_start_date', value);

  PostgresTime? get appointmentStartTime =>
      getField<PostgresTime>('appointment_start_time');
  set appointmentStartTime(PostgresTime? value) =>
      setField<PostgresTime>('appointment_start_time', value);

  String? get appointmentStatus => getField<String>('appointment_status');
  set appointmentStatus(String? value) =>
      setField<String>('appointment_status', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get consultationMode => getField<String>('consultation_mode');
  set consultationMode(String? value) =>
      setField<String>('consultation_mode', value);

  String? get appointmentType => getField<String>('appointment_type');
  set appointmentType(String? value) =>
      setField<String>('appointment_type', value);

  String? get specialty => getField<String>('specialty');
  set specialty(String? value) => setField<String>('specialty', value);

  String? get chiefComplaint => getField<String>('chief_complaint');
  set chiefComplaint(String? value) =>
      setField<String>('chief_complaint', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  bool? get videoEnabled => getField<bool>('video_enabled');
  set videoEnabled(bool? value) => setField<bool>('video_enabled', value);

  String? get videoCallId => getField<String>('video_call_id');
  set videoCallId(String? value) => setField<String>('video_call_id', value);

  String? get videoCallStatus => getField<String>('video_call_status');
  set videoCallStatus(String? value) =>
      setField<String>('video_call_status', value);

  String? get videoCallUrl => getField<String>('video_call_url');
  set videoCallUrl(String? value) => setField<String>('video_call_url', value);

  DateTime? get providerJoinedAt => getField<DateTime>('provider_joined_at');
  set providerJoinedAt(DateTime? value) =>
      setField<DateTime>('provider_joined_at', value);

  DateTime? get patientJoinedAt => getField<DateTime>('patient_joined_at');
  set patientJoinedAt(DateTime? value) =>
      setField<DateTime>('patient_joined_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get patientUserId => getField<String>('patient_user_id');
  set patientUserId(String? value) =>
      setField<String>('patient_user_id', value);

  String? get patientFirstName => getField<String>('patient_first_name');
  set patientFirstName(String? value) =>
      setField<String>('patient_first_name', value);

  String? get patientLastName => getField<String>('patient_last_name');
  set patientLastName(String? value) =>
      setField<String>('patient_last_name', value);

  String? get patientFullname => getField<String>('patient_fullname');
  set patientFullname(String? value) =>
      setField<String>('patient_fullname', value);

  String? get patientFullName => getField<String>('patient_full_name');
  set patientFullName(String? value) =>
      setField<String>('patient_full_name', value);

  String? get patientImageUrl => getField<String>('patient_image_url');
  set patientImageUrl(String? value) =>
      setField<String>('patient_image_url', value);

  String? get patientEmail => getField<String>('patient_email');
  set patientEmail(String? value) => setField<String>('patient_email', value);

  String? get patientPhone => getField<String>('patient_phone');
  set patientPhone(String? value) => setField<String>('patient_phone', value);

  String? get providerProfileId => getField<String>('provider_profile_id');
  set providerProfileId(String? value) =>
      setField<String>('provider_profile_id', value);

  String? get providerUserId => getField<String>('provider_user_id');
  set providerUserId(String? value) =>
      setField<String>('provider_user_id', value);

  String? get providerFirstName => getField<String>('provider_first_name');
  set providerFirstName(String? value) =>
      setField<String>('provider_first_name', value);

  String? get providerLastName => getField<String>('provider_last_name');
  set providerLastName(String? value) =>
      setField<String>('provider_last_name', value);

  String? get providerFullname => getField<String>('provider_fullname');
  set providerFullname(String? value) =>
      setField<String>('provider_fullname', value);

  String? get providerFullName => getField<String>('provider_full_name');
  set providerFullName(String? value) =>
      setField<String>('provider_full_name', value);

  String? get providerImageUrl => getField<String>('provider_image_url');
  set providerImageUrl(String? value) =>
      setField<String>('provider_image_url', value);

  String? get providerEmail => getField<String>('provider_email');
  set providerEmail(String? value) => setField<String>('provider_email', value);

  String? get providerPhone => getField<String>('provider_phone');
  set providerPhone(String? value) => setField<String>('provider_phone', value);

  String? get providerRole => getField<String>('provider_role');
  set providerRole(String? value) => setField<String>('provider_role', value);

  String? get providerSpecialty => getField<String>('provider_specialty');
  set providerSpecialty(String? value) =>
      setField<String>('provider_specialty', value);

  double? get consultationFee => getField<double>('consultation_fee');
  set consultationFee(double? value) =>
      setField<double>('consultation_fee', value);

  int? get consultationDurationMinutes =>
      getField<int>('consultation_duration_minutes');
  set consultationDurationMinutes(int? value) =>
      setField<int>('consultation_duration_minutes', value);

  String? get facilityRecordId => getField<String>('facility_record_id');
  set facilityRecordId(String? value) =>
      setField<String>('facility_record_id', value);

  String? get facilityName => getField<String>('facility_name');
  set facilityName(String? value) => setField<String>('facility_name', value);

  String? get facilityAddress => getField<String>('facility_address');
  set facilityAddress(String? value) =>
      setField<String>('facility_address', value);

  String? get facilityImageUrl => getField<String>('facility_image_url');
  set facilityImageUrl(String? value) =>
      setField<String>('facility_image_url', value);

  String? get facilityPhone => getField<String>('facility_phone');
  set facilityPhone(String? value) => setField<String>('facility_phone', value);
}
