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

Future<void> htmlfile() async {
  // No-op for non-web platforms
}

class ScriptElement {
  Stream<void> get onLoad => Stream.value(null);
  String? id;
  String? src;
  String? type;
}

class Document {
  dynamic querySelector(String selector) => null;
  dynamic get body => null;
}

class HtmlMock {
  static final document = Document();
}

final document = HtmlMock.document;
