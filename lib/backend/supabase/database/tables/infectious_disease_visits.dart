import '../database.dart';

class InfectiousDiseaseVisitsTable
    extends SupabaseTable<InfectiousDiseaseVisitsRow> {
  @override
  String get tableName => 'infectious_disease_visits';

  @override
  InfectiousDiseaseVisitsRow createRow(Map<String, dynamic> data) =>
      InfectiousDiseaseVisitsRow(data);
}

class InfectiousDiseaseVisitsRow extends SupabaseDataRow {
  InfectiousDiseaseVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InfectiousDiseaseVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get visitDate => getField<DateTime>('visit_date')!;
  set visitDate(DateTime value) => setField<DateTime>('visit_date', value);

  String get diseaseName => getField<String>('disease_name')!;
  set diseaseName(String value) => setField<String>('disease_name', value);

  String? get diseaseIcdCode => getField<String>('disease_icd_code');
  set diseaseIcdCode(String? value) =>
      setField<String>('disease_icd_code', value);

  String? get diseaseCategory => getField<String>('disease_category');
  set diseaseCategory(String? value) =>
      setField<String>('disease_category', value);

  DateTime? get symptomOnsetDate => getField<DateTime>('symptom_onset_date');
  set symptomOnsetDate(DateTime? value) =>
      setField<DateTime>('symptom_onset_date', value);

  List<String> get symptoms => getListField<String>('symptoms');
  set symptoms(List<String>? value) => setListField<String>('symptoms', value);

  bool? get feverPresent => getField<bool>('fever_present');
  set feverPresent(bool? value) => setField<bool>('fever_present', value);

  double? get highestTemperatureCelsius =>
      getField<double>('highest_temperature_celsius');
  set highestTemperatureCelsius(double? value) =>
      setField<double>('highest_temperature_celsius', value);

  dynamic? get rapidTestResults => getField<dynamic>('rapid_test_results');
  set rapidTestResults(dynamic? value) =>
      setField<dynamic>('rapid_test_results', value);

  List<String> get labTestsPerformed =>
      getListField<String>('lab_tests_performed');
  set labTestsPerformed(List<String>? value) =>
      setListField<String>('lab_tests_performed', value);

  String? get cultureResults => getField<String>('culture_results');
  set cultureResults(String? value) =>
      setField<String>('culture_results', value);

  String? get serologyResults => getField<String>('serology_results');
  set serologyResults(String? value) =>
      setField<String>('serology_results', value);

  String? get pcrResults => getField<String>('pcr_results');
  set pcrResults(String? value) => setField<String>('pcr_results', value);

  String? get imagingFindings => getField<String>('imaging_findings');
  set imagingFindings(String? value) =>
      setField<String>('imaging_findings', value);

  List<String> get antimicrobialsPrescribed =>
      getListField<String>('antimicrobials_prescribed');
  set antimicrobialsPrescribed(List<String>? value) =>
      setListField<String>('antimicrobials_prescribed', value);

  List<String> get antiviralsPrescribed =>
      getListField<String>('antivirals_prescribed');
  set antiviralsPrescribed(List<String>? value) =>
      setListField<String>('antivirals_prescribed', value);

  List<String> get antifungalsPrescribed =>
      getListField<String>('antifungals_prescribed');
  set antifungalsPrescribed(List<String>? value) =>
      setListField<String>('antifungals_prescribed', value);

  List<String> get antiparasiticsPrescribed =>
      getListField<String>('antiparasitics_prescribed');
  set antiparasiticsPrescribed(List<String>? value) =>
      setListField<String>('antiparasitics_prescribed', value);

  List<String> get supportiveCare => getListField<String>('supportive_care');
  set supportiveCare(List<String>? value) =>
      setListField<String>('supportive_care', value);

  int? get cd4Count => getField<int>('cd4_count');
  set cd4Count(int? value) => setField<int>('cd4_count', value);

  int? get viralLoad => getField<int>('viral_load');
  set viralLoad(int? value) => setField<int>('viral_load', value);

  String? get artRegimen => getField<String>('art_regimen');
  set artRegimen(String? value) => setField<String>('art_regimen', value);

  bool? get onProphylaxis => getField<bool>('on_prophylaxis');
  set onProphylaxis(bool? value) => setField<bool>('on_prophylaxis', value);

  List<String> get prophylaxisMedications =>
      getListField<String>('prophylaxis_medications');
  set prophylaxisMedications(List<String>? value) =>
      setListField<String>('prophylaxis_medications', value);

  String? get tbType => getField<String>('tb_type');
  set tbType(String? value) => setField<String>('tb_type', value);

  bool? get dotsTreatment => getField<bool>('dots_treatment');
  set dotsTreatment(bool? value) => setField<bool>('dots_treatment', value);

  String? get treatmentPhase => getField<String>('treatment_phase');
  set treatmentPhase(String? value) =>
      setField<String>('treatment_phase', value);

  String? get parasiteSpecies => getField<String>('parasite_species');
  set parasiteSpecies(String? value) =>
      setField<String>('parasite_species', value);

  double? get parasitemiaLevel => getField<double>('parasitemia_level');
  set parasitemiaLevel(double? value) =>
      setField<double>('parasitemia_level', value);

  bool? get isolationRequired => getField<bool>('isolation_required');
  set isolationRequired(bool? value) =>
      setField<bool>('isolation_required', value);

  String? get isolationType => getField<String>('isolation_type');
  set isolationType(String? value) => setField<String>('isolation_type', value);

  bool? get contactTracingDone => getField<bool>('contact_tracing_done');
  set contactTracingDone(bool? value) =>
      setField<bool>('contact_tracing_done', value);

  int? get contactsIdentified => getField<int>('contacts_identified');
  set contactsIdentified(int? value) =>
      setField<int>('contacts_identified', value);

  String? get treatmentResponse => getField<String>('treatment_response');
  set treatmentResponse(String? value) =>
      setField<String>('treatment_response', value);

  List<String> get complications => getListField<String>('complications');
  set complications(List<String>? value) =>
      setListField<String>('complications', value);

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
