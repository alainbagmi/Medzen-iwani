import '../database.dart';

class EhrCompositionsTable extends SupabaseTable<EhrCompositionsRow> {
  @override
  String get tableName => 'ehr_compositions';

  @override
  EhrCompositionsRow createRow(Map<String, dynamic> data) =>
      EhrCompositionsRow(data);
}

class EhrCompositionsRow extends SupabaseDataRow {
  EhrCompositionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EhrCompositionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get ehrId => getField<String>('ehr_id');
  set ehrId(String? value) => setField<String>('ehr_id', value);

  String get compositionId => getField<String>('composition_id')!;
  set compositionId(String value) => setField<String>('composition_id', value);

  String get compositionType => getField<String>('composition_type')!;
  set compositionType(String value) =>
      setField<String>('composition_type', value);

  String get templateId => getField<String>('template_id')!;
  set templateId(String value) => setField<String>('template_id', value);

  dynamic? get archetypeDetails => getField<dynamic>('archetype_details');
  set archetypeDetails(dynamic? value) =>
      setField<dynamic>('archetype_details', value);

  dynamic get content => getField<dynamic>('content')!;
  set content(dynamic value) => setField<dynamic>('content', value);

  String? get composerId => getField<String>('composer_id');
  set composerId(String? value) => setField<String>('composer_id', value);

  dynamic? get context => getField<dynamic>('context');
  set context(dynamic? value) => setField<dynamic>('context', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  String? get territory => getField<String>('territory');
  set territory(String? value) => setField<String>('territory', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
