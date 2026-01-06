import '../database.dart';

class PaymentTotalsTable extends SupabaseTable<PaymentTotalsRow> {
  @override
  String get tableName => 'payment_totals';

  @override
  PaymentTotalsRow createRow(Map<String, dynamic> data) =>
      PaymentTotalsRow(data);
}

class PaymentTotalsRow extends SupabaseDataRow {
  PaymentTotalsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentTotalsTable();

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get referenceId => getField<String>('reference_id');
  set referenceId(String? value) => setField<String>('reference_id', value);

  double? get totalAmount => getField<double>('total_amount');
  set totalAmount(double? value) => setField<double>('total_amount', value);

  int? get totalPayments => getField<int>('total_payments');
  set totalPayments(int? value) => setField<int>('total_payments', value);
}
