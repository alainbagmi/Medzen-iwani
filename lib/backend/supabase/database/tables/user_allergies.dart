import '../database.dart';

class UserAllergiesTable extends SupabaseTable<UserAllergiesRow> {
  @override
  String get tableName => 'user_allergies';

  @override
  UserAllergiesRow createRow(Map<String, dynamic> data) =>
      UserAllergiesRow(data);
}

class UserAllergiesRow extends SupabaseDataRow {
  UserAllergiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserAllergiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get allergyId => getField<String>('allergy_id');
  set allergyId(String? value) => setField<String>('allergy_id', value);

  String? get severity => getField<String>('severity');
  set severity(String? value) => setField<String>('severity', value);

  List<String> get reactionSymptoms =>
      getListField<String>('reaction_symptoms');
  set reactionSymptoms(List<String>? value) =>
      setListField<String>('reaction_symptoms', value);

  DateTime? get diagnosedDate => getField<DateTime>('diagnosed_date');
  set diagnosedDate(DateTime? value) =>
      setField<DateTime>('diagnosed_date', value);

  String? get diagnosedById => getField<String>('diagnosed_by_id');
  set diagnosedById(String? value) =>
      setField<String>('diagnosed_by_id', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
