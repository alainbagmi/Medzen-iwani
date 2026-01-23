# CLAUDE.md

Healthcare platform: FlutterFlow + Firebase Auth + Supabase + EHRbase + AWS Chime SDK + AWS Bedrock

## Quick Commands

| Action | Command |
|--------|---------|
| Run web | `flutter clean && flutter pub get && flutter run -d chrome` |
| Run Android | `flutter run -d android` |
| Run iOS | `flutter run -d ios` |
| Run tests | `flutter test` |
| Comprehensive tests | `./test_all_systems.sh` |
| Deploy Supabase functions | `npx supabase functions deploy [name]` |
| Watch logs | `npx supabase functions logs [name] --tail` |
| Reset DB locally | `npx supabase db reset` |

## Critical IDs & Versions

- **Firebase:** `medzen-bf20e` | **Supabase:** `noaeltglphdlkbflipit` | **AWS Region:** `eu-central-1`
- **Node.js:** 20.x | **Flutter:** >=3.0.0 <4.0.0 | **Chime SDK:** v3.19.0
- **Main PR Branch:** `ALINO` | **Supabase Pooler:** `aws-0-eu-central-1.pooler.supabase.com:6543`

## Non-Negotiable Rules

1. **Initialization Order** (`lib/main.dart:28-42`): Environment → Firebase → Supabase → Localizations → AppState → initializeMessaging()
2. **Never modify** `lib/flutter_flow/` (auto-generated). Ignore ~10k analyzer warnings on unused imports.
3. **Auth Pattern:** Firebase-only auth; data in Supabase via `firebase_uid` column
4. **RLS Policies:** Allow `auth.uid() IS NULL` for Firebase tokens (no Supabase session)
5. **Video Calls (Chime v3):** Use `startVideoInput()`/`startAudioInput()` (v2 deprecated)
   - Widget: `lib/custom_code/widgets/chime_meeting_enhanced.dart`
   - Action: `lib/custom_code/actions/join_room.dart`
   - CDN: `https://du6iimxem4mh7.cloudfront.net/assets/amazon-chime-sdk-medzen.min.js`
6. **Edge Functions:** HTTP (not `SupaFlow.client.functions.invoke()`); Firebase token in `x-firebase-token` header (lowercase)
7. **Migrations:** Never edit existing; create new: `supabase/migrations/YYYYMMDDHHMMSS_*.sql`
8. **UUIDs:** Never cast to TEXT; use native UUID
9. **Firebase Config:** Never hardcode credentials
10. **FlutterFlow Conflicts:** Accept generated version; re-apply custom logic in `lib/custom_code/`

## Directory Structure

```
lib/
├── main.dart                      # Critical init order (28-42)
├── app_state.dart                 # FFAppState global state
├── flutter_flow/                  # ⚠️  Auto-generated (NEVER edit)
└── custom_code/                   # Your edits (actions/ + widgets/)

supabase/
├── functions/                     # 18+ edge functions (TypeScript)
└── migrations/                    # Database schema (NEVER edit existing)
```

## Core Architecture

**State:** FFAppState singleton + flutter_secure_storage

**Backend Patterns:**
1. Supabase direct queries: `SupaFlow.client.from('table').select()...`
2. Edge functions: HTTP POST with Firebase token in `x-firebase-token` header
3. Firebase functions: Cloud Functions (auth events, direct calls)

**Real-time:** Supabase subscriptions via `realtime()` (e.g., chime_messages)

**Error Handling:** Edge functions return `{ error, code, status }` format

## Key Files & Actions

| Type | Path | Notes |
|------|------|-------|
| Entry | `lib/main.dart` | Critical init order |
| State | `lib/app_state.dart` | FFAppState, secure storage |
| Video Call | `lib/custom_code/widgets/chime_meeting_enhanced.dart` | ~2k lines, Chime v3 |
| Join Room | `lib/custom_code/actions/join_room.dart` | ~1k lines, orchestrator |
| Edge Funcs | `supabase/functions/*/index.ts` | 18 standard functions |

## Important Code Patterns

