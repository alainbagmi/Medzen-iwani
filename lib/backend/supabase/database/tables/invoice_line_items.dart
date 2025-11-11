import '../database.dart';

class InvoiceLineItemsTable extends SupabaseTable<InvoiceLineItemsRow> {
  @override
  String get tableName => 'invoice_line_items';

  @override
  InvoiceLineItemsRow createRow(Map<String, dynamic> data) =>
      InvoiceLineItemsRow(data);
}

class InvoiceLineItemsRow extends SupabaseDataRow {
  InvoiceLineItemsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InvoiceLineItemsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get invoiceId => getField<String>('invoice_id');
  set invoiceId(String? value) => setField<String>('invoice_id', value);

  String get description => getField<String>('description')!;
  set description(String value) => setField<String>('description', value);

  int? get quantity => getField<int>('quantity');
  set quantity(int? value) => setField<int>('quantity', value);

  double get unitPrice => getField<double>('unit_price')!;
  set unitPrice(double value) => setField<double>('unit_price', value);

  double get totalPrice => getField<double>('total_price')!;
  set totalPrice(double value) => setField<double>('total_price', value);

  double? get taxRate => getField<double>('tax_rate');
  set taxRate(double? value) => setField<double>('tax_rate', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
