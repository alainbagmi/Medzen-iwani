# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MedZen healthcare application - FlutterFlow-based telehealth platform with 4 user roles: Patient, Provider, Facility Admin, System Admin.

**Stack:** Flutter + Firebase Auth + Supabase (DB/Storage) + EHRbase (OpenEHR) + AWS Chime SDK (video) + AWS Bedrock (AI)

**Critical IDs:**
- Firebase: `medzen-bf20e`
- Supabase: `noaeltglphdlkbflipit`
- AWS Regions:
  - `eu-central-1` (primary) - ALL services (Chime SDK, Bedrock AI, EHRbase - migrating)
  - `eu-west-1` (secondary/DR) - EHRbase (current primary, becoming read replica), failover infrastructure
  - `af-south-1` - **DECOMMISSIONED** (deleted/being deleted)

## Non-Negotiable Rules

### 1. Initialization Order (CRITICAL)
Firebase → Supabase → App State initialization MUST happen in this exact order in `lib/main.dart:22-37`. Breaking this order causes app crashes.

### 2. FlutterFlow Files - DO NOT EDIT
NEVER modify files in `lib/flutter_flow/` - they are auto-generated and will be overwritten. NEVER remove auto-generated imports even if they appear unused.

### 3. Medical Data Operations
Medical data (vital_signs, lab_results, prescriptions, etc.) MUST use Supabase directly.

**IMPORTANT:** PowerSync is extensively referenced in documentation but is NOT currently deployed in production. All data operations should use Supabase directly.

```dart
// ✅ Correct - use Supabase
await SupaFlow.client.from('vital_signs').insert({'patient_id': userId, 'bp': 120});

// ❌ Wrong - PowerSync not deployed
await db.execute('INSERT INTO vital_signs...');
```

### 4. Video Call Implementation
Video calls use `ChimeMeetingWebview` widget with Amazon Chime SDK v3.19.0 bundled directly as inline JavaScript (1.11 MB UMD bundle). The SDK is embedded in a Dart raw string (`r'''`) to prevent string interpolation conflicts. No external CDN dependencies or asset files required - completely self-contained and works offline after initial app load.

### 5. Firebase Configuration
NEVER hardcode credentials. Use `firebase functions:config:set` only. Check before deployment: `firebase functions:config:get`

### 6. Database Migrations
NEVER edit existing migration files. Always create new timestamped migrations in `supabase/migrations/YYYYMMDDHHMMSS_description.sql`.

### 7. UUID Handling
NEVER cast UUIDs to TEXT in SQL. Use native UUID type. Wrong: `id::text`, Right: `id`

### 8. Image URL Constraints
User avatar URLs MUST start with `http://` or `https://`. Database constraints enforce this. See migration `20251203000000_fix_malformed_image_urls.sql`.

## Essential Commands

### Root Project Commands
```bash
# Lint all Firebase functions
npm run lint
```

### Flutter Development
```bash
# Clean build (fixes most issues)
flutter clean && flutter pub get

# Run on specific device
flutter run -d chrome  # or specific device
flutter devices       # list available devices

# Build for platforms
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web

# Analyze code
flutter analyze

# Check for Flutter/Dart issues
flutter doctor -v
```

### Firebase Functions
```bash
# Install dependencies
cd firebase/functions && npm install

# Lint code
npm run lint

# Test locally (emulator)
npm run serve

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onUserCreated

# View logs (real-time)
firebase functions:log --limit 50
npm run logs  # shortcut

# Configure secrets (NEVER hardcode)
firebase functions:config:set supabase.url="..." supabase.service_key="..."
firebase functions:config:get  # verify config
```

