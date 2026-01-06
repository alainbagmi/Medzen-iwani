import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'dart:math' as math;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'patient_account_creation_widget.dart' show PatientAccountCreationWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PatientAccountCreationModel
    extends FlutterFlowModel<PatientAccountCreationWidget> {
  ///  Local state fields for this page.

  String? patientPhoneNumber;

  String? patientCountryCode;

  String? eMCPhoneNumber;

  String? eMCCountryCode;

  ///  State fields for stateful widgets in this page.

  final formKey3 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
  // State field(s) for Role widget.
  FocusNode? roleFocusNode;
  TextEditingController? roleTextController;
  String? Function(BuildContext, String?)? roleTextControllerValidator;
  String? _roleTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'cpmvgs1a' /* First Name is required */,
      );
    }

    return null;
  }

  // State field(s) for pickLanguage widget.
  String? pickLanguageValue;
  FormFieldController<String>? pickLanguageValueController;
  // State field(s) for PreferedLanguage widget.
  FocusNode? preferedLanguageFocusNode;
  TextEditingController? preferedLanguageTextController;
  String? Function(BuildContext, String?)?
      preferedLanguageTextControllerValidator;
  // State field(s) for FirstName widget.
  FocusNode? firstNameFocusNode;
  TextEditingController? firstNameTextController;
  String? Function(BuildContext, String?)? firstNameTextControllerValidator;
  // State field(s) for MiddleName widget.
  FocusNode? middleNameFocusNode;
  TextEditingController? middleNameTextController;
  String? Function(BuildContext, String?)? middleNameTextControllerValidator;
  // State field(s) for LastName widget.
  FocusNode? lastNameFocusNode;
  TextEditingController? lastNameTextController;
  String? Function(BuildContext, String?)? lastNameTextControllerValidator;
  String? _lastNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'cagmk1lf' /* Last Name is required */,
      );
    }

    return null;
  }

  // State field(s) for PatientDateOfBirth widget.
  FocusNode? patientDateOfBirthFocusNode;
  TextEditingController? patientDateOfBirthTextController;
  String? Function(BuildContext, String?)?
      patientDateOfBirthTextControllerValidator;
  String? _patientDateOfBirthTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'i5enjk7g' /* Date Of Birth is required */,
      );
    }

    return null;
  }

  DateTime? datePicked1;
  // State field(s) for PatientIDCARDNUm widget.
  FocusNode? patientIDCARDNUmFocusNode;
  TextEditingController? patientIDCARDNUmTextController;
  String? Function(BuildContext, String?)?
      patientIDCARDNUmTextControllerValidator;
  String? _patientIDCARDNUmTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '3dqlo2ie' /* ID Card Number Is Required */,
      );
    }

    return null;
  }

  // State field(s) for PatientIDCARDDATEOFISSUE widget.
  FocusNode? patientIDCARDDATEOFISSUEFocusNode;
  TextEditingController? patientIDCARDDATEOFISSUETextController;
  String? Function(BuildContext, String?)?
      patientIDCARDDATEOFISSUETextControllerValidator;
  String? _patientIDCARDDATEOFISSUETextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'etg8ce3u' /* ID CARD DATE OF ISSUE is requi... */,
      );
    }

    return null;
  }

  DateTime? datePicked2;
  // State field(s) for PatientIDCARDDATEOFEXPIRATION widget.
  FocusNode? patientIDCARDDATEOFEXPIRATIONFocusNode;
  TextEditingController? patientIDCARDDATEOFEXPIRATIONTextController;
  String? Function(BuildContext, String?)?
      patientIDCARDDATEOFEXPIRATIONTextControllerValidator;
  String? _patientIDCARDDATEOFEXPIRATIONTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'bf8gux43' /* ID CARD DATE OF EXPIRATION is ... */,
      );
    }

    return null;
  }

  DateTime? datePicked3;
  // State field(s) for SelectGender widget.
  FocusNode? selectGenderFocusNode;
  TextEditingController? selectGenderTextController;
  String? Function(BuildContext, String?)? selectGenderTextControllerValidator;
  String? _selectGenderTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'dx9d0slv' /* Select Gender is required */,
      );
    }

    return null;
  }

  // State field(s) for GenderChoice widget.
  FormFieldController<List<String>>? genderChoiceValueController;
  String? get genderChoiceValue =>
      genderChoiceValueController?.value?.firstOrNull;
  set genderChoiceValue(String? val) =>
      genderChoiceValueController?.value = val != null ? [val] : [];
  // State field(s) for StreetRue widget.
  FocusNode? streetRueFocusNode;
  TextEditingController? streetRueTextController;
  String? Function(BuildContext, String?)? streetRueTextControllerValidator;
  // State field(s) for City widget.
  FocusNode? cityFocusNode;
  TextEditingController? cityTextController;
  String? Function(BuildContext, String?)? cityTextControllerValidator;
  // State field(s) for Region widget.
  FocusNode? regionFocusNode;
  TextEditingController? regionTextController;
  String? Function(BuildContext, String?)? regionTextControllerValidator;
  // State field(s) for POstalCode widget.
  FocusNode? pOstalCodeFocusNode;
  TextEditingController? pOstalCodeTextController;
  String? Function(BuildContext, String?)? pOstalCodeTextControllerValidator;
  // State field(s) for InsuranceProvider widget.
  FocusNode? insuranceProviderFocusNode;
  TextEditingController? insuranceProviderTextController;
  String? Function(BuildContext, String?)?
      insuranceProviderTextControllerValidator;
  // State field(s) for PolicyNumber widget.
  FocusNode? policyNumberFocusNode;
  TextEditingController? policyNumberTextController;
  String? Function(BuildContext, String?)? policyNumberTextControllerValidator;
  // State field(s) for GroupNumber widget.
  FocusNode? groupNumberFocusNode;
  TextEditingController? groupNumberTextController;
  String? Function(BuildContext, String?)? groupNumberTextControllerValidator;
  // State field(s) for DonateBlood widget.
  FocusNode? donateBloodFocusNode;
  TextEditingController? donateBloodTextController;
  String? Function(BuildContext, String?)? donateBloodTextControllerValidator;
  // State field(s) for BDonate widget.
  FormFieldController<List<String>>? bDonateValueController;
  String? get bDonateValue => bDonateValueController?.value?.firstOrNull;
  set bDonateValue(String? val) =>
      bDonateValueController?.value = val != null ? [val] : [];
  // State field(s) for EmergencyNames widget.
  FocusNode? emergencyNamesFocusNode;
  TextEditingController? emergencyNamesTextController;
  String? Function(BuildContext, String?)?
      emergencyNamesTextControllerValidator;
  String? _emergencyNamesTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'te6qwqj4' /* Emergency Names is required */,
      );
    }

    return null;
  }

  // State field(s) for SelectRelationship widget.
  String? selectRelationshipValue;
  FormFieldController<String>? selectRelationshipValueController;
  // State field(s) for Relationship widget.
  FocusNode? relationshipFocusNode;
  TextEditingController? relationshipTextController;
  String? Function(BuildContext, String?)? relationshipTextControllerValidator;
  // State field(s) for LogMCPhoneCcode widget.
  FocusNode? logMCPhoneCcodeFocusNode;
  TextEditingController? logMCPhoneCcodeTextController;
  String? Function(BuildContext, String?)?
      logMCPhoneCcodeTextControllerValidator;
  // State field(s) for LogPhoneNumber widget.
  FocusNode? logPhoneNumberFocusNode;
  TextEditingController? logPhoneNumberTextController;
  String? Function(BuildContext, String?)?
      logPhoneNumberTextControllerValidator;
  // State field(s) for Password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  String? _passwordTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'dqw218co' /* Password is required */,
      );
    }

    return null;
  }

  // State field(s) for ConfirmPassword widget.
  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  late bool confirmPasswordVisibility;
  String? Function(BuildContext, String?)?
      confirmPasswordTextControllerValidator;
  String? _confirmPasswordTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'r2pe9e3o' /* Confirm Password is required */,
      );
    }

    return null;
  }

  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UsersRow>? aUthUser;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<PatientProfilesRow>? paprofile;
  // Stores action output result for [Backend Call - API (AWS SMS)] action in Button widget.
  ApiCallResponse? apiResultv2o;

  @override
  void initState(BuildContext context) {
    roleTextControllerValidator = _roleTextControllerValidator;
    lastNameTextControllerValidator = _lastNameTextControllerValidator;
    patientDateOfBirthTextControllerValidator =
        _patientDateOfBirthTextControllerValidator;
    patientIDCARDNUmTextControllerValidator =
        _patientIDCARDNUmTextControllerValidator;
    patientIDCARDDATEOFISSUETextControllerValidator =
        _patientIDCARDDATEOFISSUETextControllerValidator;
    patientIDCARDDATEOFEXPIRATIONTextControllerValidator =
        _patientIDCARDDATEOFEXPIRATIONTextControllerValidator;
    selectGenderTextControllerValidator = _selectGenderTextControllerValidator;
    emergencyNamesTextControllerValidator =
        _emergencyNamesTextControllerValidator;
    passwordVisibility = false;
    passwordTextControllerValidator = _passwordTextControllerValidator;
    confirmPasswordVisibility = false;
    confirmPasswordTextControllerValidator =
        _confirmPasswordTextControllerValidator;
  }

  @override
  void dispose() {
    roleFocusNode?.dispose();
    roleTextController?.dispose();

    preferedLanguageFocusNode?.dispose();
    preferedLanguageTextController?.dispose();

    firstNameFocusNode?.dispose();
    firstNameTextController?.dispose();

    middleNameFocusNode?.dispose();
    middleNameTextController?.dispose();

    lastNameFocusNode?.dispose();
    lastNameTextController?.dispose();

    patientDateOfBirthFocusNode?.dispose();
    patientDateOfBirthTextController?.dispose();

    patientIDCARDNUmFocusNode?.dispose();
    patientIDCARDNUmTextController?.dispose();

    patientIDCARDDATEOFISSUEFocusNode?.dispose();
    patientIDCARDDATEOFISSUETextController?.dispose();

    patientIDCARDDATEOFEXPIRATIONFocusNode?.dispose();
    patientIDCARDDATEOFEXPIRATIONTextController?.dispose();

    selectGenderFocusNode?.dispose();
    selectGenderTextController?.dispose();

    streetRueFocusNode?.dispose();
    streetRueTextController?.dispose();

    cityFocusNode?.dispose();
    cityTextController?.dispose();

    regionFocusNode?.dispose();
    regionTextController?.dispose();

    pOstalCodeFocusNode?.dispose();
    pOstalCodeTextController?.dispose();

    insuranceProviderFocusNode?.dispose();
    insuranceProviderTextController?.dispose();

    policyNumberFocusNode?.dispose();
    policyNumberTextController?.dispose();

    groupNumberFocusNode?.dispose();
    groupNumberTextController?.dispose();

    donateBloodFocusNode?.dispose();
    donateBloodTextController?.dispose();

    emergencyNamesFocusNode?.dispose();
    emergencyNamesTextController?.dispose();

    relationshipFocusNode?.dispose();
    relationshipTextController?.dispose();

    logMCPhoneCcodeFocusNode?.dispose();
    logMCPhoneCcodeTextController?.dispose();

    logPhoneNumberFocusNode?.dispose();
    logPhoneNumberTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
}
