# OpenEHR Quick Reference Guide

## Official Resources (Your Links)

### 1. OpenEHR Specifications
**URL:** https://specifications.openehr.org/releases/1.0.1/html/architecture/overview/Output/archetyping.html

**What it covers:**
- Two-level modeling architecture
- Archetype constraint principles
- Template composition patterns
- Specialization rules

**When to use:** Understanding theoretical foundations and design principles

---

### 2. Clinical Knowledge Manager (CKM)
**URL:** https://ckm.openehr.org/

**What it covers:**
- Official peer-reviewed archetypes
- Validated templates
- Terminology subsets
- International standards

**When to use:** Finding validated, production-ready archetypes

---

### 3. GitHub CKM Mirror
**URL:** https://github.com/openEHR/CKM-mirror

**What it covers:**
- ADL source files for all archetypes
- ADMIN_ENTRY, EVALUATION, OBSERVATION, etc.
- Downloadable archetype definitions
- Version history and changes

**When to use:**
- Reviewing actual archetype structure
- Downloading ADL files for local use
- Understanding archetype composition

**Direct links:**
- ADMIN_ENTRY archetypes: https://github.com/openEHR/CKM-mirror/tree/master/local/archetypes/entry/admin_entry
- Demographics archetype: https://github.com/openEHR/CKM-mirror/blob/master/local/archetypes/entry/admin_entry/openEHR-EHR-ADMIN_ENTRY.demographics.v0.adl

---

### 4. Example Templates
**URL:** https://github.com/openEHR/adl-archetypes/tree/master/Example/openEHR

**Specific example:** https://github.com/openEHR/adl-archetypes/blob/master/Example/openEHR/single_file_template/templates/openEHR-EHR-COMPOSITION.t_clinical_info_ds_sf.v1.0.0.adls

**What it covers:**
- Real-world template examples
- Proper archetype composition
- Slot usage patterns
- Use_archetype declarations

**When to use:** Learning by example, understanding proper template structure

---

### 5. Freshehr.github.io
**URL:** https://freshehr.github.io/

**What it covers:**
- Tutorials on archetypes and templates
- Links to repository and tools
- Practical implementation guides

**When to use:** Step-by-step learning and practical tutorials

---

### 6. Medblocks
**URL:** Medblocks guides (link not provided, but referenced)

**What it covers:**
- Summary guides on archetypes and templates
- How they're used in openEHR
- Practical implementation patterns

**When to use:** Quick summaries and implementation guidance

---

## Key Archetypes for MedZen

### Official ADMIN_ENTRY Archetypes

| Archetype ID | Status | Relevance | Notes |
|-------------|--------|-----------|-------|
| `openEHR-EHR-ADMIN_ENTRY.demographics.v0` | Development | ✅ High | Container for patient demographics |
| `openEHR-EHR-ADMIN_ENTRY.episode_institution.v0` | Development | ✅ Medium | Healthcare facility episodes |
| `openEHR-EHR-ADMIN_ENTRY.transfer_of_care.v0` | Development | ⚠️ Low | Care transitions |
| `openEHR-EHR-ADMIN_ENTRY.triage.v0` | Development | ⚠️ Low | Administrative triage |

**Note:** All archetypes are in development status (v0.x), indicating they're still evolving but available for use.

---

## Quick Comparison: Standard vs. MedZen Approach

### Standard OpenEHR (Modular)

```
✅ Pros:
- Highly reusable archetypes
- Peer-reviewed standards
- Easy data sharing with other systems
- Advanced querying capabilities

⚠️ Cons:
- More complex to implement
- Requires multiple archetype files
- Steeper learning curve
- Longer development time
```

### MedZen Approach (Simplified Web Templates)

```
✅ Pros:
- Faster development
- Easier to maintain
- Direct tech stack integration
- Single file per template

⚠️ Cons:
- Less modular
- Custom archetype IDs
- Harder to share externally
- Limited CLUSTER reuse
```

---

## Common OpenEHR Patterns

### 1. Container Archetype Pattern

Official demographics archetype uses this:

