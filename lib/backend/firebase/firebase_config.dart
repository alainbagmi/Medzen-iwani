import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  try {
    // Try initializing Firebase - on web and desktop, this is required
    // On Android/iOS, native configs may already initialize it
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ",
            authDomain: "medzen-bf20e.firebaseapp.com",
            projectId: "medzen-bf20e",
            storageBucket: "medzen-bf20e.firebasestorage.app",
            messagingSenderId: "1084592687667",
            appId: kIsWeb
                ? "1:1084592687667:web:ec6aeeedc7c8535cb0b146"
                : "1:1084592687667:android:8c6c6e3e7e3e3e3e",
            measurementId: kIsWeb ? "G-SMXWQMHERC" : null));

    // Set Firebase Auth locale to prevent null header warning
    FirebaseAuth.instance.setLanguageCode('en');
  } catch (e) {
    // Firebase already initialized by native code (Android/iOS)
    // This is expected - native configs init Firebase before Dart code runs
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
}
