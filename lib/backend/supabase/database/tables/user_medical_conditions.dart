import '../database.dart';

class UserMedicalConditionsTable
    extends SupabaseTable<UserMedicalConditionsRow> {
  @override
  String get tableName => 'user_medical_conditions';

  @override
  UserMedicalConditionsRow createRow(Map<String, dynamic> data) =>
      UserMedicalConditionsRow(data);
}

class UserMedicalConditionsRow extends SupabaseDataRow {
  UserMedicalConditionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserMedicalConditionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get conditionId => getField<String>('condition_id');
  set conditionId(String? value) => setField<String>('condition_id', value);

  DateTime? get diagnosisDate => getField<DateTime>('diagnosis_date');
  set diagnosisDate(DateTime? value) =>
      setField<DateTime>('diagnosis_date', value);

  String? get diagnosedById => getField<String>('diagnosed_by_id');
  set diagnosedById(String? value) =>
      setField<String>('diagnosed_by_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get severity => getField<String>('severity');
  set severity(String? value) => setField<String>('severity', value);

  String? get treatmentPlan => getField<String>('treatment_plan');
  set treatmentPlan(String? value) => setField<String>('treatment_plan', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  String? get medicalRecordId => getField<String>('medical_record_id');
  set medicalRecordId(String? value) =>
      setField<String>('medical_record_id', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
