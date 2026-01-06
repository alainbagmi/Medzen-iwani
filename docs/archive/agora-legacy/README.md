# Agora RTC Legacy Documentation Archive

**Archive Date:** November 22, 2025
**Migration Status:** Completed - Migrated to Amazon Chime SDK

## Overview

This directory contains historical documentation for the Agora RTC Engine implementation that was previously used in the MedZen telehealth application for video calling functionality.

## Migration Context

**Original Implementation:**
- Agora RTC Engine v6.3.2
- Token generation via Firebase Cloud Function (`agora-token`)
- Flutter integration using `agora_rtc_engine` package

**Migration Target:**
- Amazon Chime SDK (eu-west-1, af-south-1 regions)
- Token generation via Supabase Edge Function (`chime-meeting-token`)
- WebView-based implementation with HTML/JavaScript Chime SDK

**Completion Date:** November 2025

## Archived Files

### AGORA_SETUP_SUMMARY.md
Summary of the original Agora RTC setup, including:
- Installation instructions
- Firebase Function configuration
- Dependencies (`agora-token@2.0.5`)

### AGORA_VIDEO_CALL_TESTING_GUIDE.md
Testing procedures and validation steps for the Agora RTC implementation:
- User flows (Provider/Patient)
- Permission handling
- Token generation testing
- Error scenarios

## Why This Documentation is Preserved

1. **Migration History:** Provides context for understanding why and how the video calling architecture changed
2. **Lessons Learned:** Documents the previous approach for reference in future architectural decisions
3. **Troubleshooting:** May be useful if any legacy issues surface related to old video call sessions
4. **Knowledge Transfer:** Helps new team members understand the evolution of the video calling feature

## Current Video Calling Architecture

For current implementation details, see:
- `CHIME_VIDEO_TESTING_GUIDE.md` - Current testing procedures
- `CHIME_SDK_DEPLOYMENT_GUIDE.md` - Deployment instructions
- `CHIME_DEPLOYMENT_COMPLETE.md` - Migration completion notes
- `CLAUDE.md` - Overall architecture documentation (Video/Audio Calling section)

## Code Status

**All Agora code has been removed from the active codebase:**
- ✅ `lib/custom_code/widgets/pre_joining_dialog.dart` - Removed
- ✅ PreJoiningDialog export from index.dart - Removed
- ✅ agora-token dependency - Removed from package.json
- ✅ Agora Firebase Functions - Removed
- ✅ Agora Flutter dependencies - Removed

**Remaining references:**
- Documentation files only (this archive)
- Database migration history (video_call_sessions table evolution)
- Comments in CLAUDE.md explaining the migration

---

**Note:** This documentation is read-only and should not be used for implementation. Refer to the current Chime SDK documentation for all video calling development.
