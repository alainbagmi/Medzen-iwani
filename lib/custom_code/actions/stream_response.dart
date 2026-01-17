// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:http/http.dart' as http;

Future streamResponse(
    Future Function() onStreamCallback,
    Future Function(String? error)? onErrorCallback,
    Future Function(String? threadId)? onCompleteCallback,
    String url,
    String prompt,
    String? threadId) async {
  try {
    // Setup our request. Pass in a pompt within the body of the request
    var request = http.Request('POST', Uri.parse(url))
      ..headers.addAll({'Content-Type': 'application/json'})
      ..body = jsonEncode({'prompt': prompt, 'threadId': threadId});

    // Send the request
    var streamedResponse = await request.send();

    // Retrieve the Thread ID from the header in the response
    String? responseThreadId = streamedResponse.headers['x-thread-id'];

    // Listen to the response stream
    streamedResponse.stream.transform(utf8.decoder).listen((value) {
      // Continually add the response value to the App State variable called streamResponse
      FFAppState().streamResponse += value;
      // Perform callback to perform state update!
      onStreamCallback();
    }, onError: (e) {
      if (onErrorCallback != null) {
        onErrorCallback(e);
      }
    }, onDone: () {
      if (onCompleteCallback != null) {
        onCompleteCallback(responseThreadId);
      }
    });
  } catch (e) {
    // Handle any other errors
    debugPrint('Error: $e');
  }
}
