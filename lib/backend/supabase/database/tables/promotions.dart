import '../database.dart';

class PromotionsTable extends SupabaseTable<PromotionsRow> {
  @override
  String get tableName => 'promotions';

  @override
  PromotionsRow createRow(Map<String, dynamic> data) => PromotionsRow(data);
}

class PromotionsRow extends SupabaseDataRow {
  PromotionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PromotionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get createdById => getField<String>('created_by_id');
  set createdById(String? value) => setField<String>('created_by_id', value);

  String get promotionCode => getField<String>('promotion_code')!;
  set promotionCode(String value) => setField<String>('promotion_code', value);

  String? get promotionType => getField<String>('promotion_type');
  set promotionType(String? value) => setField<String>('promotion_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get discountType => getField<String>('discount_type');
  set discountType(String? value) => setField<String>('discount_type', value);

  double? get discountValue => getField<double>('discount_value');
  set discountValue(double? value) => setField<double>('discount_value', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  double? get minimumPurchaseAmount =>
      getField<double>('minimum_purchase_amount');
  set minimumPurchaseAmount(double? value) =>
      setField<double>('minimum_purchase_amount', value);

  double? get maximumDiscountAmount =>
      getField<double>('maximum_discount_amount');
  set maximumDiscountAmount(double? value) =>
      setField<double>('maximum_discount_amount', value);

  int? get usageLimitTotal => getField<int>('usage_limit_total');
  set usageLimitTotal(int? value) => setField<int>('usage_limit_total', value);

  int? get usageLimitPerUser => getField<int>('usage_limit_per_user');
  set usageLimitPerUser(int? value) =>
      setField<int>('usage_limit_per_user', value);

  int? get usageCount => getField<int>('usage_count');
  set usageCount(int? value) => setField<int>('usage_count', value);

  List<String> get applicableTo => getListField<String>('applicable_to');
  set applicableTo(List<String>? value) =>
      setListField<String>('applicable_to', value);

  List<String> get targetUsers => getListField<String>('target_users');
  set targetUsers(List<String>? value) =>
      setListField<String>('target_users', value);

  DateTime get startDate => getField<DateTime>('start_date')!;
  set startDate(DateTime value) => setField<DateTime>('start_date', value);

  DateTime get endDate => getField<DateTime>('end_date')!;
  set endDate(DateTime value) => setField<DateTime>('end_date', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get termsConditions => getField<String>('terms_conditions');
  set termsConditions(String? value) =>
      setField<String>('terms_conditions', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
