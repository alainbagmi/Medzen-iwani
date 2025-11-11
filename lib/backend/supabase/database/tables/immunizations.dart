import '../database.dart';

class ImmunizationsTable extends SupabaseTable<ImmunizationsRow> {
  @override
  String get tableName => 'immunizations';

  @override
  ImmunizationsRow createRow(Map<String, dynamic> data) =>
      ImmunizationsRow(data);
}

class ImmunizationsRow extends SupabaseDataRow {
  ImmunizationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ImmunizationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String get vaccineName => getField<String>('vaccine_name')!;
  set vaccineName(String value) => setField<String>('vaccine_name', value);

  String? get vaccineCode => getField<String>('vaccine_code');
  set vaccineCode(String? value) => setField<String>('vaccine_code', value);

  int? get doseNumber => getField<int>('dose_number');
  set doseNumber(int? value) => setField<int>('dose_number', value);

  String? get seriesName => getField<String>('series_name');
  set seriesName(String? value) => setField<String>('series_name', value);

  String? get administeredById => getField<String>('administered_by_id');
  set administeredById(String? value) =>
      setField<String>('administered_by_id', value);

  DateTime get administrationDate => getField<DateTime>('administration_date')!;
  set administrationDate(DateTime value) =>
      setField<DateTime>('administration_date', value);

  DateTime? get expiryDate => getField<DateTime>('expiry_date');
  set expiryDate(DateTime? value) => setField<DateTime>('expiry_date', value);

  String? get lotNumber => getField<String>('lot_number');
  set lotNumber(String? value) => setField<String>('lot_number', value);

  String? get manufacturer => getField<String>('manufacturer');
  set manufacturer(String? value) => setField<String>('manufacturer', value);

  String? get site => getField<String>('site');
  set site(String? value) => setField<String>('site', value);

  String? get route => getField<String>('route');
  set route(String? value) => setField<String>('route', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

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
