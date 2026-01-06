import '../database.dart';

class PaymentOverviewTable extends SupabaseTable<PaymentOverviewRow> {
  @override
  String get tableName => 'payment_overview';

  @override
  PaymentOverviewRow createRow(Map<String, dynamic> data) =>
      PaymentOverviewRow(data);
}

class PaymentOverviewRow extends SupabaseDataRow {
  PaymentOverviewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentOverviewTable();

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get referenceId => getField<String>('reference_id');
  set referenceId(String? value) => setField<String>('reference_id', value);

  String? get referenceName => getField<String>('reference_name');
  set referenceName(String? value) => setField<String>('reference_name', value);

  String? get referencePicUrl => getField<String>('reference_pic_url');
  set referencePicUrl(String? value) =>
      setField<String>('reference_pic_url', value);

  String? get referencePhone => getField<String>('reference_phone');
  set referencePhone(String? value) =>
      setField<String>('reference_phone', value);

  double? get totalAmount => getField<double>('total_amount');
  set totalAmount(double? value) => setField<double>('total_amount', value);

  DateTime? get firstPaymentDate => getField<DateTime>('first_payment_date');
  set firstPaymentDate(DateTime? value) =>
      setField<DateTime>('first_payment_date', value);

  DateTime? get lastPaymentDate => getField<DateTime>('last_payment_date');
  set lastPaymentDate(DateTime? value) =>
      setField<DateTime>('last_payment_date', value);

  int? get totalPayments => getField<int>('total_payments');
  set totalPayments(int? value) => setField<int>('total_payments', value);
}
