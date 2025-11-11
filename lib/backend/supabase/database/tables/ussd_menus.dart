import '../database.dart';

class UssdMenusTable extends SupabaseTable<UssdMenusRow> {
  @override
  String get tableName => 'ussd_menus';

  @override
  UssdMenusRow createRow(Map<String, dynamic> data) => UssdMenusRow(data);
}

class UssdMenusRow extends SupabaseDataRow {
  UssdMenusRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UssdMenusTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get menuCode => getField<String>('menu_code')!;
  set menuCode(String value) => setField<String>('menu_code', value);

  String? get parentMenuCode => getField<String>('parent_menu_code');
  set parentMenuCode(String? value) =>
      setField<String>('parent_menu_code', value);

  String get titleEn => getField<String>('title_en')!;
  set titleEn(String value) => setField<String>('title_en', value);

  String? get titleFr => getField<String>('title_fr');
  set titleFr(String? value) => setField<String>('title_fr', value);

  dynamic get options => getField<dynamic>('options')!;
  set options(dynamic value) => setField<dynamic>('options', value);

  bool? get requiresAuth => getField<bool>('requires_auth');
  set requiresAuth(bool? value) => setField<bool>('requires_auth', value);

  List<String> get accessibleTo => getListField<String>('accessible_to');
  set accessibleTo(List<String>? value) =>
      setListField<String>('accessible_to', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
