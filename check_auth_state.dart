import 'package:flutter/material.dart';
import '/backend/supabase/supabase.dart';
import '/auth/firebase_auth/auth_util.dart';

// DIAGNOSTIC TOOL: Check Authentication State
// Run this to verify both Firebase and Supabase auth are active

Future<void> checkAuthState(BuildContext context) async {
  print('=== AUTHENTICATION STATE CHECK ===');

  // 1. Check Firebase Auth
  final firebaseUser = currentUser;
  print('\n📱 Firebase Auth:');
  print('  Logged in: ${firebaseUser != null}');
  if (firebaseUser != null) {
    print('  UID: ${currentUserUid}');
    print('  Email: ${currentUserEmail}');
  } else {
    print('  ❌ No Firebase user!');
  }

  // 2. Check Supabase Auth Session
  final supabaseSession = SupaFlow.client.auth.currentSession;
  final supabaseUser = SupaFlow.client.auth.currentUser;

  print('\n🔐 Supabase Auth:');
  print('  Session exists: ${supabaseSession != null}');
  print('  User exists: ${supabaseUser != null}');

  if (supabaseSession != null) {
    print('  Access Token: ${supabaseSession.accessToken.substring(0, 20)}...');
    print('  User ID: ${supabaseUser?.id}');
    print('  Role: ${supabaseUser?.role}');
  } else {
    print('  ❌ No Supabase session!');
    print('  ⚠️  THIS IS THE PROBLEM - Storage uploads will fail!');
  }

  // 3. Check auth.uid() equivalent
  final authUid = supabaseUser?.id;
  print('\n🎯 auth.uid() Check:');
  print('  Value: ${authUid ?? "NULL"}');
  if (authUid == null) {
    print('  ❌ RLS policies requiring auth.uid() will FAIL');
  } else {
    print('  ✅ RLS policies will work');
  }

  print('\n=== END AUTH CHECK ===\n');

  // Show result to user
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          supabaseSession != null
              ? '✅ Both Firebase & Supabase authenticated'
              : '❌ Supabase session missing - uploads will fail!',
        ),
        backgroundColor: supabaseSession != null ? Colors.green : Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
