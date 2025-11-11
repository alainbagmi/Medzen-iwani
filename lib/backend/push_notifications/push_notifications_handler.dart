import 'dart:async';
import 'dart:convert';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../index.dart';
import '../../main.dart';

final _handledMessageIds = <String?>{};

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  _PushNotificationsHandlerState createState() =>
      _PushNotificationsHandlerState();
}

class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  bool _loading = false;

  Future handleOpenedPushNotification() async {
    if (isWeb) {
      return;
    }

    final notification = await FirebaseMessaging.instance.getInitialMessage();
    if (notification != null) {
      await _handlePushNotification(notification);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotification);
  }

  Future _handlePushNotification(RemoteMessage message) async {
    if (_handledMessageIds.contains(message.messageId)) {
      return;
    }
    _handledMessageIds.add(message.messageId);

    safeSetState(() => _loading = true);
    try {
      final initialPageName = message.data['initialPageName'] as String;
      final initialParameterData = getInitialParameterData(message.data);
      final parametersBuilder = parametersBuilderMap[initialPageName];
      if (parametersBuilder != null) {
        final parameterData = await parametersBuilder(initialParameterData);
        if (mounted) {
          context.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        } else {
          appNavigatorKey.currentContext?.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      safeSetState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      handleOpenedPushNotification();
    });
  }

  @override
  Widget build(BuildContext context) => _loading
      ? Container(
          color: Colors.transparent,
          child: Image.asset(
            'assets/images/medzen.logo.png',
            fit: BoxFit.contain,
          ),
        )
      : widget.child;
}

class ParameterData {
  const ParameterData(
      {this.requiredParams = const {}, this.allParams = const {}});
  final Map<String, String?> requiredParams;
  final Map<String, dynamic> allParams;

  Map<String, String> get pathParameters => Map.fromEntries(
        requiredParams.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
  Map<String, dynamic> get extra => Map.fromEntries(
        allParams.entries.where((e) => e.value != null),
      );

  static Future<ParameterData> Function(Map<String, dynamic>) none() =>
      (data) async => ParameterData();
}

final parametersBuilderMap =
    <String, Future<ParameterData> Function(Map<String, dynamic>)>{
  'Provider_confirmation_page': ParameterData.none(),
  'videoCall': ParameterData.none(),
  'JoinCall': ParameterData.none(),
  'provider_landing_page': ParameterData.none(),
  'Role_page': ParameterData.none(),
  'PatientAccountCreation': ParameterData.none(),
  'systemAdminLanding_page': ParameterData.none(),
  'facilityAdminLanding_page': ParameterData.none(),
  'PatientProfile_page': (data) async => ParameterData(
        allParams: {
          'patientAuthUser': getParameter<String>(data, 'patientAuthUser'),
        },
      ),
  'HomePage': ParameterData.none(),
  'Features': ParameterData.none(),
  'AboutUs': ParameterData.none(),
  'SplashScreen': ParameterData.none(),
  'Publications': ParameterData.none(),
  'facilityStatusPage': ParameterData.none(),
  'systemAdminAccountCreation': ParameterData.none(),
  'FacilityAdminAccountCreation': ParameterData.none(),
  'admin_patientStatusPage': ParameterData.none(),
  'appoitmentStatusPage': ParameterData.none(),
  'providerStatusPage': ParameterData.none(),
  'PaymentStatusPage': ParameterData.none(),
  'facilityDetailsPage': ParameterData.none(),
  'patient_landing_page': ParameterData.none(),
  'Appointments': (data) async => ParameterData(
        allParams: {
          'username': getParameter<String>(data, 'username'),
          'usernumber': getParameter<String>(data, 'usernumber'),
          'avatarUrl': getParameter<String>(data, 'avatarUrl'),
        },
      ),
  'FacilityRegistrationPage': (data) async => ParameterData(
        allParams: {
          'departmentsChosen': getParameter<String>(data, 'departmentsChosen'),
        },
      ),
  'AdminStatusPage': ParameterData.none(),
  'TermsAndCOnditionsPage': ParameterData.none(),
  'PaymentHistory': (data) async => ParameterData(
        allParams: {
          'username': getParameter<String>(data, 'username'),
          'userNumber': getParameter<String>(data, 'userNumber'),
          'avatar': getParameter<String>(data, 'avatar'),
        },
      ),
  'MedicalPractitioners': ParameterData.none(),
  'PractionerDetail': (data) async => ParameterData(
        allParams: {
          'providerid': getParameter<String>(data, 'providerid'),
        },
      ),
  'facilitySearchPage': ParameterData.none(),
  'PatientsNotificationsPage': ParameterData.none(),
  'ProviderProfile_page': ParameterData.none(),
  'PatientsMedicationPage': ParameterData.none(),
  'Patient_Diagnostics': ParameterData.none(),
  'Admin_PatientsAdminEditPage': ParameterData.none(),
  'FacilitySettingsPage': ParameterData.none(),
  'signIn': ParameterData.none(),
  'patientsSettingsPage': ParameterData.none(),
  'facilityAdminSettingsPage': ParameterData.none(),
  'ProviderSettingsPage': ParameterData.none(),
  'systemAdmin_settings_Page': ParameterData.none(),
  'ProviderNotificationsPage': ParameterData.none(),
  'facilityNotificationsPage': ParameterData.none(),
  'SystemAdminNotificationsPage': ParameterData.none(),
  'systemAdminProfilePage': (data) async => ParameterData(
        allParams: {
          'patientAuthUser': getParameter<String>(data, 'patientAuthUser'),
        },
      ),
  'facilityAdminProfilePage': (data) async => ParameterData(
        allParams: {
          'patientAuthUser': getParameter<String>(data, 'patientAuthUser'),
        },
      ),
  'ProvidersDocumentPage': ParameterData.none(),
  'PatientsDocumentPage': ParameterData.none(),
  'ProviderAccountCreation': (data) async => ParameterData(
        allParams: {
          'eMCPhone': getParameter<String>(data, 'eMCPhone'),
        },
      ),
  'FacilityAdminDocumentPage': ParameterData.none(),
  'SystAdminDocumentPage': ParameterData.none(),
  'systAdminPaymentPage': ParameterData.none(),
  'facilityAdminPaymentPage': ParameterData.none(),
  'providersWallet': ParameterData.none(),
  'availability': ParameterData.none(),
};

Map<String, dynamic> getInitialParameterData(Map<String, dynamic> data) {
  try {
    final parameterDataStr = data['parameterData'];
    if (parameterDataStr == null ||
        parameterDataStr is! String ||
        parameterDataStr.isEmpty) {
      return {};
    }
    return jsonDecode(parameterDataStr) as Map<String, dynamic>;
  } catch (e) {
    print('Error parsing parameter data: $e');
    return {};
  }
}
