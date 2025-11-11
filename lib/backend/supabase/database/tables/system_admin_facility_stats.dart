import '../database.dart';

class SystemAdminFacilityStatsTable
    extends SupabaseTable<SystemAdminFacilityStatsRow> {
  @override
  String get tableName => 'system_admin_facility_stats';

  @override
  SystemAdminFacilityStatsRow createRow(Map<String, dynamic> data) =>
      SystemAdminFacilityStatsRow(data);
}

class SystemAdminFacilityStatsRow extends SupabaseDataRow {
  SystemAdminFacilityStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemAdminFacilityStatsTable();

  int? get totalFacilities => getField<int>('total_facilities');
  set totalFacilities(int? value) => setField<int>('total_facilities', value);

  int? get activeFacilities => getField<int>('active_facilities');
  set activeFacilities(int? value) => setField<int>('active_facilities', value);

  int? get inactiveFacilities => getField<int>('inactive_facilities');
  set inactiveFacilities(int? value) =>
      setField<int>('inactive_facilities', value);

  int? get facilitiesAddedLast30Days =>
      getField<int>('facilities_added_last_30_days');
  set facilitiesAddedLast30Days(int? value) =>
      setField<int>('facilities_added_last_30_days', value);

  int? get hospitals => getField<int>('hospitals');
  set hospitals(int? value) => setField<int>('hospitals', value);

  int? get clinics => getField<int>('clinics');
  set clinics(int? value) => setField<int>('clinics', value);

  int? get pharmacies => getField<int>('pharmacies');
  set pharmacies(int? value) => setField<int>('pharmacies', value);

  int? get laboratories => getField<int>('laboratories');
  set laboratories(int? value) => setField<int>('laboratories', value);

  int? get facilitiesWithEmergencyServices =>
      getField<int>('facilities_with_emergency_services');
  set facilitiesWithEmergencyServices(int? value) =>
      setField<int>('facilities_with_emergency_services', value);

  int? get totalBedCapacity => getField<int>('total_bed_capacity');
  set totalBedCapacity(int? value) =>
      setField<int>('total_bed_capacity', value);
}
