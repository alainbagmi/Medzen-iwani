# Automated Template Conversion Options

**Goal:** Get 26 MedZen templates converted to OPT format for AWS EHRbase upload

**Current Status:**
- ✅ 26 official CKM templates in OET format (`official-templates/*.oet`)
- ❌ 26 MedZen custom templates in ADL 1.5.1 format (cannot be imported to Template Designer)
- ✅ AWS EHRbase running at https://ehr.medzenhealth.app/ehrbase
- ✅ "medzen-dev" repository in Template Designer with 236 archetypes

---

## Option 1: Java Archie CLI Tool (FASTEST - 5-10 minutes)

### What It Does
Uses the official OpenEHR Archie library (Java) to batch convert OET → OPT

### Setup Time
5-10 minutes

### Conversion Time
< 1 minute for all 26 templates

### Steps

#### 1. Install Java and Download Archie

```bash
# Check if Java installed
java -version

# If not installed:
brew install openjdk@11

# Download Archie CLI (latest release)
cd ~/Downloads
curl -L -O https://github.com/openEHR/archie/releases/latest/download/archie-tools.jar

# Or specific version:
curl -L -O https://github.com/openEHR/archie/releases/download/v3.10.0/archie-tools.jar
```

#### 2. Batch Convert OET → OPT

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates

