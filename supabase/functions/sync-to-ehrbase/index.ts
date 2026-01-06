import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// EHRbase configuration - these should be set as environment variables
const EHRBASE_URL = Deno.env.get('EHRBASE_URL') || 'http://localhost:8080'
const EHRBASE_USERNAME = Deno.env.get('EHRBASE_USERNAME') || 'ehrbase-user'
const EHRBASE_PASSWORD = Deno.env.get('EHRBASE_PASSWORD') || 'ehrbase-password'
const MAX_RETRY_COUNT = 5

// Template ID mapping: MedZen custom IDs → Generic EHRbase IDs
// This is a temporary workaround until MedZen custom templates are converted and uploaded
// Updated 2025-11-10: Mapped to 73 available templates in EHRbase
const TEMPLATE_ID_MAP: Record<string, string> = {
  // Core Templates - Medical Data
  'medzen.vital_signs_encounter.v1': 'IDCR - Vital Signs Encounter.v1',
  'medzen.laboratory_result_report.v1': 'IDCR - Laboratory Test Report.v0',
  'medzen.laboratory_test_request.v1': 'IDCR - Laboratory Order.v0',
  'medzen.medication_list.v1': 'IDCR - Medication Statement List.v0',
  'medzen.medication_dispensing_record.v1': 'IDCR Medication List.v0',
  'medzen.radiology_report.v1': 'IDCR - Laboratory Test Report.v0', // Using lab report as generic diagnostic report
  'medzen.pathology_report.v1': 'IDCR - Laboratory Test Report.v0',

  // User Profile Templates - Use Clinical Notes (flexible structure)
  'medzen.patient.demographics.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.patient_demographics.v1': 'RIPPLE - Clinical Notes.v1', // Alternate naming (underscore)
  'medzen.provider.profile.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.facility.profile.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.admin.profile.v1': 'RIPPLE - Clinical Notes.v1',

  // Specialty Encounter Templates
  'medzen.clinical_consultation.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.admission_discharge_summary.v1': 'IDCR - Transfer of Care Summary TEST.v1',
  'medzen.emergency_medicine_encounter.v1': 'NCHCD - Clinical notes.v0',
  'medzen.antenatal_care_encounter.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.cardiology_encounter.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.dermatology_consultation.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.endocrinology_management.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.gastroenterology_procedures.v1': 'IDCR Procedures List.v0',
  'medzen.infectious_disease_encounter.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.nephrology_encounter.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.neurology_examination.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.oncology_treatment_plan.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.palliative_care_plan.v1': 'IDCR - End of Life Patient Preferences.v0',
  'medzen.psychiatric_assessment.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.pulmonology_encounter.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.surgical_procedure_report.v1': 'IDCR - Procedures List.v1',
  'medzen.physiotherapy_session.v1': 'RIPPLE - Clinical Notes.v1',

  // Pharmacy & Stock
  'medzen.pharmacy_stock_management.v1': 'IDCR Medication List.v0',

  // Clinical Notes - AI Generated from Video Consultations
  'medzen.clinical.notes.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.clinical_notes.v1': 'RIPPLE - Clinical Notes.v1',
}

// Helper function to get mapped template ID
function getMappedTemplateId(templateId: string): string {
  const mappedId = TEMPLATE_ID_MAP[templateId] || templateId
  if (mappedId !== templateId) {
    console.log(`Template ID mapped: ${templateId} → ${mappedId}`)
  }
  return mappedId
}

interface SyncQueueItem {
  id: string
  table_name: string
  record_id: string
  template_id: string
  sync_type: string
  sync_status: string
  retry_count: number
  data_snapshot: any
  ehrbase_composition_id?: string
  user_role?: string
}

interface EHRStatusUpdateData {
  user_id: string
  firebase_uid: string
  ehr_id: string
  first_name?: string
  last_name?: string
  middle_name?: string
  full_name?: string
  date_of_birth?: string
  gender?: string
  email?: string
  phone_number?: string
  country?: string
}

/**
 * Creates an OpenEHR composition for medical records (vital signs, lab results, etc.)
 */
async function createComposition(
  ehrId: string,
  templateId: string,
  data: any
): Promise<{ success: boolean; compositionId?: string; error?: string }> {
  try {
    // Apply template ID mapping (medzen.* → generic template IDs)
    const mappedTemplateId = getMappedTemplateId(templateId)

    // Build composition based on template type (use original template ID for pattern matching)
    const composition = buildCompositionFromTemplate(mappedTemplateId, data, templateId)

    const response = await fetch(
      `${EHRBASE_URL}/rest/openehr/v1/ehr/${ehrId}/composition`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${btoa(`${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}`)}`,
          'Accept': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(composition)
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('EHRbase composition creation failed:', errorText)
      return {
        success: false,
        error: `HTTP ${response.status}: ${errorText}`
      }
    }

    const result = await response.json()
    const compositionId = result.uid?.value || result.composition_uid

    return {
      success: true,
      compositionId
    }
  } catch (error) {
    console.error('Error creating composition:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

/**
 * Updates EHR_STATUS with demographic information
 */
async function updateEHRStatus(
  ehrId: string,
  userData: EHRStatusUpdateData
): Promise<{ success: boolean; error?: string }> {
  try {
    // First, get the current EHR_STATUS
    const getResponse = await fetch(
      `${EHRBASE_URL}/rest/openehr/v1/ehr/${ehrId}/ehr_status`,
      {
        headers: {
          'Authorization': `Basic ${btoa(`${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}`)}`,
          'Accept': 'application/json'
        }
      }
    )

    if (!getResponse.ok) {
      const errorText = await getResponse.text()
      return {
        success: false,
        error: `Failed to get current EHR_STATUS: HTTP ${getResponse.status}`
      }
    }

    const currentStatus = await getResponse.json()

    // Build updated EHR_STATUS with demographic details
    const ehrStatus = {
      ...currentStatus,
      subject: {
        external_ref: {
          id: {
            _type: 'GENERIC_ID',
            value: userData.firebase_uid,
            scheme: 'firebase_auth'
          },
          namespace: 'medzen',
          type: 'PERSON'
        }
      },
      other_details: {
        _type: 'ITEM_TREE',
        archetype_node_id: 'at0001',
        name: {
          _type: 'DV_TEXT',
          value: 'Tree'
        },
        items: buildDemographicItems(userData)
      },
      is_modifiable: true,
      is_queryable: true
    }

    // Update EHR_STATUS
    const putResponse = await fetch(
      `${EHRBASE_URL}/rest/openehr/v1/ehr/${ehrId}/ehr_status`,
      {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${btoa(`${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}`)}`,
          'Accept': 'application/json',
          'If-Match': currentStatus.uid?.value || currentStatus._uid
        },
        body: JSON.stringify(ehrStatus)
      }
    )

    if (!putResponse.ok) {
      const errorText = await putResponse.text()
      console.error('EHRbase EHR_STATUS update failed:', errorText)
      return {
        success: false,
        error: `HTTP ${putResponse.status}: ${errorText}`
      }
    }

    return { success: true }
  } catch (error) {
    console.error('Error updating EHR_STATUS:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

/**
 * Builds demographic items for other_details in EHR_STATUS
 */
function buildDemographicItems(userData: EHRStatusUpdateData): any[] {
  const items: any[] = []

  if (userData.first_name || userData.last_name) {
    const fullName = userData.full_name ||
      `${userData.first_name || ''} ${userData.middle_name || ''} ${userData.last_name || ''}`.trim()

    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0002',
      name: { _type: 'DV_TEXT', value: 'Full Name' },
      value: { _type: 'DV_TEXT', value: fullName }
    })
  }

  if (userData.date_of_birth) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0003',
      name: { _type: 'DV_TEXT', value: 'Date of Birth' },
      value: { _type: 'DV_DATE', value: userData.date_of_birth }
    })
  }

  if (userData.gender) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0004',
      name: { _type: 'DV_TEXT', value: 'Gender' },
      value: { _type: 'DV_TEXT', value: userData.gender }
    })
  }

  if (userData.email) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0005',
      name: { _type: 'DV_TEXT', value: 'Email' },
      value: { _type: 'DV_TEXT', value: userData.email }
    })
  }

  if (userData.phone_number) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0006',
      name: { _type: 'DV_TEXT', value: 'Phone Number' },
      value: { _type: 'DV_TEXT', value: userData.phone_number }
    })
  }

  if (userData.country) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0007',
      name: { _type: 'DV_TEXT', value: 'Country' },
      value: { _type: 'DV_TEXT', value: userData.country }
    })
  }

  if (userData.user_role) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0008',
      name: { _type: 'DV_TEXT', value: 'User Role' },
      value: { _type: 'DV_TEXT', value: userData.user_role }
    })
  }

  return items
}

