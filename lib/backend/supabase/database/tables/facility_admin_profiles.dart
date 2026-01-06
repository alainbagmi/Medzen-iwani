import '../database.dart';

class FacilityAdminProfilesTable
    extends SupabaseTable<FacilityAdminProfilesRow> {
  @override
  String get tableName => 'facility_admin_profiles';

  @override
  FacilityAdminProfilesRow createRow(Map<String, dynamic> data) =>
      FacilityAdminProfilesRow(data);
}

class FacilityAdminProfilesRow extends SupabaseDataRow {
  FacilityAdminProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FacilityAdminProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get adminNumber => getField<String>('admin_number')!;
  set adminNumber(String value) => setField<String>('admin_number', value);

  List<String> get managedFacilities =>
      getListField<String>('managed_facilities');
  set managedFacilities(List<String>? value) =>
      setListField<String>('managed_facilities', value);

  String? get facilityAdminLevel => getField<String>('facility_admin_level');
  set facilityAdminLevel(String? value) =>
      setField<String>('facility_admin_level', value);

  String get positionTitle => getField<String>('position_title')!;
  set positionTitle(String value) => setField<String>('position_title', value);

  String? get department => getField<String>('department');
  set department(String? value) => setField<String>('department', value);

  String? get employeeId => getField<String>('employee_id');
  set employeeId(String? value) => setField<String>('employee_id', value);

  DateTime get hireDate => getField<DateTime>('hire_date')!;
  set hireDate(DateTime value) => setField<DateTime>('hire_date', value);

  String? get reportingManagerId => getField<String>('reporting_manager_id');
  set reportingManagerId(String? value) =>
      setField<String>('reporting_manager_id', value);

  bool? get canManageStaff => getField<bool>('can_manage_staff');
  set canManageStaff(bool? value) => setField<bool>('can_manage_staff', value);

  bool? get canManageSchedules => getField<bool>('can_manage_schedules');
  set canManageSchedules(bool? value) =>
      setField<bool>('can_manage_schedules', value);

  bool? get canViewReports => getField<bool>('can_view_reports');
  set canViewReports(bool? value) => setField<bool>('can_view_reports', value);

  bool? get canManageInventory => getField<bool>('can_manage_inventory');
  set canManageInventory(bool? value) =>
      setField<bool>('can_manage_inventory', value);

  bool? get canApproveExpenses => getField<bool>('can_approve_expenses');
  set canApproveExpenses(bool? value) =>
      setField<bool>('can_approve_expenses', value);

  bool? get canManageBilling => getField<bool>('can_manage_billing');
  set canManageBilling(bool? value) =>
      setField<bool>('can_manage_billing', value);

  double? get budgetAuthorityLimit =>
      getField<double>('budget_authority_limit');
  set budgetAuthorityLimit(double? value) =>
      setField<double>('budget_authority_limit', value);

  double? get expenseApprovalLimit =>
      getField<double>('expense_approval_limit');
  set expenseApprovalLimit(double? value) =>
      setField<double>('expense_approval_limit', value);

  String? get workPhone => getField<String>('work_phone');
  set workPhone(String? value) => setField<String>('work_phone', value);

  String? get workEmail => getField<String>('work_email');
  set workEmail(String? value) => setField<String>('work_email', value);

  String? get officeLocation => getField<String>('office_location');
  set officeLocation(String? value) =>
      setField<String>('office_location', value);

  String? get workAddress => getField<String>('work_address');
  set workAddress(String? value) => setField<String>('work_address', value);

  List<String> get educationBackground =>
      getListField<String>('education_background');
  set educationBackground(List<String>? value) =>
      setListField<String>('education_background', value);

  List<String> get certifications => getListField<String>('certifications');
  set certifications(List<String>? value) =>
      setListField<String>('certifications', value);

  List<String> get trainingCompleted =>
      getListField<String>('training_completed');
  set trainingCompleted(List<String>? value) =>
      setListField<String>('training_completed', value);

  List<String> get licenseNumbers => getListField<String>('license_numbers');
  set licenseNumbers(List<String>? value) =>
      setListField<String>('license_numbers', value);

  int? get facilitiesUnderManagement =>
      getField<int>('facilities_under_management');
  set facilitiesUnderManagement(int? value) =>
      setField<int>('facilities_under_management', value);

