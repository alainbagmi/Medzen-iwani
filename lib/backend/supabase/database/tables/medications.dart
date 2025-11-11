import '../database.dart';

class MedicationsTable extends SupabaseTable<MedicationsRow> {
  @override
  String get tableName => 'medications';

  @override
  MedicationsRow createRow(Map<String, dynamic> data) => MedicationsRow(data);
}

class MedicationsRow extends SupabaseDataRow {
  MedicationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get medicationName => getField<String>('medication_name')!;
  set medicationName(String value) =>
      setField<String>('medication_name', value);

  String? get genericName => getField<String>('generic_name');
  set genericName(String? value) => setField<String>('generic_name', value);

  List<String> get brandNames => getListField<String>('brand_names');
  set brandNames(List<String>? value) =>
      setListField<String>('brand_names', value);

  String? get drugClass => getField<String>('drug_class');
  set drugClass(String? value) => setField<String>('drug_class', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get commonDosages => getListField<String>('common_dosages');
  set commonDosages(List<String>? value) =>
      setListField<String>('common_dosages', value);

  List<String> get routeOfAdministration =>
      getListField<String>('route_of_administration');
  set routeOfAdministration(List<String>? value) =>
      setListField<String>('route_of_administration', value);

  List<String> get sideEffects => getListField<String>('side_effects');
  set sideEffects(List<String>? value) =>
      setListField<String>('side_effects', value);

  List<String> get contraindications =>
      getListField<String>('contraindications');
  set contraindications(List<String>? value) =>
      setListField<String>('contraindications', value);

  List<String> get interactions => getListField<String>('interactions');
  set interactions(List<String>? value) =>
      setListField<String>('interactions', value);

  String? get pregnancyCategory => getField<String>('pregnancy_category');
  set pregnancyCategory(String? value) =>
      setField<String>('pregnancy_category', value);

  bool? get controlledSubstance => getField<bool>('controlled_substance');
  set controlledSubstance(bool? value) =>
      setField<bool>('controlled_substance', value);

  bool? get requiresPrescription => getField<bool>('requires_prescription');
  set requiresPrescription(bool? value) =>
      setField<bool>('requires_prescription', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
