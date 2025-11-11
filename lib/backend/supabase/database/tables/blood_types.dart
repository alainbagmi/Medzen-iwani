import '../database.dart';

class BloodTypesTable extends SupabaseTable<BloodTypesRow> {
  @override
  String get tableName => 'blood_types';

  @override
  BloodTypesRow createRow(Map<String, dynamic> data) => BloodTypesRow(data);
}

class BloodTypesRow extends SupabaseDataRow {
  BloodTypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => BloodTypesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get bloodTypeCode => getField<String>('blood_type_code')!;
  set bloodTypeCode(String value) => setField<String>('blood_type_code', value);

  String get bloodTypeName => getField<String>('blood_type_name')!;
  set bloodTypeName(String value) => setField<String>('blood_type_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
