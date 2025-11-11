import '../database.dart';

class ArchetypeFormFieldsTable extends SupabaseTable<ArchetypeFormFieldsRow> {
  @override
  String get tableName => 'archetype_form_fields';

  @override
  ArchetypeFormFieldsRow createRow(Map<String, dynamic> data) =>
      ArchetypeFormFieldsRow(data);
}

class ArchetypeFormFieldsRow extends SupabaseDataRow {
  ArchetypeFormFieldsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ArchetypeFormFieldsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get archetypeId => getField<String>('archetype_id')!;
  set archetypeId(String value) => setField<String>('archetype_id', value);

  String get fieldPath => getField<String>('field_path')!;
  set fieldPath(String value) => setField<String>('field_path', value);

  String get fieldName => getField<String>('field_name')!;
  set fieldName(String value) => setField<String>('field_name', value);

  String get fieldType => getField<String>('field_type')!;
  set fieldType(String value) => setField<String>('field_type', value);

  dynamic get fieldLabel => getField<dynamic>('field_label')!;
  set fieldLabel(dynamic value) => setField<dynamic>('field_label', value);

  dynamic? get fieldDescription => getField<dynamic>('field_description');
  set fieldDescription(dynamic? value) =>
      setField<dynamic>('field_description', value);

  String? get fieldUnit => getField<String>('field_unit');
  set fieldUnit(String? value) => setField<String>('field_unit', value);

  bool? get required => getField<bool>('required');
  set required(bool? value) => setField<bool>('required', value);

  dynamic? get constraints => getField<dynamic>('constraints');
  set constraints(dynamic? value) => setField<dynamic>('constraints', value);

  dynamic? get options => getField<dynamic>('options');
  set options(dynamic? value) => setField<dynamic>('options', value);

  int? get displayOrder => getField<int>('display_order');
  set displayOrder(int? value) => setField<int>('display_order', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
