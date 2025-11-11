import '../database.dart';

class NotificationPreferencesTable
    extends SupabaseTable<NotificationPreferencesRow> {
  @override
  String get tableName => 'notification_preferences';

  @override
  NotificationPreferencesRow createRow(Map<String, dynamic> data) =>
      NotificationPreferencesRow(data);
}

class NotificationPreferencesRow extends SupabaseDataRow {
  NotificationPreferencesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NotificationPreferencesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get channel => getField<String>('channel');
  set channel(String? value) => setField<String>('channel', value);

  String get notificationType => getField<String>('notification_type')!;
  set notificationType(String value) =>
      setField<String>('notification_type', value);

  bool? get isEnabled => getField<bool>('is_enabled');
  set isEnabled(bool? value) => setField<bool>('is_enabled', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
