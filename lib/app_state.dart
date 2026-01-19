import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();
    await _safeInitAsync(() async {
      _navOpen = await secureStorage.getBool('ff_navOpen') ?? _navOpen;
    });
    await _safeInitAsync(() async {
      _isDarkMode = await secureStorage.getBool('ff_isDarkMode') ?? _isDarkMode;
    });
    await _safeInitAsync(() async {
      _AppointmentAlerts =
          await secureStorage.getBool('ff_AppointmentAlerts') ??
              _AppointmentAlerts;
    });
    await _safeInitAsync(() async {
      _editAutoRefresh =
          await secureStorage.getBool('ff_editAutoRefresh') ?? _editAutoRefresh;
    });
    await _safeInitAsync(() async {
      _editTwoFactorAuth =
          await secureStorage.getBool('ff_editTwoFactorAuth') ??
              _editTwoFactorAuth;
    });
    await _safeInitAsync(() async {
      _editDataSharing =
          await secureStorage.getBool('ff_editDataSharing') ?? _editDataSharing;
    });
    await _safeInitAsync(() async {
      _editNotificationSounds =
          await secureStorage.getBool('ff_editNotificationSounds') ??
              _editNotificationSounds;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  /// Auth User Role
  String _UserRole = '';
  String get UserRole => _UserRole;
  set UserRole(String value) {
    _UserRole = value;
  }

  String _subscriptionstate = '';
  String get subscriptionstate => _subscriptionstate;
  set subscriptionstate(String value) {
    _subscriptionstate = value;
  }

  String _AuthUserPhone = '';
  String get AuthUserPhone => _AuthUserPhone;
  set AuthUserPhone(String value) {
    _AuthUserPhone = value;
  }

  String _fcmToken = '';
  String get fcmToken => _fcmToken;
  set fcmToken(String value) {
    _fcmToken = value;
  }

  String _DataPlans = '';
  String get DataPlans => _DataPlans;
  set DataPlans(String value) {
    _DataPlans = value;
  }

  String _SubscriptionType = '';
  String get SubscriptionType => _SubscriptionType;
  set SubscriptionType(String value) {
    _SubscriptionType = value;
  }

  String _SelectedRole = '';
  String get SelectedRole => _SelectedRole;
  set SelectedRole(String value) {
    _SelectedRole = value;
  }

  String _AuthUser = '';
  String get AuthUser => _AuthUser;
  set AuthUser(String value) {
    _AuthUser = value;
  }

  String _SupabaseUser = '';
  String get SupabaseUser => _SupabaseUser;
  set SupabaseUser(String value) {
    _SupabaseUser = value;
  }

  bool _navOpen = false;
  bool get navOpen => _navOpen;
  set navOpen(bool value) {
    _navOpen = value;
    secureStorage.setBool('ff_navOpen', value);
  }

  void deleteNavOpen() {
    secureStorage.delete(key: 'ff_navOpen');
  }

  List<String> _Facilitydepartments = [];
  List<String> get Facilitydepartments => _Facilitydepartments;
  set Facilitydepartments(List<String> value) {
    _Facilitydepartments = value;
  }

  void addToFacilitydepartments(String value) {
    Facilitydepartments.add(value);
  }

  void removeFromFacilitydepartments(String value) {
    Facilitydepartments.remove(value);
  }

  void removeAtIndexFromFacilitydepartments(int index) {
    Facilitydepartments.removeAt(index);
  }

  void updateFacilitydepartmentsAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    Facilitydepartments[index] = updateFn(_Facilitydepartments[index]);
  }

  void insertAtIndexInFacilitydepartments(int index, String value) {
    Facilitydepartments.insert(index, value);
  }

  String _AuthuserID = '';
  String get AuthuserID => _AuthuserID;
  set AuthuserID(String value) {
    _AuthuserID = value;
  }

  String _PageUserAuthID = '';
  String get PageUserAuthID => _PageUserAuthID;
  set PageUserAuthID(String value) {
    _PageUserAuthID = value;
  }

  String _eMCPhoneNumber = '';
  String get eMCPhoneNumber => _eMCPhoneNumber;
  set eMCPhoneNumber(String value) {
    _eMCPhoneNumber = value;
  }

  String _providerRejectionReason = '';
  String get providerRejectionReason => _providerRejectionReason;
  set providerRejectionReason(String value) {
    _providerRejectionReason = value;
  }

  String _channelName = '';
  String get channelName => _channelName;
  set channelName(String value) {
    _channelName = value;
  }

  String _profilepic = '';
  String get profilepic => _profilepic;
  set profilepic(String value) {
    _profilepic = value;
  }

  String _FacilityID = '';
  String get FacilityID => _FacilityID;
  set FacilityID(String value) {
    _FacilityID = value;
  }

  String _FacilityPhone = '';
  String get FacilityPhone => _FacilityPhone;
  set FacilityPhone(String value) {
    _FacilityPhone = value;
  }

  String _AdminFacPhone = '';
  String get AdminFacPhone => _AdminFacPhone;
  set AdminFacPhone(String value) {
    _AdminFacPhone = value;
  }

  List<MessageTypeStruct> _messageList = [];
  List<MessageTypeStruct> get messageList => _messageList;
  set messageList(List<MessageTypeStruct> value) {
    _messageList = value;
  }

  void addToMessageList(MessageTypeStruct value) {
    messageList.add(value);
  }

  void removeFromMessageList(MessageTypeStruct value) {
    messageList.remove(value);
  }

  void removeAtIndexFromMessageList(int index) {
    messageList.removeAt(index);
  }

  void updateMessageListAtIndex(
    int index,
    MessageTypeStruct Function(MessageTypeStruct) updateFn,
  ) {
    messageList[index] = updateFn(_messageList[index]);
  }

  void insertAtIndexInMessageList(int index, MessageTypeStruct value) {
    messageList.insert(index, value);
  }

  bool _IsButtonSelected = false;
  bool get IsButtonSelected => _IsButtonSelected;
  set IsButtonSelected(bool value) {
    _IsButtonSelected = value;
  }

  /// Used for all the Search bars
  String _SearchQuery = '';
  String get SearchQuery => _SearchQuery;
  set SearchQuery(String value) {
    _SearchQuery = value;
  }

  String _providerFacility = '';
  String get providerFacility => _providerFacility;
  set providerFacility(String value) {
    _providerFacility = value;
  }

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  set isDarkMode(bool value) {
    _isDarkMode = value;
    secureStorage.setBool('ff_isDarkMode', value);
  }

  void deleteIsDarkMode() {
    secureStorage.delete(key: 'ff_isDarkMode');
  }

  String _streamResponse = '';
  String get streamResponse => _streamResponse;
  set streamResponse(String value) {
    _streamResponse = value;
  }

  /// For editing settings
  String _insuranceProvider = '';
  String get insuranceProvider => _insuranceProvider;
  set insuranceProvider(String value) {
    _insuranceProvider = value;
  }

  /// For editing settings page
  String _insurancePolicyNumber = '';
  String get insurancePolicyNumber => _insurancePolicyNumber;
  set insurancePolicyNumber(String value) {
    _insurancePolicyNumber = value;
  }

  /// For editing settings page
  String _emergencyContactName = '';
  String get emergencyContactName => _emergencyContactName;
  set emergencyContactName(String value) {
    _emergencyContactName = value;
  }

  bool _AppointmentAlerts = false;
  bool get AppointmentAlerts => _AppointmentAlerts;
  set AppointmentAlerts(bool value) {
    _AppointmentAlerts = value;
    secureStorage.setBool('ff_AppointmentAlerts', value);
  }

  void deleteAppointmentAlerts() {
    secureStorage.delete(key: 'ff_AppointmentAlerts');
  }

  bool _editAutoRefresh = false;
  bool get editAutoRefresh => _editAutoRefresh;
  set editAutoRefresh(bool value) {
    _editAutoRefresh = value;
    secureStorage.setBool('ff_editAutoRefresh', value);
  }

  void deleteEditAutoRefresh() {
    secureStorage.delete(key: 'ff_editAutoRefresh');
  }

  bool _editTwoFactorAuth = false;
  bool get editTwoFactorAuth => _editTwoFactorAuth;
  set editTwoFactorAuth(bool value) {
    _editTwoFactorAuth = value;
    secureStorage.setBool('ff_editTwoFactorAuth', value);
  }

  void deleteEditTwoFactorAuth() {
    secureStorage.delete(key: 'ff_editTwoFactorAuth');
  }

  bool _editDataSharing = false;
  bool get editDataSharing => _editDataSharing;
  set editDataSharing(bool value) {
    _editDataSharing = value;
    secureStorage.setBool('ff_editDataSharing', value);
  }

  void deleteEditDataSharing() {
    secureStorage.delete(key: 'ff_editDataSharing');
  }

  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  set hasUnsavedChanges(bool value) {
    _hasUnsavedChanges = value;
  }

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;
  set isUpdatingProfile(bool value) {
    _isUpdatingProfile = value;
  }

  bool _isProfileDataLoaded = false;
  bool get isProfileDataLoaded => _isProfileDataLoaded;
  set isProfileDataLoaded(bool value) {
    _isProfileDataLoaded = value;
  }

  String _emergencyContactRelationship = '';
  String get emergencyContactRelationship => _emergencyContactRelationship;
  set emergencyContactRelationship(String value) {
    _emergencyContactRelationship = value;
  }

  String _editInsuranceProvider = '';
  String get editInsuranceProvider => _editInsuranceProvider;
  set editInsuranceProvider(String value) {
    _editInsuranceProvider = value;
  }

  String _editPolicyNumber = '';
  String get editPolicyNumber => _editPolicyNumber;
  set editPolicyNumber(String value) {
    _editPolicyNumber = value;
  }

  String _editEmergencyName = '';
  String get editEmergencyName => _editEmergencyName;
  set editEmergencyName(String value) {
    _editEmergencyName = value;
  }

  String _editEmergencyRelationship = '';
  String get editEmergencyRelationship => _editEmergencyRelationship;
  set editEmergencyRelationship(String value) {
    _editEmergencyRelationship = value;
  }

  String _editEmergencyPhone = '';
  String get editEmergencyPhone => _editEmergencyPhone;
  set editEmergencyPhone(String value) {
    _editEmergencyPhone = value;
  }

  String _editPhoneNumber = '';
  String get editPhoneNumber => _editPhoneNumber;
  set editPhoneNumber(String value) {
    _editPhoneNumber = value;
  }

  bool _editNotificationSounds = false;
  bool get editNotificationSounds => _editNotificationSounds;
  set editNotificationSounds(bool value) {
    _editNotificationSounds = value;
    secureStorage.setBool('ff_editNotificationSounds', value);
  }

  void deleteEditNotificationSounds() {
    secureStorage.delete(key: 'ff_editNotificationSounds');
  }

  String _editFacilityName = '';
  String get editFacilityName => _editFacilityName;
  set editFacilityName(String value) {
    _editFacilityName = value;
  }

  String _editFacilityWebsite = '';
  String get editFacilityWebsite => _editFacilityWebsite;
  set editFacilityWebsite(String value) {
    _editFacilityWebsite = value;
  }

  String _editFacilityEmail = '';
  String get editFacilityEmail => _editFacilityEmail;
  set editFacilityEmail(String value) {
    _editFacilityEmail = value;
  }

  String _facilityLocation = '';
  String get facilityLocation => _facilityLocation;
  set facilityLocation(String value) {
    _facilityLocation = value;
  }

  String _FacilityDepartments = '';
  String get FacilityDepartments => _FacilityDepartments;
  set FacilityDepartments(String value) {
    _FacilityDepartments = value;
  }

  String _facilityDescription = '';
  String get facilityDescription => _facilityDescription;
  set facilityDescription(String value) {
    _facilityDescription = value;
  }

  String _editconsultationFee = '';
  String get editconsultationFee => _editconsultationFee;
  set editconsultationFee(String value) {
    _editconsultationFee = value;
  }

  String _editFacilityBio = '';
  String get editFacilityBio => _editFacilityBio;
  set editFacilityBio(String value) {
    _editFacilityBio = value;
  }

  /// Checkbox state
  bool _mondayEnabled = false;
  bool get mondayEnabled => _mondayEnabled;
  set mondayEnabled(bool value) {
    _mondayEnabled = value;
  }

  /// Start time
  String _mondayStart = '';
  String get mondayStart => _mondayStart;
  set mondayStart(String value) {
    _mondayStart = value;
  }

  /// End Time
  String _mondayEnd = '';
  String get mondayEnd => _mondayEnd;
  set mondayEnd(String value) {
    _mondayEnd = value;
  }

  String _consultationFees = '';
  String get consultationFees => _consultationFees;
  set consultationFees(String value) {
    _consultationFees = value;
  }

  String _editLicenseNumber = '';
  String get editLicenseNumber => _editLicenseNumber;
  set editLicenseNumber(String value) {
    _editLicenseNumber = value;
  }

  /// Phase 8a: Pre-call context snapshot ID for SOAP generation
  String _lastContextSnapshotId = '';
  String get lastContextSnapshotId => _lastContextSnapshotId;
  set lastContextSnapshotId(String value) {
    _lastContextSnapshotId = value;
  }

  /// Phase 8: Current SOAP encounter ID
  String _currentSoapEncounterId = '';
  String get currentSoapEncounterId => _currentSoapEncounterId;
  set currentSoapEncounterId(String value) {
    _currentSoapEncounterId = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async => (await read(key: key)) == 'true';
  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        return CsvToListConverter()
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });
  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: ListToCsvConverter().convert([value]));
}