```dart
// Global state
FFAppState().update(() { FFAppState().UserRole = 'patient'; });

// Firebase token (always force-refresh)
final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);

// Call edge function
final response = await http.post(
  Uri.parse('$supabaseUrl/functions/v1/function-name'),
  headers: {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'x-firebase-token': token,  // lowercase!
    'Content-Type': 'application/json',
  },
  body: jsonEncode(requestBody),
);

// Exponential backoff retry (3 attempts)
int retries = 0;
while (retries < 3) {
  try { final r = await http.post(...); if (r.statusCode == 200) break; }
  catch (e) { retries++; await Future.delayed(Duration(seconds: pow(2, retries).toInt())); }
}
```

## Video Call Workflow (joinRoom)

**Stage 1: Pre-Call**
- Show ChimePreJoiningDialog for device permissions
- Call create-context-snapshot edge function (gathers patient demographics + appointment context)
- Fetch existing SOAP notes for context

**Stage 2: Video**
- Force-refresh Firebase token
- Call chime-meeting-token with 3-retry backoff
- Initialize Chime SDK from CloudFront CDN
- Stream real-time messages, capture transcription (12-sec buffer)
- Enable live captions with 3-5sec fade

**Stage 3: Post-Call**
- Stop transcription, build speaker map
- Initiate AWS Transcribe Medical job
- Call generate-soap-draft-v2 with context snapshot + transcript
- Provider reviews/edits SOAP in PostCallClinicalNotesDialog
- Provider signs and saves to clinical_notes table
- System triggers sync-to-ehrbase for OpenEHR integration

## Pre-Call Context Snapshot

Three-tier query architecture:
1. **appointment_overview** - Appointment + patient + provider (denormalized)
2. **users table** - Date of birth, gender, phone_number, email
3. **user_profiles** - Address, emergency contact info
4. **patient_profiles** - Patient number, blood type

**patient_demographics (14 fields):**
- REQUIRED (8): id, full_name, dob, age, gender, phone, email, created_at
- OPTIONAL (6): patient_number, address, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship, blood_type

**appointment_context (9 fields):**
- appointment_id, appointment_number, chief_complaint, appointment_type, specialty, scheduled_start, provider_name, provider_specialty, facility_name

**Tab 2 Validation:**
- Confidence: 0.8 base, -0.2 per missing required field, floor 0.5
- Threshold: >0.70 for clinical use
- ai_flags tracks missing_critical_info and needs_clinician_confirmation

## Debugging Quick Reference

| Issue | Fix |
|-------|-----|
| **401 INVALID_FIREBASE_TOKEN** | Header must be lowercase `x-firebase-token`. Call `getIdToken(true)`. |
| **403 PATIENT_CANNOT_CREATE** | Only providers create calls. Check `isProvider` param. |
| **404 NO_ACTIVE_CALL** | Verify `sessionId` in `video_call_sessions`. |
| **410 MEETING_EXPIRED** | Check `ended_at` timestamp in `video_call_sessions`. |
| **500** | Check: `npx supabase functions logs <name> --tail`. Verify env vars, AWS creds. |
| **Video blank** | Browser console: verify Chime SDK CDN loads. Check `startVideoInput()` called. |
| **RLS blocking** | Policy must allow `auth.uid() IS NULL OR user_id = auth.uid()`. |
| **Transcription stuck** | Check `transcription_usage_daily` for AWS limits. |
| **Tab 2 missing fields** | Verify create-context-snapshot deployed and context snapshots populated. |
| **Build fails** | `flutter clean && flutter pub get` |

## Custom Actions & Widgets

**Adding a Custom Action:**
1. Create `lib/custom_code/actions/my_action.dart`
2. Export in `lib/custom_code/actions/index.dart`
3. Call from FlutterFlow: Custom Action → choose your action
4. For edge functions: use Firebase token + retry pattern

**Adding a Custom Widget:**
1. Create `lib/custom_code/widgets/my_widget.dart` (extends StatefulWidget/StatelessWidget)
2. Export in `lib/custom_code/widgets/index.dart`
3. Add in FlutterFlow: Custom Widget → select from list

