import '../database.dart';

class PathologyReportsTable extends SupabaseTable<PathologyReportsRow> {
  @override
  String get tableName => 'pathology_reports';

  @override
  PathologyReportsRow createRow(Map<String, dynamic> data) =>
      PathologyReportsRow(data);
}

class PathologyReportsRow extends SupabaseDataRow {
  PathologyReportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PathologyReportsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get pathologistId => getField<String>('pathologist_id');
  set pathologistId(String? value) => setField<String>('pathologist_id', value);

  String? get orderingProviderId => getField<String>('ordering_provider_id');
  set orderingProviderId(String? value) =>
      setField<String>('ordering_provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get collectionDate => getField<DateTime>('collection_date')!;
  set collectionDate(DateTime value) =>
      setField<DateTime>('collection_date', value);

  DateTime? get receivedDate => getField<DateTime>('received_date');
  set receivedDate(DateTime? value) =>
      setField<DateTime>('received_date', value);

  DateTime? get reportDate => getField<DateTime>('report_date');
  set reportDate(DateTime? value) => setField<DateTime>('report_date', value);

  String get specimenType => getField<String>('specimen_type')!;
  set specimenType(String value) => setField<String>('specimen_type', value);

  String get specimenSite => getField<String>('specimen_site')!;
  set specimenSite(String value) => setField<String>('specimen_site', value);

  String? get specimenId => getField<String>('specimen_id');
  set specimenId(String? value) => setField<String>('specimen_id', value);

  int? get numberOfSpecimens => getField<int>('number_of_specimens');
  set numberOfSpecimens(int? value) =>
      setField<int>('number_of_specimens', value);

  String? get clinicalHistory => getField<String>('clinical_history');
  set clinicalHistory(String? value) =>
      setField<String>('clinical_history', value);

  String get indication => getField<String>('indication')!;
  set indication(String value) => setField<String>('indication', value);

  String? get procedureType => getField<String>('procedure_type');
  set procedureType(String? value) => setField<String>('procedure_type', value);

  String? get grossDescription => getField<String>('gross_description');
  set grossDescription(String? value) =>
      setField<String>('gross_description', value);

  String get microscopicDescription =>
      getField<String>('microscopic_description')!;
  set microscopicDescription(String value) =>
      setField<String>('microscopic_description', value);

  String get diagnosis => getField<String>('diagnosis')!;
  set diagnosis(String value) => setField<String>('diagnosis', value);

  List<String> get diagnosisCodes => getListField<String>('diagnosis_codes');
  set diagnosisCodes(List<String>? value) =>
      setListField<String>('diagnosis_codes', value);

  String? get histologicalType => getField<String>('histological_type');
  set histologicalType(String? value) =>
      setField<String>('histological_type', value);

  String? get grade => getField<String>('grade');
  set grade(String? value) => setField<String>('grade', value);

  String? get stage => getField<String>('stage');
  set stage(String? value) => setField<String>('stage', value);

  double? get tumorSizeCm => getField<double>('tumor_size_cm');
  set tumorSizeCm(double? value) => setField<double>('tumor_size_cm', value);

  String? get marginsStatus => getField<String>('margins_status');
  set marginsStatus(String? value) => setField<String>('margins_status', value);

  int? get lymphNodesExamined => getField<int>('lymph_nodes_examined');
  set lymphNodesExamined(int? value) =>
      setField<int>('lymph_nodes_examined', value);

  int? get lymphNodesPositive => getField<int>('lymph_nodes_positive');
  set lymphNodesPositive(int? value) =>
      setField<int>('lymph_nodes_positive', value);

  dynamic? get immunohistochemistryResults =>
      getField<dynamic>('immunohistochemistry_results');
  set immunohistochemistryResults(dynamic? value) =>
      setField<dynamic>('immunohistochemistry_results', value);

  dynamic? get molecularMarkers => getField<dynamic>('molecular_markers');
  set molecularMarkers(dynamic? value) =>
      setField<dynamic>('molecular_markers', value);

  List<String> get specialStainsPerformed =>
      getListField<String>('special_stains_performed');
  set specialStainsPerformed(List<String>? value) =>
      setListField<String>('special_stains_performed', value);

  String? get specialStainsResults =>
      getField<String>('special_stains_results');
  set specialStainsResults(String? value) =>
      setField<String>('special_stains_results', value);

  String? get finalDiagnosis => getField<String>('final_diagnosis');
  set finalDiagnosis(String? value) =>
      setField<String>('final_diagnosis', value);

  String? get recommendations => getField<String>('recommendations');
  set recommendations(String? value) =>
      setField<String>('recommendations', value);

  String? get additionalComments => getField<String>('additional_comments');
  set additionalComments(String? value) =>
      setField<String>('additional_comments', value);

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
