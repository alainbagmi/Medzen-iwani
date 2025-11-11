import '../database.dart';

class InvoicesTable extends SupabaseTable<InvoicesRow> {
  @override
  String get tableName => 'invoices';

  @override
  InvoicesRow createRow(Map<String, dynamic> data) => InvoicesRow(data);
}

class InvoicesRow extends SupabaseDataRow {
  InvoicesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InvoicesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get invoiceNumber => getField<String>('invoice_number')!;
  set invoiceNumber(String value) => setField<String>('invoice_number', value);

  String? get patientId => getField<String>('patient_id');
  set patientId(String? value) => setField<String>('patient_id', value);

  String? get appointmentId => getField<String>('appointment_id');
  set appointmentId(String? value) => setField<String>('appointment_id', value);

  double get subtotal => getField<double>('subtotal')!;
  set subtotal(double value) => setField<double>('subtotal', value);

  double? get taxAmount => getField<double>('tax_amount');
  set taxAmount(double? value) => setField<double>('tax_amount', value);

  double? get discountAmount => getField<double>('discount_amount');
  set discountAmount(double? value) =>
      setField<double>('discount_amount', value);

  double get totalAmount => getField<double>('total_amount')!;
  set totalAmount(double value) => setField<double>('total_amount', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get dueDate => getField<DateTime>('due_date');
  set dueDate(DateTime? value) => setField<DateTime>('due_date', value);

  DateTime? get paidAt => getField<DateTime>('paid_at');
  set paidAt(DateTime? value) => setField<DateTime>('paid_at', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
