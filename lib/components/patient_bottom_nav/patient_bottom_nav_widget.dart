import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'patient_bottom_nav_model.dart';
export 'patient_bottom_nav_model.dart';

class PatientBottomNavWidget extends StatefulWidget {
  const PatientBottomNavWidget({super.key});

  @override
  State<PatientBottomNavWidget> createState() => _PatientBottomNavWidgetState();
}

class _PatientBottomNavWidgetState extends State<PatientBottomNavWidget> {
  late PatientBottomNavModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PatientBottomNavModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.userdetails = await SupagraphqlGroup.userDetailsCall.call();

      if (!(_model.userdetails?.succeeded ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting nav details',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            duration: Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
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
    return Visibility(
      visible: responsiveVisibility(
        context: context,
        tablet: false,
        tabletLandscape: false,
        desktop: false,
      ),
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Container(
          width: double.infinity,
          height: 80.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primaryText,
              width: 2.0,
            ),
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(
                    PatientProfilePageWidget.routeName,
                    queryParameters: {
                      'patientAuthUser': serializeParam(
                        '',
                        ParamType.String,
                      ),
                    }.withoutNulls,
                  );
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
                        size: 24.0,
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          'ywbv3vko' /* Profile */,
                        ),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
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
                    ],
                  ),
                ),
              ),
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(
                    AppointmentsWidget.routeName,
                    queryParameters: {
                      'username': serializeParam(
                        getJsonField(
                          SupagraphqlGroup.userDetailsCall.userProfile(
                            (_model.userdetails?.jsonBody ?? ''),
                          ),
                          r'''$.display_name''',
                        ).toString(),
                        ParamType.String,
                      ),
                      'usernumber': serializeParam(
                        getJsonField(
                          SupagraphqlGroup.userDetailsCall.patientProfile(
                            (_model.userdetails?.jsonBody ?? ''),
                          ),
                          r'''$.patient_number''',
                        ).toString(),
                        ParamType.String,
                      ),
                      'avatarUrl': serializeParam(
                        valueOrDefault<String>(
                          getJsonField(
                            SupagraphqlGroup.userDetailsCall.userDetails(
                              (_model.userdetails?.jsonBody ?? ''),
                            ),
                            r'''$.avatar_url''',
                          )?.toString(),
                          '\$.avatar_url',
                        ),
                        ParamType.String,
                      ),
                    }.withoutNulls,
                  );
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
                        Icons.calendar_today,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 24.0,
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          'zxu7fsey' /* Appts */,
                        ),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
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
                    ],
                  ),
                ),
              ),
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(
                    PaymentHistoryWidget.routeName,
                    queryParameters: {
                      'username': serializeParam(
                        '',
                        ParamType.String,
                      ),
                      'userNumber': serializeParam(
                        '',
                        ParamType.String,
                      ),
                      'avatar': serializeParam(
                        '',
                        ParamType.String,
                      ),
                    }.withoutNulls,
                  );
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
                        Icons.paypal,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 24.0,
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          '28aljha0' /* Payments */,
                        ),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
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
                    ],
                  ),
                ),
              ),
              InkWell(
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
                      Text(
                        FFLocalizations.of(context).getText(
                          'q2g8bonc' /* Meds */,
                        ),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(PatientsSettingsPageWidget.routeName);
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
                      Text(
                        FFLocalizations.of(context).getText(
                          'c8p766yp' /* Settings */,
                        ),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
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
