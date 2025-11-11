import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/medzen_landing_header/medzen_landing_header_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'facility_registration_page_widget.dart'
    show FacilityRegistrationPageWidget;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FacilityRegistrationPageModel
    extends FlutterFlowModel<FacilityRegistrationPageWidget> {
  ///  Local state fields for this page.

  String? facilityPhoneNumber;

  String? facilityAdminNumber;

  List<String> facilityDepartments = [];
  void addToFacilityDepartments(String item) => facilityDepartments.add(item);
  void removeFromFacilityDepartments(String item) =>
      facilityDepartments.remove(item);
  void removeAtIndexFromFacilityDepartments(int index) =>
      facilityDepartments.removeAt(index);
  void insertAtIndexInFacilityDepartments(int index, String item) =>
      facilityDepartments.insert(index, item);
  void updateFacilityDepartmentsAtIndex(int index, Function(String) updateFn) =>
      facilityDepartments[index] = updateFn(facilityDepartments[index]);

  ///  State fields for stateful widgets in this page.

  final formKey3 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  final formKey4 = GlobalKey<FormState>();
  // Model for medzen_landing_header component.
  late MedzenLandingHeaderModel medzenLandingHeaderModel;
  // State field(s) for ServiceOfferings widget.
  PageController? serviceOfferingsController;

  int get serviceOfferingsCurrentIndex => serviceOfferingsController != null &&
          serviceOfferingsController!.hasClients &&
          serviceOfferingsController!.page != null
      ? serviceOfferingsController!.page!.round()
      : 0;
  // State field(s) for FacilityName widget.
  FocusNode? facilityNameFocusNode;
  TextEditingController? facilityNameTextController;
  String? Function(BuildContext, String?)? facilityNameTextControllerValidator;
  String? _facilityNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'psvmtxuj' /* Facility Name is required */,
      );
    }

    return null;
  }

  // State field(s) for DropDownfacilityType widget.
  String? dropDownfacilityTypeValue;
  FormFieldController<String>? dropDownfacilityTypeValueController;
  // State field(s) for FacilityType widget.
  FocusNode? facilityTypeFocusNode;
  TextEditingController? facilityTypeTextController;
  String? Function(BuildContext, String?)? facilityTypeTextControllerValidator;
  String? _facilityTypeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'wrb2vfae' /* FacilityType is required */,
      );
    }

    return null;
  }

  // State field(s) for Departments widget.
  FormFieldController<List<String>>? departmentsValueController;
  List<String>? get departmentsValues => departmentsValueController?.value;
  set departmentsValues(List<String>? val) =>
      departmentsValueController?.value = val;
  // State field(s) for RegistrationLicenseNumber widget.
  FocusNode? registrationLicenseNumberFocusNode;
  TextEditingController? registrationLicenseNumberTextController;
  String? Function(BuildContext, String?)?
      registrationLicenseNumberTextControllerValidator;
  String? _registrationLicenseNumberTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'jx7ftcou' /* Registration/License Number is... */,
      );
    }

    return null;
  }

  // State field(s) for Yearestablished widget.
  FocusNode? yearestablishedFocusNode;
  TextEditingController? yearestablishedTextController;
  String? Function(BuildContext, String?)?
      yearestablishedTextControllerValidator;
  String? _yearestablishedTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '66dmaa00' /* Year Established is required */,
      );
    }

    return null;
  }

  DateTime? datePicked1;
  // State field(s) for OwnershipType widget.
  FocusNode? ownershipTypeFocusNode;
  TextEditingController? ownershipTypeTextController;
  String? Function(BuildContext, String?)? ownershipTypeTextControllerValidator;
  String? _ownershipTypeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '6dnx54bl' /* Ownership Type is required */,
      );
    }

    return null;
  }

  // State field(s) for EmailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  String? _emailAddressTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'vk6hk4kx' /* Email Address is required */,
      );
    }

    return null;
  }

  // State field(s) for Website widget.
  FocusNode? websiteFocusNode;
  TextEditingController? websiteTextController;
  String? Function(BuildContext, String?)? websiteTextControllerValidator;
  String? _websiteTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '387le0sl' /* Website is required */,
      );
    }

    return null;
  }

  // State field(s) for DescriptionAboutUs widget.
  FocusNode? descriptionAboutUsFocusNode;
  TextEditingController? descriptionAboutUsTextController;
  String? Function(BuildContext, String?)?
      descriptionAboutUsTextControllerValidator;
  String? _descriptionAboutUsTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '2tt5xl19' /* Description/About Us is requir... */,
      );
    }

    return null;
  }

  // State field(s) for StreetAddress widget.
  FocusNode? streetAddressFocusNode;
  TextEditingController? streetAddressTextController;
  String? Function(BuildContext, String?)? streetAddressTextControllerValidator;
  // State field(s) for City widget.
  FocusNode? cityFocusNode;
  TextEditingController? cityTextController;
  String? Function(BuildContext, String?)? cityTextControllerValidator;
  // State field(s) for Region widget.
  FocusNode? regionFocusNode;
  TextEditingController? regionTextController;
  String? Function(BuildContext, String?)? regionTextControllerValidator;
  // State field(s) for PostalCode widget.
  FocusNode? postalCodeFocusNode;
  TextEditingController? postalCodeTextController;
  String? Function(BuildContext, String?)? postalCodeTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue1;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode1;
  TextEditingController? startTimeTextController1;
  String? Function(BuildContext, String?)? startTimeTextController1Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode1;
  TextEditingController? pmTextController1;
  String? Function(BuildContext, String?)? pmTextController1Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode1;
  TextEditingController? endTimeTextController1;
  String? Function(BuildContext, String?)? endTimeTextController1Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode2;
  TextEditingController? pmTextController2;
  String? Function(BuildContext, String?)? pmTextController2Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue2;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode2;
  TextEditingController? startTimeTextController2;
  String? Function(BuildContext, String?)? startTimeTextController2Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode3;
  TextEditingController? pmTextController3;
  String? Function(BuildContext, String?)? pmTextController3Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode2;
  TextEditingController? endTimeTextController2;
  String? Function(BuildContext, String?)? endTimeTextController2Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode4;
  TextEditingController? pmTextController4;
  String? Function(BuildContext, String?)? pmTextController4Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue3;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode3;
  TextEditingController? startTimeTextController3;
  String? Function(BuildContext, String?)? startTimeTextController3Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode5;
  TextEditingController? pmTextController5;
  String? Function(BuildContext, String?)? pmTextController5Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode3;
  TextEditingController? endTimeTextController3;
  String? Function(BuildContext, String?)? endTimeTextController3Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode6;
  TextEditingController? pmTextController6;
  String? Function(BuildContext, String?)? pmTextController6Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue4;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode4;
  TextEditingController? startTimeTextController4;
  String? Function(BuildContext, String?)? startTimeTextController4Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode7;
  TextEditingController? pmTextController7;
  String? Function(BuildContext, String?)? pmTextController7Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode4;
  TextEditingController? endTimeTextController4;
  String? Function(BuildContext, String?)? endTimeTextController4Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode8;
  TextEditingController? pmTextController8;
  String? Function(BuildContext, String?)? pmTextController8Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue5;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode5;
  TextEditingController? startTimeTextController5;
  String? Function(BuildContext, String?)? startTimeTextController5Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode9;
  TextEditingController? pmTextController9;
  String? Function(BuildContext, String?)? pmTextController9Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode5;
  TextEditingController? endTimeTextController5;
  String? Function(BuildContext, String?)? endTimeTextController5Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode10;
  TextEditingController? pmTextController10;
  String? Function(BuildContext, String?)? pmTextController10Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue6;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode6;
  TextEditingController? startTimeTextController6;
  String? Function(BuildContext, String?)? startTimeTextController6Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode11;
  TextEditingController? pmTextController11;
  String? Function(BuildContext, String?)? pmTextController11Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode6;
  TextEditingController? endTimeTextController6;
  String? Function(BuildContext, String?)? endTimeTextController6Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode12;
  TextEditingController? pmTextController12;
  String? Function(BuildContext, String?)? pmTextController12Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue7;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode7;
  TextEditingController? startTimeTextController7;
  String? Function(BuildContext, String?)? startTimeTextController7Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode13;
  TextEditingController? pmTextController13;
  String? Function(BuildContext, String?)? pmTextController13Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode7;
  TextEditingController? endTimeTextController7;
  String? Function(BuildContext, String?)? endTimeTextController7Validator;
  // State field(s) for PM widget.
  FocusNode? pmFocusNode14;
  TextEditingController? pmTextController14;
  String? Function(BuildContext, String?)? pmTextController14Validator;
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
  // State field(s) for AdminDateOfBirth widget.
  FocusNode? adminDateOfBirthFocusNode;
  TextEditingController? adminDateOfBirthTextController;
  String? Function(BuildContext, String?)?
      adminDateOfBirthTextControllerValidator;
  DateTime? datePicked2;
  // State field(s) for AdminDCARDNUm widget.
  FocusNode? adminDCARDNUmFocusNode;
  TextEditingController? adminDCARDNUmTextController;
  String? Function(BuildContext, String?)? adminDCARDNUmTextControllerValidator;
  // State field(s) for AdminIDCARDDATEOFISSUE widget.
  FocusNode? adminIDCARDDATEOFISSUEFocusNode;
  TextEditingController? adminIDCARDDATEOFISSUETextController;
  String? Function(BuildContext, String?)?
      adminIDCARDDATEOFISSUETextControllerValidator;
  DateTime? datePicked3;
  // State field(s) for AdminIDCARDDATEOFEXPIRATION widget.
  FocusNode? adminIDCARDDATEOFEXPIRATIONFocusNode;
  TextEditingController? adminIDCARDDATEOFEXPIRATIONTextController;
  String? Function(BuildContext, String?)?
      adminIDCARDDATEOFEXPIRATIONTextControllerValidator;
  DateTime? datePicked4;
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
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {
    medzenLandingHeaderModel =
        createModel(context, () => MedzenLandingHeaderModel());
    facilityNameTextControllerValidator = _facilityNameTextControllerValidator;
    facilityTypeTextControllerValidator = _facilityTypeTextControllerValidator;
    registrationLicenseNumberTextControllerValidator =
        _registrationLicenseNumberTextControllerValidator;
    yearestablishedTextControllerValidator =
        _yearestablishedTextControllerValidator;
    ownershipTypeTextControllerValidator =
        _ownershipTypeTextControllerValidator;
    emailAddressTextControllerValidator = _emailAddressTextControllerValidator;
    websiteTextControllerValidator = _websiteTextControllerValidator;
    descriptionAboutUsTextControllerValidator =
        _descriptionAboutUsTextControllerValidator;
  }

  @override
  void dispose() {
    medzenLandingHeaderModel.dispose();
    facilityNameFocusNode?.dispose();
    facilityNameTextController?.dispose();

    facilityTypeFocusNode?.dispose();
    facilityTypeTextController?.dispose();

    registrationLicenseNumberFocusNode?.dispose();
    registrationLicenseNumberTextController?.dispose();

    yearestablishedFocusNode?.dispose();
    yearestablishedTextController?.dispose();

    ownershipTypeFocusNode?.dispose();
    ownershipTypeTextController?.dispose();

    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    websiteFocusNode?.dispose();
    websiteTextController?.dispose();

    descriptionAboutUsFocusNode?.dispose();
    descriptionAboutUsTextController?.dispose();

    streetAddressFocusNode?.dispose();
    streetAddressTextController?.dispose();

    cityFocusNode?.dispose();
    cityTextController?.dispose();

    regionFocusNode?.dispose();
    regionTextController?.dispose();

    postalCodeFocusNode?.dispose();
    postalCodeTextController?.dispose();

    startTimeFocusNode1?.dispose();
    startTimeTextController1?.dispose();

    pmFocusNode1?.dispose();
    pmTextController1?.dispose();

    endTimeFocusNode1?.dispose();
    endTimeTextController1?.dispose();

    pmFocusNode2?.dispose();
    pmTextController2?.dispose();

    startTimeFocusNode2?.dispose();
    startTimeTextController2?.dispose();

    pmFocusNode3?.dispose();
    pmTextController3?.dispose();

    endTimeFocusNode2?.dispose();
    endTimeTextController2?.dispose();

    pmFocusNode4?.dispose();
    pmTextController4?.dispose();

    startTimeFocusNode3?.dispose();
    startTimeTextController3?.dispose();

    pmFocusNode5?.dispose();
    pmTextController5?.dispose();

    endTimeFocusNode3?.dispose();
    endTimeTextController3?.dispose();

    pmFocusNode6?.dispose();
    pmTextController6?.dispose();

    startTimeFocusNode4?.dispose();
    startTimeTextController4?.dispose();

    pmFocusNode7?.dispose();
    pmTextController7?.dispose();

    endTimeFocusNode4?.dispose();
    endTimeTextController4?.dispose();

    pmFocusNode8?.dispose();
    pmTextController8?.dispose();

    startTimeFocusNode5?.dispose();
    startTimeTextController5?.dispose();

    pmFocusNode9?.dispose();
    pmTextController9?.dispose();

    endTimeFocusNode5?.dispose();
    endTimeTextController5?.dispose();

    pmFocusNode10?.dispose();
    pmTextController10?.dispose();

    startTimeFocusNode6?.dispose();
    startTimeTextController6?.dispose();

    pmFocusNode11?.dispose();
    pmTextController11?.dispose();

    endTimeFocusNode6?.dispose();
    endTimeTextController6?.dispose();

    pmFocusNode12?.dispose();
    pmTextController12?.dispose();

    startTimeFocusNode7?.dispose();
    startTimeTextController7?.dispose();

    pmFocusNode13?.dispose();
    pmTextController13?.dispose();

    endTimeFocusNode7?.dispose();
    endTimeTextController7?.dispose();

    pmFocusNode14?.dispose();
    pmTextController14?.dispose();

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

    emergencyNamesFocusNode?.dispose();
    emergencyNamesTextController?.dispose();

    relationshipFocusNode?.dispose();
    relationshipTextController?.dispose();
  }
}
