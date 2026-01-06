import '../database.dart';

class ConsultationMedicalEntitiesTable
    extends SupabaseTable<ConsultationMedicalEntitiesRow> {
  @override
  String get tableName => 'consultation_medical_entities';

  @override
  ConsultationMedicalEntitiesRow createRow(Map<String, dynamic> data) =>
      ConsultationMedicalEntitiesRow(data);
}

class ConsultationMedicalEntitiesRow extends SupabaseDataRow {
  ConsultationMedicalEntitiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConsultationMedicalEntitiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String get entityType => getField<String>('entity_type')!;
  set entityType(String value) => setField<String>('entity_type', value);

  String get entityText => getField<String>('entity_text')!;
  set entityText(String value) => setField<String>('entity_text', value);

  String? get entityCategory => getField<String>('entity_category');
  set entityCategory(String? value) =>
      setField<String>('entity_category', value);

  double? get confidenceScore => getField<double>('confidence_score');
  set confidenceScore(double? value) =>
      setField<double>('confidence_score', value);

  String? get icd10Code => getField<String>('icd10_code');
  set icd10Code(String? value) => setField<String>('icd10_code', value);

  dynamic? get additionalData => getField<dynamic>('additional_data');
  set additionalData(dynamic? value) =>
      setField<dynamic>('additional_data', value);

  String get source => getField<String>('source')!;
  set source(String value) => setField<String>('source', value);

  bool? get verifiedByProvider => getField<bool>('verified_by_provider');
  set verifiedByProvider(bool? value) =>
      setField<bool>('verified_by_provider', value);

  DateTime? get verifiedAt => getField<DateTime>('verified_at');
  set verifiedAt(DateTime? value) => setField<DateTime>('verified_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
