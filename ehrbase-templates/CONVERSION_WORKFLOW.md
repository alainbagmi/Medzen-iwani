# OpenEHR Template Conversion - Optimized Workflow

This guide provides the most efficient workflow for converting all 26 ADL templates to OPT format.

## 🚀 Quick Start (Recommended)

### Use the Automated Helper Script

The **convert_templates_helper.sh** script automates everything possible and guides you through the conversion process step-by-step.

```bash
# Start the conversion workflow
./ehrbase-templates/convert_templates_helper.sh
```

**What the script does automatically:**
- ✅ Opens Template Designer in your browser
- ✅ Copies ADL content to clipboard
- ✅ Tracks progress across sessions (resumable)
- ✅ Validates OPT files after creation
- ✅ Provides clear next-step instructions
- ✅ Shows estimated time remaining
- ✅ Allows skipping problematic templates

**Features:**
- **Progress persistence** - If you quit, progress is saved and you can resume anytime
- **Auto-clipboard** - Template content automatically copied (macOS/Linux)
- **Validation** - Checks for correct XML namespace in OPT files
- **Visual feedback** - Color-coded status and progress bars
- **Sequential workflow** - Processes templates in order, one at a time

## 📋 Manual Workflow (Without Helper Script)

If you prefer to work manually:

### Step 1: Open Template Designer

Navigate to: https://tools.openehr.org/designer/

### Step 2: For Each Template

1. **Open ADL file** from `ehrbase-templates/proper-templates/`
2. **Copy content** (Ctrl+A, Ctrl+C or Cmd+A, Cmd+C)
3. **In Template Designer:**
   - Click "Import" or "New Template"
   - Paste ADL content
   - Wait for validation
   - Fix any errors shown
   - Click "Export" → "Operational Template (OPT)"
4. **Save OPT file** to `ehrbase-templates/opt-templates/` with same filename (change .adl → .opt)
5. **Verify namespace** - Open OPT in text editor, ensure root has:
   ```xml
   <template xmlns="http://schemas.openehr.org/v1">
   ```

### Step 3: Track Progress

Run after each template or batch:

```bash
./ehrbase-templates/track_conversion_progress.sh
```

## 🎯 Conversion Tips

### Optimize Your Workspace

**Recommended Setup:**
1. **Left side:** Template Designer browser tab
2. **Right side:** Terminal with helper script
3. **Bottom:** Text editor with `opt-templates/` folder open (for quick validation)

### Keyboard Shortcuts

**In Template Designer:**
- Import: Usually `Ctrl+I` or menu → Import
- Export: Usually `Ctrl+E` or menu → Export → Operational Template

**Clipboard Management:**
- macOS: `pbcopy` and `pbpaste` (built-in)
- Linux: Install `xclip`: `sudo apt-get install xclip`

### Batch Processing Strategy

**Option 1: Full Session (Fastest)**
- Block 6-13 hours
- Run `convert_templates_helper.sh`
- Process all 26 templates sequentially
- Take breaks every 5-7 templates (track_conversion_progress.sh shows progress)

**Option 2: Incremental (Most Flexible)**
- Convert 5-10 templates per session
- Helper script saves progress automatically
- Resume with same command: `./ehrbase-templates/convert_templates_helper.sh`
- Ideal for spreading work across multiple days

**Option 3: Priority-First**
- Convert 19 specialty templates first (lines 1-19 in tracking script output)
- These are required for production
- 7 additional templates can be done later

## 🐛 Troubleshooting

### Template Designer Issues

**Issue: Designer shows validation errors**
- **Cause:** ADL syntax issues or missing archetype dependencies
- **Solution:** Check error message for specific archetype name, ensure proper ADL 1.5.1 syntax

**Issue: Export button disabled**
- **Cause:** Template hasn't been validated successfully
- **Solution:** Fix validation errors first, look for red error indicators in designer

**Issue: Designer loads indefinitely**
- **Cause:** Network issues or browser cache
- **Solution:** Clear browser cache, try different browser, check internet connection

### OPT File Issues

