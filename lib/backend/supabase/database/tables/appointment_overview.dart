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

  String? get patientFullname => getField<String>('patient_fullname');
  set patientFullname(String? value) =>
      setField<String>('patient_fullname', value);

  String? get providerFullname => getField<String>('provider_fullname');
  set providerFullname(String? value) =>
      setField<String>('provider_fullname', value);

  String? get providerSpecialty => getField<String>('provider_specialty');
  set providerSpecialty(String? value) =>
      setField<String>('provider_specialty', value);

  String? get patientImageUrl => getField<String>('patient_image_url');
  set patientImageUrl(String? value) =>
      setField<String>('patient_image_url', value);

  String? get providerImageUrl => getField<String>('provider_image_url');
  set providerImageUrl(String? value) =>
      setField<String>('provider_image_url', value);

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

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String? get consultationMode => getField<String>('consultation_mode');
  set consultationMode(String? value) =>
      setField<String>('consultation_mode', value);
}
