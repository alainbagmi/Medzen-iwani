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