**Adding Edge Function:**
1. Create `supabase/functions/my-function/index.ts`
2. Use `verifyFirebaseJWT()` for auth
3. Deploy: `npx supabase functions deploy my-function`
4. View logs: `npx supabase functions logs my-function --tail`

## Edge Function Authentication

```typescript
const token = req.headers['x-firebase-token'];
const auth = await verifyFirebaseJWT(token);
if (!auth.valid) return { error: 'Unauthorized', code: 'INVALID_FIREBASE_TOKEN', status: 401 };
const result = await supabaseAdminClient.from('table').select().eq('user_id', auth.userId);
return { success: true, data: result, status: 200 };
```

## Database Tables (By Category)

**Users/Profiles:** users (firebase_uid, lat/lng + PostGIS), patient_profiles, medical_provider_profiles, facility_admin_profiles, system_admin_profiles, facilities

**Appointments/Calls:** appointments, video_call_sessions, chime_messages, call_notifications, transcription_usage_daily

**AI/Clinical:** ai_assistants, ai_conversations, ai_messages, clinical_notes, ehrbase_sync_queue

**Other:** active_sessions, language_preferences, Storage: chime_storage, profile_pictures

**Pharmacy:** pharmacy_products, pharmacy_inventory, user_cart, user_addresses, pharmacy_orders, pharmacy_coupons

## Error Codes

- **401 INVALID_FIREBASE_TOKEN** - Token invalid/expired/malformed
- **403 PATIENT_CANNOT_CREATE** - Patients can't initiate calls
- **403 INSUFFICIENT_PERMISSIONS** - Lacks role/authorization
- **404 NO_ACTIVE_CALL** - Meeting doesn't exist/inactive
- **410 MEETING_EXPIRED** - Meeting ended/finalized

## Development Setup

```bash
nvm use 20 && flutter pub get && cd firebase/functions && npm install && cd ../..
npx supabase link --project-ref noaeltglphdlkbflipit
flutter run -d chrome
```

**Required:** `assets/environment_values/environment.json` (request from team; gitignored)

**Verify:** `dart --version`, `flutter --version`, `node --version`, `firebase --version`

## Git Workflow

- **Branch:** `ALINO` (main PR target, not main)
- **Before push:** `git fetch origin ALINO && git rebase origin/ALINO && dart analyze lib/ --fatal-infos && flutter test`
- **FlutterFlow conflicts:** `git checkout --theirs lib/flutter_flow/ && git add lib/flutter_flow/`

## Cloud Functions Summary

**Firebase (6):** onUserCreated, onUserDeleted, addFcmToken, sendPushNotificationsTrigger, sendScheduledPushNotifications, sendVideoCallNotification

**Supabase Edge (18):** bedrock-ai-chat, chime-meeting-token, chime-messaging, start-medical-transcription, generate-soap-draft-v2, sync-to-ehrbase, storage-sign-url, upload-profile-picture, etc.

## Key Integrations

- **AWS Chime SDK v3** - Video calls via InAppWebView (CDN-hosted)
- **AWS Bedrock** - AI chat (role-based models: Nova Lite/Pro, Claude Opus)
- **AWS Transcribe Medical** - Async transcription (2-10 min)
- **EHRbase** - OpenEHR clinical records (EU-1 region)
- **Firebase Auth** - Authentication only
- **PostGIS** - Geolocation (50km radius queries)

## Performance Tips

- **Slow queries:** Add indexes on user_id, firebase_uid, appointment_id
- **Transcription:** 2-10 min; show progress UI
- **Chime SDK:** Pre-cache from CloudFront or use service worker
- **Realtime:** Use filters; avoid subscribing to large tables
- **Large widgets:** Use `const` constructors; profile ChimeMeetingEnhanced separately

## External Resources

[Flutter](https://flutter.dev/docs) | [Supabase](https://supabase.com/docs) | [Firebase](https://firebase.google.com/docs) | [AWS Chime SDK](https://docs.aws.amazon.com/chime-sdk/) | [AWS Bedrock](https://docs.aws.amazon.com/bedrock/)
