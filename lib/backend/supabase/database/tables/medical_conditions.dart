import '../database.dart';

class MedicalConditionsTable extends SupabaseTable<MedicalConditionsRow> {
  @override
  String get tableName => 'medical_conditions';

  @override
  MedicalConditionsRow createRow(Map<String, dynamic> data) =>
      MedicalConditionsRow(data);
}

class MedicalConditionsRow extends SupabaseDataRow {
  MedicalConditionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalConditionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get conditionName => getField<String>('condition_name')!;
  set conditionName(String value) => setField<String>('condition_name', value);

  String? get icd10Code => getField<String>('icd10_code');
  set icd10Code(String? value) => setField<String>('icd10_code', value);

  String? get icd11Code => getField<String>('icd11_code');
  set icd11Code(String? value) => setField<String>('icd11_code', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get commonSymptoms => getListField<String>('common_symptoms');
  set commonSymptoms(List<String>? value) =>
      setListField<String>('common_symptoms', value);

  List<String> get riskFactors => getListField<String>('risk_factors');
  set riskFactors(List<String>? value) =>
      setListField<String>('risk_factors', value);

  List<String> get treatmentOptions =>
      getListField<String>('treatment_options');
  set treatmentOptions(List<String>? value) =>
      setListField<String>('treatment_options', value);

  bool? get isChronic => getField<bool>('is_chronic');
  set isChronic(bool? value) => setField<bool>('is_chronic', value);

  String? get severityLevel => getField<String>('severity_level');
  set severityLevel(String? value) => setField<String>('severity_level', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
