import '../database.dart';

class RadiologyReportsTable extends SupabaseTable<RadiologyReportsRow> {
  @override
  String get tableName => 'radiology_reports';

  @override
  RadiologyReportsRow createRow(Map<String, dynamic> data) =>
      RadiologyReportsRow(data);
}

class RadiologyReportsRow extends SupabaseDataRow {
  RadiologyReportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RadiologyReportsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get radiologistId => getField<String>('radiologist_id');
  set radiologistId(String? value) => setField<String>('radiologist_id', value);

  String? get orderingProviderId => getField<String>('ordering_provider_id');
  set orderingProviderId(String? value) =>
      setField<String>('ordering_provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get examDate => getField<DateTime>('exam_date')!;
  set examDate(DateTime value) => setField<DateTime>('exam_date', value);

  String get modality => getField<String>('modality')!;
  set modality(String value) => setField<String>('modality', value);

  String get bodyPart => getField<String>('body_part')!;
  set bodyPart(String value) => setField<String>('body_part', value);

  String get indication => getField<String>('indication')!;
  set indication(String value) => setField<String>('indication', value);

  String? get technique => getField<String>('technique');
  set technique(String? value) => setField<String>('technique', value);

  String get findings => getField<String>('findings')!;
  set findings(String value) => setField<String>('findings', value);

  String get impressions => getField<String>('impressions')!;
  set impressions(String value) => setField<String>('impressions', value);

  String? get comparisonStudies => getField<String>('comparison_studies');
  set comparisonStudies(String? value) =>
      setField<String>('comparison_studies', value);

  String? get recommendations => getField<String>('recommendations');
  set recommendations(String? value) =>
      setField<String>('recommendations', value);

  bool? get contrastUsed => getField<bool>('contrast_used');
  set contrastUsed(bool? value) => setField<bool>('contrast_used', value);

  String? get contrastType => getField<String>('contrast_type');
  set contrastType(String? value) => setField<String>('contrast_type', value);

  double? get radiationDoseMgy => getField<double>('radiation_dose_mgy');
  set radiationDoseMgy(double? value) =>
      setField<double>('radiation_dose_mgy', value);

  int? get numberOfImages => getField<int>('number_of_images');
  set numberOfImages(int? value) => setField<int>('number_of_images', value);

  bool? get criticalFinding => getField<bool>('critical_finding');
  set criticalFinding(bool? value) => setField<bool>('critical_finding', value);

  bool? get criticalFindingCommunicated =>
      getField<bool>('critical_finding_communicated');
  set criticalFindingCommunicated(bool? value) =>
      setField<bool>('critical_finding_communicated', value);

  String? get communicatedTo => getField<String>('communicated_to');
  set communicatedTo(String? value) =>
      setField<String>('communicated_to', value);

  DateTime? get communicationTime => getField<DateTime>('communication_time');
  set communicationTime(DateTime? value) =>
      setField<DateTime>('communication_time', value);

  String? get pacsAccessionNumber => getField<String>('pacs_accession_number');
  set pacsAccessionNumber(String? value) =>
      setField<String>('pacs_accession_number', value);

  String? get pacsStudyInstanceUid =>
      getField<String>('pacs_study_instance_uid');
  set pacsStudyInstanceUid(String? value) =>
      setField<String>('pacs_study_instance_uid', value);

  List<String> get dicomSeriesUrls => getListField<String>('dicom_series_urls');
  set dicomSeriesUrls(List<String>? value) =>
      setListField<String>('dicom_series_urls', value);

  bool? get followUpRecommended => getField<bool>('follow_up_recommended');
  set followUpRecommended(bool? value) =>
      setField<bool>('follow_up_recommended', value);

  String? get followUpTimeframe => getField<String>('follow_up_timeframe');
  set followUpTimeframe(String? value) =>
      setField<String>('follow_up_timeframe', value);

  String? get reportStatus => getField<String>('report_status');
  set reportStatus(String? value) => setField<String>('report_status', value);

  DateTime? get reportFinalizedAt => getField<DateTime>('report_finalized_at');
  set reportFinalizedAt(DateTime? value) =>
      setField<DateTime>('report_finalized_at', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  bool? get ehrbaseSynced => getField<bool>('ehrbase_synced');
  set ehrbaseSynced(bool? value) => setField<bool>('ehrbase_synced', value);

  DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
  set ehrbaseSyncedAt(DateTime? value) =>
      setField<DateTime>('ehrbase_synced_at', value);

  String? get ehrbaseSyncError => getField<String>('ehrbase_sync_error');
  set ehrbaseSyncError(String? value) =>
      setField<String>('ehrbase_sync_error', value);

  int? get ehrbaseRetryCount => getField<int>('ehrbase_retry_count');
  set ehrbaseRetryCount(int? value) =>
      setField<int>('ehrbase_retry_count', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
