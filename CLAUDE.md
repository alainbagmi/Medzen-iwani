# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**medzen-iwani** - Flutter healthcare app (FlutterFlow-generated) for iOS/Android/Web with 4 user roles: Patient, Medical Provider, Facility Admin, System Admin.

**Tech Stack:** Flutter >=3.0.0, Firebase (Auth, Functions, Performance), Supabase (DB, Storage), Node.js 20, PowerSync (offline-first), EHRbase (OpenEHR)

**Firebase Project:** `medzen-bf20e` (used in Firebase CLI commands)

## Before You Start

**Prerequisites:**
- Flutter SDK >=3.0.0
- Node.js 20 (for Firebase Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- Supabase CLI (`npm install -g supabase`)
- Active accounts: Firebase, Supabase, PowerSync, EHRbase

**First-Time Setup:**
```bash
# 1. Flutter dependencies
flutter pub get

# 2. Firebase setup
cd firebase/functions && npm install
firebase login
firebase use medzen-bf20e

# 3. Supabase setup
npx supabase login
npx supabase link --project-ref <YOUR_PROJECT_REF>

# 4. Verify connections (make scripts executable if needed)
chmod +x *.sh
./test_system_connections_simple.sh
```

## Essential Commands

### Flutter
```bash
flutter pub get                              # Install dependencies
flutter run [-d chrome|macos|<device-id>]   # Run app
flutter test && flutter analyze              # Test & analyze
flutter build apk|appbundle|ios|web          # Build for platform
flutter clean                                # Clean build artifacts
```

### Firebase
```bash
cd firebase/functions
npm install && npm run lint                  # Setup & lint
npm run serve                                # Local emulator (targets medzen-bf20e)
npm run logs                                 # View logs (shortcut)
npm run shell                                # Interactive shell
npm run compile                              # TypeScript compilation
firebase emulators:start [--only functions]  # Local emulator testing
firebase deploy [--only functions|firestore:rules|storage]  # Deploy

# Config (never commit .runtimeconfig.json)
firebase functions:config:set supabase.url="..." supabase.service_key="..."
firebase functions:config:set ehrbase.url="..." ehrbase.username="..." ehrbase.password="..."
firebase functions:config:get                # View current config
firebase functions:log [--only functionName] # View logs
```

**Note:** Firebase project is `medzen-bf20e` - npm scripts automatically target this project.

**Structure:** `firebase/{firebase.json, firestore.rules, storage.rules, functions/index.js}`
**Functions:** `onUserCreated` (creates Supabase user + EHRbase EHR), `onUserDeleted` (cleanup)

**Additional Capabilities:** Functions include payment processing (Stripe, Razorpay, Braintree), LangChain integration (OpenAI, Google Gemini, Anthropic), Mux video, and OneSignal notifications.

### Supabase
```bash
npx supabase login && npx supabase link      # Initial setup
npx supabase db push|reset|diff|remote       # DB management
npx supabase functions deploy [function-name]  # Deploy edge functions
npx supabase secrets set KEY=value           # Set secrets
npx supabase secrets list                    # List all secrets
npx supabase functions logs function-name    # View logs
```

**Edge Functions:**
- `sync-to-ehrbase` - Processes EHR sync queue, creates EHRbase compositions
- `powersync-token` - JWT generation for PowerSync authentication
- `refresh-powersync-views` - Refreshes materialized views for role-based access

**Important Files:**
- `supabase/config.toml` - Local emulator and functions configuration
- `supabase/.env.template` - Template for edge function secrets
- `supabase/migrations/` - Database schema migrations (applied in order)

## Architecture

### 4-System Architecture
1. **Firebase Auth** - Authentication (Google/Apple/Email), Firestore user docs, Cloud Functions, Performance
2. **Supabase** - Primary DB (100+ tables), Storage, Realtime, Row-level security
3. **PowerSync** - Offline-first local SQLite with bidirectional sync
4. **EHRbase** - OpenEHR-compliant health records (external)

**Critical Init Order (`lib/main.dart`):** Firebase → Supabase → PowerSync → App State

This order is **NON-NEGOTIABLE** - the app will fail to function correctly if initialization happens out of order.

**Important:** PowerSync is NOT initialized in `lib/main.dart` itself. The initialization sequence in `main.dart` prepares Firebase and Supabase, but PowerSync initialization occurs later in landing pages via Custom Actions. This is intentional to support role-based sync rules that depend on authenticated user context.

### Authentication Flows

**Signup (Online Required):**
1. Firebase Auth creates user → triggers `onUserCreated` Cloud Function
2. Function creates: Supabase user, EHRbase EHR, `electronic_health_records` entry
3. App init: Firebase → Supabase → PowerSync (gets JWT token, downloads initial data)

**Login - Online:**
1. Firebase Auth validates → App init (Firebase → Supabase → PowerSync)
2. PowerSync gets fresh token, connects to cloud, bidirectional sync with Supabase

**Login - Offline:**
1. Firebase uses cached credentials (✅ works offline)
2. PowerSync uses local SQLite (✅ full CRUD offline)
3. When online: Auto-sync queued changes → Supabase → `ehrbase_sync_queue` → EHRbase

### Offline Capabilities

| System | Offline Login | Offline R/W | Sync |
|--------|--------------|-------------|------|
| Firebase Auth | ✅ Cached | ✅ Profile only | N/A |
| Supabase | ⚠️ Passive | ❌ Fails | ✅ Via PowerSync |
| PowerSync | ✅ Yes | ✅ Full CRUD | ✅ Bidirectional auto |
| EHRbase | ❌ No | ❌ No | ✅ Via queue→edge fn |

**Dev Rules:** Init order matters. Use PowerSync `db` for medical data (never direct Supabase). Test offline with airplane mode.

### Key Structures

**4 User Roles** (select via `lib/home_pages/role_page/`):
- **Patient:** `lib/patients_folder/` (bottom_nav, landing_page, profile)
- **Provider:** `lib/medical_provider/` (account_creation, confirmation, patient access)
- **Facility Admin:** `lib/facility_admin/` (bottom_nav, landing_page, staff management)
- **System Admin:** `lib/system_admin/` (bottom_nav, landing_page, system config)

**State Management:**
- `FFAppState` (`lib/app_state.dart`): Global state with `ChangeNotifier` (UserRole, SelectedRole, subscription, AuthUser/SupabaseUser, persisted via `flutter_secure_storage`)
- `AppStateNotifier` (`lib/main.dart`): Firebase auth stream, splash screen, `go_router` redirects
- `authenticatedUserStream` & `jwtTokenStream`: Real-time auth state streams

**FlutterFlow Pattern** (DO NOT edit `lib/flutter_flow/` directly):
- Every page: `*_widget.dart` (UI) + `*_model.dart` (state/logic)
- Custom code: `lib/custom_code/{actions,widgets}/`, `lib/flutter_flow/custom_functions.dart`
  - Actions: `get_specialties_by_category.dart`, `get_all_specialties.dart`, `join_room.dart`, etc.
  - Widgets: `country_phone_picker.dart`, `pre_joining_dialog.dart`, etc.
  - Both directories export components via `index.dart`
  - **CRITICAL**: FlutterFlow requires specific auto-generated imports between `// Automatic FlutterFlow imports` and `// Begin custom action code`. NEVER remove these imports even if analyzer shows them as "unused" - they are required for FlutterFlow platform validation
- Utils: `flutter_flow_{theme,util,widgets,animations}.dart`, `internationalization.dart` (en/fr/af), `nav/`
- Navigation: `lib/flutter_flow/nav/nav.dart` - All routes defined here with `go_router`

**Backend:**
- Firestore: `lib/backend/backend.dart` (`queryUsersRecord()`, `FFFirestorePage`, `maybeCreateUser()`)
- Supabase: `lib/backend/supabase/` (`SupaFlow.client`, `database/{tables,row,table}.dart`)
- API: `lib/backend/api_requests/` (`APIManager`)
- Auth: `lib/auth/firebase_auth/` (auth_util.dart, firebase_user_provider.dart)

**GraphQL Queries:**
- `graphql_queries/` - Pre-built GraphQL queries for Supabase PostgREST
- Used for complex queries (specialties, provider types, pagination)
- See `graphql_queries/PAGINATION_GUIDE.md` and `SOLUTION_CUSTOM_ACTIONS.md`
- Note: FlutterFlow GraphQL has limitations - use Custom Actions for complex queries

## EHR Synchronization & OpenEHR Integration

**Docs:** See POWERSYNC_QUICK_START.md (⭐ start here), POWERSYNC_IMPLEMENTATION.md, EHR_SYSTEM_README.md, EHR_SYSTEM_DEPLOYMENT.md

**Components:**
1. Firebase `onUserCreated` → creates EHRbase EHR + Supabase user (atomic operation)
2. Supabase `sync-to-ehrbase` edge function → processes `ehrbase_sync_queue`
3. DB triggers (in migrations) → auto-queue medical records on insert/update
4. Flutter `ehr_sync_service.dart` → background sync (5min interval), connectivity monitor

**OpenEHR Tables** (`lib/backend/supabase/database/tables/`):
- `electronic_health_records` - Links users to EHRbase EHR IDs
- `ehr_compositions` - OpenEHR compositions (template_id, archetypes, data)
- `ehrbase_sync_queue` - Sync queue (sync_status, retry_count, ehrbase_composition_id, data_snapshot JSONB)
- `openehr_integration_health` - System health metrics
- `v_ehrbase_sync_status` - View for sync monitoring
- Medical data tables: `vital_signs`, `lab_results`, `prescriptions`, `immunizations`, `medical_records`, `allergies`

**OpenEHR Templates:**
- **Status**: 26 ADL templates created in `ehrbase-templates/proper-templates/`
- **Deployment Status**: ⏳ Awaiting ADL-to-OPT conversion before upload to EHRbase
- **Templates Include**:
  - 19 specialty templates (antenatal care, surgical procedures, oncology, cardiology, etc.)
  - 7 core templates (patient demographics, vital signs, lab results, prescriptions, etc.)
- **Template IDs**: All use `medzen.*` namespace (e.g., `medzen.antenatal_care_encounter.v1`)

**Template Conversion & Deployment:**
- **Conversion Required**: ADL templates must be converted to OPT (XML) format before EHRbase upload
- **Tracking Tool**: `ehrbase-templates/track_conversion_progress.sh` - Real-time conversion status
- **Upload Tool**: `ehrbase-templates/upload_all_templates.sh` - Batch upload script (ready)
- **Verification Tool**: `ehrbase-templates/verify_templates.sh` - Post-upload verification (ready)
- **Documentation**: See `ehrbase-templates/TEMPLATE_CONVERSION_STATUS.md` for complete status
- **Conversion Options**:
  - OpenEHR Template Designer (web tool) - Recommended, 15-30 min per template
  - Archie Java Library - For programmatic conversion/automation
- **Estimated Timeline**: 6-13 hours for conversion + 30 min upload + 2-3 hours testing

**Sync Flow:** Local write → PowerSync → Supabase → DB trigger → `ehrbase_sync_queue` → Edge function → EHRbase (async, with exponential backoff retry)

**Check Sync Status:** Query `sync_status` in `ehrbase_sync_queue` before assuming data is in EHRbase (pending/processing/completed/failed)

**Template Integration:**
- Edge function `sync-to-ehrbase` has template mappings configured for all 19 specialty tables
- Database triggers active on all specialty tables for automatic sync queue population
- Templates ready for integration testing once uploaded to EHRbase

**Shared Components:** `lib/components/` (24 directories: headers, footers, OTP, password validation, reset/logout dialogs, system_status_debug)

**Video Call:** `lib/home_pages/{video_call,join_call}/` (WebRTC via `webview_flutter`)

**Assets:** `assets/{fonts,images,videos,audios,rive_animations,pdfs,jsons}/` - All assets must be added to `pubspec.yaml`

## Development Workflows

### Adding a New Page
1. **FlutterFlow export** OR manual creation:
   - Create `page_name_widget.dart` (UI)
   - Create `page_name_model.dart` (state/logic)
2. Export in `lib/index.dart`
3. Add route in `lib/flutter_flow/nav/nav.dart`

### Auth Flow Pattern
```
Firebase Auth (source of truth)
    ↓
maybeCreateUser() creates Firestore doc
    ↓
FFAppState().UserRole set
    ↓
Role-based redirect (go_router)
```

### Modifying State
```dart
// Global state (persisted)
FFAppState().update(() {
  FFAppState().UserRole = 'patient';
  FFAppState().SelectedRole = 'patient';
});

// Page-level state (temporary)
pageModel.setState(() { /* ... */ });

// Listen to auth streams
medzenIwaniFirebaseUserStream().listen((user) {
  // React to auth changes
});
```

### Adding Firebase Functions
1. Edit `firebase/functions/index.js`
2. Test locally: `npm run serve` or `firebase emulators:start`
3. Deploy: `firebase deploy --only functions`
4. View logs: `firebase functions:log`

### Adding Supabase Functions
1. Create `supabase/functions/<name>/index.ts`
2. Set secrets: `npx supabase secrets set KEY=value`
3. Deploy: `npx supabase functions deploy <name>`
4. View logs: `npx supabase functions logs <name>`

### Adding Database Migrations
1. Create SQL file in `supabase/migrations/` with timestamp prefix (YYYYMMDDHHMMSS)
2. Apply locally: `npx supabase db push`
3. Verify: Check Supabase Studio or `npx supabase db remote commit`
4. Regenerate Dart types if needed

**CRITICAL: PostgreSQL Type Casting Rules**
- **NEVER** cast UUID to TEXT when comparing UUID columns: `WHERE patient_id = NEW.patient_id::TEXT` ❌
- **ALWAYS** compare UUID columns directly: `WHERE patient_id = NEW.patient_id` ✅
- PostgreSQL error: "operator does not exist: uuid = text" indicates improper casting
- All 22 EHR sync trigger functions fixed in migration `20251103200001_fix_all_sync_functions_comprehensive.sql`
- Pattern affects queries against `electronic_health_records` table where `patient_id` is UUID type

## PowerSync Integration (Offline-First)

**Use for all medical data operations.** Offline writes never fail, auto-sync when online, HIPAA-compliant, supports all 4 roles.

**Files:**
- `lib/powersync/{schema,supabase_connector,database}.dart` (implementation files)
- `supabase/functions/powersync-token/index.ts`
- `POWERSYNC_SYNC_RULES.yaml` (deploy to PowerSync dashboard)

**Important:** PowerSync IS in `pubspec.yaml` (v1.11.1) along with required dependencies (sqflite, path_provider). The implementation files in `lib/powersync/` define the schema, connector, and database interface.

**Quick Health Check:**
```bash
# Make scripts executable if needed
chmod +x *.sh

# Test system connections
./test_system_connections.sh          # Comprehensive test suite
./test_system_connections_simple.sh   # Quick connectivity check
./verify_powersync_setup.sh           # PowerSync-specific validation
```

**Docs:** POWERSYNC_MULTI_ROLE_GUIDE.md (roles), POWERSYNC_QUICK_START.md (setup)

### PowerSync Setup (Quick)

**1. Account:** Create at powersync.journeyapps.com → save instance URL + generate RSA keys (Key ID + Private Key)

**2. Sync Rules:** Copy `POWERSYNC_SYNC_RULES.yaml` → PowerSync Dashboard → paste → deploy (auto role detection for 4 roles)

**3. Deploy Token Function:**
```bash
npx supabase secrets set POWERSYNC_URL=... POWERSYNC_KEY_ID=... POWERSYNC_PRIVATE_KEY="..."
npx supabase functions deploy powersync-token
```

**4. Verify Token Function:**
```bash
npx supabase functions logs powersync-token
# Or test: curl with Authorization header
```

**5. Initialize (FlutterFlow):** Landing page → On Page Load → Custom Action:
```dart
import 'package:medzen_iwani/powersync/database.dart';
Future<void> initializePowerSyncAction() async {
  await initializePowerSync();
}
```
Place AFTER Supabase init (critical order: Firebase → Supabase → PowerSync).

**6. Use PowerSync (not direct Supabase):**
```dart
// ✅ PowerSync (offline-safe)
import 'package:medzen_iwani/powersync/database.dart';
await db.execute('INSERT INTO vital_signs (patient_id, systolic_bp, diastolic_bp) VALUES (?, ?, ?)', [userId, 120, 80]);

// ❌ Direct Supabase (fails offline)
await SupaFlow.client.from('vital_signs').insert({'patient_id': userId, 'systolic_bp': 120});
```

### PowerSync Operations (FlutterFlow Custom Actions)

```dart
import 'package:medzen_iwani/powersync/database.dart';

// Query (one-time)
Future<List<Map<String, dynamic>>> getVitalSigns(String userId) async {
  return await executeQuery(
    'SELECT * FROM vital_signs WHERE patient_id = ? ORDER BY recorded_at DESC LIMIT 50',
    [userId]
  );
}

// Query (real-time via StreamBuilder)
Stream<List<Map<String, dynamic>>> watchVitalSigns(String userId) {
  return watchQuery(
    'SELECT * FROM vital_signs WHERE patient_id = ? ORDER BY recorded_at DESC',
    [userId]
  );
}

// Insert
await db.execute(
  'INSERT INTO vital_signs (patient_id, systolic_bp, diastolic_bp, heart_rate) VALUES (?, ?, ?, ?)',
  [userId, 120, 80, 72]
);

// Update
await db.execute(
  'UPDATE vital_signs SET systolic_bp = ?, diastolic_bp = ? WHERE id = ?',
  [130, 85, recordId]
);

// Delete
await db.execute('DELETE FROM vital_signs WHERE id = ?', [recordId]);

// Sync status monitoring
final status = getPowerSyncStatus();
bool isConnected = isPowerSyncConnected();
db.statusStream.listen((status) {
  print('PowerSync status: ${status.connected}');
});
```

**Data Flow:** User Action → PowerSync SQLite (✅ immediate, never fails) → (when online) → Supabase → `ehrbase_sync_queue` (DB trigger) → Edge function → EHRbase

**Troubleshoot:**
- Check secrets: `npx supabase secrets list` (verify POWERSYNC_*)
- Debug stream: `db.statusStream` for connection status
- Ensure init order: Firebase → Supabase → PowerSync
- Check logs: `npx supabase functions logs powersync-token`

**Use PowerSync For:** Medical records, patient profiles, appointments, prescriptions, all UI reads, real-time queries

**Use Direct Supabase For:** File uploads to Storage only (PowerSync doesn't sync Storage, only database tables)

## System Testing

**Docs:** TESTING_GUIDE.md, SYSTEM_INTEGRATION_STATUS.md

**Test Actions** (`lib/custom_code/actions/` - may need to be created):
- `test_signup_flow.dart` - Tests all 4 systems (Firebase, Supabase, PowerSync, EHRbase)
- `test_login_flow.dart` - Online/offline login validation
- `test_data_operations.dart` - CRUD operations in both modes
- See TESTING_GUIDE.md for implementation details

**Test Scripts (bash):**
- `test_system_connections.sh` - Comprehensive integration test (all 4 systems)
- `test_system_connections_simple.sh` - Quick connectivity check (Firebase, Supabase, PowerSync, EHRbase)
- `verify_powersync_setup.sh` - Validates PowerSync configuration and token function
- `test_live_connections.sh` - Tests live production endpoints
- `test_auth_flow.sh` - Tests authentication flow with all systems
- `test_production_auth.sh` - Tests production authentication endpoints
- All scripts output color-coded results and JSON reports

**Note:** Test scripts require actual credentials/API keys to be configured. Make executable with `chmod +x *.sh` before first use.

**Test UI:** `lib/test_page/connection_test_page_widget.dart` (interactive, color-coded status, clipboard export)

**Access:** `context.pushNamed('ConnectionTestPage')` or navigate to `/connectionTest` URL

**5 System Tests:**
1. **Signup Flow** (10-15s, dev only) - Creates test user in all 4 systems, validates EHR creation
2. **Login Online** (5-8s) - Validates Firebase auth, Supabase connection, PowerSync sync
3. **Login Offline** (3-5s) - Validates cached Firebase auth, local PowerSync DB
4. **Data Ops Online** (5-8s) - Tests CRUD operations, validates sync queue creation
5. **Data Ops Offline** (3-5s) - Tests local CRUD, validates queue preparation

**Status Indicators:**
- 🟢 Green - Test passed
- 🔴 Red - Test failed
- 🟡 Yellow - Test in progress
- ⚪ Gray - Test not run

**Troubleshoot:**
- **Signup fails:**
  - Check Cloud Functions: `firebase functions:log --only onUserCreated`
  - Verify config: `firebase functions:config:get`
  - Check Supabase edge function: `npx supabase functions logs sync-to-ehrbase`
- **Offline fails:**
  - Enable airplane mode
  - Ensure PowerSync initialized (check `db.statusStream`)
  - Run online test first to seed local database
- **Sync queue missing:**
  - Check DB triggers: `SELECT * FROM pg_trigger WHERE tgname LIKE '%ehrbase%'`
  - Reapply migrations: `npx supabase db push`

**Pre-Production Checklist:** All 5 tests pass, System Status component shows all green, no console errors, test data cleaned from databases

## MCP Server Integration

This project has several MCP (Model Context Protocol) servers configured for enhanced AI-assisted development:

**Available MCP Servers:**
- **FlutterFlow** (`mcp__flutterflow__*`) - Programmatic access to FlutterFlow projects, custom actions, components, and app state
- **Proxmox** (`mcp__proxmox-main__*` & `mcp__proxmox-legacy__*`) - Manage VMs, nodes, storage, and execute commands in VMs
- **pfSense** (`mcp__pfsense__*`) - Firewall rules, NAT configuration, DNS management, system monitoring
- **Supabase** (native integration) - Database operations, migrations, edge functions
- **PowerSync** (`mcp__powersync__*`) - Sync status monitoring, instance health checks
- **OpenEHR** (`mcp__openEHR__*`) - EHRbase template management, composition operations, AQL queries
- **Cloudflare** (`mcp__cloudflare-*`) - Browser automation, Workers Builds debugging, container execution

**Local MCP Servers (in project):**
- `openehr-mcp-server/` - OpenEHR/EHRbase integration server
- `powersync-mcp-server/` - PowerSync monitoring and diagnostics server

**FlutterFlow MCP Usage:**
```bash
# List all MCP servers and status
claude mcp list

# FlutterFlow server location
/Users/alainbagmi/MCP_DETAILS/flutterflow-mcp-server

# API token configured in ~/.claude.json
# Interact using natural language: "List custom actions in MedZen-Iwani"
```

**Common MCP Operations:**
- Query project structure and custom code via FlutterFlow MCP
- Verify PowerSync custom actions exist in FlutterFlow
- Generate documentation for components and pages
- Check sync status and health via PowerSync MCP
- Manage firewall rules and DNS via pfSense MCP
- Query EHRbase templates and compositions via OpenEHR MCP

**Troubleshoot MCP Issues:**
```bash
# Check server status
claude mcp list

# Remove and re-add server if connection fails
claude mcp remove flutterflow
claude mcp add flutterflow --env FLUTTERFLOW_API_TOKEN=... -- node /path/to/build/index.js

# Verify server responds
# Ask: "List my FlutterFlow projects"
```

**Docs:** FLUTTERFLOW_MCP_SETUP.md (FlutterFlow setup), `~/MCP_DETAILS/` (server installations)

## Critical Rules

- **DO NOT** edit `lib/flutter_flow/` (FlutterFlow-managed, changes will be overwritten)
- **NEVER** write medical data to Firestore (Firebase for auth only, Supabase for data)
- **NEVER** use direct Supabase for medical CRUD (use PowerSync `db` for offline support)
- **Init Order:** Firebase → Supabase → PowerSync (CRITICAL - violating this breaks the app)
- **Firebase Config:** Server-side only via `firebase functions:config:set` (NEVER in code or .env)
- **EHR Creation:** Auto via `onUserCreated` (don't create manually, will cause duplicates)
- **Secure Storage:** `flutter_secure_storage` for sensitive data (tokens, keys, credentials)
- **Credentials Rotation:** If `lib/backend/supabase/supabase.dart` is ever exposed publicly, rotate all Supabase keys immediately
- **File Uploads:** Use direct Supabase Storage (PowerSync only syncs database tables, not Storage)
- **Testing:** Always test offline mode with airplane mode enabled
- **Migrations:** Never edit existing migration files, always create new ones
- **Secrets:** Never commit `.runtimeconfig.json`, `.env`, or any files with credentials

**Additional Constraints:**
- **i18n:** Supports en/fr/af (use `FFLocalizations` for all user-facing strings)
- **Material:** Material Design v2 (not v3)
- **Payments:** Stripe, Razorpay, Braintree (handled via Cloud Functions, never client-side)
- **Node.js:** Functions require Node.js 20
- **Flutter Version:** >=3.0.0 (check `flutter --version` matches)

## Code Protection & Safety

**Protection Status:** ✅ ACTIVE (Implemented 2025-11-11)

This project has comprehensive protection measures to prevent accidental deletion or overwriting of critical code, particularly the `onUserCreated` Firebase Cloud Function and custom implementations.

### Version Control (Git)

**Status:** ✅ Initialized and Active

```bash
# Repository initialized with comprehensive .gitignore
git init
git add firebase/functions/index.js firebase/functions/package.json
git commit -m "Protect onUserCreated function"

# Check repository status
git status
git log --oneline
```

**Protected in .gitignore:**
- `firebase/functions/.runtimeconfig.json` (sensitive config)
- `firebase/functions/node_modules/` (dependencies)
- `**/*.env` (all environment files)
- `supabase/.env*` (Supabase secrets)
- All credential files (*.key, *.pem, *credentials*.json)

### Automated Backups

**Status:** ✅ Scripts Created (Cron Setup Required)

**Manual Backup:** Run anytime before risky operations
```bash
./create-backup.sh
# Creates timestamped backup in ~/backups-medzen/backup_YYYYMMDD_HHMMSS/
# Includes: Firebase functions, Supabase migrations, PowerSync config, documentation, Git bundle
```

**Automated Backup:** Daily backups via cron (30-day retention)
```bash
# Setup automated backups (one-time)
./setup-automated-backups.sh
# Choose schedule: Daily 2 AM (recommended) or custom

# View backup log
tail -f ~/backups-medzen/backup.log

# List all backups
ls -lh ~/backups-medzen/
```

**Backup Locations:**
- `~/backups-medzen/backup_*/` - Timestamped backups (kept 30 days)
- `~/backups-medzen/backup.log` - Automated backup log

**What's Backed Up:**
- Firebase Cloud Functions (`firebase/functions/index.js`, `package.json`)
- Firebase config (`firebase.json`, `firestore.rules`, `storage.rules`)
- Supabase migrations (`supabase/migrations/*.sql`)
- Supabase edge functions (`supabase/functions/`)
- PowerSync configuration (`POWERSYNC_SYNC_RULES.yaml`, `lib/powersync/`)
- Critical documentation (CLAUDE.md, ONUSERCREATED_COMPLETE_IMPLEMENTATION.md, etc.)
- Git repository bundle (full history)

### Pre-Deployment Verification

**Status:** ✅ Script Ready

**Always run before deploying functions:**
```bash
cd firebase/functions
./pre-deploy-check.sh
```

**Checks Performed:**
1. ✅ Node.js version (20 or higher)
2. ✅ npm dependencies installed
3. ✅ Firebase Functions config set (Supabase, EHRbase)
4. ✅ onUserCreated function exists with EHRbase integration
5. ✅ No hardcoded credentials in code
6. ✅ Linting passes
7. ✅ .runtimeconfig.json in .gitignore
8. ✅ Git tracking status

**Deploy only if all checks pass:**
```bash
# If pre-deploy-check.sh passes
firebase deploy --only functions:onUserCreated
```

### Safe FlutterFlow Re-Export

**Status:** ✅ Script Ready

**Critical:** FlutterFlow re-export can overwrite custom code. ALWAYS use the safe re-export script:

```bash
# 1. Export from FlutterFlow web interface
#    - Download Code → Export as ZIP
#    - Save to ~/Downloads/

# 2. Run safe re-export script
./safe-reexport.sh ~/Downloads/medzen-iwani-export.zip

# Script will:
# ✓ Create automatic backup
# ✓ Extract ZIP to temp directory
# ✓ Analyze changes
# ✓ Show diff summary
# ✓ Ask for confirmation
# ✓ Copy ONLY safe directories (lib/flutter_flow/)
# ✓ PROTECT critical directories (lib/powersync/, lib/custom_code/, firebase/, supabase/)
# ✓ Verify protected files still exist
# ✓ Run flutter pub get
```

**Protected Directories (NEVER overwritten):**
- 🔒 `lib/powersync/` - Offline-first database implementation
- 🔒 `lib/custom_code/` - Custom actions and widgets
- 🔒 `firebase/` - Cloud Functions and configuration
- 🔒 `supabase/` - Migrations and edge functions
- 🔒 `graphql_queries/` - Custom GraphQL queries

**Safe Directories (Updated from FlutterFlow):**
- ✓ `lib/flutter_flow/` - FlutterFlow-managed utilities
- ✓ Generated page widgets (lib/*_page/)

### Recovery Procedures

**If Function Gets Deleted/Corrupted:**

1. **From Git (Fastest):**
   ```bash
   git status  # Check what changed
   git diff firebase/functions/index.js  # Review changes
   git checkout firebase/functions/index.js  # Restore from last commit
   git log --oneline  # View commit history
   ```

2. **From Backup:**
   ```bash
   # List backups
   ls -lh ~/backups-medzen/

   # Restore from specific backup
   BACKUP_DIR=~/backups-medzen/backup_20251111_130510
   cp $BACKUP_DIR/firebase/functions/index.js firebase/functions/
   cp $BACKUP_DIR/firebase/functions/package.json firebase/functions/

   # Verify and redeploy
   cd firebase/functions
   npm install
   ./pre-deploy-check.sh
   firebase deploy --only functions:onUserCreated
   ```

3. **From Documentation:**
   ```bash
   # Reference implementation in documentation
   cat ONUSERCREATED_COMPLETE_IMPLEMENTATION.md
   # Contains complete function code and configuration
   ```

**If FlutterFlow Re-Export Breaks Things:**

1. **Check what was overwritten:**
   ```bash
   git status
   git diff
   ```

2. **Restore from Git:**
   ```bash
   git checkout lib/powersync/
   git checkout lib/custom_code/
   git checkout firebase/
   git checkout supabase/
   ```

3. **Or restore from backup:**
   ```bash
   BACKUP_DIR=~/backups-medzen/backup_YYYYMMDD_HHMMSS
   cp -r $BACKUP_DIR/lib/powersync lib/
   cp -r $BACKUP_DIR/firebase/functions/ firebase/
   ```

### Verification After Recovery

After any recovery operation:

```bash
# 1. Verify critical files exist
ls -lh firebase/functions/index.js
ls -lh lib/powersync/
ls -lh supabase/migrations/

# 2. Check function is correct
grep "exports.onUserCreated" firebase/functions/index.js
grep "electronic_health_records" firebase/functions/index.js

# 3. Run pre-deployment check
cd firebase/functions && ./pre-deploy-check.sh

# 4. Deploy and verify
firebase deploy --only functions:onUserCreated
firebase functions:list | grep onUserCreated

# 5. Test function
firebase functions:log --only onUserCreated
```

### Protection Maintenance

**Weekly:**
- ✅ Verify automated backups running: `tail ~/backups-medzen/backup.log`
- ✅ Check Git status: `git status` (commit any changes)

**Before Major Changes:**
- ✅ Run manual backup: `./create-backup.sh`
- ✅ Commit to Git: `git add . && git commit -m "Checkpoint before X"`

**Before FlutterFlow Re-Export:**
- ✅ Run safe re-export script: `./safe-reexport.sh /path/to/export.zip`
- ✅ NEVER manually extract and copy FlutterFlow exports

**Before Deploying Functions:**
- ✅ Run pre-deployment check: `cd firebase/functions && ./pre-deploy-check.sh`

**Monthly:**
- ✅ Test recovery procedures (restore from backup to temp directory)
- ✅ Review backup retention (30 days default)

## Infrastructure & Deployment

**EHRbase Deployment:** AWS ECS (Production)
- `aws-deployment/` - CloudFormation templates for EHRbase on AWS ECS
- Stack: ECS Fargate, RDS PostgreSQL, Application Load Balancer, VPC
- Endpoint: `https://ehr.medzenhealth.app/ehrbase`
- Access: EHRbase REST API, Web UI at `/ehrbase/`
- See AWS_MCP_INSTALLATION_SUMMARY.md and AWS_EHRBASE_DEPLOYMENT_GUIDE.md

**Alternative Deployment:** Kubernetes on Proxmox (Development/Testing)
- `proxmox-deployment/k8s/` - Kubernetes manifests for EHRbase, PostgreSQL, Studio
- `ehrbase-admin/kubernetes/` - Admin dashboard deployment
- Access via MCP: `mcp__proxmox-main__*` tools for VM/node management
- Note: Currently not in use for production

**OpenEHR MCP Server:** `openehr-mcp-server/` - Local MCP server for EHRbase interaction
- Templates, compositions, AQL queries
- Docker setup: `docker-compose/docker-compose.yml`

**OpenEHR Templates:** `ehrbase-templates/` - Template conversion and deployment
- **ADL Templates**: 26 source templates in `proper-templates/` (specialty + core templates)
- **OPT Templates**: Target directory `opt-templates/` (awaiting ADL-to-OPT conversion)
- **Automation Scripts**:
  - `track_conversion_progress.sh` - Real-time conversion status tracker
  - `upload_all_templates.sh` - Batch upload to EHRbase (ready)
  - `verify_templates.sh` - Post-upload verification (ready)
- **Documentation**: `TEMPLATE_CONVERSION_STATUS.md` - Complete status and procedures
- **Current Status**: ⏳ Awaiting manual conversion (6-13 hours estimated)
- **Integration Ready**: Edge function mappings and DB triggers configured

**Network Configuration:** pfSense firewall (NAT, DNS overrides)
- Access via MCP: `mcp__pfsense__*` tools for firewall/DNS management

## FlutterFlow Re-Export Process

**When package warnings appear:**
1. Open FlutterFlow web interface → Load project fully (30-60s)
2. Download Code → Export as ZIP
3. Extract and copy ONLY FlutterFlow-managed files (`lib/flutter_flow/`, generated widgets)
4. NEVER overwrite: `lib/powersync/`, `lib/custom_code/`, `firebase/`, `supabase/`
5. Run `flutter pub get` and verify with test suite

**Docs:** FOLLOW_THESE_STEPS.md, FLUTTERFLOW_REEXPORT_GUIDE.md, REEXPORT_CHECKLIST.md

## Common Gotchas

1. **Script permissions** - Many bash scripts may not be executable by default. Run `chmod +x *.sh` in project root before using test/deployment scripts
2. **FlutterFlow re-exports** - NEVER overwrite custom code directories when re-exporting from FlutterFlow (`lib/powersync/`, `lib/custom_code/`, `firebase/`, `supabase/`)
3. **Firebase config in code** - Config MUST be set server-side via `firebase functions:config:set`, never in code
4. **Offline testing** - Must run online tests FIRST to seed local PowerSync database before offline tests work
5. **EHRbase sync timing** - Check `ehrbase_sync_queue.sync_status` - don't assume data is in EHRbase immediately
6. **Init order violations** - App will fail silently or with cryptic errors if Firebase → Supabase → PowerSync order is violated
7. **Direct Supabase writes** - Medical data written directly to Supabase (bypassing PowerSync) won't work offline
8. **PowerSync initialization timing** - PowerSync initializes in landing pages (not `main.dart`) to support role-based sync rules
9. **Test script credentials** - All test scripts require actual credentials/keys to be configured. They test live systems, not mocks
10. **FlutterFlow custom code imports** - NEVER remove auto-generated imports in custom actions/widgets even if Flutter analyzer shows them as unused. FlutterFlow platform requires these imports for validation and will reject pushes without them

## Quick Troubleshooting Reference

**Common Issues:**

| Issue | Quick Fix | Command/Action |
|-------|----------|----------------|
| Build fails | Clean and rebuild | `flutter clean && flutter pub get && flutter build <platform>` |
| PowerSync not connecting | Check token function | `npx supabase functions logs powersync-token` |
| Firebase auth fails | Check Firebase config | `firebase functions:config:get` |
| Supabase connection fails | Verify project link | `npx supabase link --project-ref YOUR_REF` |
| EHRbase sync stuck | Check sync queue | Query `ehrbase_sync_queue` table for failures |
| Offline mode broken | Verify init order | Check `lib/main.dart` - Firebase → Supabase → PowerSync |
| MCP server offline | Check server status | `claude mcp list` |
| Package version warnings | Re-export from FlutterFlow | See FLUTTERFLOW_REEXPORT_GUIDE.md |
| Scripts not executable | Fix permissions | `chmod +x *.sh` |

**Diagnostic Scripts:**
- `./test_system_connections.sh` - Full system integration test
- `./test_system_connections_simple.sh` - Quick connectivity check
- `./verify_powersync_setup.sh` - PowerSync validation
- `./verify_reexport.sh` - FlutterFlow re-export verification
- `./test_auth_flow.sh` - Complete authentication flow test
- `./test_production_auth.sh` - Production authentication test
- `./verify_specialties_count.sh` - Verify Supabase data integrity

**OpenEHR Template Scripts:**
- `./ehrbase-templates/track_conversion_progress.sh` - Check ADL-to-OPT conversion status
- `./ehrbase-templates/upload_all_templates.sh` - Batch upload OPT templates to EHRbase
- `./ehrbase-templates/verify_templates.sh` - Verify templates uploaded successfully

**Note:** All scripts require proper credentials. Make executable: `chmod +x *.sh` or `chmod +x ehrbase-templates/*.sh`

**Debug Logs:**
- Firebase: `firebase functions:log [--only functionName]`
- Supabase Edge Functions: `npx supabase functions logs <function-name>`
- Flutter: Check console output during `flutter run`
- PowerSync: Monitor `db.statusStream` in code

## Documentation Reference

**Quick Start:** QUICK_START.md (30-minute setup guide)
**Architecture:** EHR_SYSTEM_README.md, IMPLEMENTATION_SUMMARY.md
**Deployment:** EHR_SYSTEM_DEPLOYMENT.md, PRODUCTION_DEPLOYMENT_GUIDE.md, DEPLOYMENT_CHECKLIST.md
**PowerSync:** POWERSYNC_QUICK_START.md, POWERSYNC_MULTI_ROLE_GUIDE.md (+ 13 other PowerSync docs)
**Testing:** TESTING_GUIDE.md, SYSTEM_INTEGRATION_STATUS.md
**FlutterFlow:** FLUTTERFLOW_MCP_SETUP.md, FLUTTERFLOW_INTEGRATION_SUMMARY.md, FLUTTERFLOW_POWERSYNC_GUIDE.md
**OpenEHR Templates:**
- `ehrbase-templates/TEMPLATE_CONVERSION_STATUS.md` - ⭐ Template conversion tracking and procedures
- `ehrbase-templates/README.md` - Quick reference and script documentation
- `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` - Comprehensive deployment guide
- `ehrbase-templates/TEMPLATE_DESIGN_OVERVIEW.md` - Template architecture
**Troubleshooting:** Each major doc has a dedicated troubleshooting section

Total documentation: 13,000+ lines across 50+ files
