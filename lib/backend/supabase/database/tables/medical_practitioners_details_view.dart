import '../database.dart';

class MedicalPractitionersDetailsViewTable
    extends SupabaseTable<MedicalPractitionersDetailsViewRow> {
  @override
  String get tableName => 'medical_practitioners_details_view';

  @override
  MedicalPractitionersDetailsViewRow createRow(Map<String, dynamic> data) =>
      MedicalPractitionersDetailsViewRow(data);
}

class MedicalPractitionersDetailsViewRow extends SupabaseDataRow {
  MedicalPractitionersDetailsViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MedicalPractitionersDetailsViewTable();

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

  double? get rating => getField<double>('rating');
  set rating(double? value) => setField<double>('rating', value);

  int? get numberOfConsultations => getField<int>('number_of_consultations');
  set numberOfConsultations(int? value) =>
      setField<int>('number_of_consultations', value);

  String? get providerid => getField<String>('providerid');
  set providerid(String? value) => setField<String>('providerid', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);
}
