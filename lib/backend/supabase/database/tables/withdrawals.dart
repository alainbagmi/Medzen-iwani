import '../database.dart';

class WithdrawalsTable extends SupabaseTable<WithdrawalsRow> {
  @override
  String get tableName => 'withdrawals';

  @override
  WithdrawalsRow createRow(Map<String, dynamic> data) => WithdrawalsRow(data);
}

class WithdrawalsRow extends SupabaseDataRow {
  WithdrawalsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WithdrawalsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime? get processedAt => getField<DateTime>('processed_at');
  set processedAt(DateTime? value) => setField<DateTime>('processed_at', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityid => getField<String>('facilityid');
  set facilityid(String? value) => setField<String>('facilityid', value);

  double get amount => getField<double>('amount')!;
  set amount(double value) => setField<double>('amount', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  String get refId => getField<String>('Ref_id')!;
  set refId(String value) => setField<String>('Ref_id', value);

  String? get paymentMethod => getField<String>('payment_method');
  set paymentMethod(String? value) => setField<String>('payment_method', value);

  String? get rejectionReason => getField<String>('rejection_reason');
  set rejectionReason(String? value) =>
      setField<String>('rejection_reason', value);

  String? get paymentPhoneNumber => getField<String>('payment_phone_number');
  set paymentPhoneNumber(String? value) =>
      setField<String>('payment_phone_number', value);
}
