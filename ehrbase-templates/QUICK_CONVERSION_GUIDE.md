# Quick Conversion Guide - MedZen Templates

**Task:** Convert 26 MedZen ADL templates to OPT format for EHRbase upload
**Time:** 6.5-10.8 hours (can be split across multiple sessions)
**Method:** Manual conversion via Template Designer (ONLY option for macOS)

## Before You Start

### Prerequisites

- ✅ macOS system (Darwin 24.6.0)
- ✅ Web browser (Safari, Chrome, or Firefox)
- ✅ 26 ADL source templates in `ehrbase-templates/proper-templates/`
- ✅ Conversion helper script ready
- ✅ Stable internet connection

### Time Planning

**Recommended Sessions:**

| Session | Templates | Time | When |
|---------|-----------|------|------|
| 1 | 1-10 | 2.5-4 hours | Morning or afternoon block |
| 2 | 11-20 | 2.5-4 hours | Next day (avoid fatigue) |
| 3 | 21-26 | 1.5-2.5 hours | Final session |

**Why split?**
- Prevents repetitive strain
- Maintains conversion accuracy
- Progress auto-saved between sessions
- Can pause anytime with `Q` command

## Step-by-Step Instructions

### 1. Start Conversion Helper Script

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
./ehrbase-templates/convert_templates_helper.sh
```

**What happens:**
- Script opens Template Designer in your default browser
- First template's ADL content copied to clipboard
- Terminal shows template preview and instructions
- Waits for your completion

### 2. For Each Template (Repeat 26 Times)

#### A. Import Template (30 seconds)

1. **Browser opens automatically** to: https://tools.openehr.org/designer/
2. **Click** "Import" or "New Template" button
3. **Paste** ADL content (Cmd+V) - already in clipboard
4. **Wait** for validation (5-10 seconds)

**Expected:** Green checkmark, no errors

**If errors appear:**
- Copy error message
- Check ADL file syntax (rare - templates are pre-validated)
- Consult `CONVERSION_WORKFLOW.md` for troubleshooting

#### B. Export Template (30 seconds)

5. **Click** "Export" dropdown menu
6. **Select** "Operational Template (OPT)"
7. **Save file** with exact name shown by script:
   - Example: `medzen-admission-discharge-summary.v1.opt`
   - Location: `ehrbase-templates/opt-templates/`

**Important:** Use exact filename (script provides it)

#### C. Confirm Completion (5 seconds)

8. **Return to terminal**
9. **Press ENTER** to mark template complete

**What script does:**
- ✅ Verifies OPT file exists
- ✅ Validates XML namespace (`xmlns="http://schemas.openehr.org/v1"`)
- ✅ Checks for required `<concept>` and `<template_id>` elements
- ✅ Updates progress counter
- ✅ Copies next template to clipboard
- ✅ Opens browser for next template

**Script advances automatically to next template**

### 3. Pause and Resume

**To Pause:**
- Press `Q` + ENTER at any prompt
- Progress saved to `.conversion_progress` file
- Can resume later

**To Resume:**
```bash
./ehrbase-templates/convert_templates_helper.sh
# Starts from where you left off
```

### 4. Skip a Template (if needed)

**To Skip:**
- Press `S` + ENTER at prompt
- Template marked as skipped
- Script moves to next template

**When to skip:**
- Template has validation errors you can't resolve
- Want to batch-fix issues later
- Need to consult with team about template structure

**Note:** You can manually convert skipped templates later

## Progress Tracking

### Check Current Status

```bash
./ehrbase-templates/track_conversion_progress.sh
```

**Output shows:**
```
Total ADL Templates: 26
Converted to OPT: 15
Pending Conversion: 11

Conversion Progress: 57.7%
[████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░]