### Supabase
```bash
# Link project (first time only)
npx supabase link --project-ref noaeltglphdlkbflipit

# Apply migrations
npx supabase db push

# Deploy ALL Production Edge Functions (required for full functionality)
# Authentication & EHR
npx supabase functions deploy powersync-token
npx supabase functions deploy sync-to-ehrbase

# Video Calls (Chime SDK) - 5 functions
npx supabase functions deploy chime-meeting-token
npx supabase functions deploy chime-messaging
npx supabase functions deploy chime-recording-callback
npx supabase functions deploy chime-transcription-callback
npx supabase functions deploy chime-entity-extraction

# AI Chat
npx supabase functions deploy bedrock-ai-chat

# Utilities
npx supabase functions deploy cleanup-expired-recordings
npx supabase functions deploy cleanup-old-profile-pictures
npx supabase functions deploy upload-profile-picture
npx supabase functions deploy check-user
npx supabase functions deploy refresh-powersync-views

# Set secrets (required before deploying functions)
npx supabase secrets set EHRBASE_URL=https://ehr.medzenhealth.app/ehrbase
npx supabase secrets set EHRBASE_USERNAME=ehrbase-admin
npx supabase secrets set EHRBASE_PASSWORD=your-password
npx supabase secrets set CHIME_API_ENDPOINT=https://xxx.execute-api.eu-central-1.amazonaws.com
npx supabase secrets set AWS_REGION=eu-central-1

# View logs
npx supabase functions logs [function-name] --tail

# List deployed functions
npx supabase functions list
```

### AWS Deployment
```bash
# Navigate to deployment directory
cd aws-deployment

# Deploy Chime SDK to all regions
./scripts/deploy-all-regions.sh

# Deploy individual region
./scripts/deploy-bedrock-ai.sh

# Validate entire deployment
./scripts/validate-deployment.sh

# Configure S3 notifications for recordings
./scripts/configure-s3-notifications.sh

# Setup EventBridge for scheduled cleanup
./scripts/setup-eventbridge-cleanup.sh

# Cost analysis and reporting
./scripts/cost-report.sh

# Test multi-region failover
./scripts/failover-test.sh

# Cleanup EventBridge rules (if needed)
./scripts/cleanup-eventbridge.sh

# Direct CloudFormation deployment
aws cloudformation deploy \
  --template-file cloudformation/chime-sdk-multi-region.yaml \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1 \
  --capabilities CAPABILITY_IAM

# Monitor CloudFormation stack
aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1
```

### FlutterFlow Re-export (Critical)
```bash
# After FlutterFlow export, use this script to safely merge
./safe-reexport.sh ~/Downloads/export.zip

# ALWAYS verify after re-export
grep -q "assets/html/" pubspec.yaml && echo "✅ OK" || echo "❌ Video will fail!"
```

## Architecture

### Five Integrated Systems

**Authentication & Data Flow:**
```
Firebase Auth (login)
    ↓
Supabase Auth + Database (user profiles, medical records)
    ↓
EHRbase (OpenEHR health records)
    +
AWS Chime SDK (video/audio calls - online only)
    +
AWS Bedrock (AI chat assistant)
```

### User Signup Flow (Automatic)
```
1. User signs up → Firebase Auth creates user
2. Firebase `onUserCreated` Cloud Function triggers (~2.3s total):
   - Creates Supabase Auth user (via Admin API)
   - Inserts record in `users` table
   - Creates EHR in EHRbase via REST API
   - Inserts record in `electronic_health_records` table
3. All systems synchronized automatically
```

### Medical Data Sync Flow
```
1. User creates medical data → Supabase tables
2. Database trigger → adds entry to `ehrbase_sync_queue`
3. Edge Function `sync-to-ehrbase` → processes queue (polls or triggered)
4. Creates OpenEHR composition in EHRbase
5. Updates queue entry with sync_status='completed'
```

### Video Call Flow (Online Only)
```
1. User taps join call → `join_room.dart` custom action
2. Calls Supabase Edge Function `chime-meeting-token`
3. Edge Function → AWS Lambda (via API Gateway)
4. Lambda creates/joins Chime meeting
5. Returns meeting + attendee tokens + join info
6. `ChimeMeetingWebview` widget loads with embedded HTML/JS and Chime SDK v3.19.0
7. Real-time video/audio communication via AWS Chime
```