```
ADMIN_ENTRY[demographics.v0]
  └─ ITEM_TREE
      └─ SLOT[Person/Organisation]
          └─ CLUSTER[person.v1]  ← Actual data here
```

**Benefits:** Modular, reusable CLUSTER archetypes

### 2. Inline Field Pattern (Our Approach)

```
ADMIN_ENTRY[person_data.v0]
  └─ ITEM_TREE
      ├─ ELEMENT[Patient ID]
      ├─ ELEMENT[Full Name]
      └─ ELEMENT[Date of Birth]
```

**Benefits:** Simpler, faster, direct mapping

### 3. Template Composition Pattern

```
COMPOSITION[report.v1]
  ├─ ADMIN_ENTRY[demographics.v0]
  ├─ ADMIN_ENTRY[contact_info.v0]
  └─ ADMIN_ENTRY[insurance.v0]
```

**Benefits:** Organized by functional sections

---

## Key OpenEHR Principles

### 1. Two-Level Modeling
- **Reference Model (RM):** Technical structures (DV_TEXT, COMPOSITION, etc.)
- **Archetype Model:** Domain constraints (patient name, blood pressure, etc.)

### 2. Specialization Rule
- Child archetypes can only **narrow** parent constraints
- Never widen or add new requirements
- Example: Glucose test specializes Lab Result archetype

### 3. Slots Enable Composition
- Archetypes reference other archetypes via slots
- Avoids inline definitions
- Promotes reusability

### 4. Templates are Local
- Sites typically use ~100 core archetypes
- Templates combine and specialize for local needs
- Not all templates need international registration

---

## When to Align More Closely with Standards

Consider refactoring if you need:

1. **Data Exchange** - Share with other openEHR systems
2. **Certification** - Meet regulatory requirements
3. **Advanced Queries** - Complex AQL across modular components
4. **Archetype Reuse** - Share across multiple templates
5. **Community Contribution** - Submit to international CKM

---

## Current MedZen Status

### ✅ What Works
- Valid openEHR compositions created
- Data stored correctly in EHRbase
- Standard COMPOSITION archetype used
- Proper RM data types (DV_TEXT, DV_CODED_TEXT, etc.)
- Web template format followed

### ⚠️ Areas for Future Enhancement
- Could use modular CLUSTER archetypes
- Could reference official demographics.v0
- Could register archetypes in local CKM
- Could convert to full ADL format

### Production Status
**✅ READY** - System is fully functional and meets current requirements

---

## Quick Decision Tree

```
Need to implement new data type?
│
├─ Is there an official archetype?
│  ├─ YES → Consider using it (check CKM/GitHub)
│  └─ NO → Create simplified web template (our approach)
│
└─ Need to share data externally?
   ├─ YES → Use official archetypes
   └─ NO → Simplified approach OK
```

---

## Tools & Validators

### Archetype Design Tools
- **Archetype Designer** - Web-based archetype editor
- **ADL Workbench** - Desktop tool for ADL development
- **Ocean Template Designer** - Visual template creation

### Validation Tools
- **openEHR Validator** - Validates archetype syntax
- **EHRbase Studio** - Web UI for template management
- **AQL Query Console** - Test composition queries

---

## Additional Learning Resources

### Tutorials
1. Start with: freshehr.github.io tutorials
2. Read: OpenEHR specifications (Section 10)
3. Review: GitHub example templates
4. Practice: Create simple template in EHRbase Studio

### Community
- **OpenEHR Discourse:** https://discourse.openehr.org/
- **Slack Workspace:** OpenEHR community chat
- **Implementers List:** Email discussion group

---

## MedZen-Specific Documentation

For MedZen implementation details:
- **Implementation Summary:** `ROLE_BASED_EHR_IMPLEMENTATION_SUMMARY.md`
- **Standards Analysis:** `OPENEHR_STANDARDS_COMPLIANCE.md` ⭐
- **System Architecture:** `EHR_SYSTEM_README.md`
- **Template Files:** `ehrbase-templates/` directory

---

**Quick Reference Version:** 1.0
**Last Updated:** November 2, 2025
**Target Audience:** MedZen developers and OpenEHR beginners
