import '../database.dart';

class MedicalRecordConditionsTable
    extends SupabaseTable<MedicalRecordConditionsRow> {
  @override
  String get tableName => 'medical_record_conditions';

  @override
  MedicalRecordConditionsRow createRow(Map<String, dynamic> data) =>
      MedicalRecordConditionsRow(data);
}

class MedicalRecordConditionsRow extends SupabaseDataRow {
  MedicalRecordConditionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalRecordConditionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get medicalRecordId => getField<String>('medical_record_id');
  set medicalRecordId(String? value) =>
      setField<String>('medical_record_id', value);

  String? get conditionId => getField<String>('condition_id');
  set conditionId(String? value) => setField<String>('condition_id', value);

  DateTime? get diagnosisDate => getField<DateTime>('diagnosis_date');
  set diagnosisDate(DateTime? value) =>
      setField<DateTime>('diagnosis_date', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