### AI Chat Flow (Bedrock)
```
1. User sends message → Firebase Function `handleAiChatMessage`
2. Function calls AWS Lambda `bedrock-ai-chat`
3. Lambda invokes Bedrock (Claude Sonnet 3.5)
4. Streaming response via EventSource
5. Messages stored in `ai_messages` table
6. Supports multiple languages with auto-translation
```

## Key File Locations

### Custom Code
- Actions: `lib/custom_code/actions/`
- Widgets: `lib/custom_code/widgets/`
- Main video call: `lib/custom_code/actions/join_room.dart`
- AI chat actions: `lib/custom_code/actions/send_bedrock_message.dart`

### Backend
- Supabase config: `lib/backend/supabase/supabase.dart`
- Database schema: `lib/backend/supabase/database/tables/*.dart`
- API calls: `lib/backend/api_requests/api_calls.dart`

### User Roles
- Patients: `lib/patients_folder/`
- Providers: `lib/medical_provider/`
- Facility Admins: `lib/facility_admin/`
- System Admins: `lib/system_admin/`

### Configuration
- Environment: `assets/environment_values/environment.json` (FlutterFlow managed)
- Routes: `lib/flutter_flow/nav/nav.dart`
- App State: `lib/app_state.dart`

### Backend Functions
- Firebase: `firebase/functions/index.js` (modular functions imported)
- Firebase modules: `firebase/functions/*.js` (individual function files)
- Supabase: `supabase/functions/*/index.ts`
- AWS Lambda: `aws-lambda/*/index.js`
- Migrations: `supabase/migrations/*.sql`

### Assets
- Video calls: Self-contained in `ChimeMeetingWebview` widget (no external files)
- Fonts: `assets/fonts/`
- Images: `assets/images/`

## Critical Functions

### Firebase Cloud Functions
- `onUserCreated` - 5-system user sync (Firebase → Supabase → EHRbase)
- `onUserDeleted` - Cascading deletion across all systems
- `handleAiChatMessage` - Bedrock AI chat integration (streaming)
- `sendPushNotificationsTrigger` - FCM push notifications
- `videoCallTokens` - Legacy video call tokens (deprecated, use Chime)

### Supabase Edge Functions

**Authentication & EHR:**
- `powersync-token` - JWT token for PowerSync auth (PowerSync not currently deployed)
- `sync-to-ehrbase` - Medical data → OpenEHR compositions
- `check-user` - User validation and lookup
- `refresh-powersync-views` - Refresh materialized views

**Video Calls (Chime SDK):**
- `chime-meeting-token` - Video call meeting creation/join
- `chime-messaging` - Real-time chat messaging in calls
- `chime-recording-callback` - S3 recording processing
- `chime-transcription-callback` - Medical transcription processing
- `chime-entity-extraction` - Extract medical entities from transcripts

**AI Chat:**
- `bedrock-ai-chat` - AI assistant chat (also available via Firebase)

**Storage & Utilities:**
- `cleanup-expired-recordings` - Scheduled S3 cleanup
- `cleanup-old-profile-pictures` - Remove old profile pictures
- `upload-profile-picture` - Handle profile picture uploads

### AWS Lambda Functions
- `CreateChimeMeeting` - Create/join video meetings
- `BedrockAIChat` - Bedrock AI streaming chat
- `ChimeRecordingProcessor` - Process meeting recordings
- `ChimeTranscriptionProcessor` - Medical transcription

## Common Issues & Quick Fixes

