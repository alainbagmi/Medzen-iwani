import '../database.dart';

class ProviderTypesTable extends SupabaseTable<ProviderTypesRow> {
  @override
  String get tableName => 'provider_types';

  @override
  ProviderTypesRow createRow(Map<String, dynamic> data) =>
      ProviderTypesRow(data);
}

class ProviderTypesRow extends SupabaseDataRow {
  ProviderTypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProviderTypesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get typeName => getField<String>('type_name')!;
  set typeName(String value) => setField<String>('type_name', value);

  String get typeCode => getField<String>('type_code')!;
  set typeCode(String value) => setField<String>('type_code', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  bool? get requiresMedicalLicense =>
      getField<bool>('requires_medical_license');
  set requiresMedicalLicense(bool? value) =>
      setField<bool>('requires_medical_license', value);

  bool? get requiresBoardCertification =>
      getField<bool>('requires_board_certification');
  set requiresBoardCertification(bool? value) =>
      setField<bool>('requires_board_certification', value);

  bool? get canPrescribeMedication =>
      getField<bool>('can_prescribe_medication');
  set canPrescribeMedication(bool? value) =>
      setField<bool>('can_prescribe_medication', value);

  bool? get supervisionRequired => getField<bool>('supervision_required');
  set supervisionRequired(bool? value) =>
      setField<bool>('supervision_required', value);

  int? get displayOrder => getField<int>('display_order');
  set displayOrder(int? value) => setField<int>('display_order', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
