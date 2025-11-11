import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'password_validation_item_model.dart';
export 'password_validation_item_model.dart';

class PasswordValidationItemWidget extends StatefulWidget {
  const PasswordValidationItemWidget({
    super.key,
    bool? isValid,
    required this.label,
  }) : this.isValid = isValid ?? true;

  final bool isValid;
  final String? label;

  @override
  State<PasswordValidationItemWidget> createState() =>
      _PasswordValidationItemWidgetState();
}

class _PasswordValidationItemWidgetState
    extends State<PasswordValidationItemWidget> {
  late PasswordValidationItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PasswordValidationItemModel());

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
      decoration: BoxDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Builder(
            builder: (context) {
              if (widget!.isValid) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/images/CheckCircle.png',
                    width: 16.0,
                    height: 16.0,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/images/XCircle.png',
                    width: 16.0,
                    height: 16.0,
                    fit: BoxFit.cover,
                  ),
                );
              }
            },
          ),
          Expanded(
            child: AnimatedDefaultTextStyle(
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
                    color: widget!.isValid
                        ? FlutterFlowTheme.of(context).success
                        : FlutterFlowTheme.of(context).error,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodySmall.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Text(
                valueOrDefault<String>(
                  widget!.label,
                  'No label',
                ),
              ),
            ),
          ),
        ].divide(SizedBox(width: 8.0)),
      ),
    );
  }
}