| Problem | Solution |
|---------|----------|
| App won't build | `flutter clean && flutter pub get` |
| Video calls show blank screen | Check camera/microphone permissions. Verify Firebase authentication. SDK is bundled locally (no CDN dependency). Check console logs for JavaScript errors. |
| Firebase function fails | Check config: `firebase functions:config:get` |
| Offline mode broken | Verify init order in `lib/main.dart:22-37` |
| EHR sync failing | Check queue: `SELECT * FROM ehrbase_sync_queue WHERE sync_status='failed'` |
| Chime video fails | Verify `CHIME_API_ENDPOINT` in Supabase secrets |
| Malformed image URLs | Run migration `20251203000000_fix_malformed_image_urls.sql` |
| FlutterFlow re-export broke code | Use `./safe-reexport.sh` instead of manual copy |
| AWS Lambda timeout | Check CloudFormation timeout settings (default 60s) |

## Testing

### Automated Test Scripts
The repository includes several automated test scripts for system validation:

```bash
# Complete system integration test
./test_system_connections_simple.sh

# Video call functionality
./test_chime_deployment.sh
./test_chime_video_complete.sh
./test_video_call_auth_fix.sh
./test_video_call_jwt_fix.sh
./test_video_call_permissions.sh

# AI chat system
./test_ai_chat_e2e.sh

# Edge functions
./test_edge_function.sh

# User flows
./test_complete_flow.sh

# Data verification
./verify_appointment_data.sh
```

**Usage:**
```bash
# Make scripts executable (if needed)
chmod +x test_*.sh verify_*.sh

# Run any test
./test_chime_deployment.sh
```

### Manual Testing Workflows
```bash
# Test user creation flow
firebase functions:log --limit 10  # watch logs
# Then create user in app

# Test EHR sync
# 1. Create/update medical record in app
# 2. Check queue: SELECT * FROM ehrbase_sync_queue ORDER BY created_at DESC LIMIT 5;
# 3. Check logs: npx supabase functions logs sync-to-ehrbase

# Test video call
# 1. Create appointment with video_enabled=true
# 2. Join call from both provider and patient
# 3. Check CloudWatch logs for Lambda execution
```

### In-App Testing
Navigate to Connection Test Page in the app to run automated integration tests for all systems.

## Important Patterns

### Global State Updates
```dart
FFAppState().update(() {
  FFAppState().UserRole = 'patient';
  FFAppState().currentUserId = userId;
});
```

### Supabase Queries
```dart
// Single record
final result = await SupaFlow.client
  .from('users')
  .select()
  .eq('id', userId)
  .single();

// With joins
final appts = await SupaFlow.client
  .from('appointment_overview')
  .select('*')
  .eq('provider_id', providerId)
  .order('appointment_start_date', ascending: false);
```

### Video Call Initialization
```dart
await joinRoom(
  context,
  sessionId,
  providerId,
  patientId,
  appointmentId,
  isProvider,
  userName,
  profileImage,
);
```

### Calling Edge Functions
```dart
final response = await SupaFlow.client.functions.invoke(
  'chime-meeting-token',
  body: {
    'appointmentId': appointmentId,
    'userId': userId,
  },
);
```

## Documentation References

For comprehensive information, see:
- `QUICK_START.md` - Setup and deployment guide
- `TESTING_GUIDE.md` - Testing procedures and workflows
- `SYSTEM_INTEGRATION_STATUS.md` - Architecture and integration details
- `CHIME_VIDEO_TESTING_GUIDE.md` - Video call testing procedures
- `PRODUCTION_DEPLOYMENT_GUIDE.md` - Production deployment checklist
- `4_SYSTEM_INTEGRATION_SUMMARY.md` - System integration overview
- `DEPLOYMENT_COMPLETE.md` - AWS Chime SDK deployment guide

## Environment Variables

Configuration is managed through:
- **Flutter:** `assets/environment_values/environment.json` (managed by FlutterFlow, DO NOT edit manually)
- **Firebase Functions:** `firebase functions:config:set key.subkey="value"`
- **Supabase Edge Functions:** `npx supabase secrets set KEY=value`
- **AWS Lambda:** CloudFormation parameters and environment variables

