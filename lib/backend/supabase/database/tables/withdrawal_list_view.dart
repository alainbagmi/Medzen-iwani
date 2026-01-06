import '../database.dart';

class WithdrawalListViewTable extends SupabaseTable<WithdrawalListViewRow> {
  @override
  String get tableName => 'withdrawal_list_view';

  @override
  WithdrawalListViewRow createRow(Map<String, dynamic> data) =>
      WithdrawalListViewRow(data);
}

class WithdrawalListViewRow extends SupabaseDataRow {
  WithdrawalListViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WithdrawalListViewTable();

  String? get withdrawalId => getField<String>('withdrawal_id');
  set withdrawalId(String? value) => setField<String>('withdrawal_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get paymentMethod => getField<String>('payment_method');
  set paymentMethod(String? value) => setField<String>('payment_method', value);

  String? get paymentPhoneNumber => getField<String>('payment_phone_number');
  set paymentPhoneNumber(String? value) =>
      setField<String>('payment_phone_number', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  double? get amount => getField<double>('amount');
  set amount(double? value) => setField<double>('amount', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get providerId => getField<String>('provider_id');
  set providerId(String? value) => setField<String>('provider_id', value);

  String? get facilityid => getField<String>('facilityid');
  set facilityid(String? value) => setField<String>('facilityid', value);

  String? get image => getField<String>('image');
  set image(String? value) => setField<String>('image', value);
}
