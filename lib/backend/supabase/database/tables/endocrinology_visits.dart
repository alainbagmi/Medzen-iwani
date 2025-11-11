import '../database.dart';

class EndocrinologyVisitsTable extends SupabaseTable<EndocrinologyVisitsRow> {
  @override
  String get tableName => 'endocrinology_visits';

  @override
  EndocrinologyVisitsRow createRow(Map<String, dynamic> data) =>
      EndocrinologyVisitsRow(data);
}

class EndocrinologyVisitsRow extends SupabaseDataRow {
  EndocrinologyVisitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EndocrinologyVisitsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get endocrinologistId => getField<String>('endocrinologist_id');
  set endocrinologistId(String? value) =>
      setField<String>('endocrinologist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime get visitDate => getField<DateTime>('visit_date')!;
  set visitDate(DateTime value) => setField<DateTime>('visit_date', value);

  String get primaryEndocrineCondition =>
      getField<String>('primary_endocrine_condition')!;
  set primaryEndocrineCondition(String value) =>
      setField<String>('primary_endocrine_condition', value);

  String? get diabetesType => getField<String>('diabetes_type');
  set diabetesType(String? value) => setField<String>('diabetes_type', value);

  double? get hba1cPercent => getField<double>('hba1c_percent');
  set hba1cPercent(double? value) => setField<double>('hba1c_percent', value);

  double? get fastingGlucoseMgDl => getField<double>('fasting_glucose_mg_dl');
  set fastingGlucoseMgDl(double? value) =>
      setField<double>('fasting_glucose_mg_dl', value);

  String? get insulinRegimen => getField<String>('insulin_regimen');
  set insulinRegimen(String? value) =>
      setField<String>('insulin_regimen', value);

  List<String> get oralMedications => getListField<String>('oral_medications');
  set oralMedications(List<String>? value) =>
      setListField<String>('oral_medications', value);

  bool? get cgmInUse => getField<bool>('cgm_in_use');
  set cgmInUse(bool? value) => setField<bool>('cgm_in_use', value);

  int? get hypoglycemiaEpisodes => getField<int>('hypoglycemia_episodes');
  set hypoglycemiaEpisodes(int? value) =>
      setField<int>('hypoglycemia_episodes', value);

  String? get thyroidCondition => getField<String>('thyroid_condition');
  set thyroidCondition(String? value) =>
      setField<String>('thyroid_condition', value);

  double? get tshMiuL => getField<double>('tsh_miu_l');
  set tshMiuL(double? value) => setField<double>('tsh_miu_l', value);

  double? get t3NgDl => getField<double>('t3_ng_dl');
  set t3NgDl(double? value) => setField<double>('t3_ng_dl', value);

  double? get t4NgDl => getField<double>('t4_ng_dl');
  set t4NgDl(double? value) => setField<double>('t4_ng_dl', value);

  List<String> get thyroidMedications =>
      getListField<String>('thyroid_medications');
  set thyroidMedications(List<String>? value) =>
      setListField<String>('thyroid_medications', value);

  List<String> get hormonalImbalances =>
      getListField<String>('hormonal_imbalances');
  set hormonalImbalances(List<String>? value) =>
      setListField<String>('hormonal_imbalances', value);

  dynamic? get hormoneLevels => getField<dynamic>('hormone_levels');
  set hormoneLevels(dynamic? value) =>
      setField<dynamic>('hormone_levels', value);

  double? get weightKg => getField<double>('weight_kg');
  set weightKg(double? value) => setField<double>('weight_kg', value);

  double? get bmi => getField<double>('bmi');
  set bmi(double? value) => setField<double>('bmi', value);

  int? get bloodPressureSystolic => getField<int>('blood_pressure_systolic');
  set bloodPressureSystolic(int? value) =>
      setField<int>('blood_pressure_systolic', value);

  int? get bloodPressureDiastolic => getField<int>('blood_pressure_diastolic');
  set bloodPressureDiastolic(int? value) =>
      setField<int>('blood_pressure_diastolic', value);

  String? get treatmentPlan => getField<String>('treatment_plan');
  set treatmentPlan(String? value) => setField<String>('treatment_plan', value);

  String? get lifestyleRecommendations =>
      getField<String>('lifestyle_recommendations');
  set lifestyleRecommendations(String? value) =>
      setField<String>('lifestyle_recommendations', value);

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