**NEVER commit:**
- `.env` files
- `.runtimeconfig.json`
- `firebase-adminsdk-*.json`
- Any files with credentials or API keys

## Debugging

### Firebase Functions
```bash
# Local debugging
cd firebase/functions
npm run serve  # starts emulator

# View real-time logs
firebase functions:log --limit 50

# Check function config
firebase functions:config:get
```

### Supabase Edge Functions
```bash
# View logs (real-time)
npx supabase functions logs [function-name] --tail

# Test locally (if Deno installed)
deno run --allow-net --allow-env supabase/functions/[function-name]/index.ts
```

### Flutter App
```bash
# Enable verbose logging
flutter run -v

# View device logs
flutter logs

# Check for issues
flutter doctor -v
flutter analyze
```

### AWS Lambda
```bash
# View CloudWatch logs
aws logs tail /aws/lambda/[function-name] --follow

# Invoke function directly
aws lambda invoke \
  --function-name medzen-CreateChimeMeeting \
  --payload '{"body":"{}"}' \
  response.json
```

## Multi-Region Architecture

**MIGRATION IN PROGRESS:** Consolidating to eu-central-1 as primary region. See `EU_CENTRAL_1_MIGRATION_PLAN.md` for details.

The system is deployed across two AWS regions for high availability and compliance:

### Production Regions

**`eu-central-1` (Frankfurt) - PRIMARY REGION FOR ALL SERVICES**
- ✅ **Chime SDK** (deployed Dec 11, 2025)
  - Stack: `medzen-chime-sdk-eu-central-1`
  - API Gateway: `https://156da6e3xb.execute-api.eu-central-1.amazonaws.com`
  - Lambda Functions (7): meeting-manager, recording-processor, transcription-processor, messaging-handler, polly-tts, health-check, ai-chat-handler
  - DynamoDB: `medzen-meeting-audit`
  - S3 Buckets: recordings, transcripts, medical-data
  - Security: KMS encryption, IAM least privilege, bucket policies
- ✅ **Bedrock AI** (deployed Dec 11, 2025)
  - Stack: `medzen-bedrock-ai-eu-central-1`
  - Model: `eu.amazon.nova-pro-v1:0`
  - Lambda: `medzen-ai-chat-handler`
  - Multi-language support with auto-translation
- 🔄 **EHRbase** (migration planned from eu-west-1)
  - Target: RDS PostgreSQL Multi-AZ
  - Target: ECS Fargate cluster
  - Target: Application Load Balancer
  - Domain: `ehr.medzenhealth.app`
- Primary API services for EU/Global users
- Serves: Video consultations, real-time messaging, medical transcription, AI chat, health records

**`eu-west-1` (Ireland) - SECONDARY/DR REGION**
- ✅ **EHRbase production** (deployed, Multi-AZ high availability) - **MIGRATING TO eu-central-1**
  - RDS PostgreSQL Multi-AZ (current primary, will become read replica)
  - Application Load Balancer
  - ECS Fargate cluster
  - Domain: `ehr.medzenhealth.app`
- 🔄 **DR Infrastructure** (hot standby for failover)
  - RDS read replica (target)
  - Standby Lambda functions (3): auth-send-otp, auth-verify-otp, sms-notification-handler
  - Route53 health checks and automatic failover
- ✅ **S3 Storage** (cross-region replication from eu-central-1)
  - Versioning enabled
  - Lifecycle policies configured
- GDPR compliant data residency
- ~50ms latency for EU users

**`af-south-1` (Cape Town) - DECOMMISSIONED**
- ❌ **Status:** All resources deleted/planned for deletion
- ⚠️ **Legacy Chime SDK** (deleted - replaced by eu-central-1)
- ⚠️ **Bedrock AI** (deleted - replaced by eu-central-1)
- **Cost Savings:** $290/month from decommissioning
- **Rationale:** Duplicated resources, low African user base (<5%), cost optimization