# Convert all OET files to OPT
for oet in official-templates/*.oet; do
    filename=$(basename "$oet" .oet)
    java -jar ~/Downloads/archie-tools.jar convert \
        --input "$oet" \
        --output "opt-templates/${filename}.opt" \
        --format opt1.4
done

# Verify conversion
ls -l opt-templates/*.opt | wc -l
# Should show: 26
```

#### 3. Upload to EHRbase

```bash
./upload_all_templates.sh
```

### Pros
- ✅ Official OpenEHR tool
- ✅ Batch conversion (all 26 in < 1 minute)
- ✅ Command-line automation
- ✅ Supports OET input format

### Cons
- ⚠️ Requires Java installation
- ⚠️ May not work with ADL 1.5.1 files (only OET)

### Success Criteria
- 26 OPT files generated in `opt-templates/`
- All files valid XML with `xmlns="http://schemas.openehr.org/v1"`

---

## Option 2: Use Existing EHRbase Test Templates (QUICKEST - 2 minutes)

### What It Does
Download ready-made OPT templates from EHRbase GitHub test resources

### Setup Time
2 minutes

### Steps

#### 1. Clone EHRbase Test Repository

```bash
cd /tmp
git clone --depth 1 https://github.com/ehrbase/ehrbase.git
cd ehrbase

# Find test templates
find . -name "*.opt" -o -name "*.xml" | grep -i template | head -20
```

#### 2. Copy Relevant Templates

```bash
# Copy test OPT templates
cp tests/robot/_resources/templates/*.opt \
   /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/opt-templates/

# Verify
ls -l /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/opt-templates/
```

#### 3. Upload to EHRbase

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates
./upload_all_templates.sh
```

### Pros
- ✅ Instant access (no conversion needed)
- ✅ Already tested with EHRbase
- ✅ No tool installation required
- ✅ Production-ready templates

### Cons
- ❌ May not include MedZen-specific templates
- ❌ Generic templates (not customized for Cameroon/African healthcare)
- ❌ Would still need to update database migrations if template IDs don't match

### Use Case
**Best for:** Quick setup to test EHRbase integration, then add MedZen custom templates later

---

## Option 3: Template Designer Bulk Import (SEMI-AUTOMATED - 30-45 minutes)

### What It Does
Import 26 OET files one-by-one to Template Designer, export all as OPT

### Setup Time
30-45 minutes (manual but systematized)

### Steps

#### 1. Prepare Workspace

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates

# Create import manifest
ls official-templates/*.oet > import_list.txt

# Open Template Designer
open "https://tools.openehr.org/designer/"
```

#### 2. Bulk Import Script (Semi-Automated)

Create helper script: `bulk_import_helper.sh`

```bash
#!/bin/bash

COUNTER=1
TOTAL=26

for oet_file in official-templates/*.oet; do
    filename=$(basename "$oet_file")
    opt_name="${filename%.oet}.opt"

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  Template $COUNTER/$TOTAL: $filename"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Steps:"
    echo "1. In Template Designer, click 'Import'"
    echo "2. Upload: $oet_file"
    echo "3. Click 'Export' → 'Operational Template (OPT)'"
    echo "4. Save as: opt-templates/$opt_name"
    echo ""
    read -p "Press ENTER when done..."

    COUNTER=$((COUNTER + 1))
done

echo ""
echo "✅ All 26 templates processed!"
echo ""
echo "Verify:"
echo "  ls -l opt-templates/*.opt | wc -l"
```

#### 3. Run Helper Script

```bash
chmod +x bulk_import_helper.sh
./bulk_import_helper.sh
```

### Pros
- ✅ No external tools required
- ✅ Visual validation (see template structure)
- ✅ Works with OET files (official templates)
- ✅ Browser-based (macOS compatible)

### Cons
- ⏱️ 30-45 minutes total time
- ⚠️ Still manual (click import/export for each)
- ❌ Doesn't work with ADL 1.5.1 files

---

## Comparison Matrix

| Method | Setup | Conversion | Total Time | Automation | Works With |
|--------|-------|------------|------------|------------|------------|
| **Archie CLI** | 5-10 min | < 1 min | **10-15 min** | ✅ Full | OET, ADL 2 |
| **EHRbase Test** | 2 min | 0 min | **2 min** | ✅ Full | OPT (ready) |
| **Template Designer** | 0 min | 30-45 min | **30-45 min** | ⚠️ Semi | OET only |

---

## Recommended Approach

### Fastest Path: Combination Strategy (10-15 minutes total)

**Phase 1: Use EHRbase Test Templates (2 min)**
```bash
# Get working templates immediately
git clone --depth 1 https://github.com/ehrbase/ehrbase.git /tmp/ehrbase
cp /tmp/ehrbase/tests/robot/_resources/templates/*.opt \
   ehrbase-templates/opt-templates/
./upload_all_templates.sh
```

**Phase 2: Convert Official OET → OPT with Archie (10 min)**
```bash
# Install Archie
curl -L -O https://github.com/openEHR/archie/releases/latest/download/archie-tools.jar

# Batch convert
for oet in official-templates/*.oet; do
    java -jar archie-tools.jar convert --input "$oet" --output "opt-templates/$(basename "$oet" .oet).opt"
done

./upload_all_templates.sh
```

**Phase 3: MedZen Custom Templates (Later)**
- Decision needed: Rebuild in Template Designer using medzen-dev archetypes
- OR: Find ADL 1.5.1 → OPT converter (research ongoing)

---

## Decision Factors

### Choose Archie CLI If:
- ✅ You want full automation
- ✅ You have 26 OET files to convert
- ✅ You can install Java quickly
- ✅ You want batch processing

### Choose EHRbase Test If:
- ✅ You need templates RIGHT NOW
- ✅ You want to test EHRbase integration first
- ✅ You're OK with generic templates initially
- ✅ You'll customize later

### Choose Template Designer If:
- ✅ You want visual validation
- ✅ You have time for 30-45 min work
- ✅ You want to learn Template Designer
- ✅ No tool installation desired

---

## Next Steps

1. **Decide which approach** based on your time/requirements
2. **Run the chosen method**
3. **Verify conversion:** `ls opt-templates/*.opt | wc -l` should show 26
4. **Upload to EHRbase:** `./upload_all_templates.sh`
5. **Test integration:** Create a test composition

---

## For MedZen Custom ADL 1.5.1 Templates

**Problem:** Template Designer cannot import ADL 1.5.1 syntax

**Options:**
1. **Convert ADL 1.5.1 → ADL 2** (requires Archie or ADL Workbench)
2. **Rebuild manually** in Template Designer using medzen-dev archetypes (6-8 hours)
3. **Extract template definitions** and create OET files programmatically

**Recommendation:** Start with official OET templates (Option 1 or 2 above), test EHRbase integration, then decide on MedZen custom approach.

---

## Support Resources

- **Archie GitHub:** https://github.com/openEHR/archie
- **EHRbase Docs:** https://docs.ehrbase.org/
- **Template Designer:** https://tools.openehr.org/designer/
- **CKM Repository:** https://ckm.openehr.org/

---

**Status:** Ready to implement - awaiting user decision on approach
