import '../database.dart';

class NearbySearchOptionsTable extends SupabaseTable<NearbySearchOptionsRow> {
  @override
  String get tableName => 'nearby_search_options';

  @override
  NearbySearchOptionsRow createRow(Map<String, dynamic> data) =>
      NearbySearchOptionsRow(data);
}

class NearbySearchOptionsRow extends SupabaseDataRow {
  NearbySearchOptionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NearbySearchOptionsTable();

  String? get optionType => getField<String>('option_type');
  set optionType(String? value) => setField<String>('option_type', value);

  String? get optionValue => getField<String>('option_value');
  set optionValue(String? value) => setField<String>('option_value', value);

  int? get count => getField<int>('count');
  set count(int? value) => setField<int>('count', value);
}
