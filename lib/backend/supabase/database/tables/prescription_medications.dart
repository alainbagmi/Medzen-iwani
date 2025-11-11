import '../database.dart';

class PrescriptionMedicationsTable
    extends SupabaseTable<PrescriptionMedicationsRow> {
  @override
  String get tableName => 'prescription_medications';

  @override
  PrescriptionMedicationsRow createRow(Map<String, dynamic> data) =>
      PrescriptionMedicationsRow(data);
}

class PrescriptionMedicationsRow extends SupabaseDataRow {
  PrescriptionMedicationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PrescriptionMedicationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get prescriptionId => getField<String>('prescription_id');
  set prescriptionId(String? value) =>
      setField<String>('prescription_id', value);

  String? get medicationId => getField<String>('medication_id');
  set medicationId(String? value) => setField<String>('medication_id', value);

  String get dosage => getField<String>('dosage')!;
  set dosage(String value) => setField<String>('dosage', value);

  String get frequency => getField<String>('frequency')!;
  set frequency(String value) => setField<String>('frequency', value);

  String? get duration => getField<String>('duration');
  set duration(String? value) => setField<String>('duration', value);

  int? get quantity => getField<int>('quantity');
  set quantity(int? value) => setField<int>('quantity', value);

  int? get refillsAllowed => getField<int>('refills_allowed');
  set refillsAllowed(int? value) => setField<int>('refills_allowed', value);

  String? get instructions => getField<String>('instructions');
  set instructions(String? value) => setField<String>('instructions', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