/**
 * Creates a comprehensive demographics composition in EHRbase
 * Called when user profile is created or updated
 */
async function createDemographicsComposition(ehrId: string, userData: any): Promise<{ success: boolean; compositionId?: string; error?: string }> {
  try {
    const now = new Date().toISOString()
    const content: any[] = []

    // Get mapped template ID for demographics
    const medzenTemplateId = 'medzen.patient_demographics.v1'
    const mappedTemplateId = getMappedTemplateId(medzenTemplateId)

    // 1. Personal Demographics Section
    const personalItems: any[] = []

    if (userData.first_name || userData.last_name) {
      const fullName = `${userData.first_name || ''} ${userData.middle_name || ''} ${userData.last_name || ''}`.trim()
      if (fullName) {
        personalItems.push({
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Full Name' },
          value: { _type: 'DV_TEXT', value: fullName }
        })
      }
    }

    if (userData.date_of_birth) {
      personalItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0003',
        name: { _type: 'DV_TEXT', value: 'Date of Birth' },
        value: { _type: 'DV_DATE', value: userData.date_of_birth }
      })
    }

    if (userData.gender) {
      personalItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0004',
        name: { _type: 'DV_TEXT', value: 'Gender' },
        value: { _type: 'DV_TEXT', value: userData.gender }
      })
    }


    if (personalItems.length > 0) {
      content.push({
        _type: 'ADMIN_ENTRY',
        archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.person_data.v0',
        name: { _type: 'DV_TEXT', value: 'Personal Demographics' },
        language: { _type: 'CODE_PHRASE', terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' }, code_string: 'en' },
        encoding: { _type: 'CODE_PHRASE', terminology_id: { _type: 'TERMINOLOGY_ID', value: 'IANA_character-sets' }, code_string: 'UTF-8' },
        subject: { _type: 'PARTY_SELF' },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0001',
          items: personalItems
        }
      })
    }

    // 2. Contact Information Section
    const contactItems: any[] = []

    if (userData.email) {
      contactItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Email' },
        value: { _type: 'DV_TEXT', value: userData.email }
      })
    }

    if (userData.phone_number) {
      contactItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0003',
        name: { _type: 'DV_TEXT', value: 'Phone Number' },
        value: { _type: 'DV_TEXT', value: userData.phone_number }
      })
    }

    if (userData.secondary_phone) {
      contactItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0004',
        name: { _type: 'DV_TEXT', value: 'Secondary Phone' },
        value: { _type: 'DV_TEXT', value: userData.secondary_phone }
      })
    }

    if (userData.country) {
      contactItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0005',
        name: { _type: 'DV_TEXT', value: 'Country' },
        value: { _type: 'DV_TEXT', value: userData.country }
      })
    }

    if (contactItems.length > 0) {
      content.push({
        _type: 'ADMIN_ENTRY',
        archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.contact_info.v0',
        name: { _type: 'DV_TEXT', value: 'Contact Information' },
        language: { _type: 'CODE_PHRASE', terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' }, code_string: 'en' },
        encoding: { _type: 'CODE_PHRASE', terminology_id: { _type: 'TERMINOLOGY_ID', value: 'IANA_character-sets' }, code_string: 'UTF-8' },
        subject: { _type: 'PARTY_SELF' },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0001',
          items: contactItems
        }
      })
    }

    // 3. Demographics Details Section
    const demographicsItems: any[] = []

    if (userData.preferred_language) {
      demographicsItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Preferred Language' },
        value: { _type: 'DV_TEXT', value: userData.preferred_language }
      })
    }

    if (userData.timezone) {
      demographicsItems.push({
        _type: 'ELEMENT',
        archetype_node_id: 'at0003',
        name: { _type: 'DV_TEXT', value: 'Timezone' },
        value: { _type: 'DV_TEXT', value: userData.timezone }
      })
    }

    if (demographicsItems.length > 0) {
      content.push({
        _type: 'ADMIN_ENTRY',
        archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.demographics.v0',
        name: { _type: 'DV_TEXT', value: 'Demographics Details' },
        language: { _type: 'CODE_PHRASE', terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' }, code_string: 'en' },
        encoding: { _type: 'CODE_PHRASE', terminology_id: { _type: 'TERMINOLOGY_ID', value: 'IANA_character-sets' }, code_string: 'UTF-8' },
        subject: { _type: 'PARTY_SELF' },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0001',
          items: demographicsItems
        }
      })
    }

    // Build the complete composition
    const composition = {
      _type: 'COMPOSITION',
      name: {
        _type: 'DV_TEXT',
        value: 'Patient Demographics'
      },
      archetype_node_id: 'openEHR-EHR-COMPOSITION.admin_entry.v0',
      archetype_details: {
        _type: 'ARCHETYPED',
        archetype_id: {
          _type: 'ARCHETYPE_ID',
          value: 'openEHR-EHR-COMPOSITION.admin_entry.v0'
        },
        template_id: {
          _type: 'TEMPLATE_ID',
          value: mappedTemplateId
        },
        rm_version: '1.0.4'
      },
      language: {
        _type: 'CODE_PHRASE',
        terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' },
        code_string: 'en'
      },
      territory: {
        _type: 'CODE_PHRASE',
        terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_3166-1' },
        code_string: 'CM'
      },
      category: {
        _type: 'DV_CODED_TEXT',
        value: 'event',
        defining_code: {
          _type: 'CODE_PHRASE',
          terminology_id: { _type: 'TERMINOLOGY_ID', value: 'openehr' },
          code_string: '433'
        }
      },
      composer: {
        _type: 'PARTY_IDENTIFIED',
        name: 'MedZen System'
      },
      context: {
        _type: 'EVENT_CONTEXT',
        start_time: {
          _type: 'DV_DATE_TIME',
          value: now
        },
        setting: {
          _type: 'DV_CODED_TEXT',
          value: 'other care',
          defining_code: {
            _type: 'CODE_PHRASE',
            terminology_id: { _type: 'TERMINOLOGY_ID', value: 'openehr' },
            code_string: '238'
          }
        }
      },
      content
    }

    // POST to EHRbase
    const response = await fetch(
      `${EHRBASE_URL}/rest/openehr/v1/ehr/${ehrId}/composition`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${btoa(`${EHRBASE_USERNAME}:${EHRBASE_PASSWORD}`)}`,
          'Accept': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(composition)
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Failed to create demographics composition:', response.status, errorText)
      return {
        success: false,
        error: `HTTP ${response.status}: ${errorText}`
      }
    }

    const result = await response.json()
    const compositionId = result?.uid?.value || result?.compositionUid || 'unknown'

    console.log('✅ Demographics composition created:', compositionId)
    return {
      success: true,
      compositionId
    }

  } catch (error) {
    console.error('Error creating demographics composition:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

/**
 * Builds OpenEHR composition from template and data
 * @param templateId - The mapped (generic) template ID to use in the composition
 * @param data - The data to include in the composition
 * @param originalTemplateId - The original MedZen template ID for pattern matching (optional)
 */
function buildCompositionFromTemplate(templateId: string, data: any, originalTemplateId?: string): any {
  const now = new Date().toISOString()

  // Use original template ID for pattern matching if provided, otherwise use mapped ID
  const patternMatchId = originalTemplateId || templateId

  // Determine archetype based on template type
  const isProfile = patternMatchId.includes('patient.demographics') ||
                    patternMatchId.includes('provider.profile') ||
                    patternMatchId.includes('facility.profile') ||
                    patternMatchId.includes('admin.profile')

  // Base composition structure
  const composition: any = {
    _type: 'COMPOSITION',
    name: {
      _type: 'DV_TEXT',
      value: getCompositionName(templateId)
    },
    archetype_details: {
      archetype_id: {
        value: isProfile ? 'openEHR-EHR-COMPOSITION.report.v1' : 'openEHR-EHR-COMPOSITION.encounter.v1'
      },
      template_id: {
        value: templateId
      },
      rm_version: '1.0.4'
    },
    archetype_node_id: isProfile ? 'openEHR-EHR-COMPOSITION.report.v1' : 'openEHR-EHR-COMPOSITION.encounter.v1',
    language: {
      _type: 'CODE_PHRASE',
      terminology_id: {
        _type: 'TERMINOLOGY_ID',
        value: 'ISO_639-1'
      },
      code_string: 'en'
    },
    territory: {
      _type: 'CODE_PHRASE',
      terminology_id: {
        _type: 'TERMINOLOGY_ID',
        value: 'ISO_3166-1'
      },
      code_string: 'CM' // Cameroon
    },
    category: {
      _type: 'DV_CODED_TEXT',
      value: 'event',
      defining_code: {
        _type: 'CODE_PHRASE',
        terminology_id: {
          _type: 'TERMINOLOGY_ID',
          value: 'openehr'
        },
        code_string: '433'
      }
    },
    composer: {
      _type: 'PARTY_IDENTIFIED',
      name: 'MedZen System'
    },
    context: {
      _type: 'EVENT_CONTEXT',
      start_time: {
        _type: 'DV_DATE_TIME',
        value: now
      },
      setting: {
        _type: 'DV_CODED_TEXT',
        value: 'other care',
        defining_code: {
          _type: 'CODE_PHRASE',
          terminology_id: {
            _type: 'TERMINOLOGY_ID',
            value: 'openehr'
          },
          code_string: '238'
        }
      }
    },
    content: []
  }

  // Add content based on template type (use patternMatchId for matching)
  if (patternMatchId.includes('vital_signs')) {
    composition.content.push(buildVitalSignsContent(data))
  } else if (patternMatchId.includes('lab_results')) {
    composition.content.push(buildLabResultsContent(data))
  } else if (patternMatchId.includes('prescriptions')) {
    composition.content.push(buildPrescriptionContent(data))
  } else if (patternMatchId.includes('patient.demographics') || patternMatchId.includes('patient_demographics')) {
    // Use generic builder for RIPPLE template, custom builder for MedZen templates
    if (templateId === 'RIPPLE - Clinical Notes.v1') {
      composition.content.push(...buildGenericDemographicsContent(data))
    } else {
      composition.content.push(...buildPatientDemographicsContent(data))
    }
  } else if (patternMatchId.includes('provider.profile') || patternMatchId.includes('provider_profile')) {
    // Use generic builder for RIPPLE template
    if (templateId === 'RIPPLE - Clinical Notes.v1') {
      composition.content.push(...buildGenericDemographicsContent(data))
    } else {
      composition.content.push(...buildProviderProfileContent(data))
    }
  } else if (patternMatchId.includes('facility.profile') || patternMatchId.includes('facility_profile')) {
    // Use generic builder for RIPPLE template
    if (templateId === 'RIPPLE - Clinical Notes.v1') {
      composition.content.push(...buildGenericDemographicsContent(data))
    } else {
      composition.content.push(...buildFacilityProfileContent(data))
    }
  } else if (patternMatchId.includes('admin.profile') || patternMatchId.includes('admin_profile')) {
    // Use generic builder for RIPPLE template
    if (templateId === 'RIPPLE - Clinical Notes.v1') {
      composition.content.push(...buildGenericDemographicsContent(data))
    } else {
      composition.content.push(...buildAdminProfileContent(data))
    }
  } else if (patternMatchId.includes('antenatal_care_encounter')) {
    composition.content.push(buildAntenatalVisitContent(data))
  } else if (patternMatchId.includes('surgical_procedure')) {
    composition.content.push(buildSurgicalProcedureContent(data))
  } else if (patternMatchId.includes('admission_discharge')) {
    composition.content.push(buildAdmissionDischargeContent(data))
  } else if (patternMatchId.includes('medication_dispensing')) {
    composition.content.push(buildMedicationDispensingContent(data))
  } else if (patternMatchId.includes('pharmacy_stock_management')) {
    composition.content.push(buildPharmacyStockContent(data))
  } else if (patternMatchId.includes('clinical_consultation')) {
    composition.content.push(buildClinicalConsultationContent(data))
  } else if (patternMatchId.includes('oncology_treatment_plan')) {
    composition.content.push(buildOncologyTreatmentContent(data))
  } else if (patternMatchId.includes('infectious_disease_encounter')) {
    composition.content.push(buildInfectiousDiseaseContent(data))
  } else if (patternMatchId.includes('cardiology_encounter')) {
    composition.content.push(buildCardiologyVisitContent(data))
  } else if (patternMatchId.includes('emergency_medicine_encounter')) {
    composition.content.push(buildEmergencyVisitContent(data))
  } else if (patternMatchId.includes('nephrology_encounter')) {
    composition.content.push(buildNephrologyVisitContent(data))
  } else if (patternMatchId.includes('gastroenterology_procedures')) {
    composition.content.push(buildGastroenterologyProcedureContent(data))
  } else if (patternMatchId.includes('endocrinology_management')) {
    composition.content.push(buildEndocrinologyVisitContent(data))
  } else if (patternMatchId.includes('pulmonology_encounter')) {
    composition.content.push(buildPulmonologyVisitContent(data))
  } else if (patternMatchId.includes('psychiatric_assessment')) {
    composition.content.push(buildPsychiatricAssessmentContent(data))
  } else if (patternMatchId.includes('neurology_examination')) {
    composition.content.push(buildNeurologyExamContent(data))
  } else if (patternMatchId.includes('radiology_report')) {
    composition.content.push(buildRadiologyReportContent(data))
  } else if (patternMatchId.includes('pathology_report')) {
    composition.content.push(buildPathologyReportContent(data))
  } else if (patternMatchId.includes('physiotherapy_session')) {
    composition.content.push(buildPhysiotherapySessionContent(data))
  } else if (patternMatchId.includes('clinical.notes') || patternMatchId.includes('clinical_notes')) {
    // AI-generated clinical notes from video consultations
    composition.content.push(...buildClinicalNotesContent(data))
  }

  return composition
}

function getCompositionName(patternMatchId: string): string {
  // Check if using RIPPLE - Clinical Notes template (generic template requires specific name)
  if (patternMatchId === 'RIPPLE - Clinical Notes.v1') return 'Clinical Notes'

  if (patternMatchId.includes('vital_signs')) return 'Vital Signs'
  if (patternMatchId.includes('lab_results')) return 'Laboratory Results'
  if (patternMatchId.includes('prescriptions')) return 'Prescription'
  if (patternMatchId.includes('patient.demographics') || patternMatchId.includes('patient_demographics')) return 'Clinical Notes'
  if (patternMatchId.includes('provider.profile')) return 'Clinical Notes'
  if (patternMatchId.includes('facility.profile')) return 'Clinical Notes'
  if (patternMatchId.includes('admin.profile')) return 'Clinical Notes'
  return 'Medical Record'
}

// ========================================
// ROLE-SPECIFIC COMPOSITION BUILDERS
// ========================================

/**
 * Builds patient demographics composition content
 */
/**
 * Builds demographics content for generic templates (RIPPLE - Clinical Notes)
 * Uses EVALUATION entries with standard structures
 */
function buildGenericDemographicsContent(data: any): any[] {
  const profileData = data.profile_data || data
  const content: any[] = []

  // Build narrative text summary
  const demographicsText = [
    `Patient: ${profileData.full_name || 'Unknown'}`,
    profileData.date_of_birth ? `Date of Birth: ${profileData.date_of_birth}` : null,
    profileData.gender ? `Gender: ${profileData.gender}` : null,
    profileData.email ? `Email: ${profileData.email}` : null,
    profileData.phone_number ? `Phone: ${profileData.phone_number}` : null,
    profileData.country ? `Country: ${profileData.country}` : null,
    profileData.preferred_language ? `Language: ${profileData.preferred_language}` : null,
    profileData.timezone ? `Timezone: ${profileData.timezone}` : null
  ].filter(Boolean).join('\n')

  // Create single EVALUATION entry with demographics as narrative
  content.push({
    _type: 'EVALUATION',
    archetype_node_id: 'openEHR-EHR-EVALUATION.clinical_synopsis.v1',
    name: { _type: 'DV_TEXT', value: 'Patient Demographics' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Synopsis' },
          value: { _type: 'DV_TEXT', value: demographicsText }
        }
      ]
    },
    language: {
      _type: 'CODE_PHRASE',
      terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' },
      code_string: 'en'
    },
    encoding: {
      _type: 'CODE_PHRASE',
      terminology_id: { _type: 'TERMINOLOGY_ID', value: 'IANA_character-sets' },
      code_string: 'UTF-8'
    }
  })

  return content
}

/**
 * Builds clinical notes content from AI-generated SOAP notes
 * Used for syncing telemedicine consultation notes to EHRbase
 */
function buildClinicalNotesContent(data: any): any[] {
  const content: any[] = []

  // Build SOAP note sections as narrative text
  const soapSections: string[] = []

  // Chief Complaint
  if (data.chief_complaint) {
    soapSections.push(`CHIEF COMPLAINT:\n${data.chief_complaint}`)
  }

  // History of Present Illness
  if (data.history_of_present_illness) {
    soapSections.push(`\nHISTORY OF PRESENT ILLNESS:\n${data.history_of_present_illness}`)
  }

  // Subjective
  if (data.subjective) {
    soapSections.push(`\nSUBJECTIVE:\n${data.subjective}`)
  }

  // Objective
  if (data.objective) {
    soapSections.push(`\nOBJECTIVE:\n${data.objective}`)
  }

  // Assessment
  if (data.assessment) {
    soapSections.push(`\nASSESSMENT:\n${data.assessment}`)
  }

  // Plan
  if (data.plan) {
    soapSections.push(`\nPLAN:\n${data.plan}`)
  }

  // ICD-10 Codes
  if (data.icd10_codes && Array.isArray(data.icd10_codes) && data.icd10_codes.length > 0) {
    const icd10Text = data.icd10_codes
      .map((code: any) => `  - ${code.code}: ${code.description} (confidence: ${(code.confidence * 100).toFixed(0)}%)`)
      .join('\n')
    soapSections.push(`\nICD-10 DIAGNOSIS CODES:\n${icd10Text}`)
  }

  // CPT Codes
  if (data.cpt_codes && Array.isArray(data.cpt_codes) && data.cpt_codes.length > 0) {
    const cptText = data.cpt_codes
      .map((code: any) => `  - ${code.code}: ${code.description} (confidence: ${(code.confidence * 100).toFixed(0)}%)`)
      .join('\n')
    soapSections.push(`\nCPT PROCEDURE CODES:\n${cptText}`)
  }

  // Medical Entities
  if (data.medical_entities && Array.isArray(data.medical_entities) && data.medical_entities.length > 0) {
    const entitiesText = data.medical_entities
      .map((entity: any) => `  - [${entity.type}] ${entity.text}${entity.icd10 ? ` (${entity.icd10})` : ''} - ${(entity.confidence * 100).toFixed(0)}% confidence`)
      .join('\n')
    soapSections.push(`\nEXTRACTED MEDICAL ENTITIES:\n${entitiesText}`)
  }

  // Metadata
  const metadataText = [
    `Note Type: ${data.note_type || 'SOAP'}`,
    `Status: ${data.status || 'draft'}`,
    data.ai_generated ? 'AI Generated: Yes' : null,
    data.ai_model ? `AI Model: ${data.ai_model}` : null,
    data.ai_confidence_score ? `AI Confidence: ${(data.ai_confidence_score * 100).toFixed(0)}%` : null,
    data.transcript_language ? `Transcript Language: ${data.transcript_language}` : null,
    data.provider_signature ? `Signed By: ${data.provider_signature}` : null,
    data.signed_at ? `Signed At: ${data.signed_at}` : null,
  ].filter(Boolean).join('\n')
  soapSections.push(`\nMETADATA:\n${metadataText}`)

  const fullNoteText = soapSections.join('\n')

  // Create EVALUATION entry with clinical synopsis
  content.push({
    _type: 'EVALUATION',
    archetype_node_id: 'openEHR-EHR-EVALUATION.clinical_synopsis.v1',
    name: { _type: 'DV_TEXT', value: 'Clinical Note' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Synopsis' },
          value: { _type: 'DV_TEXT', value: fullNoteText }
        }
      ]
    },
    language: {
      _type: 'CODE_PHRASE',
      terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' },
      code_string: 'en'
    },
    encoding: {
      _type: 'CODE_PHRASE',
      terminology_id: { _type: 'TERMINOLOGY_ID', value: 'IANA_character-sets' },
      code_string: 'UTF-8'
    }
  })

  // Add problem/diagnosis entries for each ICD-10 code
  if (data.icd10_codes && Array.isArray(data.icd10_codes)) {
    data.icd10_codes.forEach((code: any, index: number) => {
      content.push({
        _type: 'EVALUATION',
        archetype_node_id: 'openEHR-EHR-EVALUATION.problem_diagnosis.v1',
        name: { _type: 'DV_TEXT', value: `Diagnosis ${index + 1}` },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0001',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0002',
              name: { _type: 'DV_TEXT', value: 'Problem/Diagnosis name' },
              value: {
                _type: 'DV_CODED_TEXT',
                value: code.description,
                defining_code: {
                  _type: 'CODE_PHRASE',
                  terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ICD-10' },
                  code_string: code.code
                }
              }
            }
          ]
        },
        language: {
          _type: 'CODE_PHRASE',
          terminology_id: { _type: 'TERMINOLOGY_ID', value: 'ISO_639-1' },
          code_string: 'en'
        },
        encoding: {
          _type: 'CODE_PHRASE',
          terminology_id: { _type: 'TERMINOLOGY_ID', value: 'IANA_character-sets' },
          code_string: 'UTF-8'
        }
      })
    })
  }

  return content
}

/**
 * Builds demographics content for custom MedZen templates
 * Uses ADMIN_ENTRY structures with custom archetypes
 */
function buildPatientDemographicsContent(data: any): any[] {
  const profileData = data.profile_data || data
  const content: any[] = []

  // Patient Identification
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.person_data.v0',
    name: { _type: 'DV_TEXT', value: 'Patient Identification' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Patient ID' },
          value: { _type: 'DV_IDENTIFIER', id: profileData.user_id || data.user_id || 'unknown' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Full Name' },
          value: { _type: 'DV_TEXT', value: profileData.full_name || 'Unknown' }
        },
        ...(profileData.date_of_birth ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Date of Birth' },
          value: { _type: 'DV_DATE', value: profileData.date_of_birth }
        }] : []),
        ...(profileData.gender ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Gender' },
          value: { _type: 'DV_TEXT', value: profileData.gender }
        }] : [])
      ]
    }
  })

  // Contact Information
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.contact_info.v0',
    name: { _type: 'DV_TEXT', value: 'Contact Information' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Email' },
          value: { _type: 'DV_TEXT', value: profileData.email || '' }
        },
        ...(profileData.phone_number ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Primary Phone' },
          value: { _type: 'DV_TEXT', value: profileData.phone_number }
        }] : []),
        ...(profileData.country ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Country' },
          value: { _type: 'DV_TEXT', value: profileData.country }
        }] : [])
      ]
    }
  })

  return content
}

/**
 * Builds provider profile composition content
 */
function buildProviderProfileContent(data: any): any[] {
  const profileData = data.profile_data || data
  const content: any[] = []

  // Provider Demographics
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.person_data.v0',
    name: { _type: 'DV_TEXT', value: 'Provider Demographics' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Provider ID' },
          value: { _type: 'DV_IDENTIFIER', id: profileData.user_id || data.user_id || 'unknown' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Full Name' },
          value: { _type: 'DV_TEXT', value: profileData.full_name || profileData.display_name || 'Unknown' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Contact Email' },
          value: { _type: 'DV_TEXT', value: profileData.email || '' }
        }
      ]
    }
  })

  // Professional Credentials
  if (profileData.license_number || profileData.credentials) {
    content.push({
      _type: 'ADMIN_ENTRY',
      archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.professional_credentials.v0',
      name: { _type: 'DV_TEXT', value: 'Professional Credentials' },
      data: {
        _type: 'ITEM_TREE',
        archetype_node_id: 'at0001',
        items: [
          ...(profileData.license_number ? [{
            _type: 'ELEMENT',
            archetype_node_id: 'at0002',
            name: { _type: 'DV_TEXT', value: 'Medical License Number' },
            value: { _type: 'DV_IDENTIFIER', id: profileData.license_number }
          }] : []),
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0003',
            name: { _type: 'DV_TEXT', value: 'License Verification Status' },
            value: { _type: 'DV_TEXT', value: profileData.verification_status || 'pending' }
          }
        ]
      }
    })
  }

  // Medical Specialties
  if (profileData.specialty || profileData.specialties) {
    content.push({
      _type: 'ADMIN_ENTRY',
      archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.specialty_information.v0',
      name: { _type: 'DV_TEXT', value: 'Medical Specialties' },
      data: {
        _type: 'ITEM_TREE',
        archetype_node_id: 'at0001',
        items: [
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0002',
            name: { _type: 'DV_TEXT', value: 'Primary Specialty' },
            value: { _type: 'DV_TEXT', value: profileData.specialty || profileData.primary_specialty || 'General Practice' }
          },
          ...(profileData.years_experience ? [{
            _type: 'ELEMENT',
            archetype_node_id: 'at0003',
            name: { _type: 'DV_TEXT', value: 'Years of Experience' },
            value: { _type: 'DV_COUNT', magnitude: parseInt(profileData.years_experience) || 0 }
          }] : [])
        ]
      }
    })
  }

  // Verification Status
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.verification_status.v0',
    name: { _type: 'DV_TEXT', value: 'Verification Status' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Background Check Status' },
          value: { _type: 'DV_TEXT', value: profileData.background_check || 'pending' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Account Approval Status' },
          value: { _type: 'DV_TEXT', value: profileData.approval_status || 'pending_review' }
        }
      ]
    }
  })

  return content
}

/**
 * Builds facility profile composition content
 */
function buildFacilityProfileContent(data: any): any[] {
  const profileData = data.profile_data || data
  const content: any[] = []

  // Facility Identification
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.facility_info.v0',
    name: { _type: 'DV_TEXT', value: 'Facility Identification' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Facility ID' },
          value: { _type: 'DV_IDENTIFIER', id: profileData.user_id || data.user_id || 'unknown' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Facility Name' },
          value: { _type: 'DV_TEXT', value: profileData.facility_name || profileData.full_name || 'Unknown Facility' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Facility Type' },
          value: { _type: 'DV_TEXT', value: profileData.facility_type || 'clinic' }
        }
      ]
    }
  })

  // Facility Location
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.location.v0',
    name: { _type: 'DV_TEXT', value: 'Facility Location' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        ...(profileData.city ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'City' },
          value: { _type: 'DV_TEXT', value: profileData.city }
        }] : []),
        ...(profileData.region ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Region/State' },
          value: { _type: 'DV_TEXT', value: profileData.region }
        }] : []),
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Country' },
          value: { _type: 'DV_TEXT', value: profileData.country || 'Cameroon' }
        }
      ]
    }
  })

  // Contact Information
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.contact.v0',
    name: { _type: 'DV_TEXT', value: 'Contact Information' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Email' },
          value: { _type: 'DV_TEXT', value: profileData.email || '' }
        },
        ...(profileData.phone_number ? [{
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Primary Phone' },
          value: { _type: 'DV_TEXT', value: profileData.phone_number }
        }] : [])
      ]
    }
  })

  // Verification Status
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.verification.v0',
    name: { _type: 'DV_TEXT', value: 'Verification Status' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Accreditation Status' },
          value: { _type: 'DV_TEXT', value: profileData.accreditation_status || 'pending' }
        }
      ]
    }
  })

  return content
}

/**
 * Builds admin profile composition content
 */
function buildAdminProfileContent(data: any): any[] {
  const profileData = data.profile_data || data
  const content: any[] = []

  // Administrator Identification
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.admin_info.v0',
    name: { _type: 'DV_TEXT', value: 'Administrator Identification' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Admin ID' },
          value: { _type: 'DV_IDENTIFIER', id: profileData.user_id || data.user_id || 'unknown' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Full Name' },
          value: { _type: 'DV_TEXT', value: profileData.full_name || profileData.display_name || 'Unknown' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Email' },
          value: { _type: 'DV_TEXT', value: profileData.email || '' }
        }
      ]
    }
  })

  // Administrator Permissions
  content.push({
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.permissions.v0',
    name: { _type: 'DV_TEXT', value: 'Administrator Permissions' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Access Level' },
          value: { _type: 'DV_TEXT', value: profileData.access_level || 'admin' }
        }
      ]
    }
  })

  return content
}

// ========================================
// EXISTING MEDICAL RECORD BUILDERS
// ========================================

function buildVitalSignsContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.vital_signs.v1',
    name: {
      _type: 'DV_TEXT',
      value: 'Vital Signs'
    },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.recorded_at || new Date().toISOString() },
      events: [
        {
          _type: 'POINT_EVENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Any event' },
          time: { _type: 'DV_DATE_TIME', value: data.recorded_at || new Date().toISOString() },
          data: {
            _type: 'ITEM_TREE',
            archetype_node_id: 'at0003',
            name: { _type: 'DV_TEXT', value: 'Tree' },
            items: buildVitalSignsItems(data)
          }
        }
      ]
    }
  }
}

function buildVitalSignsItems(data: any): any[] {
  const items: any[] = []

  if (data.systolic_bp || data.diastolic_bp) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0004',
      name: { _type: 'DV_TEXT', value: 'Blood Pressure' },
      value: {
        _type: 'DV_TEXT',
        value: `${data.systolic_bp || 0}/${data.diastolic_bp || 0} mmHg`
      }
    })
  }

  if (data.heart_rate) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0005',
      name: { _type: 'DV_TEXT', value: 'Heart Rate' },
      value: {
        _type: 'DV_QUANTITY',
        magnitude: parseFloat(data.heart_rate),
        units: 'bpm'
      }
    })
  }

  if (data.temperature) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0006',
      name: { _type: 'DV_TEXT', value: 'Temperature' },
      value: {
        _type: 'DV_QUANTITY',
        magnitude: parseFloat(data.temperature),
        units: data.temperature_unit || '°C'
      }
    })
  }

  if (data.respiratory_rate) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0007',
      name: { _type: 'DV_TEXT', value: 'Respiratory Rate' },
      value: {
        _type: 'DV_QUANTITY',
        magnitude: parseFloat(data.respiratory_rate),
        units: '/min'
      }
    })
  }

  if (data.oxygen_saturation) {
    items.push({
      _type: 'ELEMENT',
      archetype_node_id: 'at0008',
      name: { _type: 'DV_TEXT', value: 'Oxygen Saturation' },
      value: {
        _type: 'DV_QUANTITY',
        magnitude: parseFloat(data.oxygen_saturation),
        units: '%'
      }
    })
  }

  return items
}

function buildLabResultsContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.laboratory_test_result.v1',
    name: {
      _type: 'DV_TEXT',
      value: data.test_name || 'Laboratory Test Result'
    },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.test_date || new Date().toISOString() },
      events: [
        {
          _type: 'POINT_EVENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Any event' },
          time: { _type: 'DV_DATE_TIME', value: data.test_date || new Date().toISOString() },
          data: {
            _type: 'ITEM_TREE',
            archetype_node_id: 'at0003',
            name: { _type: 'DV_TEXT', value: 'Test Result' },
            items: [
              {
                _type: 'ELEMENT',
                archetype_node_id: 'at0005',
                name: { _type: 'DV_TEXT', value: 'Test Name' },
                value: { _type: 'DV_TEXT', value: data.test_name || 'Unknown' }
              },
              {
                _type: 'ELEMENT',
                archetype_node_id: 'at0073',
                name: { _type: 'DV_TEXT', value: 'Result Value' },
                value: { _type: 'DV_TEXT', value: data.result_value || '' }
              },
              {
                _type: 'ELEMENT',
                archetype_node_id: 'at0074',
                name: { _type: 'DV_TEXT', value: 'Result Unit' },
                value: { _type: 'DV_TEXT', value: data.result_unit || '' }
              }
            ]
          }
        }
      ]
    }
  }
}

function buildPrescriptionContent(data: any): any {
  return {
    _type: 'INSTRUCTION',
    archetype_node_id: 'openEHR-EHR-INSTRUCTION.medication_order.v1',
    name: {
      _type: 'DV_TEXT',
      value: 'Medication Order'
    },
    narrative: {
      _type: 'DV_TEXT',
      value: `${data.medication_name}: ${data.dosage} ${data.frequency || ''}`
    },
    activities: [
      {
        _type: 'ACTIVITY',
        archetype_node_id: 'at0001',
        name: { _type: 'DV_TEXT', value: 'Order' },
        description: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0002',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0070',
              name: { _type: 'DV_TEXT', value: 'Medication Name' },
              value: { _type: 'DV_TEXT', value: data.medication_name || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0091',
              name: { _type: 'DV_TEXT', value: 'Dosage' },
              value: { _type: 'DV_TEXT', value: data.dosage || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0009',
              name: { _type: 'DV_TEXT', value: 'Frequency' },
              value: { _type: 'DV_TEXT', value: data.frequency || '' }
            }
          ]
        },
        timing: {
          _type: 'DV_PARSABLE',
          value: data.frequency || 'as needed',
          formalism: 'text'
        }
      }
    ]
  }
}

// ========================================
// SPECIALTY MEDICAL RECORD BUILDERS (PHASE 1)
// ========================================

function buildAntenatalVisitContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.antenatal_care.v1',
    name: { _type: 'DV_TEXT', value: 'Antenatal Care Encounter' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Visit' },
        time: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Gestational Age' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.gestational_age_weeks || 0), units: 'weeks' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Fundal Height' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.fundal_height_cm || 0), units: 'cm' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Fetal Heart Rate' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.fetal_heart_rate || 0), units: 'bpm' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'Blood Pressure' },
              value: { _type: 'DV_TEXT', value: `${data.blood_pressure_systolic || 0}/${data.blood_pressure_diastolic || 0} mmHg` }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Pregnancy Complications' },
              value: { _type: 'DV_TEXT', value: Array.isArray(data.pregnancy_complications) ? data.pregnancy_complications.join(', ') : '' }
            }
          ]
        }
      }]
    }
  }
}

function buildSurgicalProcedureContent(data: any): any {
  return {
    _type: 'ACTION',
    archetype_node_id: 'openEHR-EHR-ACTION.procedure.v1',
    name: { _type: 'DV_TEXT', value: 'Surgical Procedure' },
    description: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Procedure Name' },
          value: { _type: 'DV_TEXT', value: data.procedure_name || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Anesthesia Type' },
          value: { _type: 'DV_TEXT', value: data.anesthesia_type || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Duration' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.duration_minutes || 0), units: 'min' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Blood Loss' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.blood_loss_ml || 0), units: 'ml' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'Complications' },
          value: { _type: 'DV_TEXT', value: Array.isArray(data.complications) ? data.complications.join(', ') : data.complications || 'None' }
        }
      ]
    },
    time: { _type: 'DV_DATE_TIME', value: data.procedure_date || new Date().toISOString() }
  }
}

function buildAdmissionDischargeContent(data: any): any {
  return {
    _type: 'ACTION',
    archetype_node_id: 'openEHR-EHR-ACTION.admission.v1',
    name: { _type: 'DV_TEXT', value: 'Admission/Discharge' },
    description: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Admission Type' },
          value: { _type: 'DV_TEXT', value: data.admission_type || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Admission Date' },
          value: { _type: 'DV_DATE_TIME', value: data.admission_date || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Discharge Date' },
          value: { _type: 'DV_DATE_TIME', value: data.discharge_date || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Primary Diagnosis' },
          value: { _type: 'DV_TEXT', value: data.primary_diagnosis || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'Discharge Disposition' },
          value: { _type: 'DV_TEXT', value: data.discharge_disposition || '' }
        }
      ]
    },
    time: { _type: 'DV_DATE_TIME', value: data.admission_date || new Date().toISOString() }
  }
}

function buildMedicationDispensingContent(data: any): any {
  return {
    _type: 'INSTRUCTION',
    archetype_node_id: 'openEHR-EHR-INSTRUCTION.medication_dispensing.v1',
    name: { _type: 'DV_TEXT', value: 'Medication Dispensing' },
    narrative: { _type: 'DV_TEXT', value: `${data.medication_name}: ${data.quantity_dispensed} ${data.unit || ''}` },
    activities: [{
      _type: 'ACTIVITY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Dispensing' },
      description: {
        _type: 'ITEM_TREE',
        archetype_node_id: 'at0002',
        items: [
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0003',
            name: { _type: 'DV_TEXT', value: 'Medication Name' },
            value: { _type: 'DV_TEXT', value: data.medication_name || '' }
          },
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0004',
            name: { _type: 'DV_TEXT', value: 'Quantity Dispensed' },
            value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.quantity_dispensed || 0), units: data.unit || 'units' }
          },
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0005',
            name: { _type: 'DV_TEXT', value: 'Dosage Instructions' },
            value: { _type: 'DV_TEXT', value: data.dosage_instructions || '' }
          }
        ]
      }
    }]
  }
}

function buildPharmacyStockContent(data: any): any {
  return {
    _type: 'ADMIN_ENTRY',
    archetype_node_id: 'openEHR-EHR-ADMIN_ENTRY.pharmacy_stock.v1',
    name: { _type: 'DV_TEXT', value: 'Pharmacy Stock Management' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Medication Name' },
          value: { _type: 'DV_TEXT', value: data.medication_name || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Stock Level' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.stock_level || 0), units: data.unit || 'units' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Reorder Level' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.reorder_level || 0), units: data.unit || 'units' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Expiry Date' },
          value: { _type: 'DV_DATE_TIME', value: data.expiry_date || '' }
        }
      ]
    }
  }
}

function buildClinicalConsultationContent(data: any): any {
  return {
    _type: 'EVALUATION',
    archetype_node_id: 'openEHR-EHR-EVALUATION.clinical_consultation.v1',
    name: { _type: 'DV_TEXT', value: 'Clinical Consultation' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Chief Complaint' },
          value: { _type: 'DV_TEXT', value: data.chief_complaint || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Presenting Symptoms' },
          value: { _type: 'DV_TEXT', value: Array.isArray(data.presenting_symptoms) ? data.presenting_symptoms.join(', ') : data.presenting_symptoms || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Clinical Findings' },
          value: { _type: 'DV_TEXT', value: data.clinical_findings || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Diagnosis' },
          value: { _type: 'DV_TEXT', value: data.diagnosis || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'Treatment Plan' },
          value: { _type: 'DV_TEXT', value: data.treatment_plan || '' }
        }
      ]
    }
  }
}

function buildOncologyTreatmentContent(data: any): any {
  return {
    _type: 'INSTRUCTION',
    archetype_node_id: 'openEHR-EHR-INSTRUCTION.oncology_treatment.v1',
    name: { _type: 'DV_TEXT', value: 'Oncology Treatment Plan' },
    narrative: { _type: 'DV_TEXT', value: `${data.cancer_type} - Stage ${data.cancer_stage}: ${data.treatment_type}` },
    activities: [{
      _type: 'ACTIVITY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Treatment' },
      description: {
        _type: 'ITEM_TREE',
        archetype_node_id: 'at0002',
        items: [
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0003',
            name: { _type: 'DV_TEXT', value: 'Cancer Type' },
            value: { _type: 'DV_TEXT', value: data.cancer_type || '' }
          },
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0004',
            name: { _type: 'DV_TEXT', value: 'Cancer Stage' },
            value: { _type: 'DV_TEXT', value: data.cancer_stage || '' }
          },
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0005',
            name: { _type: 'DV_TEXT', value: 'Treatment Type' },
            value: { _type: 'DV_TEXT', value: data.treatment_type || '' }
          },
          {
            _type: 'ELEMENT',
            archetype_node_id: 'at0006',
            name: { _type: 'DV_TEXT', value: 'Chemotherapy Regimen' },
            value: { _type: 'DV_TEXT', value: data.chemotherapy_regimen || '' }
          }
        ]
      }
    }]
  }
}

function buildInfectiousDiseaseContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.infectious_disease.v1',
    name: { _type: 'DV_TEXT', value: 'Infectious Disease Encounter' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Visit' },
        time: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Infection Type' },
              value: { _type: 'DV_TEXT', value: data.infection_type || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Fever Present' },
              value: { _type: 'DV_TEXT', value: data.fever_present ? 'Yes' : 'No' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Symptoms' },
              value: { _type: 'DV_TEXT', value: Array.isArray(data.symptoms) ? data.symptoms.join(', ') : data.symptoms || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'Lab Findings' },
              value: { _type: 'DV_TEXT', value: data.lab_findings || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Antibiotics Prescribed' },
              value: { _type: 'DV_TEXT', value: Array.isArray(data.antibiotics_prescribed) ? data.antibiotics_prescribed.join(', ') : data.antibiotics_prescribed || '' }
            }
          ]
        }
      }]
    }
  }
}

function buildCardiologyVisitContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.cardiology.v1',
    name: { _type: 'DV_TEXT', value: 'Cardiology Encounter' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Visit' },
        time: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Chief Complaint' },
              value: { _type: 'DV_TEXT', value: data.chief_complaint || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'ECG Findings' },
              value: { _type: 'DV_TEXT', value: data.ecg_findings || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Echocardiogram Results' },
              value: { _type: 'DV_TEXT', value: data.echocardiogram_results || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'NYHA Class' },
              value: { _type: 'DV_TEXT', value: data.nyha_class || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Medications Prescribed' },
              value: { _type: 'DV_TEXT', value: Array.isArray(data.medications_prescribed) ? data.medications_prescribed.join(', ') : data.medications_prescribed || '' }
            }
          ]
        }
      }]
    }
  }
}

function buildEmergencyVisitContent(data: any): any {
  return {
    _type: 'ACTION',
    archetype_node_id: 'openEHR-EHR-ACTION.emergency_encounter.v1',
    name: { _type: 'DV_TEXT', value: 'Emergency Medicine Encounter' },
    description: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Triage Level' },
          value: { _type: 'DV_TEXT', value: data.triage_level || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Chief Complaint' },
          value: { _type: 'DV_TEXT', value: data.chief_complaint || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Glasgow Coma Score' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.glasgow_coma_score || 15), units: 'points' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Resuscitation Performed' },
          value: { _type: 'DV_TEXT', value: data.resuscitation_performed ? 'Yes' : 'No' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'Disposition' },
          value: { _type: 'DV_TEXT', value: data.disposition || '' }
        }
      ]
    },
    time: { _type: 'DV_DATE_TIME', value: data.arrival_time || new Date().toISOString() }
  }
}

function buildNephrologyVisitContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.nephrology.v1',
    name: { _type: 'DV_TEXT', value: 'Nephrology Encounter' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Visit' },
        time: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'CKD Stage' },
              value: { _type: 'DV_TEXT', value: data.ckd_stage || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'eGFR Value' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.egfr_value || 0), units: 'ml/min/1.73m2' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Creatinine' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.creatinine_mg_dl || 0), units: 'mg/dl' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'On Dialysis' },
              value: { _type: 'DV_TEXT', value: data.on_dialysis ? 'Yes' : 'No' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Dialysis Type' },
              value: { _type: 'DV_TEXT', value: data.dialysis_type || 'N/A' }
            }
          ]
        }
      }]
    }
  }
}

function buildGastroenterologyProcedureContent(data: any): any {
  return {
    _type: 'ACTION',
    archetype_node_id: 'openEHR-EHR-ACTION.gastroenterology_procedure.v1',
    name: { _type: 'DV_TEXT', value: 'Gastroenterology Procedure' },
    description: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Procedure Name' },
          value: { _type: 'DV_TEXT', value: data.procedure_name || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Indication' },
          value: { _type: 'DV_TEXT', value: data.indication || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Findings' },
          value: { _type: 'DV_TEXT', value: data.colon_findings || data.stomach_findings || data.esophagus_findings || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Biopsies Taken' },
          value: { _type: 'DV_TEXT', value: data.biopsies_taken ? 'Yes' : 'No' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'Complications' },
          value: { _type: 'DV_TEXT', value: Array.isArray(data.complications) ? data.complications.join(', ') : data.complications || 'None' }
        }
      ]
    },
    time: { _type: 'DV_DATE_TIME', value: data.procedure_date || new Date().toISOString() }
  }
}

function buildEndocrinologyVisitContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.endocrinology.v1',
    name: { _type: 'DV_TEXT', value: 'Endocrinology Management' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Visit' },
        time: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Primary Condition' },
              value: { _type: 'DV_TEXT', value: data.primary_endocrine_condition || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Diabetes Type' },
              value: { _type: 'DV_TEXT', value: data.diabetes_type || 'N/A' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'HbA1c' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.hba1c_percent || 0), units: '%' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'TSH Level' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.tsh_miu_l || 0), units: 'mIU/L' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Thyroid Condition' },
              value: { _type: 'DV_TEXT', value: data.thyroid_condition || '' }
            }
          ]
        }
      }]
    }
  }
}

function buildPulmonologyVisitContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.pulmonology.v1',
    name: { _type: 'DV_TEXT', value: 'Pulmonology Encounter' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Visit' },
        time: { _type: 'DV_DATE_TIME', value: data.visit_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Respiratory Symptoms' },
              value: { _type: 'DV_TEXT', value: Array.isArray(data.respiratory_symptoms) ? data.respiratory_symptoms.join(', ') : data.respiratory_symptoms || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Respiratory Rate' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.respiratory_rate || 0), units: '/min' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Oxygen Saturation' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.oxygen_saturation || 0), units: '%' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'Smoking Status' },
              value: { _type: 'DV_TEXT', value: data.smoking_status || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Inhaler Therapy' },
              value: { _type: 'DV_TEXT', value: Array.isArray(data.inhaler_therapy) ? data.inhaler_therapy.join(', ') : data.inhaler_therapy || '' }
            }
          ]
        }
      }]
    }
  }
}

function buildPsychiatricAssessmentContent(data: any): any {
  return {
    _type: 'EVALUATION',
    archetype_node_id: 'openEHR-EHR-EVALUATION.psychiatric_assessment.v1',
    name: { _type: 'DV_TEXT', value: 'Psychiatric Assessment' },
    data: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Assessment Type' },
          value: { _type: 'DV_TEXT', value: data.assessment_type || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Mood' },
          value: { _type: 'DV_TEXT', value: data.mood || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Affect' },
          value: { _type: 'DV_TEXT', value: data.affect || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Suicide Risk' },
          value: { _type: 'DV_TEXT', value: data.suicide_risk || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'PHQ-9 Score' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.phq9_score || 0), units: 'points' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0007',
          name: { _type: 'DV_TEXT', value: 'GAD-7 Score' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.gad7_score || 0), units: 'points' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0008',
          name: { _type: 'DV_TEXT', value: 'Diagnoses' },
          value: { _type: 'DV_TEXT', value: Array.isArray(data.psychiatric_diagnoses) ? data.psychiatric_diagnoses.join(', ') : data.psychiatric_diagnoses || '' }
        }
      ]
    }
  }
}

function buildNeurologyExamContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.neurology.v1',
    name: { _type: 'DV_TEXT', value: 'Neurology Examination' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.exam_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Examination' },
        time: { _type: 'DV_DATE_TIME', value: data.exam_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Chief Complaint' },
              value: { _type: 'DV_TEXT', value: data.chief_complaint || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Glasgow Coma Score' },
              value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.glasgow_coma_score || 15), units: 'points' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Cranial Nerves' },
              value: { _type: 'DV_TEXT', value: data.cranial_nerves || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'Motor Examination' },
              value: { _type: 'DV_TEXT', value: data.motor_examination || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'MRI Findings' },
              value: { _type: 'DV_TEXT', value: data.mri_findings || '' }
            }
          ]
        }
      }]
    }
  }
}

function buildRadiologyReportContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.radiology_report.v1',
    name: { _type: 'DV_TEXT', value: 'Radiology Report' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.exam_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Examination' },
        time: { _type: 'DV_DATE_TIME', value: data.exam_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Modality' },
              value: { _type: 'DV_TEXT', value: data.modality || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Body Part' },
              value: { _type: 'DV_TEXT', value: data.body_part || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Findings' },
              value: { _type: 'DV_TEXT', value: data.findings || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'Impressions' },
              value: { _type: 'DV_TEXT', value: data.impressions || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Critical Finding' },
              value: { _type: 'DV_TEXT', value: data.critical_finding ? 'Yes' : 'No' }
            }
          ]
        }
      }]
    }
  }
}

function buildPathologyReportContent(data: any): any {
  return {
    _type: 'OBSERVATION',
    archetype_node_id: 'openEHR-EHR-OBSERVATION.pathology_report.v1',
    name: { _type: 'DV_TEXT', value: 'Pathology Report' },
    data: {
      _type: 'HISTORY',
      archetype_node_id: 'at0001',
      name: { _type: 'DV_TEXT', value: 'Event Series' },
      origin: { _type: 'DV_DATE_TIME', value: data.collection_date || new Date().toISOString() },
      events: [{
        _type: 'POINT_EVENT',
        archetype_node_id: 'at0002',
        name: { _type: 'DV_TEXT', value: 'Report' },
        time: { _type: 'DV_DATE_TIME', value: data.report_date || data.collection_date || new Date().toISOString() },
        data: {
          _type: 'ITEM_TREE',
          archetype_node_id: 'at0003',
          items: [
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0004',
              name: { _type: 'DV_TEXT', value: 'Specimen Type' },
              value: { _type: 'DV_TEXT', value: data.specimen_type || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0005',
              name: { _type: 'DV_TEXT', value: 'Specimen Site' },
              value: { _type: 'DV_TEXT', value: data.specimen_site || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0006',
              name: { _type: 'DV_TEXT', value: 'Microscopic Description' },
              value: { _type: 'DV_TEXT', value: data.microscopic_description || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0007',
              name: { _type: 'DV_TEXT', value: 'Diagnosis' },
              value: { _type: 'DV_TEXT', value: data.diagnosis || '' }
            },
            {
              _type: 'ELEMENT',
              archetype_node_id: 'at0008',
              name: { _type: 'DV_TEXT', value: 'Histological Type' },
              value: { _type: 'DV_TEXT', value: data.histological_type || '' }
            }
          ]
        }
      }]
    }
  }
}

function buildPhysiotherapySessionContent(data: any): any {
  return {
    _type: 'ACTION',
    archetype_node_id: 'openEHR-EHR-ACTION.physiotherapy.v1',
    name: { _type: 'DV_TEXT', value: 'Physiotherapy Session' },
    description: {
      _type: 'ITEM_TREE',
      archetype_node_id: 'at0001',
      items: [
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0002',
          name: { _type: 'DV_TEXT', value: 'Session Number' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.session_number || 0), units: 'session' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0003',
          name: { _type: 'DV_TEXT', value: 'Subjective Assessment' },
          value: { _type: 'DV_TEXT', value: data.subjective_assessment || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0004',
          name: { _type: 'DV_TEXT', value: 'Objective Findings' },
          value: { _type: 'DV_TEXT', value: data.objective_findings || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0005',
          name: { _type: 'DV_TEXT', value: 'Pain Level' },
          value: { _type: 'DV_QUANTITY', magnitude: parseFloat(data.pain_level || 0), units: 'points' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0006',
          name: { _type: 'DV_TEXT', value: 'Treatment Modalities' },
          value: { _type: 'DV_TEXT', value: Array.isArray(data.modalities_used) ? data.modalities_used.join(', ') : data.modalities_used || '' }
        },
        {
          _type: 'ELEMENT',
          archetype_node_id: 'at0007',
          name: { _type: 'DV_TEXT', value: 'Progress Notes' },
          value: { _type: 'DV_TEXT', value: data.progress_notes || '' }
        }
      ]
    },
    time: { _type: 'DV_DATE_TIME', value: data.session_date || new Date().toISOString() }
  }
}

/**
 * Processes a single sync queue item
 */
async function processSyncItem(
  supabase: any,
  item: SyncQueueItem
): Promise<{ success: boolean; error?: string }> {
  console.log(`Processing sync item: ${item.id} (${item.sync_type})`)

  try {
    let result: { success: boolean; compositionId?: string; error?: string }

    if (item.sync_type === 'ehr_status_update') {
      // Update EHR_STATUS with demographic data
      result = await updateEHRStatus(
        item.data_snapshot.ehr_id,
        item.data_snapshot as EHRStatusUpdateData
      )
    } else if (item.sync_type === 'role_profile_create') {
      // Create role-specific profile composition
      // Get EHR ID from data_snapshot (already included by trigger)
      const ehrId = item.data_snapshot.ehr_id

      if (!ehrId) {
        return {
          success: false,
          error: 'No EHR ID found in data snapshot'
        }
      }

      result = await createComposition(
        ehrId,
        item.template_id,
        item.data_snapshot
      )
    } else if (item.sync_type === 'demographics') {
      // Store demographics in EHR_STATUS (correct OpenEHR approach)
      const ehrId = item.data_snapshot.ehr_id

      if (!ehrId) {
        return {
          success: false,
          error: 'No EHR ID found in data snapshot for demographics'
        }
      }

      // Update EHR_STATUS with demographics data
      result = await updateEHRStatus(ehrId, item.data_snapshot)
    } else {
      // Create composition for medical records (existing behavior)
      // Validate patient_id exists in data_snapshot
      if (!item.data_snapshot.patient_id) {
        return {
          success: false,
          error: `Missing patient_id in data_snapshot for record ${item.id} (table: ${item.table_name}, sync_type: ${item.sync_type})`
        }
      }

      // Get EHR ID from electronic_health_records table
      const { data: ehrData, error: ehrError } = await supabase
        .from('electronic_health_records')
        .select('ehr_id')
        .eq('patient_id', item.data_snapshot.patient_id)
        .single()

      if (ehrError || !ehrData) {
        return {
          success: false,
          error: `Failed to get EHR ID: ${ehrError?.message || 'Not found'}`
        }
      }

      result = await createComposition(
        ehrData.ehr_id,
        item.template_id,
        item.data_snapshot
      )
    }

    if (result.success) {
      // Update queue item as completed
      const { error: updateError } = await supabase
        .from('ehrbase_sync_queue')
        .update({
          sync_status: 'completed',
          ehrbase_composition_id: result.compositionId || null,
          processed_at: new Date().toISOString(),
          error_message: null
        })
        .eq('id', item.id)

      if (updateError) {
        console.error('Failed to update sync queue:', updateError)
      }

      // Update the source table with composition_id
      if (result.compositionId && item.record_id && item.table_name) {
        console.log(`📝 Updating ${item.table_name} record ${item.record_id} with composition_id: ${result.compositionId}`)

        const { error: sourceUpdateError } = await supabase
          .from(item.table_name)
          .update({
            composition_id: item.id  // Use sync queue ID as the composition_id reference
          })
          .eq('id', item.record_id)

        if (sourceUpdateError) {
          console.error(`⚠️  Failed to update ${item.table_name} with composition_id:`, sourceUpdateError)
          // Don't fail the sync - queue is already marked as completed
        } else {
          console.log(`✅ Updated ${item.table_name} record with composition reference`)
        }
      }

      return { success: true }
    } else {
      // Update retry count and error
      const newRetryCount = (item.retry_count || 0) + 1
      const newStatus = newRetryCount >= MAX_RETRY_COUNT ? 'failed' : 'pending'

      const { error: updateError } = await supabase
        .from('ehrbase_sync_queue')
        .update({
          sync_status: newStatus,
          retry_count: newRetryCount,
          error_message: result.error || 'Unknown error',
          last_retry_at: new Date().toISOString()
        })
        .eq('id', item.id)

      if (updateError) {
        console.error('Failed to update sync queue:', updateError)
      }

      return {
        success: false,
        error: result.error
      }
    }
  } catch (error) {
    console.error('Error processing sync item:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

serve(async (req) => {
  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get pending sync items
    const { data: syncItems, error: fetchError } = await supabaseClient
      .from('ehrbase_sync_queue')
      .select('*')
      .eq('sync_status', 'pending')
      .lt('retry_count', MAX_RETRY_COUNT)
      .order('created_at', { ascending: true })
      .limit(50) // Process in batches

    if (fetchError) {
      throw new Error(`Failed to fetch sync items: ${fetchError.message}`)
    }

    if (!syncItems || syncItems.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No items to sync', processed: 0 }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Process each item
    const results = []
    for (const item of syncItems) {
      const result = await processSyncItem(supabaseClient, item)
      results.push({
        id: item.id,
        success: result.success,
        error: result.error
      })
    }

    const successCount = results.filter(r => r.success).length
    const failureCount = results.filter(r => !r.success).length

    return new Response(
      JSON.stringify({
        message: 'Sync completed',
        total: syncItems.length,
        successful: successCount,
        failed: failureCount,
        results
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      }
    )
  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})
