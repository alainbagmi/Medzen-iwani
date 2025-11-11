import '../database.dart';

class UserMedicationsTable extends SupabaseTable<UserMedicationsRow> {
  @override
  String get tableName => 'user_medications';

  @override
  UserMedicationsRow createRow(Map<String, dynamic> data) =>
      UserMedicationsRow(data);
}

class UserMedicationsRow extends SupabaseDataRow {
  UserMedicationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserMedicationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get medicationId => getField<String>('medication_id');
  set medicationId(String? value) => setField<String>('medication_id', value);

  String get dosage => getField<String>('dosage')!;
  set dosage(String value) => setField<String>('dosage', value);

  String get frequency => getField<String>('frequency')!;
  set frequency(String value) => setField<String>('frequency', value);

  String? get route => getField<String>('route');
  set route(String? value) => setField<String>('route', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  String? get prescribedById => getField<String>('prescribed_by_id');
  set prescribedById(String? value) =>
      setField<String>('prescribed_by_id', value);

  String? get prescriptionId => getField<String>('prescription_id');
  set prescriptionId(String? value) =>
      setField<String>('prescription_id', value);

  String? get reason => getField<String>('reason');
  set reason(String? value) => setField<String>('reason', value);

  String? get instructions => getField<String>('instructions');
  set instructions(String? value) => setField<String>('instructions', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
