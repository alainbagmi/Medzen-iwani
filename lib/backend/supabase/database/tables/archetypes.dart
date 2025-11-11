import '../database.dart';

class ArchetypesTable extends SupabaseTable<ArchetypesRow> {
  @override
  String get tableName => 'archetypes';

  @override
  ArchetypesRow createRow(Map<String, dynamic> data) => ArchetypesRow(data);
}

class ArchetypesRow extends SupabaseDataRow {
  ArchetypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ArchetypesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get archetypeId => getField<String>('archetype_id')!;
  set archetypeId(String value) => setField<String>('archetype_id', value);

  String get archetypeName => getField<String>('archetype_name')!;
  set archetypeName(String value) => setField<String>('archetype_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  dynamic get definition => getField<dynamic>('definition')!;
  set definition(dynamic value) => setField<dynamic>('definition', value);

  String? get version => getField<String>('version');
  set version(String? value) => setField<String>('version', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
