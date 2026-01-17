# Custom Code Usage Analysis Report

Generated: 2025-12-16

## Summary

- **Total Custom Widgets:** 7 files (1 used, 6 unused in code)
- **Total Custom Actions:** 20 files (3 used, 17 unused in code)

## Custom Widgets

### ✅ USED (1)
| Widget | Usage Count | Location Examples |
|--------|-------------|-------------------|
| CountryPhonePicker | 14 | facility_admin_account_creation, patient_account_creation, provider_account_creation, sign_in_copy |

### ❓ UNUSED IN CODE BUT MAY BE IMPORTANT (5)
| Widget | Status | Notes |
|--------|--------|-------|
| ChimeMeetingEnhanced | 0 uses | ⚠️ **PRODUCTION-READY** per CLAUDE.md - Recommended widget with AWS Chime SDK v3.19.0 |
| ChimeMeetingWebview | 0 uses | ⚠️ Legacy implementation per CLAUDE.md - Still may be used via FlutterFlow |
| ChimeMeetingNative | 0 uses | ⚠️ Alternative implementation - May be used via FlutterFlow |
| TypingIndicator | 0 uses | Likely for chat UI - May be added via FlutterFlow |
| TextVisible | 0 uses | Utility widget - May be added via FlutterFlow |

### ⚠️ NOT IN INDEX (1)
| Widget | Status | Notes |
|--------|--------|-------|
| chime_meeting_webview_cdn.dart | Not exported | Appears to be backup/alternative version |

## Custom Actions

### ✅ USED (3)
| Action | Usage Count | Location Examples |
|--------|-------------|-------------------|
| joinRoom | 4 | Video call functionality |
| streamResponse | 4 | AI streaming responses |
| sendBedrockMessage | 2 | AI chat messaging |

### ❌ UNUSED - SAFE TO REMOVE (14)
| Action | Usage Count | Category | Reason |
|--------|-------------|----------|--------|
| htmlfile | 0 | Utility | Unknown purpose, no usage |
| uploadProfilePicture | 0 | Storage | Duplicate - likely replaced by uploadProfilePictureWithCleanup |
| uploadProfilePictureWithCleanup | 0 | Storage | Not wired up, but better version |
| initializeMessaging | 0 | Messaging | Not connected |
| subscribeToChanges | 0 | Messaging | Not connected |
| createBedrockConversation | 0 | AI Chat | Not wired up |
| deleteBedrockConversation | 0 | AI Chat | Not wired up |
| getConversationHistory | 0 | AI Chat | Not wired up |
| listPatientConversations | 0 | AI Chat | Not wired up |
| processAiResponse | 0 | AI Chat | Not wired up |
| handleAiError | 0 | AI Chat | Not wired up |
| updateSystemMessage | 0 | AI Chat | Not wired up |
| validateChatInput | 0 | AI Chat | Not wired up |
| checkAuthState | 0 | Auth | Not wired up |

### ⚠️ NOT IN INDEX (2)
| Action | Usage Count | Notes |
|--------|-------------|-------|
| getOrCreateConversation | 0 | Not exported in index.dart |
| listUserConversations | 0 | Not exported in index.dart |

## Recommendations

### ⚠️ DO NOT REMOVE - Core Features
Even though these show 0 usage in code search, they are documented as production features and may be:
- Added via FlutterFlow UI (not visible in code export)
- Required for future functionality
- Referenced in system documentation as production-ready

**Keep these widgets:**
- ChimeMeetingEnhanced (production video call widget)
- ChimeMeetingWebview (legacy video call widget)
- ChimeMeetingNative (alternative video call widget)
- TypingIndicator (chat UI component)
- TextVisible (utility component)

### ✅ SAFE TO REMOVE - Unused Actions
These actions have no usage and appear to be:
- Duplicates (uploadProfilePicture vs uploadProfilePictureWithCleanup)
- Incomplete implementations (AI chat actions not wired up)
- Utilities that were never connected (htmlfile)
- Features not yet implemented (messaging initialization)

**Can remove these 16 files:**
1. lib/custom_code/actions/htmlfile.dart
2. lib/custom_code/actions/uploadProfilePicture.dart
3. lib/custom_code/actions/uploadProfilePictureWithCleanup.dart (WAIT - might be needed later)
4. lib/custom_code/actions/initializeMessaging.dart
5. lib/custom_code/actions/subscribeToChanges.dart
6. lib/custom_code/actions/createBedrockConversation.dart
7. lib/custom_code/actions/deleteBedrockConversation.dart
8. lib/custom_code/actions/getConversationHistory.dart
9. lib/custom_code/actions/listPatientConversations.dart
10. lib/custom_code/actions/processAiResponse.dart
11. lib/custom_code/actions/handleAiError.dart
12. lib/custom_code/actions/updateSystemMessage.dart
13. lib/custom_code/actions/validateChatInput.dart
14. lib/custom_code/actions/checkAuthState.dart
15. lib/custom_code/actions/getOrCreateConversation.dart
16. lib/custom_code/actions/listUserConversations.dart

### ⚠️ MAYBE REMOVE - Backup Widget
- lib/custom_code/widgets/chime_meeting_webview_cdn.dart (not exported, appears to be backup)

## Next Steps

1. Review this report
2. Confirm which items to remove
3. Remove unused actions from files
4. Update lib/custom_code/actions/index.dart to remove exports
5. Recompile to verify no breakage
