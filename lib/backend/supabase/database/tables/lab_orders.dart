import '../database.dart';

class LabOrdersTable extends SupabaseTable<LabOrdersRow> {
  @override
  String get tableName => 'lab_orders';

  @override
  LabOrdersRow createRow(Map<String, dynamic> data) => LabOrdersRow(data);
}

class LabOrdersRow extends SupabaseDataRow {
  LabOrdersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LabOrdersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String get orderingProviderId => getField<String>('ordering_provider_id')!;
  set orderingProviderId(String value) =>
      setField<String>('ordering_provider_id', value);

  String get orderNumber => getField<String>('order_number')!;
  set orderNumber(String value) => setField<String>('order_number', value);

  String get testType => getField<String>('test_type')!;
  set testType(String value) => setField<String>('test_type', value);

  String? get priority => getField<String>('priority');
  set priority(String? value) => setField<String>('priority', value);

  String? get instructions => getField<String>('instructions');
  set instructions(String? value) => setField<String>('instructions', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get orderedAt => getField<DateTime>('ordered_at');
  set orderedAt(DateTime? value) => setField<DateTime>('ordered_at', value);

  DateTime? get collectedAt => getField<DateTime>('collected_at');
  set collectedAt(DateTime? value) => setField<DateTime>('collected_at', value);

  DateTime? get completedAt => getField<DateTime>('completed_at');
  set completedAt(DateTime? value) => setField<DateTime>('completed_at', value);

  String? get labFacilityId => getField<String>('lab_facility_id');
  set labFacilityId(String? value) =>
      setField<String>('lab_facility_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get labTestTypeId => getField<String>('lab_test_type_id');
  set labTestTypeId(String? value) =>
      setField<String>('lab_test_type_id', value);
}
