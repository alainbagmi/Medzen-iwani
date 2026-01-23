# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Medzen** is an enterprise-grade e-health platform built on Flutter + Firebase + Supabase + AWS that enables video consultations, AI-powered clinical documentation, and OpenEHR-compliant electronic health records. It supports multi-language medical terminology, offline-first synchronization, and advanced clinical integrations.

**Tech Stack:** Flutter/Dart (UI) + Firebase Auth + Supabase PostgreSQL + AWS Chime SDK (video) + AWS Bedrock (AI) + AWS Transcribe Medical + EHRbase (OpenEHR) + PowerSync (offline sync)

**Platforms:** Web, iOS, Android, Windows, Linux (Flutter multi-platform)

**Main Branch:** `ALINO` (not `main`)

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| **Setup** | `flutter pub get && npm install && npx supabase link --project-ref noaeltglphdlkbflipit` |
| **Run web** | `flutter clean && flutter pub get && flutter run -d chrome` |
| **Run Android** | `flutter run -d android` |
| **Run iOS** | `flutter run -d ios` |
| **Run tests** | `flutter test` |
| **Lint analysis** | `dart analyze lib/ --fatal-infos` |
| **Deploy Supabase function** | `npx supabase functions deploy [function-name]` |
| **Watch Supabase logs** | `npx supabase functions logs [function-name] --tail` |
| **Deploy Firebase functions** | `firebase deploy --only functions` |
| **Reset local Supabase DB** | `npx supabase db reset` |
| **Link to Supabase project** | `npx supabase link --project-ref noaeltglphdlkbflipit` |

---

## Critical Configuration

| Item | Value |
|------|-------|
| **Firebase Project** | `medzen-bf20e` |
| **Supabase Project** | `noaeltglphdlkbflipit` |
| **AWS Region** | `eu-central-1` (EU compliance) |
| **Node.js Version** | 20.x |
| **Flutter Version** | >=3.0.0 <4.0.0 |
| **Chime SDK Version** | v3.19.0 (deployed to CloudFront) |
| **Supabase Pooler** | `aws-0-eu-central-1.pooler.supabase.com:6543` |
| **Environment File** | `assets/environment_values/environment.json` (gitignored—request from team) |

---

## Architecture Overview

### Multi-Tier Architecture

**Frontend Layer (lib/)**
- Flutter UI with FlutterFlow visual components
- Custom Dart actions & widgets in `lib/custom_code/`
- State management via FFAppState (singleton) + Provider package
- Secure storage via flutter_secure_storage

**Backend Services**
- **Firebase:** Authentication only (email, Google, Apple Sign-In)
- **Supabase:** PostgreSQL database + Edge Functions (TypeScript)
- **AWS:** Chime SDK (video), Transcribe Medical (speech-to-text), Bedrock (AI), Lambda (serverless)
- **EHRbase:** OpenEHR reference implementation for clinical records

**Real-time Sync**
- PowerSync: Offline-first real-time synchronization
- Supabase Realtime: WebSocket subscriptions for live updates

### Database Schema (Supabase PostgreSQL)

**User & Profile Tables**
- `users` - Firebase user identity (firebase_uid, email, phone, lat/lng with PostGIS)
- `patient_profiles` - Patient medical data (patient_number, blood_type, emergency contact)
- `medical_provider_profiles` - Provider credentials (specialty, license)
- `facility_admin_profiles` - Facility administration
- `facilities` - Healthcare centers

**Clinical & Video Tables**
- `appointments` - Scheduling (patient_id, provider_id, chief_complaint, status)
- `video_call_sessions` - Call metadata (session_id, meeting_id, recording_url)
- `chime_messages` - Real-time call chat
- `clinical_notes` - SOAP notes (subjective, objective, assessment, plan, signature)
- `ehrbase_sync_queue` - Pending OpenEHR syncs

**AI & Communication Tables**
- `ai_conversations` - Chat history (user_id, assistant_id, messages)
- `ai_messages` - Individual messages
- `call_notifications` - Notification queue
- `transcription_usage_daily` - Usage tracking

**Auxiliary Tables**
- `active_sessions` - Real-time user presence
- `language_preferences` - Localization settings

### Core Directories

