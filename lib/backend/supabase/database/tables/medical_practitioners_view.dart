import '../database.dart';

class MedicalPractitionersViewTable
    extends SupabaseTable<MedicalPractitionersViewRow> {
  @override
  String get tableName => 'medical_practitioners_view';

  @override
  MedicalPractitionersViewRow createRow(Map<String, dynamic> data) =>
      MedicalPractitionersViewRow(data);
}

class MedicalPractitionersViewRow extends SupabaseDataRow {
  MedicalPractitionersViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalPractitionersViewTable();

  String? get providerid => getField<String>('providerid');
  set providerid(String? value) => setField<String>('providerid', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get picture => getField<String>('picture');
  set picture(String? value) => setField<String>('picture', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get specialization => getField<String>('specialization');
  set specialization(String? value) =>
      setField<String>('specialization', value);

  int? get experience => getField<int>('experience');
  set experience(int? value) => setField<int>('experience', value);

  double? get fees => getField<double>('fees');
  set fees(double? value) => setField<double>('fees', value);
}
