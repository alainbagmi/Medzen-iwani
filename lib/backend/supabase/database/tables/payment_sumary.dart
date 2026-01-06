import '../database.dart';

class PaymentSumaryTable extends SupabaseTable<PaymentSumaryRow> {
  @override
  String get tableName => 'payment_sumary';

  @override
  PaymentSumaryRow createRow(Map<String, dynamic> data) =>
      PaymentSumaryRow(data);
}

class PaymentSumaryRow extends SupabaseDataRow {
  PaymentSumaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentSumaryTable();

  double? get totalGrossAmount => getField<double>('total_gross_amount');
  set totalGrossAmount(double? value) =>
      setField<double>('total_gross_amount', value);

  double? get totalServiceFee => getField<double>('total_service_fee');
  set totalServiceFee(double? value) =>
      setField<double>('total_service_fee', value);

  double? get totalProcessingFee => getField<double>('total_processing_fee');
  set totalProcessingFee(double? value) =>
      setField<double>('total_processing_fee', value);

  double? get totalTaxes => getField<double>('total_taxes');
  set totalTaxes(double? value) => setField<double>('total_taxes', value);

  int? get totalTransactions => getField<int>('total_transactions');
  set totalTransactions(int? value) =>
      setField<int>('total_transactions', value);
}