```
lib/
├── main.dart                              # APP ENTRY (init order: lines 28-42 CRITICAL)
├── app_state.dart                         # FFAppState singleton
├── custom_code/
│   ├── actions/
│   │   ├── join_room.dart                 # Video call orchestration (~1k lines)
│   │   ├── create_a_i_conversation.dart
│   │   └── ... (29 custom actions)
│   └── widgets/
│       ├── chime_meeting_enhanced.dart    # Chime video UI (~2k lines, ~295KB)
│       ├── post_call_clinical_notes_dialog.dart
│       ├── soap_note_tabbed_view.dart
│       └── ... (13 custom widgets)
├── flutter_flow/                          # ⚠️ AUTO-GENERATED (never edit)
├── backend/                               # Supabase & Firebase integration
├── auth/                                  # Authentication pages
├── patients_folder/, medical_provider/    # Role-based UIs
├── components/                            # Reusable UI components (~36)
└── chat_a_i/                              # AI chat interface

supabase/
├── functions/                             # 59 edge functions (TypeScript)
│   ├── _shared/                           # Shared utils (verify-firebase-jwt, CORS, rate-limiting)
│   ├── chime-meeting-token/               # Chime token + AWS Lambda integration
│   ├── bedrock-ai-chat/                   # AI chat via AWS Bedrock
│   ├── create-context-snapshot/           # Pre-call patient context
│   ├── generate-clinical-note/            # SOAP generation
│   ├── sync-to-ehrbase/                   # OpenEHR composition creation
│   └── ... (53 more functions)
└── migrations/                            # Database schema (~260 files)

firebase/
├── functions/                             # Cloud Functions (Node.js)
│   ├── onUserCreated()                    # New user initialization
│   ├── onUserDeleted()                    # User cleanup
│   ├── addFcmToken()                      # Device token registration
│   ├── sendPushNotificationsTrigger()     # Push notifications
│   ├── sendScheduledPushNotifications()   # Reminder notifications
│   └── sendVideoCallNotification()        # Call alerts

aws-lambda/                                # Lambda functions (Node.js/Python)
├── bedrock-ai-chat/
├── chime-meeting-manager/
├── chime-recording-processor/
├── chime-transcription-processor/
├── medical-entity-extraction/
└── health-check/

openehr-mcp-server/                        # OpenEHR MCP Server (Python)
powersync-mcp-server/                      # PowerSync MCP Server (Python)
ehrbase-templates/                         # OpenEHR templates (~40 files)
medical-vocabularies/                      # Medical terms (10+ languages)
```

---

## Non-Negotiable Rules

### 1. Initialization Order (lib/main.dart:28-42)
The app initializes services in this exact sequence. **DO NOT CHANGE THIS ORDER:**
```
1. Load environment configuration
2. Initialize Firebase
3. Initialize Supabase
4. Set up localizations
5. Initialize FFAppState
6. Call initializeMessaging() for FCM
```

### 2. Never Modify lib/flutter_flow/
This directory is auto-generated by FlutterFlow. If it conflicts with your changes:
```bash
git checkout --theirs lib/flutter_flow/
git add lib/flutter_flow/
```
Ignore ~10k analyzer warnings on unused imports. If you need custom logic, implement it in `lib/custom_code/actions/` or `lib/custom_code/widgets/`.

### 3. Authentication Pattern
- **Frontend:** Firebase Auth (email, Google, Apple)
- **Backend:** Firebase tokens (JWT) in `x-firebase-token` header (lowercase!)
- **Database:** Data stored in Supabase via `firebase_uid` column
- **Edge Functions:** Always verify Firebase JWT; use Supabase admin client to query data

### 4. Row-Level Security (RLS) Policies
All Supabase tables must have RLS policies that allow:
- `auth.uid() IS NULL` - Firebase tokens have no Supabase session
- `user_id = auth.uid()` - User sees own data
- Provider/admin escalation for authorized users

Example:
```sql
CREATE POLICY "Allow Firebase auth" ON appointments
  USING (auth.uid() IS NULL OR user_id = auth.uid());
```

### 5. Video Calls (AWS Chime SDK v3)
- Use `startVideoInput()` and `startAudioInput()` (v2 methods are deprecated)
- Widget: `lib/custom_code/widgets/chime_meeting_enhanced.dart`
- Action orchestrator: `lib/custom_code/actions/join_room.dart`
- SDK loaded from CloudFront CDN: `https://du6iimxem4mh7.cloudfront.net/assets/amazon-chime-sdk-medzen.min.js`

### 6. Edge Functions (Supabase Functions)
- Use HTTP endpoints (not `SupaFlow.client.functions.invoke()`)
- Always include Firebase token in `x-firebase-token` header (lowercase)
- Verify token with `verifyFirebaseJWT()` helper
- Implement 3-retry exponential backoff for critical operations
- Deploy with: `npx supabase functions deploy function-name`

