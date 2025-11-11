import '../database.dart';

class AnnouncementReadsTable extends SupabaseTable<AnnouncementReadsRow> {
  @override
  String get tableName => 'announcement_reads';

  @override
  AnnouncementReadsRow createRow(Map<String, dynamic> data) =>
      AnnouncementReadsRow(data);
}

class AnnouncementReadsRow extends SupabaseDataRow {
  AnnouncementReadsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnnouncementReadsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get announcementId => getField<String>('announcement_id');
  set announcementId(String? value) =>
      setField<String>('announcement_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  DateTime? get readAt => getField<DateTime>('read_at');
  set readAt(DateTime? value) => setField<DateTime>('read_at', value);

  DateTime? get dismissedAt => getField<DateTime>('dismissed_at');
  set dismissedAt(DateTime? value) => setField<DateTime>('dismissed_at', value);
}
