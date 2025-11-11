import '../database.dart';

class SurgicalProceduresTable extends SupabaseTable<SurgicalProceduresRow> {
  @override
  String get tableName => 'surgical_procedures';

  @override
  SurgicalProceduresRow createRow(Map<String, dynamic> data) =>
      SurgicalProceduresRow(data);
}

class SurgicalProceduresRow extends SupabaseDataRow {
  SurgicalProceduresRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SurgicalProceduresTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get surgeonId => getField<String>('surgeon_id');
  set surgeonId(String? value) => setField<String>('surgeon_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get admissionId => getField<String>('admission_id');
  set admissionId(String? value) => setField<String>('admission_id', value);

  String get procedureName => getField<String>('procedure_name')!;
  set procedureName(String value) => setField<String>('procedure_name', value);

  String? get procedureCode => getField<String>('procedure_code');
  set procedureCode(String? value) => setField<String>('procedure_code', value);

  String? get procedureType => getField<String>('procedure_type');
  set procedureType(String? value) => setField<String>('procedure_type', value);

  DateTime get procedureDate => getField<DateTime>('procedure_date')!;
  set procedureDate(DateTime value) =>
      setField<DateTime>('procedure_date', value);

  int? get procedureDurationMinutes =>
      getField<int>('procedure_duration_minutes');
  set procedureDurationMinutes(int? value) =>
      setField<int>('procedure_duration_minutes', value);

  String get indication => getField<String>('indication')!;
  set indication(String value) => setField<String>('indication', value);

  String? get diagnosis => getField<String>('diagnosis');
  set diagnosis(String? value) => setField<String>('diagnosis', value);

  String? get preOpAssessment => getField<String>('pre_op_assessment');
  set preOpAssessment(String? value) =>
      setField<String>('pre_op_assessment', value);

  String? get asaClassification => getField<String>('asa_classification');
  set asaClassification(String? value) =>
      setField<String>('asa_classification', value);

  String? get riskLevel => getField<String>('risk_level');
  set riskLevel(String? value) => setField<String>('risk_level', value);

  List<String> get assistantSurgeons =>
      getListField<String>('assistant_surgeons');
  set assistantSurgeons(List<String>? value) =>
      setListField<String>('assistant_surgeons', value);

  String? get anesthetistId => getField<String>('anesthetist_id');
  set anesthetistId(String? value) => setField<String>('anesthetist_id', value);

  String? get anesthesiaType => getField<String>('anesthesia_type');
  set anesthesiaType(String? value) =>
      setField<String>('anesthesia_type', value);

  String? get scrubNurse => getField<String>('scrub_nurse');
  set scrubNurse(String? value) => setField<String>('scrub_nurse', value);

  String? get circulatingNurse => getField<String>('circulating_nurse');
  set circulatingNurse(String? value) =>
      setField<String>('circulating_nurse', value);

  String? get approach => getField<String>('approach');
  set approach(String? value) => setField<String>('approach', value);

  String? get siteOfSurgery => getField<String>('site_of_surgery');
  set siteOfSurgery(String? value) =>
      setField<String>('site_of_surgery', value);

  String? get laterality => getField<String>('laterality');
  set laterality(String? value) => setField<String>('laterality', value);

  String? get incisionType => getField<String>('incision_type');
  set incisionType(String? value) => setField<String>('incision_type', value);

  List<String> get implantsUsed => getListField<String>('implants_used');
  set implantsUsed(List<String>? value) =>
      setListField<String>('implants_used', value);

  List<String> get specimensTaken => getListField<String>('specimens_taken');
  set specimensTaken(List<String>? value) =>
      setListField<String>('specimens_taken', value);

  String? get findings => getField<String>('findings');
  set findings(String? value) => setField<String>('findings', value);

  List<String> get complicationsIntraop =>
      getListField<String>('complications_intraop');
  set complicationsIntraop(List<String>? value) =>
      setListField<String>('complications_intraop', value);

  int? get bloodLossMl => getField<int>('blood_loss_ml');
  set bloodLossMl(int? value) => setField<int>('blood_loss_ml', value);

  bool? get transfusionsGiven => getField<bool>('transfusions_given');
  set transfusionsGiven(bool? value) =>
      setField<bool>('transfusions_given', value);

  String? get transfusionDetails => getField<String>('transfusion_details');
  set transfusionDetails(String? value) =>
      setField<String>('transfusion_details', value);

  String? get outcome => getField<String>('outcome');
  set outcome(String? value) => setField<String>('outcome', value);

  String? get postOpDiagnosis => getField<String>('post_op_diagnosis');
  set postOpDiagnosis(String? value) =>
      setField<String>('post_op_diagnosis', value);

  List<String> get complicationsPostop =>
      getListField<String>('complications_postop');
  set complicationsPostop(List<String>? value) =>
      setListField<String>('complications_postop', value);

  List<String> get drainsPlaced => getListField<String>('drains_placed');
  set drainsPlaced(List<String>? value) =>
      setListField<String>('drains_placed', value);

  String? get postOpInstructions => getField<String>('post_op_instructions');
  set postOpInstructions(String? value) =>
      setField<String>('post_op_instructions', value);

  DateTime? get followUpDate => getField<DateTime>('follow_up_date');
  set followUpDate(DateTime? value) =>
      setField<DateTime>('follow_up_date', value);

  int? get estimatedRecoveryDays => getField<int>('estimated_recovery_days');
  set estimatedRecoveryDays(int? value) =>
      setField<int>('estimated_recovery_days', value);

  List<String> get specialEquipmentUsed =>
      getListField<String>('special_equipment_used');
  set specialEquipmentUsed(List<String>? value) =>
      setListField<String>('special_equipment_used', value);

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
