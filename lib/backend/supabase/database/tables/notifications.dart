import '../database.dart';

class NotificationsTable extends SupabaseTable<NotificationsRow> {
  @override
  String get tableName => 'notifications';

  @override
  NotificationsRow createRow(Map<String, dynamic> data) =>
      NotificationsRow(data);
}

class NotificationsRow extends SupabaseDataRow {
  NotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NotificationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get notificationType => getField<String>('notification_type')!;
  set notificationType(String value) =>
      setField<String>('notification_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  String? get actionUrl => getField<String>('action_url');
  set actionUrl(String? value) => setField<String>('action_url', value);

  String? get actionLabel => getField<String>('action_label');
  set actionLabel(String? value) => setField<String>('action_label', value);

  String? get icon => getField<String>('icon');
  set icon(String? value) => setField<String>('icon', value);

  String? get priority => getField<String>('priority');
  set priority(String? value) => setField<String>('priority', value);

  bool? get isRead => getField<bool>('is_read');
  set isRead(bool? value) => setField<bool>('is_read', value);

  DateTime? get readAt => getField<DateTime>('read_at');
  set readAt(DateTime? value) => setField<DateTime>('read_at', value);

  bool? get isArchived => getField<bool>('is_archived');
  set isArchived(bool? value) => setField<bool>('is_archived', value);

  DateTime? get archivedAt => getField<DateTime>('archived_at');
  set archivedAt(DateTime? value) => setField<DateTime>('archived_at', value);

  String? get relatedEntityType => getField<String>('related_entity_type');
  set relatedEntityType(String? value) =>
      setField<String>('related_entity_type', value);

  String? get relatedEntityId => getField<String>('related_entity_id');
  set relatedEntityId(String? value) =>
      setField<String>('related_entity_id', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
