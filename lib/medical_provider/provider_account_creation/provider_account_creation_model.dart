import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/components/medzen_landing_header/medzen_landing_header_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'dart:math' as math;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'provider_account_creation_widget.dart'
    show ProviderAccountCreationWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProviderAccountCreationModel
    extends FlutterFlowModel<ProviderAccountCreationWidget> {
  ///  Local state fields for this page.

  String? facilityID;

  double finalConsultationFee = 0.0;

  ///  State fields for stateful widgets in this page.

  final formKey3 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  final formKey4 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
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
  // State field(s) for ProviderDateOfBirth widget.
  FocusNode? providerDateOfBirthFocusNode;
  TextEditingController? providerDateOfBirthTextController;
  String? Function(BuildContext, String?)?
      providerDateOfBirthTextControllerValidator;
  DateTime? datePicked1;
  // State field(s) for ProviderIDCARDNUm widget.
  FocusNode? providerIDCARDNUmFocusNode;
  TextEditingController? providerIDCARDNUmTextController;
  String? Function(BuildContext, String?)?
      providerIDCARDNUmTextControllerValidator;
  // State field(s) for ProviderIDCARDDATEOFISSUE widget.
  FocusNode? providerIDCARDDATEOFISSUEFocusNode;
  TextEditingController? providerIDCARDDATEOFISSUETextController;
  String? Function(BuildContext, String?)?
      providerIDCARDDATEOFISSUETextControllerValidator;
  DateTime? datePicked2;
  // State field(s) for ProviderIDCARDDATEOFEXPIRATION widget.
  FocusNode? providerIDCARDDATEOFEXPIRATIONFocusNode;
  TextEditingController? providerIDCARDDATEOFEXPIRATIONTextController;
  String? Function(BuildContext, String?)?
      providerIDCARDDATEOFEXPIRATIONTextControllerValidator;
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
  FocusNode? regionFocusNode1;
  TextEditingController? regionTextController1;
  String? Function(BuildContext, String?)? regionTextController1Validator;
  // State field(s) for POstalCode widget.
  FocusNode? pOstalCodeFocusNode;
  TextEditingController? pOstalCodeTextController;
  String? Function(BuildContext, String?)? pOstalCodeTextControllerValidator;
  // State field(s) for ProviderInsuranceProvider widget.
  FocusNode? providerInsuranceProviderFocusNode;
  TextEditingController? providerInsuranceProviderTextController;
  String? Function(BuildContext, String?)?
      providerInsuranceProviderTextControllerValidator;
  // State field(s) for ProviderPolicyNumber widget.
  FocusNode? providerPolicyNumberFocusNode;
  TextEditingController? providerPolicyNumberTextController;
  String? Function(BuildContext, String?)?
      providerPolicyNumberTextControllerValidator;
  // State field(s) for ProviderGroupNumber widget.
  FocusNode? providerGroupNumberFocusNode;
  TextEditingController? providerGroupNumberTextController;
  String? Function(BuildContext, String?)?
      providerGroupNumberTextControllerValidator;
  // State field(s) for YearsOFExperince widget.
  FocusNode? yearsOFExperinceFocusNode;
  TextEditingController? yearsOFExperinceTextController;
  String? Function(BuildContext, String?)?
      yearsOFExperinceTextControllerValidator;
  // State field(s) for Bio widget.
  FocusNode? bioFocusNode;
  TextEditingController? bioTextController;
  String? Function(BuildContext, String?)? bioTextControllerValidator;
  bool isDataUploading_uploadDataF3f = false;
  FFUploadedFile uploadedLocalFile_uploadDataF3f =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataF3f = '';

  // State field(s) for consultationFee widget.
  FocusNode? consultationFeeFocusNode;
  TextEditingController? consultationFeeTextController;
  String? Function(BuildContext, String?)?
      consultationFeeTextControllerValidator;
  String? _consultationFeeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'uhnilj23' /* consultation Fee is required */,
      );
    }

    return null;
  }

  // State field(s) for DropDownprovider widget.
  String? dropDownproviderValue;
  FormFieldController<String>? dropDownproviderValueController;
  // State field(s) for ProviderType widget.
  FocusNode? providerTypeFocusNode;
  TextEditingController? providerTypeTextController;
  String? Function(BuildContext, String?)? providerTypeTextControllerValidator;
  String? _providerTypeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'ufjy41as' /* Select Provider Type is requir... */,
      );
    }

    return null;
  }

  // State field(s) for FormSpecialist widget.
  FocusNode? formSpecialistFocusNode;
  TextEditingController? formSpecialistTextController;
  String? Function(BuildContext, String?)?
      formSpecialistTextControllerValidator;
  String? _formSpecialistTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '5nv3to5y' /* Select Specialty Type is requi... */,
      );
    }

    return null;
  }

  // State field(s) for SelectSpecialist widget.
  FormFieldController<List<String>>? selectSpecialistValueController;
  String? get selectSpecialistValue =>
      selectSpecialistValueController?.value?.firstOrNull;
  set selectSpecialistValue(String? val) =>
      selectSpecialistValueController?.value = val != null ? [val] : [];
  // State field(s) for DropSpecialty widget.
  String? dropSpecialtyValue;
  FormFieldController<String>? dropSpecialtyValueController;
  // State field(s) for SpecialtyType widget.
  FocusNode? specialtyTypeFocusNode;
  TextEditingController? specialtyTypeTextController;
  String? Function(BuildContext, String?)? specialtyTypeTextControllerValidator;
  // State field(s) for ProviderLicence widget.
  FocusNode? providerLicenceFocusNode;
  TextEditingController? providerLicenceTextController;
  String? Function(BuildContext, String?)?
      providerLicenceTextControllerValidator;
  // State field(s) for LicenceExpiration widget.
  FocusNode? licenceExpirationFocusNode;
  TextEditingController? licenceExpirationTextController;
  String? Function(BuildContext, String?)?
      licenceExpirationTextControllerValidator;
  DateTime? datePicked4;
  // State field(s) for facilityChoice widget.
  String? facilityChoiceValue;
  FormFieldController<String>? facilityChoiceValueController;
  // State field(s) for facilityChosen widget.
  FocusNode? facilityChosenFocusNode;
  TextEditingController? facilityChosenTextController;
  String? Function(BuildContext, String?)?
      facilityChosenTextControllerValidator;
  // State field(s) for PracticeName widget.
  FocusNode? practiceNameFocusNode;
  TextEditingController? practiceNameTextController;
  String? Function(BuildContext, String?)? practiceNameTextControllerValidator;
  // State field(s) for DropDownpractise widget.
  String? dropDownpractiseValue;
  FormFieldController<String>? dropDownpractiseValueController;
  // State field(s) for PracticeType widget.
  FocusNode? practiceTypeFocusNode;
  TextEditingController? practiceTypeTextController;
  String? Function(BuildContext, String?)? practiceTypeTextControllerValidator;
  // State field(s) for PracticeStreetRue widget.
  FocusNode? practiceStreetRueFocusNode;
  TextEditingController? practiceStreetRueTextController;
  String? Function(BuildContext, String?)?
      practiceStreetRueTextControllerValidator;
  // State field(s) for PracticeCity widget.
  FocusNode? practiceCityFocusNode;
  TextEditingController? practiceCityTextController;
  String? Function(BuildContext, String?)? practiceCityTextControllerValidator;
  // State field(s) for Region widget.
  FocusNode? regionFocusNode2;
  TextEditingController? regionTextController2;
  String? Function(BuildContext, String?)? regionTextController2Validator;
  // State field(s) for PracticePOstalCode widget.
  FocusNode? practicePOstalCodeFocusNode;
  TextEditingController? practicePOstalCodeTextController;
  String? Function(BuildContext, String?)?
      practicePOstalCodeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue1;
  // State field(s) for MonStartTime widget.
  FocusNode? monStartTimeFocusNode;
  TextEditingController? monStartTimeTextController;
  String? Function(BuildContext, String?)? monStartTimeTextControllerValidator;
  // State field(s) for MonEndTime widget.
  FocusNode? monEndTimeFocusNode;
  TextEditingController? monEndTimeTextController;
  String? Function(BuildContext, String?)? monEndTimeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue2;
  // State field(s) for TueStartTime widget.
  FocusNode? tueStartTimeFocusNode;
  TextEditingController? tueStartTimeTextController;
  String? Function(BuildContext, String?)? tueStartTimeTextControllerValidator;
  // State field(s) for TueEndTime widget.
  FocusNode? tueEndTimeFocusNode;
  TextEditingController? tueEndTimeTextController;
  String? Function(BuildContext, String?)? tueEndTimeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue3;
  // State field(s) for WedStartTime widget.
  FocusNode? wedStartTimeFocusNode;
  TextEditingController? wedStartTimeTextController;
  String? Function(BuildContext, String?)? wedStartTimeTextControllerValidator;
  // State field(s) for WedEndTime widget.
  FocusNode? wedEndTimeFocusNode;
  TextEditingController? wedEndTimeTextController;
  String? Function(BuildContext, String?)? wedEndTimeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue4;
  // State field(s) for ThuStartTime widget.
  FocusNode? thuStartTimeFocusNode;
  TextEditingController? thuStartTimeTextController;
  String? Function(BuildContext, String?)? thuStartTimeTextControllerValidator;
  // State field(s) for ThurEndTime widget.
  FocusNode? thurEndTimeFocusNode;
  TextEditingController? thurEndTimeTextController;
  String? Function(BuildContext, String?)? thurEndTimeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue5;
  // State field(s) for FriStartTime widget.
  FocusNode? friStartTimeFocusNode;
  TextEditingController? friStartTimeTextController;
  String? Function(BuildContext, String?)? friStartTimeTextControllerValidator;
  // State field(s) for FriEndTime widget.
  FocusNode? friEndTimeFocusNode;
  TextEditingController? friEndTimeTextController;
  String? Function(BuildContext, String?)? friEndTimeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue6;
  // State field(s) for SatStartTime widget.
  FocusNode? satStartTimeFocusNode;
  TextEditingController? satStartTimeTextController;
  String? Function(BuildContext, String?)? satStartTimeTextControllerValidator;
  // State field(s) for SatEndTime widget.
  FocusNode? satEndTimeFocusNode;
  TextEditingController? satEndTimeTextController;
  String? Function(BuildContext, String?)? satEndTimeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue7;
  // State field(s) for SunStartTime widget.
  FocusNode? sunStartTimeFocusNode;
  TextEditingController? sunStartTimeTextController;
  String? Function(BuildContext, String?)? sunStartTimeTextControllerValidator;
  // State field(s) for SunEndTime widget.
  FocusNode? sunEndTimeFocusNode;
  TextEditingController? sunEndTimeTextController;
  String? Function(BuildContext, String?)? sunEndTimeTextControllerValidator;
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
  List<UsersRow>? lOgged;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<FacilitiesRow>? facid;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MedicalProviderProfilesRow>? mdprofile;
  // Stores action output result for [Backend Call - API (AWS SMS)] action in Button widget.
  ApiCallResponse? apiResult9n5;
  // Model for medzen_landing_header component.
  late MedzenLandingHeaderModel medzenLandingHeaderModel;

  @override
  void initState(BuildContext context) {
    consultationFeeTextControllerValidator =
        _consultationFeeTextControllerValidator;
    providerTypeTextControllerValidator = _providerTypeTextControllerValidator;
    formSpecialistTextControllerValidator =
        _formSpecialistTextControllerValidator;
    medzenLandingHeaderModel =
        createModel(context, () => MedzenLandingHeaderModel());
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

    providerDateOfBirthFocusNode?.dispose();
    providerDateOfBirthTextController?.dispose();

    providerIDCARDNUmFocusNode?.dispose();
    providerIDCARDNUmTextController?.dispose();

    providerIDCARDDATEOFISSUEFocusNode?.dispose();
    providerIDCARDDATEOFISSUETextController?.dispose();

    providerIDCARDDATEOFEXPIRATIONFocusNode?.dispose();
    providerIDCARDDATEOFEXPIRATIONTextController?.dispose();

    selectGenderFocusNode?.dispose();
    selectGenderTextController?.dispose();

    streetRueFocusNode?.dispose();
    streetRueTextController?.dispose();

    cityFocusNode?.dispose();
    cityTextController?.dispose();

    regionFocusNode1?.dispose();
    regionTextController1?.dispose();

    pOstalCodeFocusNode?.dispose();
    pOstalCodeTextController?.dispose();

    providerInsuranceProviderFocusNode?.dispose();
    providerInsuranceProviderTextController?.dispose();

    providerPolicyNumberFocusNode?.dispose();
    providerPolicyNumberTextController?.dispose();

    providerGroupNumberFocusNode?.dispose();
    providerGroupNumberTextController?.dispose();

    yearsOFExperinceFocusNode?.dispose();
    yearsOFExperinceTextController?.dispose();

    bioFocusNode?.dispose();
    bioTextController?.dispose();

    consultationFeeFocusNode?.dispose();
    consultationFeeTextController?.dispose();

    providerTypeFocusNode?.dispose();
    providerTypeTextController?.dispose();

    formSpecialistFocusNode?.dispose();
    formSpecialistTextController?.dispose();

    specialtyTypeFocusNode?.dispose();
    specialtyTypeTextController?.dispose();

    providerLicenceFocusNode?.dispose();
    providerLicenceTextController?.dispose();

    licenceExpirationFocusNode?.dispose();
    licenceExpirationTextController?.dispose();

    facilityChosenFocusNode?.dispose();
    facilityChosenTextController?.dispose();

    practiceNameFocusNode?.dispose();
    practiceNameTextController?.dispose();

    practiceTypeFocusNode?.dispose();
    practiceTypeTextController?.dispose();

    practiceStreetRueFocusNode?.dispose();
    practiceStreetRueTextController?.dispose();

    practiceCityFocusNode?.dispose();
    practiceCityTextController?.dispose();

    regionFocusNode2?.dispose();
    regionTextController2?.dispose();

    practicePOstalCodeFocusNode?.dispose();
    practicePOstalCodeTextController?.dispose();

    monStartTimeFocusNode?.dispose();
    monStartTimeTextController?.dispose();

    monEndTimeFocusNode?.dispose();
    monEndTimeTextController?.dispose();

    tueStartTimeFocusNode?.dispose();
    tueStartTimeTextController?.dispose();

    tueEndTimeFocusNode?.dispose();
    tueEndTimeTextController?.dispose();

    wedStartTimeFocusNode?.dispose();
    wedStartTimeTextController?.dispose();

    wedEndTimeFocusNode?.dispose();
    wedEndTimeTextController?.dispose();

    thuStartTimeFocusNode?.dispose();
    thuStartTimeTextController?.dispose();

    thurEndTimeFocusNode?.dispose();
    thurEndTimeTextController?.dispose();

    friStartTimeFocusNode?.dispose();
    friStartTimeTextController?.dispose();

    friEndTimeFocusNode?.dispose();
    friEndTimeTextController?.dispose();

    satStartTimeFocusNode?.dispose();
    satStartTimeTextController?.dispose();

    satEndTimeFocusNode?.dispose();
    satEndTimeTextController?.dispose();

    sunStartTimeFocusNode?.dispose();
    sunStartTimeTextController?.dispose();

    sunEndTimeFocusNode?.dispose();
    sunEndTimeTextController?.dispose();

    emergencyNamesFocusNode?.dispose();
    emergencyNamesTextController?.dispose();

    relationshipFocusNode?.dispose();
    relationshipTextController?.dispose();

    medzenLandingHeaderModel.dispose();
  }
}