Estimated Time Remaining: 2.8-5.5 hours
```

### Manual Progress Check

```bash
ls -1 ehrbase-templates/opt-templates/*.opt | wc -l
# Should eventually show: 26
```

## After Conversion Complete

### Step 1: Verify All Templates Converted

```bash
# Check count
ls -1 ehrbase-templates/opt-templates/*.opt | wc -l

# Expected output: 26
```

### Step 2: Upload to EHRbase

```bash
./ehrbase-templates/upload_all_templates.sh
```

**Expected output:**
```
Uploading templates to EHRbase...
✅ 1/26: medzen-admission-discharge-summary.v1
✅ 2/26: medzen-antenatal-care-encounter.v1
...
✅ 26/26: medzen-vital-signs-encounter.v1

Upload complete: 26/26 templates successfully uploaded
Detailed log: ehrbase-templates/upload_log_20251102_143022.txt
```

### Step 3: Verify Upload

```bash
./ehrbase-templates/verify_templates.sh
```

**Expected output:**
```
Verifying templates in EHRbase...
✅ Found 26 templates in EHRbase
✅ All medzen.* templates present
✅ All core ehrbase.* templates present

Verification successful!
```

## Troubleshooting

### Issue: Browser doesn't open automatically

**Solution:**
```bash
# Manually open in browser
open https://tools.openehr.org/designer/

# Or copy URL and paste in browser
```

### Issue: Clipboard doesn't auto-copy

**Solution:**
```bash
# Manual copy for current template (example)
cat ehrbase-templates/proper-templates/medzen-admission-discharge-summary.v1.adl | pbcopy
```

### Issue: Template Designer validation fails

**Check:**
1. Copied full ADL content (not truncated)
2. No special characters corrupted during paste
3. Browser has JavaScript enabled
4. Clear browser cache and retry

**If persistent:**
- Note template name
- Press `S` to skip
- Report issue with error details

### Issue: OPT file validation fails (after export)

**Script shows:**
```
⚠️  Warning: XML namespace may be incorrect
⚠️  Warning: Missing <concept> element
```

**Actions:**
1. Re-export from Template Designer
2. Ensure saved as "Operational Template (OPT)" not "Template (OET)"
3. Check file size (should be 50-500KB, not tiny)
4. If persistent, manually inspect XML with text editor

### Issue: Lost progress file

**Symptoms:** Script restarts from beginning

**Solution:**
```bash
# Check progress file exists
cat ehrbase-templates/.conversion_progress

# If missing, manually create with current count
echo "15" > ehrbase-templates/.conversion_progress

# Resume script
./ehrbase-templates/convert_templates_helper.sh
```

### Issue: Template already converted but script doesn't detect

**Symptom:** Script prompts for already-converted template

**Solution:**
```bash
# Press ENTER to acknowledge
# Or press S to skip

# Script will validate existing file and continue
```

## Tips for Efficiency

### 1. Keyboard Shortcuts

- **Browser:** Cmd+V (paste), Cmd+S (save)
- **Terminal:** ENTER (continue), Q+ENTER (pause), S+ENTER (skip)

### 2. Dual Monitor Setup

- **Monitor 1:** Terminal with conversion script
- **Monitor 2:** Browser with Template Designer
- Reduces window switching

### 3. Batch Similar Templates

Group by specialty type for mental model efficiency:
- Templates 1-6: General encounters (admission, consultation, emergency)
- Templates 7-12: Lab/diagnostic (laboratory, pathology, radiology)
- Templates 13-18: Specialty consults (cardiology, neurology, oncology)
- Templates 19-26: Support services (pharmacy, physiotherapy, vital signs)

### 4. Take Breaks

- Every 5-7 templates (1.5-2 hours)
- Stand, stretch, hydrate
- Prevents errors from fatigue

### 5. Error Log

Keep a note of any issues:
```
Template: medzen-neurology-examination.v1
Issue: Validation warning about archetype version
Resolution: Ignored, exported successfully
Time: 10:45 AM
```

Helps with debugging if issues recur

## Quality Checks

### After Each Template

- ✅ Filename matches script's suggested name
- ✅ File size reasonable (50-500KB)
- ✅ Script validation shows green checkmarks
- ✅ No error messages in terminal

### After All Templates

```bash
# 1. Count check
ls -1 ehrbase-templates/opt-templates/*.opt | wc -l
# Expected: 26

# 2. Name pattern check
ls ehrbase-templates/opt-templates/ | grep -c "medzen-"
# Expected: 26

# 3. Size check (no tiny files)
find ehrbase-templates/opt-templates -name "*.opt" -size -10k
# Expected: no output (all files > 10KB)

# 4. XML namespace check
grep -L 'xmlns="http://schemas.openehr.org/v1"' ehrbase-templates/opt-templates/*.opt
# Expected: no output (all files have correct namespace)
```

## Time Optimization

**Target:** 15 minutes per template (fastest realistic pace)

**Breakdown:**
- Import + validate: 30-45 seconds
- Review for errors: 15-30 seconds (if any)
- Export + save: 30-45 seconds
- Script validation: 10-15 seconds
- Total: ~2-3 minutes per template (ideal conditions)

**Reality:** 15-25 minutes average due to:
- Browser loading times
- Network latency
- Human reaction time
- Occasional validation issues
- File save dialog navigation

**Accept:** 25-minute average = 10.8 hours total (realistic)
**Strive for:** 15-minute average = 6.5 hours total (experienced pace)

## Completion Checklist

- [ ] All 26 templates converted (verify with `ls` count)
- [ ] All OPT files pass validation (no warnings in logs)
- [ ] Upload script run successfully (26/26 uploaded)
- [ ] Verification script confirms templates in EHRbase
- [ ] Test composition created successfully
- [ ] `ehrbase_sync_queue` processing verified
- [ ] Edge function logs show no errors
- [ ] Database triggers functional
- [ ] Documentation updated (if needed)
- [ ] Progress files cleaned up (`.conversion_progress` removed)

## Success Criteria

✅ 26 OPT files in `ehrbase-templates/opt-templates/`
✅ All files validate successfully (correct XML structure)
✅ EHRbase confirms 26 templates available
✅ Test composition creates without errors
✅ Sync queue processes templates correctly

## Next Steps After Completion

1. **Test EHR Integration**
   ```bash
   # Via MCP server
   # Create test composition for vital signs
   ```

2. **Monitor Sync Queue**
   ```sql
   SELECT * FROM ehrbase_sync_queue
   WHERE sync_status = 'pending'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

3. **Verify Edge Function**
   ```bash
   npx supabase functions logs sync-to-ehrbase --tail
   ```

4. **Update Status Documents**
   - Mark conversion complete in `MEDZEN_TEMPLATE_STATUS.md`
   - Update deployment timeline
   - Document any issues encountered

## Support

**Issues during conversion:**
- Check `CONVERSION_WORKFLOW.md` for detailed troubleshooting
- Review `CONVERSION_TOOL_RESEARCH.md` for tool context
- Check Template Designer documentation: https://tools.openehr.org/designer/

**Technical questions:**
- OpenEHR forum: https://discourse.openehr.org/
- EHRbase documentation: https://docs.ehrbase.org/

**MedZen-specific:**
- Review `EHR_SYSTEM_README.md`
- Check database migrations for template usage
- Consult `IMPLEMENTATION_SUMMARY.md`

---

**Ready to start?**

```bash
./ehrbase-templates/convert_templates_helper.sh
```

🚀 **Good luck with the conversion!**
