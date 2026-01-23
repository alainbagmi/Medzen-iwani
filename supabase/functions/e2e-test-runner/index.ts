import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

interface TestResult {
  phase: number;
  status: "success" | "error";
  data?: Record<string, unknown>;
  error?: string;
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: { ...corsHeaders, ...securityHeaders } });
    }

    const results: TestResult[] = [];

    // ============================================================================
    // PHASE 2: Create test users and data
    // ============================================================================
    console.log("Starting Phase 2: Create test users and data");

    try {
      // Create test patient
      const { data: patientData, error: patientError } = await supabase
        .from("users")
        .insert({
          firebase_uid: `test-e2e-${crypto.randomUUID()}`,
          email: `test-e2e-${Math.floor(Math.random() * 1000000)}@medzen.test`,
        })
        .select("id, email")
        .single();

      if (patientError) throw new Error(`Patient creation failed: ${patientError.message}`);
      const testPatientId = patientData.id;
      console.log("✅ Test patient created:", testPatientId);

      // Create test provider
      const { data: providerData, error: providerError } = await supabase
        .from("users")
        .insert({
          firebase_uid: `test-prov-e2e-${crypto.randomUUID()}`,
          email: `test-prov-e2e-${Math.floor(Math.random() * 1000000)}@medzen.test`,
        })
        .select("id, email")
        .single();

      if (providerError) throw new Error(`Provider creation failed: ${providerError.message}`);
      const testProviderId = providerData.id;
      console.log("✅ Test provider created:", testProviderId);

      // Create patient profile with empty cumulative record
      const emptyRecord = {
        conditions: [],
        medications: [],
        allergies: [],
        surgical_history: [],
        family_history: [],
        vital_trends: {},
        social_history: {},
        review_of_systems_trends: {},
        physical_exam_findings: {},
        metadata: {
          total_visits: 0,
          source_soap_notes: [],
          last_updated: null,
        },
      };

      const { error: profileError } = await supabase.from("patient_profiles").insert({
        user_id: testPatientId,
        patient_number: `E2E-${new Date().getTime()}`,
        cumulative_medical_record: emptyRecord,
      });

      if (profileError) throw new Error(`Patient profile creation failed: ${profileError.message}`);
      console.log("✅ Patient profile created");

      // Create provider profile
      const { error: medProvError } = await supabase.from("medical_provider_profiles").insert({
        user_id: testProviderId,
        provider_number: `E2E-PROV-${new Date().getTime()}`,
        medical_license_number: `LIC-E2E-${Math.floor(Math.random() * 100000)}`,
        license_expiry_date: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        professional_role: "Medical Doctor",
      });

      if (medProvError) throw new Error(`Provider profile creation failed: ${medProvError.message}`);
      console.log("✅ Provider profile created");

      // Create first appointment
      const { data: appointmentData, error: appointmentError } = await supabase
        .from("appointments")
        .insert({
          patient_id: testPatientId,
          provider_id: testProviderId,
          appointment_type: "initial_consultation",
          chief_complaint: "Annual checkup - first visit",
          scheduled_start: new Date(Date.now() + 3600000).toISOString(),
          scheduled_end: new Date(Date.now() + 7200000).toISOString(),
          status: "confirmed",
          start_date: new Date().toISOString().split("T")[0],
        })
        .select("id, appointment_number")
        .single();

      if (appointmentError) throw new Error(`Appointment creation failed: ${appointmentError.message}`);
      const testAppointment1Id = appointmentData.id;
      console.log("✅ First appointment created:", testAppointment1Id);

      // Create video call session for the appointment
      const sessionId = crypto.randomUUID();
      const { error: sessionError } = await supabase
        .from("video_call_sessions")
        .insert({
          id: sessionId,
          patient_id: testPatientId,
          provider_id: testProviderId,
          appointment_id: testAppointment1Id,
          channel_name: `e2e-test-1-${sessionId}`,
          status: "ended",
          started_at: new Date(Date.now() - 1800000).toISOString(), // 30 min ago
          ended_at: new Date().toISOString(),
        });

      if (sessionError) throw new Error(`Video session creation failed: ${sessionError.message}`);
      console.log("✅ Video session created:", sessionId);

      results.push({
        phase: 2,
        status: "success",
        data: {
          testPatientId,
          testProviderId,
          testAppointment1Id,
          testSessionId: sessionId,
        },
      });
    } catch (error) {
      results.push({
        phase: 2,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error in Phase 2",
      });
      return new Response(JSON.stringify({ results, success: false }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } });
    }

    const testPatientId = (results[0].data as Record<string, string>).testPatientId;
    const testProviderId = (results[0].data as Record<string, string>).testProviderId;
    const testAppointment1Id = (results[0].data as Record<string, string>).testAppointment1Id;
    const testSessionId = (results[0].data as Record<string, string>).testSessionId;

    // ============================================================================
    // PHASE 3: Create first SOAP note with initial medical data
    // ============================================================================
    console.log("Starting Phase 3: Create first SOAP note");

    try {
      // Create SOAP note
      const { data: soapData, error: soapError } = await supabase
        .from("soap_notes")
        .insert({
          patient_id: testPatientId,
          provider_id: testProviderId,
          appointment_id: testAppointment1Id,
          session_id: testSessionId,
          status: "finalized",
          chief_complaint: "Annual checkup - first visit",
        })
        .select("id")
        .single();

      if (soapError) throw new Error(`SOAP note creation failed: ${soapError.message}`);
      const testSoap1Id = soapData.id;
      console.log("✅ First SOAP note created:", testSoap1Id);

      // Add allergies
      const { error: allergiesError } = await supabase.from("soap_allergies").insert([
        {
          soap_note_id: testSoap1Id,
          allergen: "Penicillin",
          reaction: "Rash",
          severity: "moderate",
          onset_date: "2020-01-15",
        },
        {
          soap_note_id: testSoap1Id,
          allergen: "Shellfish",
          reaction: "Anaphylaxis",
          severity: "severe",
          onset_date: "1998-06-20",
        },
      ]);

      if (allergiesError) throw new Error(`Allergies insertion failed: ${allergiesError.message}`);
      console.log("✅ Allergies added (2)");

      // Add vital signs
      const { error: vitalsError } = await supabase.from("soap_vital_signs").insert([
        {
          soap_note_id: testSoap1Id,
          measurement_time: new Date().toISOString(),
          temperature_value: 37.2,
          temperature_unit: "celsius",
          blood_pressure_systolic: 140,
          blood_pressure_diastolic: 90,
          heart_rate: 72,
          respiratory_rate: 16,
          oxygen_saturation: 98,
          weight_kg: 75,
          height_cm: 165,
          bmi: 27.5,
          pain_score: 0,
        },
      ]);

      if (vitalsError) throw new Error(`Vital signs insertion failed: ${vitalsError.message}`);
      console.log("✅ Vital signs added");

      // Add diagnoses
      const { error: diagError } = await supabase.from("soap_assessment_items").insert([
        {
          soap_note_id: testSoap1Id,
          problem_number: 1,
          diagnosis_description: "Essential Hypertension",
          icd10_code: "I10",
          status: "new",
          severity: "mild",
        },
        {
          soap_note_id: testSoap1Id,
          problem_number: 2,
          diagnosis_description: "Type 2 Diabetes Mellitus",
          icd10_code: "E11.9",
          status: "new",
          severity: "moderate",
        },
      ]);

      if (diagError) throw new Error(`Diagnoses insertion failed: ${diagError.message}`);
      console.log("✅ Diagnoses added (2)");

      // Add medications
      const { error: medError } = await supabase.from("soap_medications").insert([
        {
          soap_note_id: testSoap1Id,
          medication_name: "Lisinopril",
          dose: "10mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          source: "current_medication",
          indication: "Hypertension",
          start_date: "2015-03-20",
        },
        {
          soap_note_id: testSoap1Id,
          medication_name: "Metformin",
          dose: "500mg",
          route: "oral",
          frequency: "twice daily",
          status: "active",
          source: "current_medication",
          indication: "Type 2 Diabetes",
          start_date: "2018-07-10",
        },
      ]);

      if (medError) throw new Error(`Medications insertion failed: ${medError.message}`);
      console.log("✅ Medications added (2)");

      results.push({
        phase: 3,
        status: "success",
        data: { testSoap1Id },
      });
    } catch (error) {
      results.push({
        phase: 3,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error in Phase 3",
      });
      return new Response(JSON.stringify({ results, success: false }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } });
    }

    const testSoap1Id = (results[1].data as Record<string, string>).testSoap1Id;

    // ============================================================================
    // PHASE 4: Trigger cumulative medical record update
    // ============================================================================
    console.log("Starting Phase 4: Trigger cumulative record update");

    try {
      // Extract SOAP detail records from database
      const { data: allergiesData, error: allergiesError } = await supabase
        .from("soap_allergies")
        .select("allergen, reaction, severity")
        .eq("soap_note_id", testSoap1Id);

      const { data: medicationsData, error: medicationsError } = await supabase
        .from("soap_medications")
        .select("medication_name, dose, route, frequency, status, source, indication")
        .eq("soap_note_id", testSoap1Id);

      const { data: diagnosisData, error: diagnosisError } = await supabase
        .from("soap_assessment_items")
        .select("diagnosis_description, icd10_code, status, severity")
        .eq("soap_note_id", testSoap1Id)
        .order("problem_number");

      if (allergiesError) throw new Error(`Failed to fetch allergies: ${allergiesError.message}`);
      if (medicationsError) throw new Error(`Failed to fetch medications: ${medicationsError.message}`);
      if (diagnosisError) throw new Error(`Failed to fetch diagnoses: ${diagnosisError.message}`);

      // Transform into merge function format
      const soapData = {
        conditions: (diagnosisData || []).map((d: Record<string, unknown>) => ({
          name: d.diagnosis_description,
          icd10: d.icd10_code,
          status: d.status,
          severity: d.severity,
        })),
        medications: (medicationsData || []).map((m: Record<string, unknown>) => ({
          name: m.medication_name,
          dose: m.dose,
          route: m.route,
          frequency: m.frequency,
          status: m.status,
          source: m.source,
          indication: m.indication,
        })),
        allergies: (allergiesData || []).map((a: Record<string, unknown>) => ({
          allergen: a.allergen,
          reaction: a.reaction,
          severity: a.severity,
        })),
      };

      console.log(`📊 Extracted: ${soapData.conditions.length} conditions, ${soapData.medications.length} medications, ${soapData.allergies.length} allergies`);

      const { data: mergeData, error: mergeError } = await supabase
        .rpc("merge_soap_into_cumulative_record", {
          p_patient_id: testPatientId,
          p_soap_note_id: testSoap1Id,
          p_soap_data: soapData,
        })
        .single();

      if (mergeError) throw new Error(`Merge function failed: ${mergeError.message}`);
      console.log("✅ Cumulative record merged");

      // Verify counts
      const { data: verifyData, error: verifyError } = await supabase
        .from("patient_profiles")
        .select(
          "user_id, cumulative_medical_record, medical_record_last_updated_at, medical_record_last_soap_note_id"
        )
        .eq("user_id", testPatientId)
        .single();

      if (verifyError) throw new Error(`Verification failed: ${verifyError.message}`);

      const medRecord = verifyData.cumulative_medical_record as Record<string, unknown>;
      const conditionCount = Array.isArray(medRecord.conditions) ? medRecord.conditions.length : 0;
      const medicationCount = Array.isArray(medRecord.medications) ? medRecord.medications.length : 0;
      const allergyCount = Array.isArray(medRecord.allergies) ? medRecord.allergies.length : 0;

      console.log(
        `✅ Phase 4 verification: conditions=${conditionCount}, medications=${medicationCount}, allergies=${allergyCount}`
      );

      if (conditionCount !== 2 || medicationCount !== 2 || allergyCount !== 2) {
        throw new Error(
          `Expected counts (2,2,2) but got (${conditionCount},${medicationCount},${allergyCount})`
        );
      }

      results.push({
        phase: 4,
        status: "success",
        data: {
          conditionCount,
          medicationCount,
          allergyCount,
          lastUpdated: verifyData.medical_record_last_updated_at,
        },
      });
    } catch (error) {
      results.push({
        phase: 4,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error in Phase 4",
      });
      return new Response(JSON.stringify({ results, success: false }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } });
    }

    // ============================================================================
    // PHASE 5: Create second SOAP note for deduplication test
    // ============================================================================
    console.log("Starting Phase 5: Create second SOAP note (deduplication test)");

    try {
      // Create second appointment
      const { data: appointment2Data, error: appointment2Error } = await supabase
        .from("appointments")
        .insert({
          patient_id: testPatientId,
          provider_id: testProviderId,
          appointment_type: "follow_up",
          chief_complaint: "Follow-up: BP check, new digestive symptoms",
          scheduled_start: new Date(Date.now() + 604800000).toISOString(), // +7 days
          scheduled_end: new Date(Date.now() + 608400000).toISOString(),
          status: "confirmed",
          start_date: new Date(Date.now() + 604800000).toISOString().split("T")[0],
        })
        .select("id")
        .single();

      if (appointment2Error) throw new Error(`Second appointment creation failed: ${appointment2Error.message}`);
      const testAppointment2Id = appointment2Data.id;
      console.log("✅ Second appointment created:", testAppointment2Id);

      // Create second video call session
      const session2Id = crypto.randomUUID();
      const { error: session2Error } = await supabase
        .from("video_call_sessions")
        .insert({
          id: session2Id,
          patient_id: testPatientId,
          provider_id: testProviderId,
          appointment_id: testAppointment2Id,
          channel_name: `e2e-test-2-${session2Id}`,
          status: "ended",
          started_at: new Date(Date.now() - 900000).toISOString(), // 15 min ago
          ended_at: new Date().toISOString(),
        });

      if (session2Error) throw new Error(`Second video session creation failed: ${session2Error.message}`);
      console.log("✅ Second video session created:", session2Id);

      // Create second SOAP note
      const { data: soap2Data, error: soap2Error } = await supabase
        .from("soap_notes")
        .insert({
          patient_id: testPatientId,
          provider_id: testProviderId,
          appointment_id: testAppointment2Id,
          session_id: session2Id,
          status: "finalized",
          chief_complaint: "Follow-up: BP check, new digestive symptoms",
        })
        .select("id")
        .single();

      if (soap2Error) throw new Error(`Second SOAP note creation failed: ${soap2Error.message}`);
      const testSoap2Id = soap2Data.id;
      console.log("✅ Second SOAP note created:", testSoap2Id);

      // Add allergies (1 duplicate, 1 new)
      const { error: allergies2Error } = await supabase.from("soap_allergies").insert([
        {
          soap_note_id: testSoap2Id,
          allergen: "Penicillin", // DUPLICATE
          reaction: "Rash",
          severity: "moderate",
          onset_date: "2020-01-15",
        },
        {
          soap_note_id: testSoap2Id,
          allergen: "Latex", // NEW
          reaction: "Hives",
          severity: "mild",
          onset_date: "2022-11-10",
        },
      ]);

      if (allergies2Error) throw new Error(`Second allergies insertion failed: ${allergies2Error.message}`);
      console.log("✅ Second allergies added (1 duplicate Penicillin, 1 new Latex)");

      // Add diagnoses (1 status change, 1 duplicate, 1 new)
      const { error: diag2Error } = await supabase.from("soap_assessment_items").insert([
        {
          soap_note_id: testSoap2Id,
          problem_number: 1,
          diagnosis_description: "Essential Hypertension",
          icd10_code: "I10",
          status: "stable", // STATUS CHANGED from "new" (valid enum: new, established, worsening, improving, stable, resolved)
          severity: "mild",
        },
        {
          soap_note_id: testSoap2Id,
          problem_number: 2,
          diagnosis_description: "Type 2 Diabetes Mellitus",
          icd10_code: "E11.9",
          status: "stable",
          severity: "moderate",
        },
        {
          soap_note_id: testSoap2Id,
          problem_number: 3,
          diagnosis_description: "Gastroesophageal Reflux Disease",
          icd10_code: "K21",
          status: "new",
          severity: "mild",
        },
      ]);

      if (diag2Error) throw new Error(`Second diagnoses insertion failed: ${diag2Error.message}`);
      console.log(
        "✅ Second diagnoses added (Hypertension status changed, 1 duplicate Diabetes, 1 new GERD)"
      );

      // Add medications (1 duplicate, 1 status change, 1 new)
      const { error: med2Error } = await supabase.from("soap_medications").insert([
        {
          soap_note_id: testSoap2Id,
          medication_name: "Metformin",
          dose: "500mg",
          route: "oral",
          frequency: "twice daily",
          status: "active",
          source: "current_medication",
          indication: "Type 2 Diabetes",
          start_date: "2018-07-10",
        },
        {
          soap_note_id: testSoap2Id,
          medication_name: "Lisinopril",
          dose: "10mg",
          route: "oral",
          frequency: "once daily",
          status: "discontinued", // STATUS CHANGED
          source: "current_medication",
          indication: "Hypertension",
          start_date: "2015-03-20",
        },
        {
          soap_note_id: testSoap2Id,
          medication_name: "Omeprazole",
          dose: "20mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          source: "newly_prescribed",
          indication: "GERD",
          start_date: new Date().toISOString().split("T")[0],
        },
      ]);

      if (med2Error) throw new Error(`Second medications insertion failed: ${med2Error.message}`);
      console.log(
        "✅ Second medications added (1 duplicate Metformin, Lisinopril status changed, 1 new Omeprazole)"
      );

      results.push({
        phase: 5,
        status: "success",
        data: { testAppointment2Id, testSoap2Id },
      });
    } catch (error) {
      results.push({
        phase: 5,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error in Phase 5",
      });
      return new Response(JSON.stringify({ results, success: false }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } });
    }

    const testSoap2Id = (results[3].data as Record<string, string>).testSoap2Id;

    // ============================================================================
    // PHASE 4c: Trigger second cumulative record update
    // ============================================================================
    console.log("Starting Phase 4c: Trigger second cumulative record update");

    try {
      // Extract second SOAP detail records from database
      const { data: allergies2Data, error: allergies2Error } = await supabase
        .from("soap_allergies")
        .select("allergen, reaction, severity")
        .eq("soap_note_id", testSoap2Id);

      const { data: medications2Data, error: medications2Error } = await supabase
        .from("soap_medications")
        .select("medication_name, dose, route, frequency, status, source, indication")
        .eq("soap_note_id", testSoap2Id);

      const { data: diagnosis2Data, error: diagnosis2Error } = await supabase
        .from("soap_assessment_items")
        .select("diagnosis_description, icd10_code, status, severity")
        .eq("soap_note_id", testSoap2Id)
        .order("problem_number");

      if (allergies2Error) throw new Error(`Failed to fetch allergies: ${allergies2Error.message}`);
      if (medications2Error) throw new Error(`Failed to fetch medications: ${medications2Error.message}`);
      if (diagnosis2Error) throw new Error(`Failed to fetch diagnoses: ${diagnosis2Error.message}`);

      // Transform into merge function format
      const soapData2 = {
        conditions: (diagnosis2Data || []).map((d: Record<string, unknown>) => ({
          name: d.diagnosis_description,
          icd10: d.icd10_code,
          status: d.status,
          severity: d.severity,
        })),
        medications: (medications2Data || []).map((m: Record<string, unknown>) => ({
          name: m.medication_name,
          dose: m.dose,
          route: m.route,
          frequency: m.frequency,
          status: m.status,
          source: m.source,
          indication: m.indication,
        })),
        allergies: (allergies2Data || []).map((a: Record<string, unknown>) => ({
          allergen: a.allergen,
          reaction: a.reaction,
          severity: a.severity,
        })),
      };

      console.log(`📊 Extracted (SOAP 2): ${soapData2.conditions.length} conditions, ${soapData2.medications.length} medications, ${soapData2.allergies.length} allergies`);

      const { data: merge2Data, error: merge2Error } = await supabase
        .rpc("merge_soap_into_cumulative_record", {
          p_patient_id: testPatientId,
          p_soap_note_id: testSoap2Id,
          p_soap_data: soapData2,
        })
        .single();

      if (merge2Error) throw new Error(`Second merge function failed: ${merge2Error.message}`);
      console.log("✅ Second cumulative record merged");

      results.push({
        phase: 4.5,
        status: "success",
        data: { merged: true },
      });
    } catch (error) {
      results.push({
        phase: 4.5,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error in Phase 4c",
      });
      return new Response(JSON.stringify({ results, success: false }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } });
    }

    // ============================================================================
    // PHASE 6: Verify deduplication results
    // ============================================================================
    console.log("Starting Phase 6: Verify deduplication results");

    try {
      // Query 1: Overall counts
      const { data: countsData, error: countsError } = await supabase
        .from("patient_profiles")
        .select("cumulative_medical_record")
        .eq("user_id", testPatientId)
        .single();

      if (countsError) throw new Error(`Counts query failed: ${countsError.message}`);

      const medRecord = countsData.cumulative_medical_record as Record<string, unknown>;
      const finalConditions = Array.isArray(medRecord.conditions) ? medRecord.conditions.length : 0;
      const finalMedications = Array.isArray(medRecord.medications) ? medRecord.medications.length : 0;
      const finalAllergies = Array.isArray(medRecord.allergies) ? medRecord.allergies.length : 0;

      console.log(
        `✅ Query 1 - Overall counts: conditions=${finalConditions}, medications=${finalMedications}, allergies=${finalAllergies}`
      );

      // Verification checks
      const allChecks = {
        conditionCount: finalConditions === 3,
        medicationCount: finalMedications === 3,
        allergyCount: finalAllergies === 3,
      };

      // Query 2: Penicillin deduplication
      const { data: penicillinData, error: penicillinError } = await supabase
        .from("patient_profiles")
        .select("cumulative_medical_record")
        .eq("user_id", testPatientId)
        .single();

      if (penicillinError) throw new Error(`Penicillin query failed: ${penicillinError.message}`);

      const allergies = Array.isArray(medRecord.allergies) ? medRecord.allergies : [];
      const penicillinCount = (allergies as Array<Record<string, unknown>>).filter(
        (a) => a.allergen === "Penicillin"
      ).length;

      console.log(
        `✅ Query 2 - Penicillin deduplication: count=${penicillinCount} (should be 1, not 2)`
      );
      allChecks.penicillinDedup = penicillinCount === 1;

      // Query 3: Hypertension status update
      const hypertension = (allergies as Array<Record<string, unknown>>)
        .find((c) => c.name === "Essential Hypertension") as Record<string, unknown> | undefined;
      const conditions = Array.isArray(medRecord.conditions) ? medRecord.conditions : [];
      const hypertensionStatus = (conditions as Array<Record<string, unknown>>)
        .find((c) => c.name === "Essential Hypertension")?.status;

      console.log(`✅ Query 3 - Hypertension status: ${hypertensionStatus} (should be "stable")`);
      allChecks.hypertensionStatus = hypertensionStatus === "stable";

      // Query 4: Lisinopril status update
      const medications = Array.isArray(medRecord.medications) ? medRecord.medications : [];
      const lisinoprilStatus = (medications as Array<Record<string, unknown>>)
        .find((m) => m.name === "Lisinopril")?.status;

      console.log(`✅ Query 4 - Lisinopril status: ${lisinoprilStatus} (should be "discontinued")`);
      allChecks.lisinoprilStatus = lisinoprilStatus === "discontinued";

      // Check for new data
      const gerdExists = (conditions as Array<Record<string, unknown>>).some(
        (c) => c.name === "Gastroesophageal Reflux Disease"
      );
      const omeprazoleExists = (medications as Array<Record<string, unknown>>).some(
        (m) => m.name === "Omeprazole"
      );
      const latexExists = (allergies as Array<Record<string, unknown>>).some((a) => a.allergen === "Latex");

      console.log(`✅ Query 5-7 - New data check: GERD=${gerdExists}, Omeprazole=${omeprazoleExists}, Latex=${latexExists}`);
      allChecks.newDataAdded = gerdExists && omeprazoleExists && latexExists;

      const allPassed = Object.values(allChecks).every((check) => check === true);

      results.push({
        phase: 6,
        status: "success",
        data: {
          finalConditions,
          finalMedications,
          finalAllergies,
          penicillinCount,
          hypertensionStatus,
          lisinoprilStatus,
          newData: {
            gerdExists,
            omeprazoleExists,
            latexExists,
          },
          allChecks,
          allPassed,
        },
      });
    } catch (error) {
      results.push({
        phase: 6,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error in Phase 6",
      });
      return new Response(JSON.stringify({ results, success: false }), { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } });
    }

    // Return all results
    const allPassed = results.every((r) => r.status === "success");

    return new Response(
      JSON.stringify({
        success: allPassed,
        testPatientId,
        testProviderId,
        testAppointment1Id,
        testSoap1Id,
        testSoap2Id,
        results,
      }),
      { status: allPassed ? 200 : 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    const origin = req.headers.get("origin");
    const corsHeaders = getCorsHeaders(origin);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
    );
  }
});
