import '/backend/api_requests/api_calls.dart';
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
import 'care_center_registration_page_widget.dart'
    show CareCenterRegistrationPageWidget;
import 'dart:math' as math;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CareCenterRegistrationPageModel
    extends FlutterFlowModel<CareCenterRegistrationPageWidget> {
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

  bool isCheckBoxSelected = false;

  double finalConsultationfee = 0.0;

  ///  State fields for stateful widgets in this page.

  final formKey2 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();
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
  // State field(s) for consultationFee widget.
  FocusNode? consultationFeeFocusNode;
  TextEditingController? consultationFeeTextController;
  String? Function(BuildContext, String?)?
      consultationFeeTextControllerValidator;
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

  DateTime? datePicked;
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
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // Model for medzen_header_back component.
  late MedzenHeaderBackModel medzenHeaderBackModel;

  @override
  void initState(BuildContext context) {
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
    medzenHeaderBackModel = createModel(context, () => MedzenHeaderBackModel());
  }

  @override
  void dispose() {
    facilityNameFocusNode?.dispose();
    facilityNameTextController?.dispose();

    facilityTypeFocusNode?.dispose();
    facilityTypeTextController?.dispose();

    consultationFeeFocusNode?.dispose();
    consultationFeeTextController?.dispose();

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

    medzenHeaderBackModel.dispose();
  }
}
