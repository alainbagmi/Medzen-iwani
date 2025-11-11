import '../database.dart';

class GastroenterologyProceduresTable
    extends SupabaseTable<GastroenterologyProceduresRow> {
  @override
  String get tableName => 'gastroenterology_procedures';

  @override
  GastroenterologyProceduresRow createRow(Map<String, dynamic> data) =>
      GastroenterologyProceduresRow(data);
}

class GastroenterologyProceduresRow extends SupabaseDataRow {
  GastroenterologyProceduresRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GastroenterologyProceduresTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get gastroenterologistId => getField<String>('gastroenterologist_id');
  set gastroenterologistId(String? value) =>
      setField<String>('gastroenterologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get procedureDate => getField<DateTime>('procedure_date')!;
  set procedureDate(DateTime value) =>
      setField<DateTime>('procedure_date', value);

  String get procedureName => getField<String>('procedure_name')!;
  set procedureName(String value) => setField<String>('procedure_name', value);

  String get indication => getField<String>('indication')!;
  set indication(String value) => setField<String>('indication', value);

  String? get sedationType => getField<String>('sedation_type');
  set sedationType(String? value) => setField<String>('sedation_type', value);

  String? get esophagusFindings => getField<String>('esophagus_findings');
  set esophagusFindings(String? value) =>
      setField<String>('esophagus_findings', value);

  String? get stomachFindings => getField<String>('stomach_findings');
  set stomachFindings(String? value) =>
      setField<String>('stomach_findings', value);

  String? get duodenumFindings => getField<String>('duodenum_findings');
  set duodenumFindings(String? value) =>
      setField<String>('duodenum_findings', value);

  String? get colonFindings => getField<String>('colon_findings');
  set colonFindings(String? value) => setField<String>('colon_findings', value);

  bool? get cecumReached => getField<bool>('cecum_reached');
  set cecumReached(bool? value) => setField<bool>('cecum_reached', value);

  bool? get ileumIntubated => getField<bool>('ileum_intubated');
  set ileumIntubated(bool? value) => setField<bool>('ileum_intubated', value);

  bool? get biopsiesTaken => getField<bool>('biopsies_taken');
  set biopsiesTaken(bool? value) => setField<bool>('biopsies_taken', value);

  List<String> get biopsySites => getListField<String>('biopsy_sites');
  set biopsySites(List<String>? value) =>
      setListField<String>('biopsy_sites', value);

  bool? get polypsRemoved => getField<bool>('polyps_removed');
  set polypsRemoved(bool? value) => setField<bool>('polyps_removed', value);

  dynamic? get polypDetails => getField<dynamic>('polyp_details');
  set polypDetails(dynamic? value) => setField<dynamic>('polyp_details', value);

  bool? get hemostasisPerformed => getField<bool>('hemostasis_performed');
  set hemostasisPerformed(bool? value) =>
      setField<bool>('hemostasis_performed', value);

  bool? get dilationPerformed => getField<bool>('dilation_performed');
  set dilationPerformed(bool? value) =>
      setField<bool>('dilation_performed', value);

  String? get pathologyResults => getField<String>('pathology_results');
  set pathologyResults(String? value) =>
      setField<String>('pathology_results', value);

  String? get hPyloriStatus => getField<String>('h_pylori_status');
  set hPyloriStatus(String? value) =>
      setField<String>('h_pylori_status', value);

  List<String> get complications => getListField<String>('complications');
  set complications(List<String>? value) =>
      setListField<String>('complications', value);

  String? get postProcedureInstructions =>
      getField<String>('post_procedure_instructions');
  set postProcedureInstructions(String? value) =>
      setField<String>('post_procedure_instructions', value);

  DateTime? get nextFollowUpDate => getField<DateTime>('next_follow_up_date');
  set nextFollowUpDate(DateTime? value) =>
      setField<DateTime>('next_follow_up_date', value);

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
