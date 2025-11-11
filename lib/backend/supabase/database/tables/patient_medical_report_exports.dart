import '../database.dart';

class PatientMedicalReportExportsTable
    extends SupabaseTable<PatientMedicalReportExportsRow> {
  @override
  String get tableName => 'patient_medical_report_exports';

  @override
  PatientMedicalReportExportsRow createRow(Map<String, dynamic> data) =>
      PatientMedicalReportExportsRow(data);
}

class PatientMedicalReportExportsRow extends SupabaseDataRow {
  PatientMedicalReportExportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PatientMedicalReportExportsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get reportType => getField<String>('report_type');
  set reportType(String? value) => setField<String>('report_type', value);

  DateTime? get dateRangeStart => getField<DateTime>('date_range_start');
  set dateRangeStart(DateTime? value) =>
      setField<DateTime>('date_range_start', value);

  DateTime? get dateRangeEnd => getField<DateTime>('date_range_end');
  set dateRangeEnd(DateTime? value) =>
      setField<DateTime>('date_range_end', value);

  List<String> get includeSections => getListField<String>('include_sections');
  set includeSections(List<String>? value) =>
      setListField<String>('include_sections', value);

  String? get format => getField<String>('format');
  set format(String? value) => setField<String>('format', value);

  String get fileUrl => getField<String>('file_url')!;
  set fileUrl(String value) => setField<String>('file_url', value);

  int? get fileSizeBytes => getField<int>('file_size_bytes');
  set fileSizeBytes(int? value) => setField<int>('file_size_bytes', value);

  String? get requestedById => getField<String>('requested_by_id');
  set requestedById(String? value) =>
      setField<String>('requested_by_id', value);

  DateTime? get expiresAt => getField<DateTime>('expires_at');
  set expiresAt(DateTime? value) => setField<DateTime>('expires_at', value);

  int? get downloadCount => getField<int>('download_count');
  set downloadCount(int? value) => setField<int>('download_count', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