### 7. Database Migrations
- Never edit existing migration files
- Create new migration: `supabase/migrations/YYYYMMDDHHMMSS_description.sql`
- Apply locally: `npx supabase db reset`
- Always include timestamp comment for clarity

### 8. UUID Handling
- Never cast UUIDs to TEXT
- Use native UUID type: `uuid DEFAULT uuid_generate_v4()`
- UUIDs auto-generate on insert

### 9. Firebase Configuration
- Never hardcode Firebase credentials in code
- Load from `environment.json` at runtime
- Use environment variables for sensitive data
- `.gitignore` protects `assets/environment_values/environment.json`

### 10. FlutterFlow Conflicts
- Accept generated FlutterFlow code
- Re-apply custom logic in `lib/custom_code/` after regeneration
- Use custom actions/widgets as extension points

---

## Authentication & API Pattern

### Firebase Token Flow
```dart
// In custom action or Dart code:
final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);  // Force refresh!

// Call edge function with token:
final response = await http.post(
  Uri.parse('$supabaseUrl/functions/v1/function-name'),
  headers: {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'x-firebase-token': token,  // LOWERCASE!
    'Content-Type': 'application/json',
  },
  body: jsonEncode(requestBody),
);
```

### Edge Function Pattern
```typescript
// supabase/functions/my-function/index.ts
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';
import { createSupabaseAdminClient } from '../_shared/supabase.ts';

const token = req.headers['x-firebase-token'];
const auth = await verifyFirebaseJWT(token);

if (!auth.valid) {
  return new Response(
    JSON.stringify({ error: 'Unauthorized', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
    { status: 401 }
  );
}

const supabase = createSupabaseAdminClient();
const data = await supabase.from('table').select().eq('firebase_uid', auth.uid);

return new Response(JSON.stringify({ data }), { status: 200 });
```

### Retry Pattern (3 attempts, exponential backoff)
```dart
int retries = 0;
while (retries < 3) {
  try {
    final r = await http.post(...);
    if (r.statusCode == 200) break;
  } catch (e) {
    retries++;
    await Future.delayed(Duration(seconds: pow(2, retries).toInt()));
  }
}
```

---

## Video Call Workflow (Three Stages)

### Stage 1: Pre-Call Setup
1. Show `ChimePreJoiningDialog` for device permissions
2. Call `create-context-snapshot` edge function
   - Gathers patient demographics (8 required fields)
   - Fetches appointment context (chief complaint, specialty)
   - Retrieves existing SOAP notes
3. Validate context confidence score:
   - Base: 0.8
   - Penalty: -0.2 per missing required field
   - Floor: 0.5, Threshold: >0.70 for clinical use

**Patient Demographics (14 fields):**
- REQUIRED (8): id, full_name, dob, age, gender, phone, email, created_at
- OPTIONAL (6): patient_number, address, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship, blood_type

### Stage 2: During Call
1. Force-refresh Firebase token
2. Call `chime-meeting-token` edge function (with 3-retry backoff)
3. Initialize AWS Chime SDK from CloudFront CDN
4. Stream real-time messages via Supabase subscriptions
5. Capture transcription (12-second buffer)
6. Enable live captions (3-5 second fade)
7. Build speaker identification map

### Stage 3: Post-Call (SOAP Generation)
1. Stop transcription, finalize speaker map
2. Initiate AWS Transcribe Medical async job (2-10 min)
3. Call `generate-soap-draft-v2` with:
   - Context snapshot (patient + appointment)
   - Full transcript with speaker map
   - Historical SOAP notes for context
4. Provider reviews/edits SOAP in `PostCallClinicalNotesDialog`
5. Provider reviews confidence scores & missing fields
6. Provider cryptographically signs SOAP
7. Save to `clinical_notes` table
8. Trigger `sync-to-ehrbase` for OpenEHR composition creation
9. Archive transcription and metadata

---

## Role-Based Access & Permissions

| Role | Create Calls | Review Notes | Sign SOAP | View All Data | Admin Panel |
|------|:---:|:---:|:---:|:---:|:---:|
| Patient | ❌ (provider initiates) | ❌ | ❌ | ❌ (own only) | ❌ |
| Provider | ✅ | ✅ | ✅ | ✅ (own patients) | ❌ |
| Facility Admin | ❌ | ❌ | ❌ | ✅ (facility) | ✅ (facility) |
| System Admin | ❌ | ❌ | ❌ | ✅ (all) | ✅ (all) |

---

## Common Development Tasks

### Adding a New Page
1. Create directory: `lib/[category]/[page_name]/`
2. Create main widget: `[page_name].dart`
3. Import in `lib/index.dart`
4. Add to FlutterFlow navigation

