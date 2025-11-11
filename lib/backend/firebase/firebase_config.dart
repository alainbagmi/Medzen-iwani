import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ",
            authDomain: "medzen-bf20e.firebaseapp.com",
            projectId: "medzen-bf20e",
            storageBucket: "medzen-bf20e.firebasestorage.app",
            messagingSenderId: "1084592687667",
            appId: "1:1084592687667:web:ec6aeeedc7c8535cb0b146",
            measurementId: "G-SMXWQMHERC"));
  } else {
    await Firebase.initializeApp();
  }
}
