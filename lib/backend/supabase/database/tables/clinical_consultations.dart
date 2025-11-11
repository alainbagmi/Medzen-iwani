import '../database.dart';

class ClinicalConsultationsTable
    extends SupabaseTable<ClinicalConsultationsRow> {
  @override
  String get tableName => 'clinical_consultations';

  @override
  ClinicalConsultationsRow createRow(Map<String, dynamic> data) =>
      ClinicalConsultationsRow(data);
}

class ClinicalConsultationsRow extends SupabaseDataRow {
  ClinicalConsultationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ClinicalConsultationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  DateTime get consultationDate => getField<DateTime>('consultation_date')!;
  set consultationDate(DateTime value) =>
      setField<DateTime>('consultation_date', value);

  String? get consultationType => getField<String>('consultation_type');
  set consultationType(String? value) =>
      setField<String>('consultation_type', value);

  String get chiefComplaint => getField<String>('chief_complaint')!;
  set chiefComplaint(String value) =>
      setField<String>('chief_complaint', value);

  String? get historyOfPresentIllness =>
      getField<String>('history_of_present_illness');
  set historyOfPresentIllness(String? value) =>
      setField<String>('history_of_present_illness', value);

  dynamic? get reviewOfSystems => getField<dynamic>('review_of_systems');
  set reviewOfSystems(dynamic? value) =>
      setField<dynamic>('review_of_systems', value);

  String? get generalAppearance => getField<String>('general_appearance');
  set generalAppearance(String? value) =>
      setField<String>('general_appearance', value);

  String? get vitalSignsId => getField<String>('vital_signs_id');
  set vitalSignsId(String? value) => setField<String>('vital_signs_id', value);

  String? get physicalExaminationFindings =>
      getField<String>('physical_examination_findings');
  set physicalExaminationFindings(String? value) =>
      setField<String>('physical_examination_findings', value);

  String? get assessment => getField<String>('assessment');
  set assessment(String? value) => setField<String>('assessment', value);

  List<String> get diagnoses => getListField<String>('diagnoses');
  set diagnoses(List<String>? value) =>
      setListField<String>('diagnoses', value);

  List<String> get differentialDiagnoses =>
      getListField<String>('differential_diagnoses');
  set differentialDiagnoses(List<String>? value) =>
      setListField<String>('differential_diagnoses', value);

  String? get treatmentPlan => getField<String>('treatment_plan');
  set treatmentPlan(String? value) => setField<String>('treatment_plan', value);

  List<String> get medicationsPrescribedIds =>
      getListField<String>('medications_prescribed_ids');
  set medicationsPrescribedIds(List<String>? value) =>
      setListField<String>('medications_prescribed_ids', value);

  List<String> get investigationsOrdered =>
      getListField<String>('investigations_ordered');
  set investigationsOrdered(List<String>? value) =>
      setListField<String>('investigations_ordered', value);

  List<String> get referrals => getListField<String>('referrals');
  set referrals(List<String>? value) =>
      setListField<String>('referrals', value);

  DateTime? get followUpDate => getField<DateTime>('follow_up_date');
  set followUpDate(DateTime? value) =>
      setField<DateTime>('follow_up_date', value);

  String? get followUpInstructions =>
      getField<String>('follow_up_instructions');
  set followUpInstructions(String? value) =>
      setField<String>('follow_up_instructions', value);

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
