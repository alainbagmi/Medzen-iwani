import '../database.dart';

class PrescriptionsTable extends SupabaseTable<PrescriptionsRow> {
  @override
  String get tableName => 'prescriptions';

  @override
  PrescriptionsRow createRow(Map<String, dynamic> data) =>
      PrescriptionsRow(data);
}

class PrescriptionsRow extends SupabaseDataRow {
  PrescriptionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PrescriptionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String get doctorId => getField<String>('doctor_id')!;
  set doctorId(String value) => setField<String>('doctor_id', value);

  String get prescriptionNumber => getField<String>('prescription_number')!;
  set prescriptionNumber(String value) =>
      setField<String>('prescription_number', value);

  String get medicationName => getField<String>('medication_name')!;
  set medicationName(String value) =>
      setField<String>('medication_name', value);

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

  int? get refillsRemaining => getField<int>('refills_remaining');
  set refillsRemaining(int? value) => setField<int>('refills_remaining', value);

  String? get instructions => getField<String>('instructions');
  set instructions(String? value) => setField<String>('instructions', value);

  String? get pharmacyId => getField<String>('pharmacy_id');
  set pharmacyId(String? value) => setField<String>('pharmacy_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get issuedDate => getField<DateTime>('issued_date');
  set issuedDate(DateTime? value) => setField<DateTime>('issued_date', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  DateTime? get filledDate => getField<DateTime>('filled_date');
  set filledDate(DateTime? value) => setField<DateTime>('filled_date', value);

  String? get compositionId => getField<String>('composition_id');
  set compositionId(String? value) => setField<String>('composition_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

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
}
