import '../database.dart';

class TransactionsTable extends SupabaseTable<TransactionsRow> {
  @override
  String get tableName => 'transactions';

  @override
  TransactionsRow createRow(Map<String, dynamic> data) => TransactionsRow(data);
}

class TransactionsRow extends SupabaseDataRow {
  TransactionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TransactionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get transactionNumber => getField<String>('transaction_number')!;
  set transactionNumber(String value) =>
      setField<String>('transaction_number', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get invoiceId => getField<String>('invoice_id');
  set invoiceId(String? value) => setField<String>('invoice_id', value);

  String? get paymentMethodId => getField<String>('payment_method_id');
  set paymentMethodId(String? value) =>
      setField<String>('payment_method_id', value);

  double get amount => getField<double>('amount')!;
  set amount(double value) => setField<double>('amount', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  String? get paymentProvider => getField<String>('payment_provider');
  set paymentProvider(String? value) =>
      setField<String>('payment_provider', value);

  String? get providerTransactionId =>
      getField<String>('provider_transaction_id');
  set providerTransactionId(String? value) =>
      setField<String>('provider_transaction_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get transactionType => getField<String>('transaction_type');
  set transactionType(String? value) =>
      setField<String>('transaction_type', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get processedAt => getField<DateTime>('processed_at');
  set processedAt(DateTime? value) => setField<DateTime>('processed_at', value);

  DateTime? get failedAt => getField<DateTime>('failed_at');
  set failedAt(DateTime? value) => setField<DateTime>('failed_at', value);

  String? get failureReason => getField<String>('failure_reason');
  set failureReason(String? value) => setField<String>('failure_reason', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
