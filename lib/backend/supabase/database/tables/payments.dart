import '../database.dart';

class PaymentsTable extends SupabaseTable<PaymentsRow> {
  @override
  String get tableName => 'payments';

  @override
  PaymentsRow createRow(Map<String, dynamic> data) => PaymentsRow(data);
}

class PaymentsRow extends SupabaseDataRow {
  PaymentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get paymentReference => getField<String>('payment_reference')!;
  set paymentReference(String value) =>
      setField<String>('payment_reference', value);

  String? get transactionId => getField<String>('transaction_id');
  set transactionId(String? value) => setField<String>('transaction_id', value);

  String? get externalTransactionId =>
      getField<String>('external_transaction_id');
  set externalTransactionId(String? value) =>
      setField<String>('external_transaction_id', value);

  String? get payerId => getField<String>('payer_id');
  set payerId(String? value) => setField<String>('payer_id', value);

  String? get recipientId => getField<String>('recipient_id');
  set recipientId(String? value) => setField<String>('recipient_id', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  String get paymentFor => getField<String>('payment_for')!;
  set paymentFor(String value) => setField<String>('payment_for', value);

  String? get relatedServiceId => getField<String>('related_service_id');
  set relatedServiceId(String? value) =>
      setField<String>('related_service_id', value);

  String? get consultationId => getField<String>('consultation_id');
  set consultationId(String? value) =>
      setField<String>('consultation_id', value);

  String? get prescriptionId => getField<String>('prescription_id');
  set prescriptionId(String? value) =>
      setField<String>('prescription_id', value);

  String? get labOrderId => getField<String>('lab_order_id');
  set labOrderId(String? value) => setField<String>('lab_order_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  String get paymentMethod => getField<String>('payment_method')!;
  set paymentMethod(String value) => setField<String>('payment_method', value);

  String? get paymentProviderId => getField<String>('payment_provider_id');
  set paymentProviderId(String? value) =>
      setField<String>('payment_provider_id', value);

  dynamic? get paymentAccountInfo => getField<dynamic>('payment_account_info');
  set paymentAccountInfo(dynamic? value) =>
      setField<dynamic>('payment_account_info', value);

  double get grossAmount => getField<double>('gross_amount')!;
  set grossAmount(double value) => setField<double>('gross_amount', value);

  double? get taxAmount => getField<double>('tax_amount');
  set taxAmount(double? value) => setField<double>('tax_amount', value);

  double? get serviceFee => getField<double>('service_fee');
  set serviceFee(double? value) => setField<double>('service_fee', value);

  double? get processingFee => getField<double>('processing_fee');
  set processingFee(double? value) => setField<double>('processing_fee', value);

  double? get discountAmount => getField<double>('discount_amount');
  set discountAmount(double? value) =>
      setField<double>('discount_amount', value);

  double get netAmount => getField<double>('net_amount')!;
  set netAmount(double value) => setField<double>('net_amount', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  double? get insuranceCoverageAmount =>
      getField<double>('insurance_coverage_amount');
  set insuranceCoverageAmount(double? value) =>
      setField<double>('insurance_coverage_amount', value);

  double? get patientCopayAmount => getField<double>('patient_copay_amount');
  set patientCopayAmount(double? value) =>
      setField<double>('patient_copay_amount', value);

  double? get deductibleAmount => getField<double>('deductible_amount');
  set deductibleAmount(double? value) =>
      setField<double>('deductible_amount', value);

  String? get insuranceClaimId => getField<String>('insurance_claim_id');
  set insuranceClaimId(String? value) =>
      setField<String>('insurance_claim_id', value);

  String? get paymentStatus => getField<String>('payment_status');
  set paymentStatus(String? value) => setField<String>('payment_status', value);

  DateTime? get initiatedAt => getField<DateTime>('initiated_at');
  set initiatedAt(DateTime? value) => setField<DateTime>('initiated_at', value);

  DateTime? get authorizedAt => getField<DateTime>('authorized_at');
  set authorizedAt(DateTime? value) =>
      setField<DateTime>('authorized_at', value);

  DateTime? get completedAt => getField<DateTime>('completed_at');
  set completedAt(DateTime? value) => setField<DateTime>('completed_at', value);

  DateTime? get failedAt => getField<DateTime>('failed_at');
  set failedAt(DateTime? value) => setField<DateTime>('failed_at', value);

  DateTime? get expiresAt => getField<DateTime>('expires_at');
  set expiresAt(DateTime? value) => setField<DateTime>('expires_at', value);

  String? get authorizationCode => getField<String>('authorization_code');
  set authorizationCode(String? value) =>
      setField<String>('authorization_code', value);

  String? get failureReason => getField<String>('failure_reason');
  set failureReason(String? value) => setField<String>('failure_reason', value);

  String? get failureCode => getField<String>('failure_code');
  set failureCode(String? value) => setField<String>('failure_code', value);

  String? get providerResponseCode =>
      getField<String>('provider_response_code');
  set providerResponseCode(String? value) =>
      setField<String>('provider_response_code', value);

  String? get providerResponseMessage =>
      getField<String>('provider_response_message');
  set providerResponseMessage(String? value) =>
      setField<String>('provider_response_message', value);

  double? get refundAmount => getField<double>('refund_amount');
  set refundAmount(double? value) => setField<double>('refund_amount', value);

  String? get refundReason => getField<String>('refund_reason');
  set refundReason(String? value) => setField<String>('refund_reason', value);

  DateTime? get refundedAt => getField<DateTime>('refunded_at');
  set refundedAt(DateTime? value) => setField<DateTime>('refunded_at', value);

  String? get refundReference => getField<String>('refund_reference');
  set refundReference(String? value) =>
      setField<String>('refund_reference', value);

  bool? get reconciled => getField<bool>('reconciled');
  set reconciled(bool? value) => setField<bool>('reconciled', value);

  DateTime? get reconciliationDate => getField<DateTime>('reconciliation_date');
  set reconciliationDate(DateTime? value) =>
      setField<DateTime>('reconciliation_date', value);

  String? get reconciliationBatchId =>
      getField<String>('reconciliation_batch_id');
  set reconciliationBatchId(String? value) =>
      setField<String>('reconciliation_batch_id', value);

  String? get receiptNumber => getField<String>('receipt_number');
  set receiptNumber(String? value) => setField<String>('receipt_number', value);

  String? get receiptUrl => getField<String>('receipt_url');
  set receiptUrl(String? value) => setField<String>('receipt_url', value);

  String? get invoiceNumber => getField<String>('invoice_number');
  set invoiceNumber(String? value) => setField<String>('invoice_number', value);

  String? get invoiceUrl => getField<String>('invoice_url');
  set invoiceUrl(String? value) => setField<String>('invoice_url', value);

  int? get riskScore => getField<int>('risk_score');
  set riskScore(int? value) => setField<int>('risk_score', value);

  bool? get fraudCheckPassed => getField<bool>('fraud_check_passed');
  set fraudCheckPassed(bool? value) =>
      setField<bool>('fraud_check_passed', value);

  dynamic? get fraudCheckDetails => getField<dynamic>('fraud_check_details');
  set fraudCheckDetails(dynamic? value) =>
      setField<dynamic>('fraud_check_details', value);

  dynamic? get paymentMetadata => getField<dynamic>('payment_metadata');
  set paymentMetadata(dynamic? value) =>
      setField<dynamic>('payment_metadata', value);

  String? get userAgent => getField<String>('user_agent');
  set userAgent(String? value) => setField<String>('user_agent', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get subscriptionType => getField<String>('subscription_type');
  set subscriptionType(String? value) =>
      setField<String>('subscription_type', value);
}
