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
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Record audio from microphone and transcribe it using AWS Transcribe Medical
/// Returns the transcribed text
Future<String> recordAndTranscribeAudio(
  BuildContext context, {
  Duration maxDuration = const Duration(seconds: 30),
  VoidCallback? onRecordingStart,
  VoidCallback? onRecordingStop,
  Function(String)? onTranscribing,
}) async {
  final recorder = FlutterSoundRecorder();
  String transcribedText = '';

  try {
    // Request microphone permission
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return '';
    }

    // Initialize recorder
    await recorder.openRecorder();

    // Get temporary directory for audio file
    final appDocDir = await getTemporaryDirectory();
    final audioPath = '${appDocDir.path}/soap_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Start recording
    debugPrint('🎤 Starting audio recording to: $audioPath');
    onRecordingStart?.call();

    await recorder.startRecorder(
      toFile: audioPath,
      codec: Codec.aacADTS,
    );

    // Wait for max duration or until user stops
    await Future.delayed(maxDuration);

    // Stop recording
    debugPrint('⏹️ Stopping audio recording');
    onRecordingStop?.call();
    await recorder.stopRecorder();

    // Check if file exists and has content
    final audioFile = io.File(audioPath);
    if (!audioFile.existsSync()) {
      throw Exception('Audio file not created');
    }

    final fileSize = await audioFile.length();
    if (fileSize == 0) {
      throw Exception('Audio file is empty');
    }

    debugPrint('📁 Audio file size: $fileSize bytes');

    // Send audio to transcription endpoint
    onTranscribing?.call('Sending audio to transcription service...');
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);

    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final supabaseKey = FFDevEnvironmentValues().Supabasekey;

    // Read audio file as bytes
    final audioBytes = await audioFile.readAsBytes();

    // Send to transcription endpoint using multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$supabaseUrl/functions/v1/transcribe-audio-section'),
    );

    request.headers.addAll({
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
      'x-firebase-token': token ?? '',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'recording.m4a',
      ),
    );

    debugPrint('📡 Sending audio to transcription endpoint...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      transcribedText = data['transcription'] ?? data['text'] ?? '';
      debugPrint('✅ Transcription successful: $transcribedText');
    } else {
      debugPrint('❌ Transcription failed: ${response.statusCode} - $responseBody');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription failed: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Clean up temporary audio file
    try {
      await audioFile.delete();
      debugPrint('🗑️ Temporary audio file deleted');
    } catch (e) {
      debugPrint('⚠️ Could not delete temporary audio file: $e');
    }
  } catch (e) {
    debugPrint('❌ Error recording/transcribing audio: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } finally {
    await recorder.closeRecorder();
  }

  return transcribedText;
}
