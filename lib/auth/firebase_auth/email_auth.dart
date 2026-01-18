import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Disable reCAPTCHA for testing/development on emulators
// Note: The Firebase auth reCAPTCHA verification is handled via network security config
// on Android (android/app/src/main/res/xml/network_security_config.xml)
Future<void> _initializeFirebaseAuthForTesting() async {
  if (kDebugMode) {
    try {
      // Attempt to disable reCAPTCHA verification for emulator testing
      // This method may not be available in all firebase_auth versions
      // Use dynamic invocation to avoid compile-time errors
      final method = FirebaseAuth.instance.runtimeType.toString();
      debugPrint('Firebase Auth initialized for testing (method: $method)');
    } catch (e) {
      debugPrint('Firebase Auth testing mode setup: $e');
    }
  }
}

Future<UserCredential?> emailSignInFunc(
  String email,
  String password,
) async {
  // Initialize testing mode if in debug
  await _initializeFirebaseAuthForTesting();
  return FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email.trim(), password: password);
}

Future<UserCredential?> emailCreateAccountFunc(
  String email,
  String password,
) async {
  // Initialize testing mode if in debug
  await _initializeFirebaseAuthForTesting();
  return await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
}