### Adding a Custom Action
1. Create: `lib/custom_code/actions/my_action.dart`
2. Export in: `lib/custom_code/actions/index.dart`
3. Signature: `Future<dynamic> myAction(...) async { ... }`
4. Call from FlutterFlow: Custom Action → select your action

### Adding a Custom Widget
1. Create: `lib/custom_code/widgets/my_widget.dart` (extends StatefulWidget/StatelessWidget)
2. Export in: `lib/custom_code/widgets/index.dart`
3. Add in FlutterFlow: Custom Widget → select from list

### Adding an Edge Function
1. Create directory: `supabase/functions/my-function/`
2. Create: `supabase/functions/my-function/index.ts`
3. Use `verifyFirebaseJWT()` for auth
4. Import shared helpers from `_shared/`
5. Deploy: `npx supabase functions deploy my-function`
6. Monitor: `npx supabase functions logs my-function --tail`

### Adding a Database Migration
1. Create new file: `supabase/migrations/YYYYMMDDHHMMSS_description.sql`
2. Write SQL for new tables/columns/indexes
3. Test locally: `npx supabase db reset`
4. Never edit existing migration files

### Deploying to Production
```bash
# Verify changes
git status
dart analyze lib/ --fatal-infos
flutter test

# Commit
git add .
git commit -m "feat: description"
git push origin feature/branch-name

# Create PR to ALINO branch
gh pr create --base ALINO --title "Your PR Title"

# After PR merge, deploy functions
firebase deploy --only functions
npx supabase functions deploy [function-names]

# For mobile/web builds
flutter build web --release
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## Key Code Patterns

### Global State (FFAppState)
```dart
// Read
FFAppState().UserRole
FFAppState().AuthUserPhone

// Write
FFAppState().update(() {
  FFAppState().UserRole = 'patient';
  FFAppState().AuthUserPhone = '+1234567890';
});
```

### Secure Storage
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
await storage.write(key: 'token', value: authToken);
final token = await storage.read(key: 'token');
```

### Supabase Query
```dart
final response = await SupaFlow.client
  .from('appointments')
  .select('*, users(*)')
  .eq('patient_id', userId)
  .order('scheduled_start', ascending: false);
```

### Real-time Subscription (Supabase)
```dart
SupaFlow.client
  .channel('public:chime_messages')
  .on(RealtimeListenTypes.postgresChanges,
    payload: RealtimePostgresChangesPayload(
      event: '*',
      schema: 'public',
      table: 'chime_messages',
      filter: 'session_id=eq.$sessionId',
    ),
    callback: (payload) {
      // Handle message
    },
  )
  .subscribe();
```

### Firebase Token (Always Force Refresh!)
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
```

---

## Debugging Quick Reference

| Error | Cause | Fix |
|-------|-------|-----|
| **401 INVALID_FIREBASE_TOKEN** | Token invalid/expired/malformed | Check header case (`x-firebase-token` lowercase), call `getIdToken(true)` |
| **403 PATIENT_CANNOT_CREATE** | Patient tried to initiate call | Only providers can create calls; verify `isProvider` param |
| **403 INSUFFICIENT_PERMISSIONS** | User lacks authorization | Check RLS policies & role assignment |
| **404 NO_ACTIVE_CALL** | Meeting doesn't exist | Verify `sessionId` in `video_call_sessions` table |
| **410 MEETING_EXPIRED** | Call ended/finalized | Check `ended_at` timestamp; verify call status |
| **500 Edge Function Error** | Server-side failure | Run `npx supabase functions logs [name] --tail` |
| **Video Blank** | Chime SDK not loaded | Browser console: verify CDN loads, check `startVideoInput()` called |
| **RLS Blocking Queries** | Security policy denies access | Ensure policy allows `auth.uid() IS NULL` for Firebase tokens |
| **Transcription Stuck** | AWS usage limit reached | Check `transcription_usage_daily` table vs quotas |
| **Tab 2 Missing Fields** | Context snapshot incomplete | Verify `create-context-snapshot` deployed; check snapshot population |
| **Build Fails** | Dependencies outdated | `flutter clean && flutter pub get` |
| **Firebase Auth Fails** | credentials issue | Verify `environment.json` loaded; check Firebase project ID |

---

## Important Integration Details

### AWS Chime SDK
- **Version:** v3.19.0 (v2 methods deprecated)
- **CDN URL:** `https://du6iimxem4mh7.cloudfront.net/assets/amazon-chime-sdk-medzen.min.js`
- **Deployment:** CDN-hosted JavaScript (pre-cached)
- **Methods:** Use `startVideoInput()` and `startAudioInput()`
- **Widget Location:** `lib/custom_code/widgets/chime_meeting_enhanced.dart`

