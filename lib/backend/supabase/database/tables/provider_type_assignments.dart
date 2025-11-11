import '../database.dart';

class ProviderTypeAssignmentsTable
    extends SupabaseTable<ProviderTypeAssignmentsRow> {
  @override
  String get tableName => 'provider_type_assignments';

  @override
  ProviderTypeAssignmentsRow createRow(Map<String, dynamic> data) =>
      ProviderTypeAssignmentsRow(data);
}

class ProviderTypeAssignmentsRow extends SupabaseDataRow {
  ProviderTypeAssignmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProviderTypeAssignmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get providerTypeId => getField<String>('provider_type_id');
  set providerTypeId(String? value) =>
      setField<String>('provider_type_id', value);

  String? get licenseNumber => getField<String>('license_number');
  set licenseNumber(String? value) => setField<String>('license_number', value);

  DateTime? get licenseExpiry => getField<DateTime>('license_expiry');
  set licenseExpiry(DateTime? value) =>
      setField<DateTime>('license_expiry', value);

  bool? get isPrimary => getField<bool>('is_primary');
  set isPrimary(bool? value) => setField<bool>('is_primary', value);

  String? get verificationStatus => getField<String>('verification_status');
  set verificationStatus(String? value) =>
      setField<String>('verification_status', value);

  DateTime? get verifiedAt => getField<DateTime>('verified_at');
  set verifiedAt(DateTime? value) => setField<DateTime>('verified_at', value);

  String? get verifiedById => getField<String>('verified_by_id');
  set verifiedById(String? value) => setField<String>('verified_by_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
