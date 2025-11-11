import '../database.dart';

class PaymentAnalyticsTable extends SupabaseTable<PaymentAnalyticsRow> {
  @override
  String get tableName => 'payment_analytics';

  @override
  PaymentAnalyticsRow createRow(Map<String, dynamic> data) =>
      PaymentAnalyticsRow(data);
}

class PaymentAnalyticsRow extends SupabaseDataRow {
  PaymentAnalyticsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentAnalyticsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get paymentReference => getField<String>('payment_reference');
  set paymentReference(String? value) =>
      setField<String>('payment_reference', value);

  String? get payerId => getField<String>('payer_id');
  set payerId(String? value) => setField<String>('payer_id', value);

  String? get payerName => getField<String>('payer_name');
  set payerName(String? value) => setField<String>('payer_name', value);

  String? get recipientId => getField<String>('recipient_id');
  set recipientId(String? value) => setField<String>('recipient_id', value);

  String? get recipientName => getField<String>('recipient_name');
  set recipientName(String? value) => setField<String>('recipient_name', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String? get facilityName => getField<String>('facility_name');
  set facilityName(String? value) => setField<String>('facility_name', value);

  String? get paymentFor => getField<String>('payment_for');
  set paymentFor(String? value) => setField<String>('payment_for', value);

  String? get paymentMethod => getField<String>('payment_method');
  set paymentMethod(String? value) => setField<String>('payment_method', value);

  String? get paymentStatus => getField<String>('payment_status');
  set paymentStatus(String? value) => setField<String>('payment_status', value);

  double? get grossAmount => getField<double>('gross_amount');
  set grossAmount(double? value) => setField<double>('gross_amount', value);

  double? get netAmount => getField<double>('net_amount');
  set netAmount(double? value) => setField<double>('net_amount', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  String? get subscriptionType => getField<String>('subscription_type');
  set subscriptionType(String? value) =>
      setField<String>('subscription_type', value);

  DateTime? get initiatedAt => getField<DateTime>('initiated_at');
  set initiatedAt(DateTime? value) => setField<DateTime>('initiated_at', value);

  DateTime? get completedAt => getField<DateTime>('completed_at');
  set completedAt(DateTime? value) => setField<DateTime>('completed_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  double? get paymentDurationSeconds =>
      getField<double>('payment_duration_seconds');
  set paymentDurationSeconds(double? value) =>
      setField<double>('payment_duration_seconds', value);
}
