import '../database.dart';

class UserSubscriptionsTable extends SupabaseTable<UserSubscriptionsRow> {
  @override
  String get tableName => 'user_subscriptions';

  @override
  UserSubscriptionsRow createRow(Map<String, dynamic> data) =>
      UserSubscriptionsRow(data);
}

class UserSubscriptionsRow extends SupabaseDataRow {
  UserSubscriptionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserSubscriptionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get planId => getField<String>('plan_id');
  set planId(String? value) => setField<String>('plan_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime get startDate => getField<DateTime>('start_date')!;
  set startDate(DateTime value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  DateTime? get nextBillingDate => getField<DateTime>('next_billing_date');
  set nextBillingDate(DateTime? value) =>
      setField<DateTime>('next_billing_date', value);

  String? get paymentMethodId => getField<String>('payment_method_id');
  set paymentMethodId(String? value) =>
      setField<String>('payment_method_id', value);

  String? get providerSubscriptionId =>
      getField<String>('provider_subscription_id');
  set providerSubscriptionId(String? value) =>
      setField<String>('provider_subscription_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
