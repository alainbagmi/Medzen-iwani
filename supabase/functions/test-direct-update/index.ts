import { createClient } from "https://esm.sh/@supabase/supabase-js@2.50.0";

export async function handler(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseKey);

  console.log("=== Direct Update Test ===\n");

  // Test 1: Try UPDATE with SERVICE_ROLE
  console.log("Test 1: Attempt UPDATE with SERVICE_ROLE...");
  const appointmentId = "8101feee-9bd4-4b44-b618-775b7192324a";
  const providerId = "7c014c7c-f96e-4e47-905d-1929cbd33790";

  const { data, error } = await supabase
    .from("appointments")
    .update({ provider_id: providerId })
    .eq("id", appointmentId)
    .select("id, provider_id");

  console.log("Update result:");
  console.log("  Error:", error ? error.code : "none");
  if (error) {
    console.log("  Message:", error.message);
    console.log("  Details:", error.details);
  }
  console.log("  Data:", data);

  // Test 2: Try to find what constraint is actually on the table
  console.log("\n\nTest 2: Query system catalogs...");

  // Create a temporary function to query constraint info
  const { error: createError } = await supabase.rpc("create_function", {
    name: "get_fk_constraint",
    return_type: "TABLE(constraint_name text, referenced_table text, referenced_column text)",
    body: `
      SELECT c.conname, t.relname::text, a.attname::text
      FROM pg_constraint c
      JOIN pg_class t ON c.conrelid = t.oid
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = c.conkey[1]
      WHERE c.conrelid = 'appointments'::regclass
      AND c.contype = 'f'
      AND a.attname = 'provider_id'
    `,
  });

  if (createError) {
    console.log("Can't create temp function, trying direct approach...");

    // Try to query pg_constraint through raw client call
    try {
      const response = await fetch(`${supabaseUrl}/rest/v1/pg_constraint`, {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${supabaseKey}`,
        },
      });

      const constraintData = await response.json();
      console.log("pg_constraint query:", constraintData);
    } catch (e) {
      console.log("pg_constraint fetch failed:", e);
    }
  }

  // Test 3: Simple SELECT to confirm provider exists
  console.log("\n\nTest 3: Verify provider exists...");
  const { data: providerData, error: providerError } = await supabase
    .from("medical_provider_profiles")
    .select("id, user_id")
    .eq("id", providerId)
    .single();

  if (providerError) {
    console.log("Provider query error:", providerError);
  } else {
    console.log("Provider found:", providerData);
  }

  // Test 4: Check current appointment state
  console.log("\n\nTest 4: Current appointment state...");
  const { data: apptData, error: apptError } = await supabase
    .from("appointments")
    .select("id, provider_id, patient_id")
    .eq("id", appointmentId)
    .single();

  if (apptError) {
    console.log("Appointment query error:", apptError);
  } else {
    console.log("Appointment:", apptData);
  }

  return new Response(
    JSON.stringify({
      status: "test_complete",
      update_attempted: { appointmentId, providerId },
      result: error ? "FAILED" : "SUCCESS",
      error: error ? { code: error.code, message: error.message } : null,
    }),
    { status: error ? 400 : 200, headers: { "Content-Type": "application/json" } }
  );
}

Deno.serve(handler);