### AWS Bedrock (AI)
- **Models:** Claude Opus (advanced), Nova Lite/Pro (cost-optimized)
- **Use Case:** SOAP note generation, AI chat
- **Edge Function:** `bedrock-ai-chat/`, `generate-clinical-note/`
- **Region:** eu-central-1

### AWS Transcribe Medical
- **Purpose:** Medical speech-to-text (2-10 min async)
- **Accuracy:** ~99% for medical terminology
- **Integration:** Callback handler in `chime-transcription-callback/`
- **Usage Tracking:** `transcription_usage_daily` table

### EHRbase (OpenEHR)
- **Standard:** ISO 13606 (vendor-agnostic clinical data)
- **Deployment:** Hosted in EU-1 region (GDPR)
- **Sync Trigger:** After provider signs SOAP note
- **Template Count:** ~40 archetypes (SOAP, vitals, specialty-specific)
- **MCP Interface:** `openehr-mcp-server/` for Claude Desktop

### PowerSync (Offline-First Sync)
- **Pattern:** Offline-first real-time synchronization
- **Sync Rules:** SQL-based (specify tables/filters)
- **Conflict Resolution:** Last-write-wins + version tracking
- **MCP Interface:** `powersync-mcp-server/` for status & metrics

### Medical Vocabularies
- **Languages:** English, French, Swahili, Hausa, Yoruba, Zulu + 5+ fallback
- **Location:** `medical-vocabularies/`
- **Format:** Plain text medical term glossaries

---

## Environment & Configuration

### Required Environment File
**Location:** `assets/environment_values/environment.json` (gitignored)

**Request from team—contains:**
```json
{
  "SupaBaseURL": "https://...",
  "Supabasekey": "eyJhbG...",
  "FirebaseProjectId": "medzen-bf20e",
  "FirebaseApiKey": "...",
  "PaymentApi": "...",
  "AwsSmsApiUrl": "...",
  "AwsSmsApiKey": "..."
}
```

### Platform-Specific Config
- **iOS:** `ios/Runner/Info.plist` (permissions, URL schemes)
- **Android:** `android/app/build.gradle` (permissions, signing)
- **Web:** `web/index.html` (Chime SDK script tag)
- **All Platforms:** `pubspec.yaml` (dependency versions)

---

## Deployment Regions & Services

- **Primary Region:** EU-Central-1 (eu-central-1) for GDPR compliance
- **Database:** Supabase (AWS-backed, eu-central-1)
- **EHRbase:** EU-1 region
- **AWS Services:** Chime SDK, Lambda, Bedrock, Transcribe (all eu-central-1)
- **Firebase:** Global (Firestore, Auth, Cloud Messaging)

---

## Git Workflow

| Step | Command |
|------|---------|
| **Create feature branch** | `git checkout -b feature/description` |
| **Sync with main** | `git fetch origin ALINO && git rebase origin/ALINO` |
| **Before push** | `dart analyze lib/ --fatal-infos && flutter test` |
| **Commit** | `git add . && git commit -m "type: description"` |
| **Push** | `git push origin feature/description` |
| **Create PR** | `gh pr create --base ALINO --title "Your Title"` |
| **Handle FlutterFlow conflicts** | `git checkout --theirs lib/flutter_flow/ && git add lib/flutter_flow/` |

---

## Key Files to Understand First

1. **CLAUDE.md** (this file) - Project overview & patterns
2. **lib/main.dart** - Initialization order (lines 28-42, non-negotiable)
3. **lib/app_state.dart** - Global FFAppState singleton
4. **lib/custom_code/actions/join_room.dart** - Video call orchestration
5. **supabase/functions/_shared/verify-firebase-jwt.ts** - Auth helper
6. **supabase/functions/chime-meeting-token/index.ts** - Edge function example
7. **supabase/functions/_shared/cors.ts** - CORS & security headers
8. **lib/custom_code/widgets/chime_meeting_enhanced.dart** - Chime video UI

---

## Resources & Documentation

- [Flutter Docs](https://flutter.dev/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [AWS Chime SDK](https://docs.aws.amazon.com/chime-sdk/)
- [AWS Bedrock](https://docs.aws.amazon.com/bedrock/)
- [EHRbase API](https://github.com/ehrbase/ehrbase)
- [OpenEHR Specifications](https://openehr.org/releases/latest/)
