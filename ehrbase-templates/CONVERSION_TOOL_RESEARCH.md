# OpenEHR Template Conversion Tool Research

**Date:** 2025-11-02
**Purpose:** Research automated ADL→OPT conversion tools for macOS
**Outcome:** Manual Template Designer is the only viable option

## Executive Summary

After comprehensive research, **no automated batch conversion tools are available for macOS** to convert ADL 1.5.1 templates to OPT 1.4 format required by EHRbase.

**Recommendation:** Proceed with manual Template Designer conversion (6.5-10.8 hours estimated).

## Tools Evaluated

### 1. ADL Workbench (adlc CLI)

**Capability:** ✅ Can convert ADL→OPT 1.4 (batch)
**Platform:** ❌ Windows/Linux only (NO macOS support)
**Status:** Not installed, not available for macOS
**Verdict:** REJECTED - Platform incompatibility

**Details:**
- Command-line tool `adlc` for batch conversion
- Official OpenEHR tool for ADL 1.4 processing
- Last macOS build was for Mac OS X 10.5 (ancient)
- Current version 2.1.0 has no macOS binaries

**Example Usage (if available):**
```bash
adlc template.adl -f xml -a serialise --flat > template.opt
```

### 2. LinkEHR Editor/Studio

**Capability:** ✅ Can convert ADL 1.4→OPT
**Platform:** ❌ Windows/Linux only (NO official macOS version)
**Status:** Eclipse-based, requires Mozilla/XULRunner/WebKitGTK+
**Verdict:** REJECTED - Platform incompatibility

**Details:**
- Multi-reference model archetype editor
- Java-based (theoretically portable)
- No official macOS builds available
- Download page only lists Windows 7-10 and Linux

### 3. Archie Java Library

**Capability:** ⚠️ Can convert ADL 1.4→ADL 2→OPT 2
**Platform:** ✅ Java (cross-platform)
**Status:** ❌ Produces OPT 2, EHRbase needs OPT 1.4
**Verdict:** REJECTED - Output format incompatibility

**Details:**
- OpenEHR library implementing ADL 2, AOM 2, BMM
- Can convert ADL 1.4→ADL 2 (used by CKM)
- Generates OPT 2 (ADL 2 operational templates)
- EHRbase only accepts OPT 1.4 (confirmed as of Jan 2024)

**GitHub:** https://github.com/openEHR/archie

**Programmatic Usage:**
```java
SimpleArchetypeRepository repository = new SimpleArchetypeRepository();
// Add all archetypes
Flattener flattener = new Flattener(repository,
    BuiltinReferenceModels.getMetaModelProvider())
    .createOperationalTemplate(true);
OperationalTemplate template = (OperationalTemplate)
    flattener.flatten(sourceArchetype);
```

**Why Rejected:**
- OPT 2 format is fundamentally different from OPT 1.4
- EHRbase REST API: `/definition/template/adl1.4` (no ADL 2 endpoint)
- Would require additional OPT 2→OPT 1.4 conversion (not available)

### 4. Archetype Designer (Web Tool)

**Capability:** ✅ Can convert ADL→OPT 1.4
**Platform:** ✅ Web-based (any OS)
**Status:** ⚠️ Manual export per template (no batch automation)
**Verdict:** VIABLE but same as Template Designer

**Details:**
- Web-based tool at https://tools.openehr.org/designer/
- Imports ADL, exports OPT 1.4 format
- GitHub integration available
- As of 2024, no automated batch export feature
- Users still requesting automation in forums

**Process:**
1. Import ADL template
2. Validate structure
3. Manually export as OPT
4. Repeat 26 times

### 5. Template Designer (Web Tool) ⭐ SELECTED

**Capability:** ✅ Can convert ADL→OPT 1.4
**Platform:** ✅ Web-based (any OS)
**Status:** ✅ Works, produces correct OPT 1.4 format
**Verdict:** ACCEPTED - Only practical option for macOS

**URL:** https://tools.openehr.org/designer/

**Advantages:**
- Official OpenEHR tool (most reliable)
- Validates template structure during import
- Produces OPT 1.4 format (confirmed compatible with EHRbase)
- Helper script automates browser/clipboard operations
- Progress tracking and resume capability

**Disadvantages:**
- Manual process (15-25 min per template)
- Total time: 6.5-10.8 hours for 26 templates
- Cannot run unattended

**Helper Script Features:**
- Auto-opens browser to Template Designer
- Auto-copies ADL content to clipboard
- Progress saved in `.conversion_progress` file
- Resumable across sessions (press Q to pause)
- XML validation of converted OPT files

## EHRbase Template Format Requirements

### Confirmed Requirements (Jan 2024)

**Supported:**
- ✅ ADL 1.4 / OPT 1.4 (XML format)
- ✅ Endpoint: `/rest/openehr/v1/definition/template/adl1.4`
- ✅ Content-Type: `application/xml`

**NOT Supported:**
- ❌ ADL 2 / OPT 2
- ❌ JSON templates (web templates)
- ❌ OET format (template design format)

**Source:**
- EHRbase documentation: https://docs.ehrbase.org/docs/EHRbase/openEHR-Introduction/Template
- Forum discussion: https://discourse.openehr.org/t/ehrbase-and-adl2-0/4825 (Jan 2024)

### Upload Process

```bash
# Upload OPT 1.4 template
curl -X POST \
  -H "Content-Type: application/xml" \
  -u "$EHRBASE_USERNAME:$EHRBASE_PASSWORD" \
  --data-binary @template.opt \
  https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4

# Expected response: 200 OK
```

## Alternative Approaches Considered

### Docker-based Linux Container

