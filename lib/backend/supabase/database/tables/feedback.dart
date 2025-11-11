import '../database.dart';

class FeedbackTable extends SupabaseTable<FeedbackRow> {
  @override
  String get tableName => 'feedback';

  @override
  FeedbackRow createRow(Map<String, dynamic> data) => FeedbackRow(data);
}

class FeedbackRow extends SupabaseDataRow {
  FeedbackRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FeedbackTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get feedbackType => getField<String>('feedback_type');
  set feedbackType(String? value) => setField<String>('feedback_type', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String get subject => getField<String>('subject')!;
  set subject(String value) => setField<String>('subject', value);

  String get description => getField<String>('description')!;
  set description(String value) => setField<String>('description', value);

  String? get priority => getField<String>('priority');
  set priority(String? value) => setField<String>('priority', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get assignedToId => getField<String>('assigned_to_id');
  set assignedToId(String? value) => setField<String>('assigned_to_id', value);

  List<String> get attachments => getListField<String>('attachments');
  set attachments(List<String>? value) =>
      setListField<String>('attachments', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get resolvedAt => getField<DateTime>('resolved_at');
  set resolvedAt(DateTime? value) => setField<DateTime>('resolved_at', value);
}
