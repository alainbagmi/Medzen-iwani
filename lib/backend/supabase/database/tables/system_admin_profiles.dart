import '../database.dart';

class SystemAdminProfilesTable extends SupabaseTable<SystemAdminProfilesRow> {
  @override
  String get tableName => 'system_admin_profiles';

  @override
  SystemAdminProfilesRow createRow(Map<String, dynamic> data) =>
      SystemAdminProfilesRow(data);
}

class SystemAdminProfilesRow extends SupabaseDataRow {
  SystemAdminProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemAdminProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get adminNumber => getField<String>('admin_number')!;
  set adminNumber(String value) => setField<String>('admin_number', value);

  String get adminLevel => getField<String>('admin_level')!;
  set adminLevel(String value) => setField<String>('admin_level', value);

  String? get adminRole => getField<String>('admin_role');
  set adminRole(String? value) => setField<String>('admin_role', value);

  bool? get fullPlatformAccess => getField<bool>('full_platform_access');
  set fullPlatformAccess(bool? value) =>
      setField<bool>('full_platform_access', value);

  bool? get canModifyUsers => getField<bool>('can_modify_users');
  set canModifyUsers(bool? value) => setField<bool>('can_modify_users', value);

  bool? get canModifyFacilities => getField<bool>('can_modify_facilities');
  set canModifyFacilities(bool? value) =>
      setField<bool>('can_modify_facilities', value);

  bool? get canModifyProviders => getField<bool>('can_modify_providers');
  set canModifyProviders(bool? value) =>
      setField<bool>('can_modify_providers', value);

  bool? get canViewAllData => getField<bool>('can_view_all_data');
  set canViewAllData(bool? value) => setField<bool>('can_view_all_data', value);

  bool? get canDeleteData => getField<bool>('can_delete_data');
  set canDeleteData(bool? value) => setField<bool>('can_delete_data', value);

  bool? get canExportData => getField<bool>('can_export_data');
  set canExportData(bool? value) => setField<bool>('can_export_data', value);

  bool? get canManageSystemSettings =>
      getField<bool>('can_manage_system_settings');
  set canManageSystemSettings(bool? value) =>
      setField<bool>('can_manage_system_settings', value);

  bool? get canManageBilling => getField<bool>('can_manage_billing');
  set canManageBilling(bool? value) =>
      setField<bool>('can_manage_billing', value);

  bool? get canAccessFinancialReports =>
      getField<bool>('can_access_financial_reports');
  set canAccessFinancialReports(bool? value) =>
      setField<bool>('can_access_financial_reports', value);

  bool? get canManageIntegrations => getField<bool>('can_manage_integrations');
  set canManageIntegrations(bool? value) =>
      setField<bool>('can_manage_integrations', value);

  bool? get canManageApiKeys => getField<bool>('can_manage_api_keys');
  set canManageApiKeys(bool? value) =>
      setField<bool>('can_manage_api_keys', value);

  bool? get twoFactorRequired => getField<bool>('two_factor_required');
  set twoFactorRequired(bool? value) =>
      setField<bool>('two_factor_required', value);

  List<String> get ipWhitelist => getListField<String>('ip_whitelist');
  set ipWhitelist(List<String>? value) =>
      setListField<String>('ip_whitelist', value);

  List<String> get allowedIpRanges => getListField<String>('allowed_ip_ranges');
  set allowedIpRanges(List<String>? value) =>
      setListField<String>('allowed_ip_ranges', value);

  int? get sessionTimeoutMinutes => getField<int>('session_timeout_minutes');
  set sessionTimeoutMinutes(int? value) =>
      setField<int>('session_timeout_minutes', value);

  int? get requirePasswordChangeDays =>
      getField<int>('require_password_change_days');
  set requirePasswordChangeDays(int? value) =>
      setField<int>('require_password_change_days', value);

  DateTime? get lastAdminAction => getField<DateTime>('last_admin_action');
  set lastAdminAction(DateTime? value) =>
      setField<DateTime>('last_admin_action', value);

  String? get lastAdminActionType => getField<String>('last_admin_action_type');
  set lastAdminActionType(String? value) =>
      setField<String>('last_admin_action_type', value);

  int? get totalAdminActions => getField<int>('total_admin_actions');
  set totalAdminActions(int? value) =>
      setField<int>('total_admin_actions', value);

  int? get totalUsersModified => getField<int>('total_users_modified');
  set totalUsersModified(int? value) =>
      setField<int>('total_users_modified', value);

  int? get totalDataExports => getField<int>('total_data_exports');
  set totalDataExports(int? value) =>
      setField<int>('total_data_exports', value);

  DateTime? get lastLoginAt => getField<DateTime>('last_login_at');
  set lastLoginAt(DateTime? value) =>
      setField<DateTime>('last_login_at', value);

  String? get lastLoginIp => getField<String>('last_login_ip');
  set lastLoginIp(String? value) => setField<String>('last_login_ip', value);

  int? get failedLoginAttempts => getField<int>('failed_login_attempts');
  set failedLoginAttempts(int? value) =>
      setField<int>('failed_login_attempts', value);

  DateTime? get accountLockedUntil =>
      getField<DateTime>('account_locked_until');
  set accountLockedUntil(DateTime? value) =>
      setField<DateTime>('account_locked_until', value);

  String? get securityClearanceLevel =>
      getField<String>('security_clearance_level');
  set securityClearanceLevel(String? value) =>
      setField<String>('security_clearance_level', value);

  bool? get backgroundCheckCompleted =>
      getField<bool>('background_check_completed');
  set backgroundCheckCompleted(bool? value) =>
      setField<bool>('background_check_completed', value);

  DateTime? get backgroundCheckDate =>
      getField<DateTime>('background_check_date');
  set backgroundCheckDate(DateTime? value) =>
      setField<DateTime>('background_check_date', value);

  bool? get dataPrivacyTrainingCompleted =>
      getField<bool>('data_privacy_training_completed');
  set dataPrivacyTrainingCompleted(bool? value) =>
      setField<bool>('data_privacy_training_completed', value);

  DateTime? get dataPrivacyTrainingDate =>
      getField<DateTime>('data_privacy_training_date');
  set dataPrivacyTrainingDate(DateTime? value) =>
      setField<DateTime>('data_privacy_training_date', value);

  bool? get confidentialityAgreementSigned =>
      getField<bool>('confidentiality_agreement_signed');
  set confidentialityAgreementSigned(bool? value) =>
      setField<bool>('confidentiality_agreement_signed', value);

  DateTime? get confidentialityAgreementDate =>
      getField<DateTime>('confidentiality_agreement_date');
  set confidentialityAgreementDate(DateTime? value) =>
      setField<DateTime>('confidentiality_agreement_date', value);

  String? get emergencyContactName =>
      getField<String>('emergency_contact_name');
  set emergencyContactName(String? value) =>
      setField<String>('emergency_contact_name', value);

  String? get emergencyContactPhone =>
      getField<String>('emergency_contact_phone');
  set emergencyContactPhone(String? value) =>
      setField<String>('emergency_contact_phone', value);

  String? get emergencyContactRelationship =>
      getField<String>('emergency_contact_relationship');
  set emergencyContactRelationship(String? value) =>
      setField<String>('emergency_contact_relationship', value);

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
}
