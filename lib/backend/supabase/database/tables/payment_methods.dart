import '../database.dart';

class PaymentMethodsTable extends SupabaseTable<PaymentMethodsRow> {
  @override
  String get tableName => 'payment_methods';

  @override
  PaymentMethodsRow createRow(Map<String, dynamic> data) =>
      PaymentMethodsRow(data);
}

class PaymentMethodsRow extends SupabaseDataRow {
  PaymentMethodsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentMethodsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get paymentType => getField<String>('payment_type');
  set paymentType(String? value) => setField<String>('payment_type', value);

  String? get provider => getField<String>('provider');
  set provider(String? value) => setField<String>('provider', value);

  String? get providerCustomerId => getField<String>('provider_customer_id');
  set providerCustomerId(String? value) =>
      setField<String>('provider_customer_id', value);

  String? get providerPaymentMethodId =>
      getField<String>('provider_payment_method_id');
  set providerPaymentMethodId(String? value) =>
      setField<String>('provider_payment_method_id', value);

  String? get lastFour => getField<String>('last_four');
  set lastFour(String? value) => setField<String>('last_four', value);

  String? get brand => getField<String>('brand');
  set brand(String? value) => setField<String>('brand', value);

  int? get expiryMonth => getField<int>('expiry_month');
  set expiryMonth(int? value) => setField<int>('expiry_month', value);

  int? get expiryYear => getField<int>('expiry_year');
  set expiryYear(int? value) => setField<int>('expiry_year', value);

  String? get mobileNumber => getField<String>('mobile_number');
  set mobileNumber(String? value) => setField<String>('mobile_number', value);

  bool? get isDefault => getField<bool>('is_default');
  set isDefault(bool? value) => setField<bool>('is_default', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
