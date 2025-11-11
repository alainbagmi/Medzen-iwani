import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/patient_bottom_nav/patient_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'patient_landing_page_model.dart';
export 'patient_landing_page_model.dart';

class PatientLandingPageWidget extends StatefulWidget {
  const PatientLandingPageWidget({super.key});

  static String routeName = 'patient_landing_page';
  static String routePath = '/patientLandingPage';

  @override
  State<PatientLandingPageWidget> createState() =>
      _PatientLandingPageWidgetState();
}

class _PatientLandingPageWidgetState extends State<PatientLandingPageWidget>
    with TickerProviderStateMixin {
  late PatientLandingPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PatientLandingPageModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 700.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 700.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 700.0.ms,
            duration: 600.0.ms,
            begin: Offset(-40.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 700.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 700.0.ms,
            duration: 600.0.ms,
            begin: Offset(40.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 110.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation5': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 700.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 700.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 700.0.ms,
            duration: 600.0.ms,
            begin: Offset(-40.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation6': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1000.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 1000.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 1000.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 52.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
            child: FutureBuilder<ApiCallResponse>(
              future: SupagraphqlGroup.userDetailsCall.call(
                userId: FFAppState().AuthuserID,
              ),
              builder: (context, snapshot) {
                // Customize what your widget looks like when it's loading.
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 50.0,
                      height: 50.0,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  );
                }
                final rowUserDetailsResponse = snapshot.data!;

                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(0.0, -1.0),
                              child: Material(
                                color: Colors.transparent,
                                elevation: 40.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(24.0),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Container(
                                              width: 100.0,
                                              height: 100.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Container(
                                                width: 200.0,
                                                height: 200.0,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Image.network(
                                                  valueOrDefault<String>(
                                                    getJsonField(
                                                      SupagraphqlGroup
                                                          .userDetailsCall
                                                          .userDetails(
                                                        rowUserDetailsResponse
                                                            .jsonBody,
                                                      ),
                                                      r'''$.avatar_url''',
                                                    )?.toString(),
                                                    'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/Default_patient_pic/default_profile.png',
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 4.0),
                                                    child: GradientText(
                                                      valueOrDefault<String>(
                                                        getJsonField(
                                                          SupagraphqlGroup
                                                              .userDetailsCall
                                                              .userProfile(
                                                            rowUserDetailsResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.display_name''',
                                                        )?.toString(),
                                                        'null',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .readexPro(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontStyle,
                                                              ),
                                                      colors: [
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryText
                                                      ],
                                                      gradientDirection:
                                                          GradientDirection.ltr,
                                                      gradientType:
                                                          GradientType.linear,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 4.0),
                                                    child: GradientText(
                                                      valueOrDefault<String>(
                                                        getJsonField(
                                                          SupagraphqlGroup
                                                              .userDetailsCall
                                                              .patientProfile(
                                                            rowUserDetailsResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.patient_number''',
                                                        )?.toString(),
                                                        'null',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 14.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                              ),
                                                      colors: [
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryText
                                                      ],
                                                      gradientDirection:
                                                          GradientDirection.ltr,
                                                      gradientType:
                                                          GradientType.linear,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: Align(
                                              alignment: AlignmentDirectional(
                                                  1.0, 0.0),
                                              child: Padding(
                                                padding: EdgeInsets.all(10.0),
                                                child: InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    context.pushNamed(
                                                        PatientsNotificationsPageWidget
                                                            .routeName);
                                                  },
                                                  child: Icon(
                                                    Icons.notifications_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 40.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                primary: false,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            if (responsiveVisibility(
                                              context: context,
                                              phone: false,
                                              tablet: false,
                                              tabletLandscape: false,
                                            ))
                                              Padding(
                                                padding: EdgeInsets.all(10.0),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  elevation: 20.0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            24.0),
                                                  ),
                                                  child: Container(
                                                    width: 312.0,
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              24.0),
                                                      border: Border.all(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                PatientProfilePageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'patientAuthUser':
                                                                      serializeParam(
                                                                    '',
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 20.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .person_2,
                                                                        color: Colors
                                                                            .black,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'v8jpbwdd' /* Profile */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                            ),
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                AppointmentsWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'username':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      SupagraphqlGroup
                                                                          .userDetailsCall
                                                                          .userProfile(
                                                                        rowUserDetailsResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.display_name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'usernumber':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      SupagraphqlGroup
                                                                          .userDetailsCall
                                                                          .patientProfile(
                                                                        rowUserDetailsResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.patient_number''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'avatarUrl':
                                                                      serializeParam(
                                                                    valueOrDefault<
                                                                        String>(
                                                                      getJsonField(
                                                                        SupagraphqlGroup
                                                                            .userDetailsCall
                                                                            .userDetails(
                                                                          rowUserDetailsResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.avatar_url''',
                                                                      )?.toString(),
                                                                      'ttps://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/Default_patient_pic/default_profile.png',
                                                                    ),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .calendar_today,
                                                                        color: Colors
                                                                            .black,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'e3tuvzu3' /* Appointments */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                  PaymentHistoryWidget
                                                                      .routeName);
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .paypal_sharp,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'nsccfmny' /* Payments */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                  PatientsMedicationPageWidget
                                                                      .routeName);
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .medication_sharp,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'i7l4ztc0' /* Medications */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                  PatientsDocumentPageWidget
                                                                      .routeName);
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .edit_document,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'l5ejawaq' /* Documents */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                  PatientsNotificationsPageWidget
                                                                      .routeName);
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .notifications_none,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        '1yb9hf0f' /* Notifications */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                  PatientsSettingsPageWidget
                                                                      .routeName);
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .settings,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            30.0,
                                                                      ),
                                                                    ),
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        '100y2szx' /* Settings */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontSize:
                                                                                20.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child: InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              GoRouter.of(
                                                                      context)
                                                                  .prepareAuthEvent();
                                                              await authManager
                                                                  .signOut();
                                                              GoRouter.of(
                                                                      context)
                                                                  .clearRedirectLocation();

                                                              context.goNamedAuth(
                                                                  SplashScreenWidget
                                                                      .routeName,
                                                                  context
                                                                      .mounted);
                                                            },
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            24.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 56.0,
                                                                constraints:
                                                                    BoxConstraints(
                                                                  minHeight:
                                                                      2.0,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Color(
                                                                      0xFFEE0505),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .tertiary,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          20.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .logout_sharp,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        size:
                                                                            24.0,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        't8t4y6uu' /* Log-out */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.normal,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryBackground,
                                                                            fontSize:
                                                                                16.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.normal,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ]
                                                          .divide(SizedBox(
                                                              height: 75.0))
                                                          .around(SizedBox(
                                                              height: 75.0)),
                                                    ),
                                                  ),
                                                ).animateOnPageLoad(animationsMap[
                                                    'containerOnPageLoadAnimation1']!),
                                              ),
                                            Expanded(
                                              child: Container(
                                                width: 100.0,
                                                decoration: BoxDecoration(),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Wrap(
                                                      spacing: 0.0,
                                                      runSpacing: 0.0,
                                                      alignment:
                                                          WrapAlignment.start,
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .start,
                                                      direction:
                                                          Axis.horizontal,
                                                      runAlignment:
                                                          WrapAlignment.start,
                                                      verticalDirection:
                                                          VerticalDirection
                                                              .down,
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      5.0,
                                                                      15.0,
                                                                      5.0,
                                                                      0.0),
                                                          child: Container(
                                                            width: () {
                                                              if (MediaQuery.sizeOf(
                                                                          context)
                                                                      .width <
                                                                  991.0) {
                                                                return MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width;
                                                              } else if (MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width <
                                                                  1100.0) {
                                                                return 250.0;
                                                              } else {
                                                                return 424.0;
                                                              }
                                                            }(),
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          24.0),
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                              ),
                                                            ),
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                GradientText(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'qfsb4vd9' /* Upcoming Appointment */,
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        fontSize:
                                                                            20.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                  colors: [
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondary
                                                                  ],
                                                                  gradientDirection:
                                                                      GradientDirection
                                                                          .ltr,
                                                                  gradientType:
                                                                      GradientType
                                                                          .linear,
                                                                ),
                                                                FutureBuilder<
                                                                    List<
                                                                        AppointmentOverviewRow>>(
                                                                  future: AppointmentOverviewTable()
                                                                      .querySingleRow(
                                                                    queryFn: (q) =>
                                                                        q.eqOrNull(
                                                                      'patient_id',
                                                                      FFAppState()
                                                                          .AuthuserID,
                                                                    ),
                                                                  ),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    // Customize what your widget looks like when it's loading.
                                                                    if (!snapshot
                                                                        .hasData) {
                                                                      return Center(
                                                                        child:
                                                                            SizedBox(
                                                                          width:
                                                                              50.0,
                                                                          height:
                                                                              50.0,
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            valueColor:
                                                                                AlwaysStoppedAnimation<Color>(
                                                                              FlutterFlowTheme.of(context).primary,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                    List<AppointmentOverviewRow>
                                                                        listViewAppointmentOverviewRowList =
                                                                        snapshot
                                                                            .data!;

                                                                    // Return an empty Container when the item does not exist.
                                                                    if (snapshot
                                                                        .data!
                                                                        .isEmpty) {
                                                                      return Container();
                                                                    }
                                                                    final listViewAppointmentOverviewRow = listViewAppointmentOverviewRowList
                                                                            .isNotEmpty
                                                                        ? listViewAppointmentOverviewRowList
                                                                            .first
                                                                        : null;

                                                                    return ListView(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      shrinkWrap:
                                                                          true,
                                                                      scrollDirection:
                                                                          Axis.vertical,
                                                                      children:
                                                                          [
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              2.0,
                                                                              0.0,
                                                                              2.0,
                                                                              0.0),
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                BoxDecoration(),
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                Material(
                                                                                  color: Colors.transparent,
                                                                                  elevation: 50.0,
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12.0),
                                                                                  ),
                                                                                  child: Container(
                                                                                    width: double.infinity,
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      boxShadow: [
                                                                                        BoxShadow(
                                                                                          blurRadius: 2.0,
                                                                                          color: Color(0x0D000000),
                                                                                          offset: Offset(
                                                                                            0.0,
                                                                                            1.0,
                                                                                          ),
                                                                                        )
                                                                                      ],
                                                                                      borderRadius: BorderRadius.circular(12.0),
                                                                                      border: Border.all(
                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                      ),
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(5.0),
                                                                                      child: Column(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          Row(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                            children: [
                                                                                              Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                children: [
                                                                                                  Container(
                                                                                                    width: 60.0,
                                                                                                    height: 60.0,
                                                                                                    decoration: BoxDecoration(
                                                                                                      image: DecorationImage(
                                                                                                        fit: BoxFit.cover,
                                                                                                        image: Image.network(
                                                                                                          '500x500?doctor#1',
                                                                                                        ).image,
                                                                                                      ),
                                                                                                      shape: BoxShape.circle,
                                                                                                      border: Border.all(
                                                                                                        color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                        width: 2.0,
                                                                                                      ),
                                                                                                    ),
                                                                                                    child: Container(
                                                                                                      width: 200.0,
                                                                                                      height: 200.0,
                                                                                                      clipBehavior: Clip.antiAlias,
                                                                                                      decoration: BoxDecoration(
                                                                                                        shape: BoxShape.circle,
                                                                                                      ),
                                                                                                      child: Image.network(
                                                                                                        listViewAppointmentOverviewRow!.providerImageUrl!,
                                                                                                        fit: BoxFit.cover,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                  Column(
                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                    children: [
                                                                                                      Text(
                                                                                                        valueOrDefault<String>(
                                                                                                          listViewAppointmentOverviewRow?.providerFullname,
                                                                                                          'provider',
                                                                                                        ),
                                                                                                        style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                              ),
                                                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                      if (FFAppState().UserRole == 'patient')
                                                                                                        Text(
                                                                                                          valueOrDefault<String>(
                                                                                                            listViewAppointmentOverviewRow?.providerSpecialty,
                                                                                                            'specialty',
                                                                                                          ),
                                                                                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                      Text(
                                                                                                        'Date :  ${dateTimeFormat(
                                                                                                          "d/M/y",
                                                                                                          listViewAppointmentOverviewRow?.appointmentStartDate,
                                                                                                          locale: FFLocalizations.of(context).languageCode,
                                                                                                        )}',
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FontWeight.w500,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.w500,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                      Text(
                                                                                                        'Time : ${dateTimeFormat(
                                                                                                          "Hm",
                                                                                                          listViewAppointmentOverviewRow?.appointmentStartTime?.time,
                                                                                                          locale: FFLocalizations.of(context).languageCode,
                                                                                                        )}',
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FontWeight.w500,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.w500,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                      GradientText(
                                                                                                        valueOrDefault<String>(
                                                                                                          listViewAppointmentOverviewRow?.consultationMode,
                                                                                                          'Mode',
                                                                                                        ),
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FontWeight.bold,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                        colors: [
                                                                                                          FlutterFlowTheme.of(context).primary,
                                                                                                          FlutterFlowTheme.of(context).secondary
                                                                                                        ],
                                                                                                        gradientDirection: GradientDirection.ltr,
                                                                                                        gradientType: GradientType.linear,
                                                                                                      ),
                                                                                                    ].divide(SizedBox(height: 3.0)),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 10.0)),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          if (listViewAppointmentOverviewRow?.consultationMode == 'Online')
                                                                                            Divider(
                                                                                              height: 1.0,
                                                                                              thickness: 1.0,
                                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                                            ),
                                                                                          if (listViewAppointmentOverviewRow?.consultationMode == 'Online')
                                                                                            Row(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                              children: [
                                                                                                Icon(
                                                                                                  Icons.sms,
                                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                                  size: 40.0,
                                                                                                ),
                                                                                                InkWell(
                                                                                                  splashColor: Colors.transparent,
                                                                                                  focusColor: Colors.transparent,
                                                                                                  hoverColor: Colors.transparent,
                                                                                                  highlightColor: Colors.transparent,
                                                                                                  onTap: () async {
                                                                                                    context.pushNamed(JoinCallWidget.routeName);
                                                                                                  },
                                                                                                  child: Icon(
                                                                                                    Icons.add_ic_call_rounded,
                                                                                                    color: FlutterFlowTheme.of(context).primary,
                                                                                                    size: 40.0,
                                                                                                  ),
                                                                                                ),
                                                                                                Icon(
                                                                                                  Icons.calendar_month_sharp,
                                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                                  size: 40.0,
                                                                                                ),
                                                                                              ].divide(SizedBox(width: 2.0)),
                                                                                            ),
                                                                                        ].divide(SizedBox(height: 5.0)).around(SizedBox(height: 5.0)),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation4']!),
                                                                              ],
                                                                            ),
                                                                          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation3']!),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              height: 10.0)),
                                                                    );
                                                                  },
                                                                ),
                                                              ]
                                                                  .divide(SizedBox(
                                                                      height:
                                                                          15.0))
                                                                  .around(SizedBox(
                                                                      height:
                                                                          15.0)),
                                                            ),
                                                          ).animateOnPageLoad(
                                                              animationsMap[
                                                                  'containerOnPageLoadAnimation2']!),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  6.0),
                                                          child: Container(
                                                            width: () {
                                                              if (MediaQuery.sizeOf(
                                                                          context)
                                                                      .width <
                                                                  991.0) {
                                                                return MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width;
                                                              } else if (MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width <
                                                                  1100.0) {
                                                                return 360.0;
                                                              } else {
                                                                return 424.0;
                                                              }
                                                            }(),
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          24.0),
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              10.0),
                                                                  child:
                                                                      Material(
                                                                    color: Colors
                                                                        .transparent,
                                                                    elevation:
                                                                        20.0,
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              24.0),
                                                                    ),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        borderRadius:
                                                                            BorderRadius.circular(24.0),
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(14.0),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children:
                                                                              [
                                                                            Align(
                                                                              alignment: AlignmentDirectional(0.0, -1.0),
                                                                              child: GradientText(
                                                                                FFLocalizations.of(context).getText(
                                                                                  '9us53754' /* Subscription  */,
                                                                                ),
                                                                                textAlign: TextAlign.center,
                                                                                style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                      font: GoogleFonts.readexPro(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                      ),
                                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    ),
                                                                                colors: [
                                                                                  FlutterFlowTheme.of(context).primary,
                                                                                  FlutterFlowTheme.of(context).secondary
                                                                                ],
                                                                                gradientDirection: GradientDirection.ltr,
                                                                                gradientType: GradientType.linear,
                                                                              ),
                                                                            ),
                                                                            Divider(
                                                                              height: 1.0,
                                                                              thickness: 1.0,
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                            ),
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  FFLocalizations.of(context).getText(
                                                                                    'd7n9lpz9' /* Subscription Status: */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w600,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    SupagraphqlGroup.userDetailsCall.subscriptionStatus(
                                                                                      rowUserDetailsResponse.jsonBody,
                                                                                    ),
                                                                                    'active',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  FFLocalizations.of(context).getText(
                                                                                    'n6s1jc3a' /* Subscription Type: */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w600,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    SupagraphqlGroup.userDetailsCall
                                                                                        .subscription(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        )
                                                                                        .toString(),
                                                                                    'free',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ].divide(SizedBox(height: 12.0)),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              4.0),
                                                                  child:
                                                                      Material(
                                                                    color: Colors
                                                                        .transparent,
                                                                    elevation:
                                                                        20.0,
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              24.0),
                                                                    ),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        borderRadius:
                                                                            BorderRadius.circular(24.0),
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(4.0),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children:
                                                                              [
                                                                            Align(
                                                                              alignment: AlignmentDirectional(0.0, -1.0),
                                                                              child: GradientText(
                                                                                FFLocalizations.of(context).getText(
                                                                                  'smyusugu' /* Emergency Contact */,
                                                                                ),
                                                                                style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                      font: GoogleFonts.readexPro(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                      ),
                                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    ),
                                                                                colors: [
                                                                                  FlutterFlowTheme.of(context).primary,
                                                                                  FlutterFlowTheme.of(context).secondary
                                                                                ],
                                                                                gradientDirection: GradientDirection.ltr,
                                                                                gradientType: GradientType.linear,
                                                                              ),
                                                                            ),
                                                                            Divider(
                                                                              height: 1.0,
                                                                              thickness: 1.0,
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                            ),
                                                                            Padding(
                                                                              padding: EdgeInsets.all(6.0),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'z6jw94th' /* Name: */,
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      getJsonField(
                                                                                        SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.emergency_contact_name''',
                                                                                      )?.toString(),
                                                                                      'null',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: EdgeInsets.all(6.0),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'gxpobr3t' /* Relationship: */,
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      getJsonField(
                                                                                        SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.emergency_contact_relationship''',
                                                                                      )?.toString(),
                                                                                      'null',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: EdgeInsets.all(6.0),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'mz04atw8' /* Phone: */,
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      getJsonField(
                                                                                        SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.emergency_contact_phone''',
                                                                                      )?.toString(),
                                                                                      'null',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(height: 8.0)),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ).animateOnPageLoad(
                                                              animationsMap[
                                                                  'containerOnPageLoadAnimation5']!),
                                                        ),
                                                      ],
                                                    ),
                                                    if (responsiveVisibility(
                                                      context: context,
                                                      phone: false,
                                                      tablet: false,
                                                      tabletLandscape: false,
                                                      desktop: false,
                                                    ))
                                                      Padding(
                                                        padding: EdgeInsets.all(
                                                            10.0),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          elevation: 20.0,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        24.0),
                                                          ),
                                                          child: Container(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                0.9,
                                                            height: 200.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          24.0),
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          12.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '51o59srf' /* Quick Links */,
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineSmall
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.notoSerif(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                            fontStyle:
                                                                                FontStyle.italic,
                                                                          ),
                                                                          fontSize:
                                                                              28.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .headlineSmall
                                                                              .fontWeight,
                                                                          fontStyle:
                                                                              FontStyle.italic,
                                                                        ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            elevation:
                                                                                20.0,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(30.0),
                                                                            ),
                                                                            child:
                                                                                Container(
                                                                              width: 60.0,
                                                                              height: 60.0,
                                                                              decoration: BoxDecoration(
                                                                                color: Color(0xFFE3F2FD),
                                                                                borderRadius: BorderRadius.circular(30.0),
                                                                              ),
                                                                              child: Icon(
                                                                                Icons.video_call,
                                                                                color: FlutterFlowTheme.of(context).primary,
                                                                                size: 30.0,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.all(4.0),
                                                                            child:
                                                                                Text(
                                                                              FFLocalizations.of(context).getText(
                                                                                '1ohmyqto' /* Video Call */,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    fontSize: 12.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 8.0)),
                                                                      ),
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            elevation:
                                                                                20.0,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(30.0),
                                                                            ),
                                                                            child:
                                                                                Container(
                                                                              width: 60.0,
                                                                              height: 60.0,
                                                                              decoration: BoxDecoration(
                                                                                color: Color(0xFFE8F5E9),
                                                                                borderRadius: BorderRadius.circular(30.0),
                                                                              ),
                                                                              child: Icon(
                                                                                Icons.phone,
                                                                                color: FlutterFlowTheme.of(context).success,
                                                                                size: 30.0,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.all(4.0),
                                                                            child:
                                                                                Text(
                                                                              FFLocalizations.of(context).getText(
                                                                                '0kt9y7dz' /* Audio Call */,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    fontSize: 12.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 8.0)),
                                                                      ),
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            elevation:
                                                                                20.0,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(30.0),
                                                                            ),
                                                                            child:
                                                                                Container(
                                                                              width: 60.0,
                                                                              height: 60.0,
                                                                              decoration: BoxDecoration(
                                                                                color: Color(0xFFFFF3E0),
                                                                                borderRadius: BorderRadius.circular(30.0),
                                                                              ),
                                                                              child: Icon(
                                                                                Icons.message_rounded,
                                                                                color: FlutterFlowTheme.of(context).tertiary,
                                                                                size: 30.0,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.all(4.0),
                                                                            child:
                                                                                Text(
                                                                              FFLocalizations.of(context).getText(
                                                                                'o2f2c6re' /* Message */,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    fontSize: 12.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 8.0)),
                                                                      ),
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            elevation:
                                                                                20.0,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(30.0),
                                                                            ),
                                                                            child:
                                                                                Container(
                                                                              width: 60.0,
                                                                              height: 60.0,
                                                                              decoration: BoxDecoration(
                                                                                color: Color(0xFFF3E5F5),
                                                                                borderRadius: BorderRadius.circular(30.0),
                                                                              ),
                                                                              child: Icon(
                                                                                Icons.calendar_today,
                                                                                color: Colors.purple,
                                                                                size: 30.0,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.all(4.0),
                                                                            child:
                                                                                Text(
                                                                              FFLocalizations.of(context).getText(
                                                                                'cuhk1aaj' /* Schedule */,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    fontSize: 12.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 8.0)),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        18.0)),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Card(
                                                        clipBehavior: Clip
                                                            .antiAliasWithSaveLayer,
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        elevation: 20.0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      24.0),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      10.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10.0),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'bzf8jkp5' /* Recent Vitals */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.readexPro(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Material(
                                                                          color:
                                                                              Colors.transparent,
                                                                          elevation:
                                                                              20.0,
                                                                          shape:
                                                                              const CircleBorder(),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                69.31,
                                                                            height:
                                                                                69.31,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).accent1,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    getJsonField(
                                                                                      SupagraphqlGroup.userDetailsCall.patientProfile(
                                                                                        rowUserDetailsResponse.jsonBody,
                                                                                      ),
                                                                                      r'''$.last_blood_pressure_systolic''',
                                                                                    )?.toString(),
                                                                                    'null',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  FFLocalizations.of(context).getText(
                                                                                    '24om7oux' /* / */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    getJsonField(
                                                                                      SupagraphqlGroup.userDetailsCall.patientProfile(
                                                                                        rowUserDetailsResponse.jsonBody,
                                                                                      ),
                                                                                      r'''$.last_blood_pressure_diastolic''',
                                                                                    )?.toString(),
                                                                                    'null',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ].divide(SizedBox(width: 2.0)),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(6.0),
                                                                          child:
                                                                              Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'fsd1hsq4' /* Blood Pressure */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.w800,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Material(
                                                                          color:
                                                                              Colors.transparent,
                                                                          elevation:
                                                                              20.0,
                                                                          shape:
                                                                              const CircleBorder(),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                68.6,
                                                                            height:
                                                                                68.6,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).accent3,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(16.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      getJsonField(
                                                                                        SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.weight_kg''',
                                                                                      )?.toString(),
                                                                                      'null',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          fontSize: 14.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(6.0),
                                                                          child:
                                                                              Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'ndwdffof' /* Weight */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.w800,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Material(
                                                                          color:
                                                                              Colors.transparent,
                                                                          elevation:
                                                                              20.0,
                                                                          shape:
                                                                              const CircleBorder(),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                66.1,
                                                                            height:
                                                                                66.1,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).accent4,
                                                                              shape: BoxShape.circle,
                                                                              border: Border.all(
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(16.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Text(
                                                                                    getJsonField(
                                                                                      SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                        rowUserDetailsResponse.jsonBody,
                                                                                      ),
                                                                                      r'''$.blood_type''',
                                                                                    ).toString(),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          fontSize: 12.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(6.0),
                                                                          child:
                                                                              Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'plhska9y' /* Blood Type */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.w800,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 12.0)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Card(
                                                        clipBehavior: Clip
                                                            .antiAliasWithSaveLayer,
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        elevation: 20.0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      24.0),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      10.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10.0),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    GradientText(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'au4fbtp6' /* Recent Demographics */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.readexPro(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                          ),
                                                                      colors: [
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary
                                                                      ],
                                                                      gradientDirection:
                                                                          GradientDirection
                                                                              .ltr,
                                                                      gradientType:
                                                                          GradientType
                                                                              .linear,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Material(
                                                                          color:
                                                                              Colors.transparent,
                                                                          elevation:
                                                                              20.0,
                                                                          shape:
                                                                              const CircleBorder(),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                69.31,
                                                                            height:
                                                                                69.31,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).accent1,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    getJsonField(
                                                                                      SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                        rowUserDetailsResponse.jsonBody,
                                                                                      ),
                                                                                      r'''$.height_cm''',
                                                                                    )?.toString(),
                                                                                    'null',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ].divide(SizedBox(width: 2.0)),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'j5ewkt2i' /* Height */,
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                                                fontSize: 14.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w800,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Material(
                                                                          color:
                                                                              Colors.transparent,
                                                                          elevation:
                                                                              20.0,
                                                                          shape:
                                                                              const CircleBorder(),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                68.6,
                                                                            height:
                                                                                68.6,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).accent3,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(16.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      getJsonField(
                                                                                        SupagraphqlGroup.userDetailsCall.patientProfile(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.is_blood_donor''',
                                                                                      )?.toString(),
                                                                                      'False',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          fontSize: 14.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(6.0),
                                                                          child:
                                                                              Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'gfiusf8l' /* Blood Donor */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.w800,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Material(
                                                                          color:
                                                                              Colors.transparent,
                                                                          elevation:
                                                                              20.0,
                                                                          shape:
                                                                              const CircleBorder(),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                66.1,
                                                                            height:
                                                                                66.1,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).accent4,
                                                                              shape: BoxShape.circle,
                                                                              border: Border.all(
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(16.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      getJsonField(
                                                                                        SupagraphqlGroup.userDetailsCall.userProfile(
                                                                                          rowUserDetailsResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.allergies''',
                                                                                      )?.toString(),
                                                                                      'null',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          fontSize: 12.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(6.0),
                                                                          child:
                                                                              Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'qxu680ku' /* Allergies */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.w800,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w800,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 12.0)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  1.0,
                                                                  10.0,
                                                                  1.0,
                                                                  10.0),
                                                      child: Card(
                                                        clipBehavior: Clip
                                                            .antiAliasWithSaveLayer,
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        elevation: 20.0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      18.0),
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              10.0),
                                                                  child:
                                                                      GradientText(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'uen16pyr' /* Documents */,
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.readexPro(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleMedium
                                                                              .fontStyle,
                                                                        ),
                                                                    colors: [
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary
                                                                    ],
                                                                    gradientDirection:
                                                                        GradientDirection
                                                                            .ltr,
                                                                    gradientType:
                                                                        GradientType
                                                                            .linear,
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              10.0),
                                                                  child:
                                                                      InkWell(
                                                                    splashColor:
                                                                        Colors
                                                                            .transparent,
                                                                    focusColor:
                                                                        Colors
                                                                            .transparent,
                                                                    hoverColor:
                                                                        Colors
                                                                            .transparent,
                                                                    highlightColor:
                                                                        Colors
                                                                            .transparent,
                                                                    onTap:
                                                                        () async {
                                                                      context.pushNamed(
                                                                          PatientsDocumentPageWidget
                                                                              .routeName);
                                                                    },
                                                                    child: Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'l1j9ie0v' /* View All */,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FontWeight.w600,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Material(
                                                              color: Colors
                                                                  .transparent,
                                                              elevation: 40.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                              ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .alternate,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12.0),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .description_rounded,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            24.0,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              12.0,
                                                                              0.0,
                                                                              12.0,
                                                                              0.0),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                FFLocalizations.of(context).getText(
                                                                                  'pyeh1ewv' /*  */,
                                                                                ),
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      font: GoogleFonts.inter(
                                                                                        fontWeight: FontWeight.w600,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
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
                                                            ),
                                                          ].divide(SizedBox(
                                                              height: 12.0)),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  10.0,
                                                                  10.0,
                                                                  10.0,
                                                                  0.0),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        elevation: 20.0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      24.0),
                                                        ),
                                                        child: SafeArea(
                                                          child: Container(
                                                            width: 1000.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          24.0),
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          24.0,
                                                                          0.0,
                                                                          24.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            24.0,
                                                                            0.0,
                                                                            24.0,
                                                                            16.0),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        GradientText(
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'zhlvr7wd' /* Diagnostic History */,
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                fontSize: MediaQuery.sizeOf(context).width < 767.0 ? 16.0 : 20.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                          colors: [
                                                                            FlutterFlowTheme.of(context).primary,
                                                                            FlutterFlowTheme.of(context).secondary
                                                                          ],
                                                                          gradientDirection:
                                                                              GradientDirection.ltr,
                                                                          gradientType:
                                                                              GradientType.linear,
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(12.0),
                                                                          child:
                                                                              InkWell(
                                                                            splashColor:
                                                                                Colors.transparent,
                                                                            focusColor:
                                                                                Colors.transparent,
                                                                            hoverColor:
                                                                                Colors.transparent,
                                                                            highlightColor:
                                                                                Colors.transparent,
                                                                            onTap:
                                                                                () async {
                                                                              context.pushNamed(PatientDiagnosticsWidget.routeName);
                                                                            },
                                                                            child:
                                                                                Text(
                                                                              FFLocalizations.of(context).getText(
                                                                                '73u0nud7' /* View All */,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).primary,
                                                                                    fontSize: 14.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(8.0),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            12.0),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      height:
                                                                          36.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            12.0,
                                                                            0.0,
                                                                            12.0,
                                                                            0.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          children: [
                                                                            if (responsiveVisibility(
                                                                              context: context,
                                                                              phone: false,
                                                                              tablet: false,
                                                                            ))
                                                                              Expanded(
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText(
                                                                                    'jdqcpj57' /* Order ID */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        fontSize: 12.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            Expanded(
                                                                              child: Text(
                                                                                FFLocalizations.of(context).getText(
                                                                                  'naepyd30' /* Date */,
                                                                                ),
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      font: GoogleFonts.inter(
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                      fontSize: 12.0,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                            Expanded(
                                                                              child: Text(
                                                                                FFLocalizations.of(context).getText(
                                                                                  'kk486vgf' /* Total */,
                                                                                ),
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      font: GoogleFonts.inter(
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                      fontSize: 12.0,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                            Expanded(
                                                                              child: Align(
                                                                                alignment: AlignmentDirectional(0.0, -1.0),
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText(
                                                                                    'lpdor5oy' /* Status */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        fontSize: 12.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            12.0,
                                                                            0.0,
                                                                            12.0,
                                                                            24.0),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                      ),
                                                                      child:
                                                                          ListView(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        primary:
                                                                            false,
                                                                        shrinkWrap:
                                                                            true,
                                                                        scrollDirection:
                                                                            Axis.vertical,
                                                                        children: [
                                                                          Container(
                                                                            width:
                                                                                double.infinity,
                                                                            height:
                                                                                45.0,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).primaryBackground,
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                if (responsiveVisibility(
                                                                                  context: context,
                                                                                  phone: false,
                                                                                  tablet: false,
                                                                                ))
                                                                                  Expanded(
                                                                                    child: Text(
                                                                                      FFLocalizations.of(context).getText(
                                                                                        '2hoovwda' /* null */,
                                                                                      ),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            font: GoogleFonts.inter(
                                                                                              fontWeight: FontWeight.normal,
                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                            ),
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.normal,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                Expanded(
                                                                                  child: Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 0.0, 0.0),
                                                                                    child: Text(
                                                                                      FFLocalizations.of(context).getText(
                                                                                        'x3hvr6qd' /* null */,
                                                                                      ),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            font: GoogleFonts.inter(
                                                                                              fontWeight: FontWeight.normal,
                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                            ),
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.normal,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Expanded(
                                                                                  child: Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 0.0, 0.0),
                                                                                    child: Text(
                                                                                      FFLocalizations.of(context).getText(
                                                                                        '4pcjo3je' /* null */,
                                                                                      ),
                                                                                      textAlign: TextAlign.start,
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            font: GoogleFonts.inter(
                                                                                              fontWeight: FontWeight.normal,
                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                            ),
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.normal,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'sglsszpz' /* null */,
                                                                                    ),
                                                                                    textAlign: TextAlign.center,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          font: GoogleFonts.inter(
                                                                                            fontWeight: FontWeight.normal,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).error,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.normal,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                              ],
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
                                                        ),
                                                      ).animateOnPageLoad(
                                                          animationsMap[
                                                              'containerOnPageLoadAnimation6']!),
                                                    ),
                                                  ]
                                                      .divide(SizedBox(
                                                          height: 20.0))
                                                      .around(SizedBox(
                                                          height: 20.0)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.patientBottomNavModel,
                              updateCallback: () => safeSetState(() {}),
                              child: PatientBottomNavWidget(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