**Issue: Invalid XML namespace after export**
- **Symptom:** `track_conversion_progress.sh` shows "Invalid XML namespace"
- **Fix:** Open OPT file, change root element:
  ```xml
  <!-- ❌ Wrong -->
  <template xmlns="openEHR/v1/Template">

  <!-- ✅ Correct -->
  <template xmlns="http://schemas.openehr.org/v1">
  ```

**Issue: File saved with wrong extension**
- **Solution:** Rename `.xml` to `.opt`, or re-export as Operational Template

**Issue: File too large / garbled content**
- **Cause:** Binary encoding or wrong export format
- **Solution:** Re-export, ensure "Operational Template (OPT)" format selected

### Helper Script Issues

**Issue: Clipboard not working**
- **macOS:** Should work automatically with `pbcopy`
- **Linux:** Install xclip: `sudo apt-get install xclip`
- **Workaround:** Manually copy with `cat ehrbase-templates/proper-templates/[file].adl`

**Issue: Browser doesn't open automatically**
- **Solution:** Manually navigate to https://tools.openehr.org/designer/

**Issue: Progress file corruption**
- **Solution:** Delete progress file and restart: `rm ehrbase-templates/.conversion_progress`

## ⏱️ Time Estimates

| Approach | Time per Template | Total Time (26) | Best For |
|----------|-------------------|-----------------|----------|
| **With Helper Script** | 15-25 min | 6.5-10.8 hours | Most users |
| **Manual Workflow** | 20-30 min | 8.7-13.0 hours | Advanced users |
| **First-Time User** | 25-35 min | 10.8-15.2 hours | Learning process |

**Factors affecting speed:**
- Familiarity with Template Designer
- Template complexity (specialty templates more complex than core)
- Validation errors requiring fixes
- Coffee breaks 😊

## ✅ Verification Checklist

After completing conversions, verify your work:

1. **Count check:**
   ```bash
   ls -1 ehrbase-templates/opt-templates/*.opt | wc -l
   # Should show: 26
   ```

2. **Progress check:**
   ```bash
   ./ehrbase-templates/track_conversion_progress.sh
   # Should show: 100% complete, 0 pending
   ```

3. **Namespace validation:**
   ```bash
   grep -L 'xmlns="http://schemas.openehr.org/v1"' ehrbase-templates/opt-templates/*.opt
   # Should show: (empty) - no files with wrong namespace
   ```

4. **File size check:**
   ```bash
   ls -lh ehrbase-templates/opt-templates/*.opt
   # All files should be 10-200 KB range (typical OPT size)
   ```

## 🎯 Next Steps After Conversion

Once all 26 templates are converted:

1. **Final Verification:**
   ```bash
   ./ehrbase-templates/track_conversion_progress.sh
   ```

2. **Upload to EHRbase:**
   ```bash
   ./ehrbase-templates/upload_all_templates.sh
   ```

3. **Verify Upload:**
   ```bash
   ./ehrbase-templates/verify_templates.sh
   ```

4. **Integration Testing:**
   - See `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` for composition creation tests
   - Monitor `ehrbase_sync_queue` for sync processing
   - Test edge function: `npx supabase functions logs sync-to-ehrbase`

## 📚 Additional Resources

- **Template Designer Guide:** https://tools.openehr.org/designer/docs
- **ADL Documentation:** https://specifications.openehr.org/releases/AM/latest/ADL2.html
- **OpenEHR Specifications:** https://specifications.openehr.org/
- **Project Documentation:**
  - `TEMPLATE_CONVERSION_STATUS.md` - Current status and overview
  - `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` - Complete deployment guide
  - `README.md` - Quick reference

## 💡 Pro Tips

1. **Name Consistency:** Keep ADL and OPT filenames identical (except extension)
2. **Validation First:** Don't proceed if Template Designer shows errors
3. **Save Progress:** Use helper script's pause feature (press 'Q') for breaks
4. **Batch Verification:** Run track_conversion_progress.sh after every 5 templates
5. **Backup Originals:** ADL files in `proper-templates/` should never be modified
6. **Git Commit:** Consider committing OPT files after every 5-10 conversions

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-02
**Status:** Ready for use
**Estimated Total Time:** 6.5-15 hours depending on approach and experience
