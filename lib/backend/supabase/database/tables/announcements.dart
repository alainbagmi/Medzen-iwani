import '../database.dart';

class AnnouncementsTable extends SupabaseTable<AnnouncementsRow> {
  @override
  String get tableName => 'announcements';

  @override
  AnnouncementsRow createRow(Map<String, dynamic> data) =>
      AnnouncementsRow(data);
}

class AnnouncementsRow extends SupabaseDataRow {
  AnnouncementsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnnouncementsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get createdById => getField<String>('created_by_id');
  set createdById(String? value) => setField<String>('created_by_id', value);

  String? get announcementType => getField<String>('announcement_type');
  set announcementType(String? value) =>
      setField<String>('announcement_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  String? get priority => getField<String>('priority');
  set priority(String? value) => setField<String>('priority', value);

  List<String> get targetAudience => getListField<String>('target_audience');
  set targetAudience(List<String>? value) =>
      setListField<String>('target_audience', value);

  List<String> get targetUserIds => getListField<String>('target_user_ids');
  set targetUserIds(List<String>? value) =>
      setListField<String>('target_user_ids', value);

  List<String> get displayLocations =>
      getListField<String>('display_locations');
  set displayLocations(List<String>? value) =>
      setListField<String>('display_locations', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  bool? get isDismissible => getField<bool>('is_dismissible');
  set isDismissible(bool? value) => setField<bool>('is_dismissible', value);

  String? get actionUrl => getField<String>('action_url');
  set actionUrl(String? value) => setField<String>('action_url', value);

  String? get actionLabel => getField<String>('action_label');
  set actionLabel(String? value) => setField<String>('action_label', value);

  String? get icon => getField<String>('icon');
  set icon(String? value) => setField<String>('icon', value);

  String? get color => getField<String>('color');
  set color(String? value) => setField<String>('color', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
