import '../database.dart';

class PromotionUsageTable extends SupabaseTable<PromotionUsageRow> {
  @override
  String get tableName => 'promotion_usage';

  @override
  PromotionUsageRow createRow(Map<String, dynamic> data) =>
      PromotionUsageRow(data);
}

class PromotionUsageRow extends SupabaseDataRow {
  PromotionUsageRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PromotionUsageTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get promotionId => getField<String>('promotion_id');
  set promotionId(String? value) => setField<String>('promotion_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get transactionId => getField<String>('transaction_id');
  set transactionId(String? value) => setField<String>('transaction_id', value);

  double? get discountApplied => getField<double>('discount_applied');
  set discountApplied(double? value) =>
      setField<double>('discount_applied', value);

  DateTime? get usedAt => getField<DateTime>('used_at');
  set usedAt(DateTime? value) => setField<DateTime>('used_at', value);
}
