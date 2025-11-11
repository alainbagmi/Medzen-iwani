// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:html' if (dart.library.io) '/custom_code/actions/htmlfile.dart'
    as html;

Future<void> loadAgoraSdkScript() async {
  try {
    final agoraSdk = html.document.querySelector('#agora-sdk');
    if (agoraSdk == null) {
      final script1 = html.ScriptElement()
        ..id = 'agora-sdk'
        ..src = 'https://download.agora.io/sdk/release/AgoraRTC_N.js'
        ..type = 'application/javascript';
      html.document.body?.append(script1);
      await script1.onLoad.first;
      print('✅ AgoraRTC_N.js loaded');
    }

    final irisSdk = html.document.querySelector('#iris-sdk');
    if (irisSdk == null) {
      final script2 = html.ScriptElement()
        ..id = 'iris-sdk'
        ..src =
            'https://download.agora.io/sdk/release/iris-web-rtc_n450_w4220_0.8.6.js'
        ..type = 'application/javascript';
      html.document.body?.append(script2);
      await script2.onLoad.first;
      print('✅ Iris SDK loaded');
    }
  } catch (e, s) {
    print('❌ ERROR loading Agora SDK: $e\n$s');
  }
}
