import '../database.dart';

class UsersTable extends SupabaseTable<UsersRow> {
  @override
  String get tableName => 'users';

  @override
  UsersRow createRow(Map<String, dynamic> data) => UsersRow(data);
}

class UsersRow extends SupabaseDataRow {
  UsersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UsersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get firebaseUid => getField<String>('firebase_uid')!;
  set firebaseUid(String value) => setField<String>('firebase_uid', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  DateTime? get dateOfBirth => getField<DateTime>('date_of_birth');
  set dateOfBirth(DateTime? value) =>
      setField<DateTime>('date_of_birth', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get profilePictureUrl => getField<String>('profile_picture_url');
  set profilePictureUrl(String? value) =>
      setField<String>('profile_picture_url', value);

  String? get preferredLanguage => getField<String>('preferred_language');
  set preferredLanguage(String? value) =>
      setField<String>('preferred_language', value);

  String? get timezone => getField<String>('timezone');
  set timezone(String? value) => setField<String>('timezone', value);

  String? get accountStatus => getField<String>('account_status');
  set accountStatus(String? value) => setField<String>('account_status', value);

  String? get fcmToken => getField<String>('fcm_token');
  set fcmToken(String? value) => setField<String>('fcm_token', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  bool? get isVerified => getField<bool>('is_verified');
  set isVerified(bool? value) => setField<bool>('is_verified', value);

  bool? get emailVerified => getField<bool>('email_verified');
  set emailVerified(bool? value) => setField<bool>('email_verified', value);

  bool? get phoneVerified => getField<bool>('phone_verified');
  set phoneVerified(bool? value) => setField<bool>('phone_verified', value);

  bool? get termsAccepted => getField<bool>('terms_accepted');
  set termsAccepted(bool? value) => setField<bool>('terms_accepted', value);

  DateTime? get termsAcceptedAt => getField<DateTime>('terms_accepted_at');
  set termsAcceptedAt(DateTime? value) =>
      setField<DateTime>('terms_accepted_at', value);

  bool? get privacyAccepted => getField<bool>('privacy_accepted');
  set privacyAccepted(bool? value) => setField<bool>('privacy_accepted', value);

  DateTime? get privacyAcceptedAt => getField<DateTime>('privacy_accepted_at');
  set privacyAcceptedAt(DateTime? value) =>
      setField<DateTime>('privacy_accepted_at', value);

  DateTime? get lastLoginAt => getField<DateTime>('last_login_at');
  set lastLoginAt(DateTime? value) =>
      setField<DateTime>('last_login_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

  String? get middleName => getField<String>('middle_name');
  set middleName(String? value) => setField<String>('middle_name', value);

  bool? get bloodDonation => getField<bool>('blood_donation');
  set bloodDonation(bool? value) => setField<bool>('blood_donation', value);

  String? get country => getField<String>('country');
  set country(String? value) => setField<String>('country', value);

  DateTime? get lastSeenAt => getField<DateTime>('last_seen_at');
  set lastSeenAt(DateTime? value) => setField<DateTime>('last_seen_at', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  String? get uniquePatientId => getField<String>('unique_patient_id');
  set uniquePatientId(String? value) =>
      setField<String>('unique_patient_id', value);

  String? get secondaryPhone => getField<String>('secondary_phone');
  set secondaryPhone(String? value) =>
      setField<String>('secondary_phone', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get deviceType => getField<String>('device_type');
  set deviceType(String? value) => setField<String>('device_type', value);

  String? get activeDeviceId => getField<String>('active_device_id');
  set activeDeviceId(String? value) =>
      setField<String>('active_device_id', value);

  String? get activeSessionToken => getField<String>('active_session_token');
  set activeSessionToken(String? value) =>
      setField<String>('active_session_token', value);

  String? get ehrId => getField<String>('ehr_id');
  set ehrId(String? value) => setField<String>('ehr_id', value);
}
