import '../database.dart';

class MedicationDispensingTable extends SupabaseTable<MedicationDispensingRow> {
  @override
  String get tableName => 'medication_dispensing';

  @override
  MedicationDispensingRow createRow(Map<String, dynamic> data) =>
      MedicationDispensingRow(data);
}

class MedicationDispensingRow extends SupabaseDataRow {
  MedicationDispensingRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicationDispensingTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get patientId => getField<String>('patient_id')!;
  set patientId(String value) => setField<String>('patient_id', value);

  String? get prescriptionId => getField<String>('prescription_id');
  set prescriptionId(String? value) =>
      setField<String>('prescription_id', value);

  String? get pharmacistId => getField<String>('pharmacist_id');
  set pharmacistId(String? value) => setField<String>('pharmacist_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String get medicationName => getField<String>('medication_name')!;
  set medicationName(String value) =>
      setField<String>('medication_name', value);

  String? get medicationCode => getField<String>('medication_code');
  set medicationCode(String? value) =>
      setField<String>('medication_code', value);

  String? get strength => getField<String>('strength');
  set strength(String? value) => setField<String>('strength', value);

  String? get dosageForm => getField<String>('dosage_form');
  set dosageForm(String? value) => setField<String>('dosage_form', value);

  String? get route => getField<String>('route');
  set route(String? value) => setField<String>('route', value);

  double get quantityDispensed => getField<double>('quantity_dispensed')!;
  set quantityDispensed(double value) =>
      setField<double>('quantity_dispensed', value);

  String get unit => getField<String>('unit')!;
  set unit(String value) => setField<String>('unit', value);

  DateTime get dispensingDate => getField<DateTime>('dispensing_date')!;
  set dispensingDate(DateTime value) =>
      setField<DateTime>('dispensing_date', value);

  String? get batchNumber => getField<String>('batch_number');
  set batchNumber(String? value) => setField<String>('batch_number', value);

  DateTime? get expiryDate => getField<DateTime>('expiry_date');
  set expiryDate(DateTime? value) => setField<DateTime>('expiry_date', value);

  String? get manufacturer => getField<String>('manufacturer');
  set manufacturer(String? value) => setField<String>('manufacturer', value);

  String? get dosageInstructions => getField<String>('dosage_instructions');
  set dosageInstructions(String? value) =>
      setField<String>('dosage_instructions', value);

  String? get frequency => getField<String>('frequency');
  set frequency(String? value) => setField<String>('frequency', value);

  int? get durationDays => getField<int>('duration_days');
  set durationDays(int? value) => setField<int>('duration_days', value);

  int? get refillsRemaining => getField<int>('refills_remaining');
  set refillsRemaining(int? value) => setField<int>('refills_remaining', value);

  bool? get counselingProvided => getField<bool>('counseling_provided');
  set counselingProvided(bool? value) =>
      setField<bool>('counseling_provided', value);

  String? get counselingNotes => getField<String>('counseling_notes');
  set counselingNotes(String? value) =>
      setField<String>('counseling_notes', value);

  String? get specialInstructions => getField<String>('special_instructions');
  set specialInstructions(String? value) =>
      setField<String>('special_instructions', value);

  List<String> get warnings => getListField<String>('warnings');
  set warnings(List<String>? value) => setListField<String>('warnings', value);

  double? get unitPrice => getField<double>('unit_price');
  set unitPrice(double? value) => setField<double>('unit_price', value);

  double? get totalCost => getField<double>('total_cost');
  set totalCost(double? value) => setField<double>('total_cost', value);

  double? get insuranceCoverage => getField<double>('insurance_coverage');
  set insuranceCoverage(double? value) =>
      setField<double>('insurance_coverage', value);

  double? get patientCopay => getField<double>('patient_copay');
  set patientCopay(double? value) => setField<double>('patient_copay', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  bool? get ehrbaseSynced => getField<bool>('ehrbase_synced');
  set ehrbaseSynced(bool? value) => setField<bool>('ehrbase_synced', value);

  DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
  set ehrbaseSyncedAt(DateTime? value) =>
      setField<DateTime>('ehrbase_synced_at', value);

  String? get ehrbaseSyncError => getField<String>('ehrbase_sync_error');
  set ehrbaseSyncError(String? value) =>
      setField<String>('ehrbase_sync_error', value);

  int? get ehrbaseRetryCount => getField<int>('ehrbase_retry_count');
  set ehrbaseRetryCount(int? value) =>
      setField<int>('ehrbase_retry_count', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
