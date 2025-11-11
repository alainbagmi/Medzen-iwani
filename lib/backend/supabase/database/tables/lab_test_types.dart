import '../database.dart';

class LabTestTypesTable extends SupabaseTable<LabTestTypesRow> {
  @override
  String get tableName => 'lab_test_types';

  @override
  LabTestTypesRow createRow(Map<String, dynamic> data) => LabTestTypesRow(data);
}

class LabTestTypesRow extends SupabaseDataRow {
  LabTestTypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LabTestTypesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get testCode => getField<String>('test_code')!;
  set testCode(String value) => setField<String>('test_code', value);

  String get testName => getField<String>('test_name')!;
  set testName(String value) => setField<String>('test_name', value);

  String? get categoryId => getField<String>('category_id');
  set categoryId(String? value) => setField<String>('category_id', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get specimenType => getListField<String>('specimen_type');
  set specimenType(List<String>? value) =>
      setListField<String>('specimen_type', value);

  String? get specimenVolume => getField<String>('specimen_volume');
  set specimenVolume(String? value) =>
      setField<String>('specimen_volume', value);

  String? get collectionInstructions =>
      getField<String>('collection_instructions');
  set collectionInstructions(String? value) =>
      setField<String>('collection_instructions', value);

  bool? get fastingRequired => getField<bool>('fasting_required');
  set fastingRequired(bool? value) => setField<bool>('fasting_required', value);

  int? get typicalTurnaroundHours => getField<int>('typical_turnaround_hours');
  set typicalTurnaroundHours(int? value) =>
      setField<int>('typical_turnaround_hours', value);

  String? get normalRangeMale => getField<String>('normal_range_male');
  set normalRangeMale(String? value) =>
      setField<String>('normal_range_male', value);

  String? get normalRangeFemale => getField<String>('normal_range_female');
  set normalRangeFemale(String? value) =>
      setField<String>('normal_range_female', value);

  String? get normalRangePediatric =>
      getField<String>('normal_range_pediatric');
  set normalRangePediatric(String? value) =>
      setField<String>('normal_range_pediatric', value);

  String? get units => getField<String>('units');
  set units(String? value) => setField<String>('units', value);

  String? get cptCode => getField<String>('cpt_code');
  set cptCode(String? value) => setField<String>('cpt_code', value);

  String? get loincCode => getField<String>('loinc_code');
  set loincCode(String? value) => setField<String>('loinc_code', value);

  double? get price => getField<double>('price');
  set price(double? value) => setField<double>('price', value);

  bool? get requiresSpecialHandling =>
      getField<bool>('requires_special_handling');
  set requiresSpecialHandling(bool? value) =>
      setField<bool>('requires_special_handling', value);

  String? get specialInstructions => getField<String>('special_instructions');
  set specialInstructions(String? value) =>
      setField<String>('special_instructions', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
