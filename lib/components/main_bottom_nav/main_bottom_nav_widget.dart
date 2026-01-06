import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'main_bottom_nav_model.dart';
export 'main_bottom_nav_model.dart';

class MainBottomNavWidget extends StatefulWidget {
  const MainBottomNavWidget({super.key});

  @override
  State<MainBottomNavWidget> createState() => _MainBottomNavWidgetState();
}

class _MainBottomNavWidgetState extends State<MainBottomNavWidget> {
  late MainBottomNavModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainBottomNavModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.userdetails = await SupagraphqlGroup.userDetailsCall.call();

      if (!(_model.userdetails?.succeeded ?? true)) {
        await Future.delayed(
          Duration(
            milliseconds: 1,
          ),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Visibility(
      visible: responsiveVisibility(
        context: context,
        tablet: false,
        tabletLandscape: false,
        desktop: false,
      ),
      child: Container(
        width: double.infinity,
        height: 60.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(6.0),
        ),
        alignment: AlignmentDirectional(0.0, 1.0),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  if (valueOrDefault(currentUserDocument?.role, '') ==
                      'patient') {
                    context.pushNamed(PatientLandingPageWidget.routeName);
                  } else if (valueOrDefault(currentUserDocument?.role, '') ==
                      'medical_provider') {
                    context.pushNamed(ProviderLandingPageWidget.routeName);
                  } else if (valueOrDefault(currentUserDocument?.role, '') ==
                      'system_admin') {
                    context.pushNamed(SystemAdminLandingPageWidget.routeName);
                  } else {
                    context.pushNamed(FacilityAdminLandingPageWidget.routeName);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    shape: BoxShape.rectangle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.home,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 20.0,
                      ),
                      Expanded(
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'u4coqb6k' /* Home */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 11.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (valueOrDefault(currentUserDocument?.role, '') !=
                  'system_admin')
                AuthUserStreamWidget(
                  builder: (context) => InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      if (valueOrDefault(currentUserDocument?.role, '') ==
                          'patient') {
                        context.pushNamed(AppointmentsWidget.routeName);
                      } else if (valueOrDefault(
                              currentUserDocument?.role, '') ==
                          'medical_provider') {
                        context.pushNamed(
                          AppointmentsWidget.routeName,
                          queryParameters: {
                            'facilityid': serializeParam(
                              FFAppState().FacilityID,
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        );
                      } else if (valueOrDefault(
                              currentUserDocument?.role, '') ==
                          'system_admin') {
                        context.pushNamed(AppointmentsWidget.routeName);
                      } else {
                        context.pushNamed(
                          AppointmentsWidget.routeName,
                          queryParameters: {
                            'facilityid': serializeParam(
                              '',
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.calendarPlus,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 22.0,
                          ),
                          Expanded(
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'hbqowqj4' /* Appts */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if ((valueOrDefault(currentUserDocument?.role, '') ==
                      'facility_admin') ||
                  (valueOrDefault(currentUserDocument?.role, '') ==
                      'medical_provider'))
                AuthUserStreamWidget(
                  builder: (context) => InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      if (valueOrDefault(currentUserDocument?.role, '') ==
                          'system_admin') {
                      } else if (valueOrDefault(
                              currentUserDocument?.role, '') ==
                          'medical_provider') {
                        context
                            .pushNamed(ProvidersDocumentPageWidget.routeName);
                      } else if (valueOrDefault(
                              currentUserDocument?.role, '') ==
                          'facility_admin') {
                        context.pushNamed(
                            FacilityAdminDocumentPageWidget.routeName);
                      } else {
                        context.pushNamed(PatientsDocumentPageWidget.routeName);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_document,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 23.0,
                          ),
                          Expanded(
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'ra7oarnn' /* Docs */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if ((valueOrDefault(currentUserDocument?.role, '') ==
                      'facility_admin') ||
                  (valueOrDefault(currentUserDocument?.role, '') ==
                      'system_admin'))
                AuthUserStreamWidget(
                  builder: (context) => InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      if (valueOrDefault(currentUserDocument?.role, '') ==
                          'system_admin') {
                        context.pushNamed(
                          SystemAdminProfilePageWidget.routeName,
                          queryParameters: {
                            'patientAuthUser': serializeParam(
                              '',
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        );
                      } else if (valueOrDefault(
                              currentUserDocument?.role, '') ==
                          'medical_provider') {
                      } else if (valueOrDefault(
                              currentUserDocument?.role, '') ==
                          'facility_admin') {
                        context.pushNamed(
                          FacilityAdminProfilePageWidget.routeName,
                          queryParameters: {
                            'patientAuthUser': serializeParam(
                              '',
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 25.0,
                          ),
                          Expanded(
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'c21fqmlg' /* Profile */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  if (valueOrDefault(currentUserDocument?.role, '') ==
                      'patient') {
                    context.pushNamed(PaymentHistoryWidget.routeName);
                  } else if (valueOrDefault(currentUserDocument?.role, '') ==
                      'medical_provider') {
                    context.pushNamed(PaymentHistoryWidget.routeName);
                  } else if (valueOrDefault(currentUserDocument?.role, '') ==
                      'system_admin') {
                    context.pushNamed(FinanceWidget.routeName);
                  } else {
                    context.pushNamed(PaymentHistoryWidget.routeName);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.paypal_sharp,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 23.0,
                      ),
                      Expanded(
                        child: Text(
                          FFLocalizations.of(context).getText(
                            's7hz2fm0' /* Payments */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 11.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (valueOrDefault(currentUserDocument?.role, '') == 'patient')
                AuthUserStreamWidget(
                  builder: (context) => InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      context.pushNamed(PatientsMedicationPageWidget.routeName);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_sharp,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 24.0,
                          ),
                          Expanded(
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'p9vdjgx8' /* Meds */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  if (valueOrDefault(currentUserDocument?.role, '') ==
                      'patient') {
                    context.pushNamed(PatientsSettingsPageWidget.routeName);
                  } else if (valueOrDefault(currentUserDocument?.role, '') ==
                      'medical_provider') {
                    context.pushNamed(ProviderSettingsPageWidget.routeName);
                  } else if (valueOrDefault(currentUserDocument?.role, '') ==
                      'system_admin') {
                    context.pushNamed(SystemAdminSettingsPageWidget.routeName);
                  } else {
                    context
                        .pushNamed(FacilityAdminSettingsPageWidget.routeName);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_sharp,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 24.0,
                      ),
                      Expanded(
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'x25my10u' /* Settings */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 11.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