### Current Deployment Status (December 12, 2025)

| Service | eu-central-1 | eu-west-1 | af-south-1 | Status |
|---------|--------------|-----------|------------|--------|
| Chime SDK | ✅ Primary | ⬜ Not deployed | ❌ Decommissioned | Production |
| EHRbase | 🔄 Migration in progress | ✅ Current Primary | ⬜ Not deployed | Migration |
| Bedrock AI | ✅ Primary | ⬜ Not deployed | ❌ Decommissioned | Production |
| Lambda Functions | ✅ 7 deployed | 🔄 3 DR functions | ❌ Decommissioned | Production |
| S3 Storage | ✅ Primary | 🔄 Replication target | ⬜ Not deployed | Production |

**Legend:**
- ✅ Deployed and active
- 🔄 Migration/configuration in progress
- ❌ Decommissioned/deleted
- ⬜ Not deployed

### Failover & High Availability

- **Route 53**: Health checks and automatic failover to eu-west-1
- **Multi-AZ**: All RDS instances span multiple availability zones
- **Cross-Region Replication**: S3 data replicated eu-central-1 → eu-west-1
- **RDS Read Replica**: Hot standby in eu-west-1 for disaster recovery
- **Testing**: Run `./aws-deployment/scripts/failover-test.sh` to validate

### Migration Roadmap (In Progress)

**See `EU_CENTRAL_1_MIGRATION_PLAN.md` for complete details.**

**Phase 1:** Preparation & Validation ✅ COMPLETE
- [x] Infrastructure audit complete
- [x] Migration plan created
- [x] Rollback procedures documented

**Phase 2:** Deploy EHRbase to eu-central-1 (Week 1)
- [ ] CloudFormation stack deployed
- [ ] RDS restored from snapshot
- [ ] ECS cluster running
- [ ] Read replica in eu-west-1

**Phase 3:** Bedrock AI ✅ COMPLETE
- [x] Already deployed in eu-central-1

**Phase 4:** Lambda Migration (Week 1-2)
- [ ] Unique functions migrated to eu-central-1
- [ ] DR functions kept in eu-west-1

**Phase 5:** Production Cutover (Week 2)
- [ ] DNS updated to eu-central-1
- [ ] Zero downtime achieved
- [ ] Monitoring confirms health

**Phase 6:** Decommission af-south-1 (Week 3)
- [ ] 7-day monitoring complete
- [ ] All resources deleted
- [ ] Cost savings validated

**Phase 7:** DR Configuration (Week 2-3)
- [ ] Route53 failover configured
- [ ] DR tested and validated

**Timeline:** 2-3 weeks
**Cost Savings:** $135/month ($1,620/year)
**Expected Downtime:** < 5 minutes (during cutover)

## Regional Deployment Rationale

**Why eu-central-1 (Frankfurt) as Primary:**
- ✅ Central European location - optimal for EU/Global users
- ✅ 20-30ms lower latency compared to eu-west-1
- ✅ All AWS services available (Chime SDK, Bedrock, RDS, ECS)
- ✅ GDPR compliant (EU data residency)
- ✅ Cost-effective for consolidated architecture
- ✅ Better inter-service communication (same region)

**Why eu-west-1 (Ireland) as DR:**
- ✅ Geographic diversity (different region, same EU)
- ✅ GDPR compliant
- ✅ Proven infrastructure for EHRbase
- ✅ Automatic failover capability
- ✅ Low-cost hot standby (read replica model)

**Why Decommission af-south-1:**
- ❌ Low African user base (<5% of total)
- ❌ High latency from Europe (250ms+)
- ❌ Duplicate resources = wasted costs ($290/month)
- ❌ Complexity of managing 3 regions
- ✅ African users still served adequately from eu-central-1 (200ms avg)

**Future Consideration:**
- Will reconsider af-south-1 deployment if African users exceed 40% of user base
- Alternative: Deploy edge caching/CDN in Africa for static content
