import '../database.dart';

class ConsultationNoteDraftsTable
    extends SupabaseTable<ConsultationNoteDraftsRow> {
  @override
  String get tableName => 'consultation_note_drafts';

  @override
  ConsultationNoteDraftsRow createRow(Map<String, dynamic> data) =>
      ConsultationNoteDraftsRow(data);
}

class ConsultationNoteDraftsRow extends SupabaseDataRow {
  ConsultationNoteDraftsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConsultationNoteDraftsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get appointmentId => getField<String>('appointment_id')!;
  set appointmentId(String value) => setField<String>('appointment_id', value);

  String? get sessionId => getField<String>('session_id');
  set sessionId(String? value) => setField<String>('session_id', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  String get source => getField<String>('source')!;
  set source(String value) => setField<String>('source', value);

  String get languageCode => getField<String>('language_code')!;
  set languageCode(String value) => setField<String>('language_code', value);

  String get draftText => getField<String>('draft_text')!;
  set draftText(String value) => setField<String>('draft_text', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime? get submittedAt => getField<DateTime>('submitted_at');
  set submittedAt(DateTime? value) => setField<DateTime>('submitted_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
