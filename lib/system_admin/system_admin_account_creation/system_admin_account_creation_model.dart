import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/components/medzen_header_back/medzen_header_back_widget.dart';
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
import 'system_admin_account_creation_widget.dart'
    show SystemAdminAccountCreationWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SystemAdminAccountCreationModel
    extends FlutterFlowModel<SystemAdminAccountCreationWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();
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
  // State field(s) for picklanguage widget.
  String? picklanguageValue;
  FormFieldController<String>? picklanguageValueController;
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
  // State field(s) for AdminDateOfBirth widget.
  FocusNode? adminDateOfBirthFocusNode;
  TextEditingController? adminDateOfBirthTextController;
  String? Function(BuildContext, String?)?
      adminDateOfBirthTextControllerValidator;
  DateTime? datePicked1;
  // State field(s) for AdminDCARDNUm widget.
  FocusNode? adminDCARDNUmFocusNode;
  TextEditingController? adminDCARDNUmTextController;
  String? Function(BuildContext, String?)? adminDCARDNUmTextControllerValidator;
  // State field(s) for AdminIDCARDDATEOFISSUE widget.
  FocusNode? adminIDCARDDATEOFISSUEFocusNode;
  TextEditingController? adminIDCARDDATEOFISSUETextController;
  String? Function(BuildContext, String?)?
      adminIDCARDDATEOFISSUETextControllerValidator;
  DateTime? datePicked2;
  // State field(s) for AdminIDCARDDATEOFEXPIRATION widget.
  FocusNode? adminIDCARDDATEOFEXPIRATIONFocusNode;
  TextEditingController? adminIDCARDDATEOFEXPIRATIONTextController;
  String? Function(BuildContext, String?)?
      adminIDCARDDATEOFEXPIRATIONTextControllerValidator;
  DateTime? datePicked3;
  // State field(s) for SelectGender widget.
  FocusNode? selectGenderFocusNode;
  TextEditingController? selectGenderTextController;
  String? Function(BuildContext, String?)? selectGenderTextControllerValidator;
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
  // State field(s) for AdminInsuranceProvider widget.
  FocusNode? adminInsuranceProviderFocusNode;
  TextEditingController? adminInsuranceProviderTextController;
  String? Function(BuildContext, String?)?
      adminInsuranceProviderTextControllerValidator;
  // State field(s) for AdminPolicyNumber widget.
  FocusNode? adminPolicyNumberFocusNode;
  TextEditingController? adminPolicyNumberTextController;
  String? Function(BuildContext, String?)?
      adminPolicyNumberTextControllerValidator;
  // State field(s) for AdminGroupNumber widget.
  FocusNode? adminGroupNumberFocusNode;
  TextEditingController? adminGroupNumberTextController;
  String? Function(BuildContext, String?)?
      adminGroupNumberTextControllerValidator;
  // State field(s) for EmergencyNames widget.
  FocusNode? emergencyNamesFocusNode;
  TextEditingController? emergencyNamesTextController;
  String? Function(BuildContext, String?)?
      emergencyNamesTextControllerValidator;
  // State field(s) for SelectRelationship widget.
  String? selectRelationshipValue;
  FormFieldController<String>? selectRelationshipValueController;
  // State field(s) for Relationship widget.
  FocusNode? relationshipFocusNode;
  TextEditingController? relationshipTextController;
  String? Function(BuildContext, String?)? relationshipTextControllerValidator;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UsersRow>? aUthUser;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<SystemAdminProfilesRow>? saprofile;
  // Model for medzen_header_back component.
  late MedzenHeaderBackModel medzenHeaderBackModel;

  @override
  void initState(BuildContext context) {
    medzenHeaderBackModel = createModel(context, () => MedzenHeaderBackModel());
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

    adminDateOfBirthFocusNode?.dispose();
    adminDateOfBirthTextController?.dispose();

    adminDCARDNUmFocusNode?.dispose();
    adminDCARDNUmTextController?.dispose();

    adminIDCARDDATEOFISSUEFocusNode?.dispose();
    adminIDCARDDATEOFISSUETextController?.dispose();

    adminIDCARDDATEOFEXPIRATIONFocusNode?.dispose();
    adminIDCARDDATEOFEXPIRATIONTextController?.dispose();

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

    adminInsuranceProviderFocusNode?.dispose();
    adminInsuranceProviderTextController?.dispose();

    adminPolicyNumberFocusNode?.dispose();
    adminPolicyNumberTextController?.dispose();

    adminGroupNumberFocusNode?.dispose();
    adminGroupNumberTextController?.dispose();

    emergencyNamesFocusNode?.dispose();
    emergencyNamesTextController?.dispose();

    relationshipFocusNode?.dispose();
    relationshipTextController?.dispose();

    medzenHeaderBackModel.dispose();
  }
}
