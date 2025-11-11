import '../database.dart';

class TemplatesTable extends SupabaseTable<TemplatesRow> {
  @override
  String get tableName => 'templates';

  @override
  TemplatesRow createRow(Map<String, dynamic> data) => TemplatesRow(data);
}

class TemplatesRow extends SupabaseDataRow {
  TemplatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TemplatesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get templateId => getField<String>('template_id')!;
  set templateId(String value) => setField<String>('template_id', value);

  String get templateName => getField<String>('template_name')!;
  set templateName(String value) => setField<String>('template_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  List<String> get archetypeIds => getListField<String>('archetype_ids');
  set archetypeIds(List<String>? value) =>
      setListField<String>('archetype_ids', value);

  dynamic get definition => getField<dynamic>('definition')!;
  set definition(dynamic value) => setField<dynamic>('definition', value);

  String? get version => getField<String>('version');
  set version(String? value) => setField<String>('version', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