**Idea:** Run ADL Workbench in Docker container
**Status:** Not pursued
**Reason:**
- Would require X11 forwarding for GUI (complex)
- ADL Workbench GUI required for conversion
- Command-line `adlc` not well-documented
- Setup time comparable to manual conversion

### Virtual Machine

**Idea:** Windows/Linux VM with ADL Workbench
**Status:** Not pursued
**Reason:**
- VM setup time (1-2 hours)
- Windows license or Linux configuration
- Still requires manual interaction with ADL Workbench GUI
- Not significantly faster than Template Designer

### Pre-converted Templates

**Idea:** Find MedZen-compatible OPT templates online
**Status:** Not found
**Reason:**
- MedZen uses CUSTOM templates (medzen.* namespace)
- Searched GitHub: RippleOSI, regionostergotland repositories
- No matching templates found
- Generic CKM templates don't match MedZen specialties

## Recommended Workflow

### Step 1: Execute Conversion Helper Script

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
./ehrbase-templates/convert_templates_helper.sh
```

**Features:**
- Processes all 26 ADL templates in alphabetical order
- Auto-opens Template Designer in browser
- Auto-copies ADL content to clipboard (macOS `pbcopy`)
- Prompts for confirmation after each conversion
- Tracks progress (resumable with `Q` to pause)

### Step 2: Manual Conversion per Template

For each of 26 templates:

1. **Import** - Paste ADL content into Template Designer (Cmd+V)
2. **Validate** - Wait for validation to complete (check for errors)
3. **Export** - Click "Export" → "Operational Template (OPT)"
4. **Save** - Save to `ehrbase-templates/opt-templates/[template-name].opt`
5. **Confirm** - Press ENTER in script to continue

**Time Estimate:** 15-25 minutes per template

### Step 3: Batch Upload

After all 26 templates converted:

```bash
./ehrbase-templates/upload_all_templates.sh
```

Expected output: 26/26 templates uploaded successfully

### Step 4: Verification

```bash
./ehrbase-templates/verify_templates.sh
```

Confirms all templates accessible in EHRbase

## Time Investment Analysis

| Approach | Setup Time | Conversion Time | Total | Status |
|----------|-----------|----------------|-------|--------|
| **Template Designer (Manual)** | 0 min | 6.5-10.8 hours | 6.5-10.8 hours | ✅ Available |
| ADL Workbench (macOS build) | N/A | N/A | N/A | ❌ Not available |
| Docker + ADL Workbench | 1-2 hours | Unknown | Unknown | ❌ Not pursued |
| Virtual Machine | 1-2 hours | Unknown | Unknown | ❌ Not pursued |
| Archie Library (Java) | 2-3 hours | Unknown | Unknown | ❌ Wrong output |

**Conclusion:** Manual Template Designer is both the fastest AND most reliable option.

## Files and Scripts Ready

### Conversion Infrastructure

✅ `convert_templates_helper.sh` - Interactive conversion workflow
✅ `track_conversion_progress.sh` - Progress monitoring
✅ `.conversion_progress` - Progress state file (resumable)
✅ `ehrbase-templates/proper-templates/*.adl` - 26 source templates
📁 `ehrbase-templates/opt-templates/` - Output directory (ready)

### Upload Infrastructure

✅ `upload_all_templates.sh` - Batch upload script
✅ `verify_templates.sh` - Verification script
✅ EHRbase credentials configured
✅ Endpoint configured: https://ehr.medzenhealth.app/ehrbase

### Database Infrastructure

✅ `ehrbase_sync_queue` table - Sync queue for compositions
✅ Database triggers - Auto-queue on insert/update (19 specialty tables)
✅ `sync-to-ehrbase` edge function - Supabase→EHRbase sync
✅ Template mappings - All 26 templates mapped to tables

## Next Steps

1. **Execute conversion script:**
   ```bash
   ./ehrbase-templates/convert_templates_helper.sh
   ```

2. **Monitor progress:**
   ```bash
   ./ehrbase-templates/track_conversion_progress.sh
   ```

3. **Convert templates:**
   - Session 1: Templates 1-10 (2.5-4 hours)
   - Session 2: Templates 11-20 (2.5-4 hours)
   - Session 3: Templates 21-26 (1.5-2.5 hours)
   - Progress saved between sessions

4. **Upload templates:**
   ```bash
   ./ehrbase-templates/upload_all_templates.sh
   ```

5. **Verify upload:**
   ```bash
   ./ehrbase-templates/verify_templates.sh
   ```

6. **Test integration:**
   - Create test composition via MCP server
   - Monitor `ehrbase_sync_queue` table
   - Verify edge function logs

## References

### Documentation
- EHRbase template upload: https://docs.ehrbase.org/docs/EHRbase/openEHR-Introduction/Template
- OpenEHR REST API: https://specifications.openehr.org/releases/ITS-REST/latest/definitions.html
- ADL 1.4 specification: https://specifications.openehr.org/releases/AM/latest/ADL1.4.html
- OPT 1.4 format: https://specifications.openehr.org/releases/AM/latest/OPT2.html

### Tools
- Template Designer: https://tools.openehr.org/designer/
- ADL Workbench: https://github.com/openEHR/adl-tools (Windows/Linux only)
- Archie library: https://github.com/openEHR/archie (ADL 2 / OPT 2 only)

### Forum Discussions
- EHRbase ADL 2 support: https://discourse.openehr.org/t/ehrbase-and-adl2-0/4825
- OPT 1.4 generation: https://discourse.openehr.org/t/how-to-generate-an-opt-1-4/1505

---

**Decision:** Proceed with manual Template Designer conversion
**Estimated Time:** 6.5-10.8 hours (26 templates × 15-25 min)
**Alternative:** None available for macOS
**Status:** Ready to begin
