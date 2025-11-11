import '../database.dart';

class AllergiesTable extends SupabaseTable<AllergiesRow> {
  @override
  String get tableName => 'allergies';

  @override
  AllergiesRow createRow(Map<String, dynamic> data) => AllergiesRow(data);
}

class AllergiesRow extends SupabaseDataRow {
  AllergiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AllergiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get allergyName => getField<String>('allergy_name')!;
  set allergyName(String value) => setField<String>('allergy_name', value);

  String? get allergyType => getField<String>('allergy_type');
  set allergyType(String? value) => setField<String>('allergy_type', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  List<String> get commonSymptoms => getListField<String>('common_symptoms');
  set commonSymptoms(List<String>? value) =>
      setListField<String>('common_symptoms', value);

  List<String> get severityLevels => getListField<String>('severity_levels');
  set severityLevels(List<String>? value) =>
      setListField<String>('severity_levels', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