  int? get staffUnderManagement => getField<int>('staff_under_management');
  set staffUnderManagement(int? value) =>
      setField<int>('staff_under_management', value);

  double? get patientSatisfactionAvg =>
      getField<double>('patient_satisfaction_avg');
  set patientSatisfactionAvg(double? value) =>
      setField<double>('patient_satisfaction_avg', value);

  double? get operationalEfficiencyScore =>
      getField<double>('operational_efficiency_score');
  set operationalEfficiencyScore(double? value) =>
      setField<double>('operational_efficiency_score', value);

  int? get totalStaffMeetingsConducted =>
      getField<int>('total_staff_meetings_conducted');
  set totalStaffMeetingsConducted(int? value) =>
      setField<int>('total_staff_meetings_conducted', value);

  int? get totalReportsGenerated => getField<int>('total_reports_generated');
  set totalReportsGenerated(int? value) =>
      setField<int>('total_reports_generated', value);

  DateTime? get lastFacilityVisit => getField<DateTime>('last_facility_visit');
  set lastFacilityVisit(DateTime? value) =>
      setField<DateTime>('last_facility_visit', value);

  dynamic? get workingHours => getField<dynamic>('working_hours');
  set workingHours(dynamic? value) => setField<dynamic>('working_hours', value);

  dynamic? get onCallAvailability => getField<dynamic>('on_call_availability');
  set onCallAvailability(dynamic? value) =>
      setField<dynamic>('on_call_availability', value);

  int? get vacationDaysRemaining => getField<int>('vacation_days_remaining');
  set vacationDaysRemaining(int? value) =>
      setField<int>('vacation_days_remaining', value);

  String? get accessLevel => getField<String>('access_level');
  set accessLevel(String? value) => setField<String>('access_level', value);

  bool? get twoFactorEnabled => getField<bool>('two_factor_enabled');
  set twoFactorEnabled(bool? value) =>
      setField<bool>('two_factor_enabled', value);

  int? get failedLoginAttempts => getField<int>('failed_login_attempts');
  set failedLoginAttempts(int? value) =>
      setField<int>('failed_login_attempts', value);

  DateTime? get lastLoginAt => getField<DateTime>('last_login_at');
  set lastLoginAt(DateTime? value) =>
      setField<DateTime>('last_login_at', value);

  bool? get hipaaTrainingCompleted =>
      getField<bool>('hipaa_training_completed');
  set hipaaTrainingCompleted(bool? value) =>
      setField<bool>('hipaa_training_completed', value);

  DateTime? get hipaaTrainingDate => getField<DateTime>('hipaa_training_date');
  set hipaaTrainingDate(DateTime? value) =>
      setField<DateTime>('hipaa_training_date', value);

  bool? get safetyTrainingCompleted =>
      getField<bool>('safety_training_completed');
  set safetyTrainingCompleted(bool? value) =>
      setField<bool>('safety_training_completed', value);

  DateTime? get safetyTrainingDate =>
      getField<DateTime>('safety_training_date');
  set safetyTrainingDate(DateTime? value) =>
      setField<DateTime>('safety_training_date', value);

  bool? get confidentialityAgreementSigned =>
      getField<bool>('confidentiality_agreement_signed');
  set confidentialityAgreementSigned(bool? value) =>
      setField<bool>('confidentiality_agreement_signed', value);

  DateTime? get confidentialityAgreementDate =>
      getField<DateTime>('confidentiality_agreement_date');
  set confidentialityAgreementDate(DateTime? value) =>
      setField<DateTime>('confidentiality_agreement_date', value);

  dynamic? get notificationPreferences =>
      getField<dynamic>('notification_preferences');
  set notificationPreferences(dynamic? value) =>
      setField<dynamic>('notification_preferences', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  String? get applicationStatus => getField<String>('application_status');
  set applicationStatus(String? value) =>
      setField<String>('application_status', value);

  String? get rejectionReason => getField<String>('rejection_reason');
  set rejectionReason(String? value) =>
      setField<String>('rejection_reason', value);

  String? get primaryFacilityId => getField<String>('primary_facility_id');
  set primaryFacilityId(String? value) =>
      setField<String>('primary_facility_id', value);
}
