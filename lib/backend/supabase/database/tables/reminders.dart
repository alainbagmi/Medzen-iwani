import '../database.dart';

class RemindersTable extends SupabaseTable<RemindersRow> {
  @override
  String get tableName => 'reminders';

  @override
  RemindersRow createRow(Map<String, dynamic> data) => RemindersRow(data);
}

class RemindersRow extends SupabaseDataRow {
  RemindersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RemindersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get reminderType => getField<String>('reminder_type')!;
  set reminderType(String value) => setField<String>('reminder_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  DateTime get reminderTime => getField<DateTime>('reminder_time')!;
  set reminderTime(DateTime value) =>
      setField<DateTime>('reminder_time', value);

  String? get recurrenceRule => getField<String>('recurrence_rule');
  set recurrenceRule(String? value) =>
      setField<String>('recurrence_rule', value);

  String? get relatedEntityType => getField<String>('related_entity_type');
  set relatedEntityType(String? value) =>
      setField<String>('related_entity_type', value);

  String? get relatedEntityId => getField<String>('related_entity_id');
  set relatedEntityId(String? value) =>
      setField<String>('related_entity_id', value);

  List<String> get notificationChannels =>
      getListField<String>('notification_channels');
  set notificationChannels(List<String>? value) =>
      setListField<String>('notification_channels', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get sentAt => getField<DateTime>('sent_at');
  set sentAt(DateTime? value) => setField<DateTime>('sent_at', value);

  DateTime? get snoozedUntil => getField<DateTime>('snoozed_until');
  set snoozedUntil(DateTime? value) =>
      setField<DateTime>('snoozed_until', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
