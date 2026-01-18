import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Disable reCAPTCHA for testing/development on emulators
Future<void> _initializeFirebaseAuthForTesting() async {
  if (kDebugMode) {
    try {
      // Disable reCAPTCHA verification for emulator testing
      // This allows Firebase auth to work on emulators without network issues
      await FirebaseAuth.instance.setAppVerificationDisabledForTesting(true);
    } catch (e) {
      // setAppVerificationDisabledForTesting only available on Android/iOS
      // Web doesn't support this, so catch and ignore the error
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
