import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'header_back_model.dart';
export 'header_back_model.dart';

class HeaderBackWidget extends StatefulWidget {
  const HeaderBackWidget({super.key});

  @override
  State<HeaderBackWidget> createState() => _HeaderBackWidgetState();
}

class _HeaderBackWidgetState extends State<HeaderBackWidget> {
  late HeaderBackModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HeaderBackModel());

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
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional(-1.0, 0.0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
                  child: FlutterFlowIconButton(
                    borderColor: FlutterFlowTheme.of(context).primaryText,
                    borderRadius: 20.0,
                    borderWidth: 2.0,
                    buttonSize: 50.0,
                    fillColor: FlutterFlowTheme.of(context).primaryBackground,
                    hoverColor: FlutterFlowTheme.of(context).primary,
                    icon: Icon(
                      Icons.chevron_left,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 35.0,
                    ),
                    onPressed: () async {
                      context.safePop();
                    },
                  ),
                ),
              ),
            ),
            Icon(
              Icons.more_vert,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 30.0,
            ),
          ],
        ),
      ),
    );
  }
}
