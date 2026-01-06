import 'dart:convert';
import 'package:flutter/services.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFDevEnvironmentValues {
  static const String currentEnvironment = 'Production';
  static const String environmentValuesPath =
      'assets/environment_values/environment.json';

  static final FFDevEnvironmentValues _instance =
      FFDevEnvironmentValues._internal();

  factory FFDevEnvironmentValues() {
    return _instance;
  }

  FFDevEnvironmentValues._internal();

  Future<void> initialize() async {
    try {
      final String response =
          await rootBundle.loadString(environmentValuesPath);
      final data = await json.decode(response);
      _SupaBaseURL = data['SupaBaseURL'];
      _Supabasekey = data['Supabasekey'];
      _PaymentApi = data['PaymentApi'];
      _PaypentAPIKey = data['PaypentAPIKey'];
      _PaymentUser = data['PaymentUser'];
      _PUBaseUrl = data['PUBaseUrl'];
      _PUMode = data['PUMode'];
      _PUApiKey = data['PUApiKey'];
      _PUAuth = data['PUAuth'];
      _SupaBaseAPIBaseUrl = data['SupaBaseAPIBaseUrl'];
      _SupabaseRestAPIBaseUrl = data['SupabaseRestAPIBaseUrl'];
      _AwsSmsApiUrl = data['AwsSmsApiUrl'];
      _AwsSmsApiKey = data['AwsSmsApiKey'];
      _AWSOtpsendurl = data['AWSOtpsendurl'];
      _AWSOtpsendApiKey = data['AWSOtpsendApiKey'];
      _AWSOtpVerifyurl = data['AWSOtpVerifyurl'];
      _AWSOtpVerifyApiKey = data['AWSOtpVerifyApiKey'];
      _AWSResetPwdurl = data['AWSResetPwdurl'];
      _AWSResetPwdKey = data['AWSResetPwdKey'];
    } catch (e) {
      print('Error loading environment values: $e');
    }
  }

  String _SupaBaseURL = '';
  String get SupaBaseURL => _SupaBaseURL;

  String _Supabasekey = '';
  String get Supabasekey => _Supabasekey;

  String _PaymentApi = '';
  String get PaymentApi => _PaymentApi;

  String _PaypentAPIKey = '';
  String get PaypentAPIKey => _PaypentAPIKey;

  String _PaymentUser = '';
  String get PaymentUser => _PaymentUser;

  String _PUBaseUrl = '';
  String get PUBaseUrl => _PUBaseUrl;

  String _PUMode = '';
  String get PUMode => _PUMode;

  String _PUApiKey = '';
  String get PUApiKey => _PUApiKey;

  String _PUAuth = '';
  String get PUAuth => _PUAuth;

  String _SupaBaseAPIBaseUrl = '';
  String get SupaBaseAPIBaseUrl => _SupaBaseAPIBaseUrl;

  String _SupabaseRestAPIBaseUrl = '';
  String get SupabaseRestAPIBaseUrl => _SupabaseRestAPIBaseUrl;

  String _AwsSmsApiUrl = '';
  String get AwsSmsApiUrl => _AwsSmsApiUrl;

  String _AwsSmsApiKey = '';
  String get AwsSmsApiKey => _AwsSmsApiKey;

  String _AWSOtpsendurl = '';
  String get AWSOtpsendurl => _AWSOtpsendurl;

  String _AWSOtpsendApiKey = '';
  String get AWSOtpsendApiKey => _AWSOtpsendApiKey;

  String _AWSOtpVerifyurl = '';
  String get AWSOtpVerifyurl => _AWSOtpVerifyurl;

  String _AWSOtpVerifyApiKey = '';
  String get AWSOtpVerifyApiKey => _AWSOtpVerifyApiKey;

  String _AWSResetPwdurl = '';
  String get AWSResetPwdurl => _AWSResetPwdurl;

  String _AWSResetPwdKey = '';
  String get AWSResetPwdKey => _AWSResetPwdKey;
}
