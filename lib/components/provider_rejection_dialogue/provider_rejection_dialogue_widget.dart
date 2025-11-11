import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'provider_rejection_dialogue_model.dart';
export 'provider_rejection_dialogue_model.dart';

class ProviderRejectionDialogueWidget extends StatefulWidget {
  const ProviderRejectionDialogueWidget({
    super.key,
    String? name,
    String? service,
    String? specialty,
    double? amount,
  })  : this.name = name ?? 'Name of doctor or facility',
        this.service = service ?? 'Services',
        this.specialty = specialty ?? 'specialty or location',
        this.amount = amount ?? 3000.0;

  final String name;
  final String service;
  final String specialty;
  final double amount;

  @override
  State<ProviderRejectionDialogueWidget> createState() =>
      _ProviderRejectionDialogueWidgetState();
}

class _ProviderRejectionDialogueWidgetState
    extends State<ProviderRejectionDialogueWidget>
    with TickerProviderStateMixin {
  late ProviderRejectionDialogueModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProviderRejectionDialogueModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          MoveEffect(
            curve: Curves.bounceOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, 100.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).accent4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            elevation: 40.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 670.0,
              ),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12.0,
                    color: Color(0x1E000000),
                    offset: Offset(
                      0.0,
                      5.0,
                    ),
                  )
                ],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: Color(0xFFCB0009),
                          size: 40.0,
                        ),
                        Text(
                          FFLocalizations.of(context).getText(
                            'ef002p3a' /* Reject Applicant */,
                          ),
                          style:
                              FlutterFlowTheme.of(context).titleLarge.override(
                                    font: GoogleFonts.readexPro(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    color: Color(0xFFDC2626),
                                    fontSize: 25.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                        ),
                      ].divide(SizedBox(height: 5.0)),
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        'a41qq2s9' /* Please provide reason for reje... */,
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Material(
                        color: Colors.transparent,
                        elevation: 30.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 70.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: FlutterFlowChoiceChips(
                                            options: [
                                              ChipData(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                '8r8hsn2x' /* License Invalid */,
                                              )),
                                              ChipData(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                'ueqdthpm' /* License Expired */,
                                              ))
                                            ],
                                            onChanged: (val) => safeSetState(
                                                () =>
                                                    _model.reasonsValues = val),
                                            selectedChipStyle: ChipStyle(
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .info,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                              iconColor:
                                                  FlutterFlowTheme.of(context)
                                                      .info,
                                              iconSize: 25.0,
                                              elevation: 40.0,
                                              borderRadius:
                                                  BorderRadius.circular(18.0),
                                            ),
                                            unselectedChipStyle: ChipStyle(
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                              iconColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              iconSize: 25.0,
                                              elevation: 40.0,
                                              borderColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              borderRadius:
                                                  BorderRadius.circular(14.0),
                                            ),
                                            chipSpacing: 15.0,
                                            rowSpacing: 12.0,
                                            multiselect: true,
                                            initialized:
                                                _model.reasonsValues != null,
                                            alignment: WrapAlignment.start,
                                            controller: _model
                                                    .reasonsValueController ??=
                                                FormFieldController<
                                                    List<String>>(
                                              [],
                                            ),
                                            wrapped: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                                  .divide(SizedBox(height: 10.0))
                                  .around(SizedBox(height: 10.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Material(
                          color: Colors.transparent,
                          elevation: 22.0,
                          child: Container(
                            decoration: BoxDecoration(),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    'b2iok722' /* Cancel */,
                                  ),
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        24.0, 0.0, 24.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: Color(0xFF305A8B),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 40.0,
                                    borderSide: BorderSide(
                                      color: Color(0xFFD1D5DB),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(18.0),
                                    hoverColor:
                                        FlutterFlowTheme.of(context).primary,
                                    hoverBorderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FFButtonWidget(
                                  onPressed: () {
                                    print('Button pressed ...');
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    '1s0lwab8' /* Submit Rejection */,
                                  ),
                                  options: FFButtonOptions(
                                    height: 48.33,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        24.0, 0.0, 24.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).error,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 40.0,
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(20.0),
                                    hoverColor: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(width: 12.0)),
                          ),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
            ),
          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
        ],
      ),
    );
  }
}
