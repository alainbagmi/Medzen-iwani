import '../database.dart';

class PharmacyStockTable extends SupabaseTable<PharmacyStockRow> {
  @override
  String get tableName => 'pharmacy_stock';

  @override
  PharmacyStockRow createRow(Map<String, dynamic> data) =>
      PharmacyStockRow(data);
}

class PharmacyStockRow extends SupabaseDataRow {
  PharmacyStockRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PharmacyStockTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get facilityId => getField<String>('facility_id')!;
  set facilityId(String value) => setField<String>('facility_id', value);

  String? get updatedById => getField<String>('updated_by_id');
  set updatedById(String? value) => setField<String>('updated_by_id', value);

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

  double get currentQuantity => getField<double>('current_quantity')!;
  set currentQuantity(double value) =>
      setField<double>('current_quantity', value);

  String get unit => getField<String>('unit')!;
  set unit(String value) => setField<String>('unit', value);

  double? get reorderLevel => getField<double>('reorder_level');
  set reorderLevel(double? value) => setField<double>('reorder_level', value);

  double? get maximumStockLevel => getField<double>('maximum_stock_level');
  set maximumStockLevel(double? value) =>
      setField<double>('maximum_stock_level', value);

  String? get batchNumber => getField<String>('batch_number');
  set batchNumber(String? value) => setField<String>('batch_number', value);

  String? get manufacturer => getField<String>('manufacturer');
  set manufacturer(String? value) => setField<String>('manufacturer', value);

  DateTime? get manufacturingDate => getField<DateTime>('manufacturing_date');
  set manufacturingDate(DateTime? value) =>
      setField<DateTime>('manufacturing_date', value);

  DateTime? get expiryDate => getField<DateTime>('expiry_date');
  set expiryDate(DateTime? value) => setField<DateTime>('expiry_date', value);

  String? get storageLocation => getField<String>('storage_location');
  set storageLocation(String? value) =>
      setField<String>('storage_location', value);

  String? get temperatureRequirement =>
      getField<String>('temperature_requirement');
  set temperatureRequirement(String? value) =>
      setField<String>('temperature_requirement', value);

  double? get unitCost => getField<double>('unit_cost');
  set unitCost(double? value) => setField<double>('unit_cost', value);

  double? get totalValue => getField<double>('total_value');
  set totalValue(double? value) => setField<double>('total_value', value);

  String? get stockStatus => getField<String>('stock_status');
  set stockStatus(String? value) => setField<String>('stock_status', value);

  DateTime? get lastStockCheckDate =>
      getField<DateTime>('last_stock_check_date');
  set lastStockCheckDate(DateTime? value) =>
      setField<DateTime>('last_stock_check_date', value);

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
