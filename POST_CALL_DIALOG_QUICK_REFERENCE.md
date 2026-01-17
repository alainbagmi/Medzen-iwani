# Post-Call Dialog - Quick Reference Card

## TL;DR - 5 Second Check

After ending a provider video call, look for these messages in the debug logs:

### ✅ SUCCESS (Dialog should appear)
```
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met
```

### ⚠️ NOT PROVIDER (Dialog won't show)
```
🔍 isProvider value: false
   → Not a provider - only providers see post-call dialog
```

### ⚠️ CONTEXT INVALID (Dialog can't appear)
```
🔍 context.mounted value: false
   → Context not mounted - cannot show dialog
```

### ❌ EXCEPTION (Something broke)
```
❌ Error in post-call dialog logic: [error message]
```

---

## Quick Test

```bash
# Run this command
flutter run -d chrome -v 2>&1 | grep -E "(🔍 isProvider|🔍 context.mounted|Both conditions|Conditions not met|Error in post-call)"

# End a provider call and check output
```

---

## Expected vs Actual

| What Should Happen | What to See in Logs | What You See | Action |
|---|---|---|---|
| Dialog appears | `✅ Both conditions met` | Dialog appears | ✅ SUCCESS |
| Dialog appears | `✅ Both conditions met` | Dialog does NOT appear | Check for dialog exception |
| Dialog not shown | `isProvider: false` | Dialog not shown | ✅ Correct (patient role) |
| Dialog not shown | `context.mounted: false` | Dialog not shown | Try longer delay |
| Error occurs | `❌ Error in post-call` | Dialog not shown | Fix exception |

---

## Common Issues & Fixes

| Log Output | Meaning | Quick Fix |
|---|---|---|
| `isProvider: false` (but you're a provider) | Wrong role detected | Check appointments_widget.dart line 839 |
| `context.mounted: false` | Context disposed | Increase delay from 300ms to 500ms+ |
| Exception about dialog | Widget build error | Check PostCallClinicalNotesDialog parameters |
| No logs at all | Didn't reach post-call logic | Video call didn't end properly (check Navigator.pop) |

---

## Where to Look for Logs by Platform

- **Chrome Web:** DevTools → Console → Search "🔍"
- **Android:** `flutter logs | grep "isProvider"`
- **Terminal:** `grep "isProvider" video_call_test.log`
