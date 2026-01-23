import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.50.0";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseKey);

  console.log("=== FK Constraint Deep Inspection ===\n");

  // Query 1: Check the constraint using information_schema
  console.log("Query 1: Information schema constraint check...");
  const { data: constraintInfo, error: constraintInfoError } = await supabase
    .from("information_schema_table_constraints")
    .select()
    .eq("constraint_name", "appointments_provider_id_fkey");

  if (constraintInfoError) {
    console.log("information_schema query not available");
  } else {
    console.log("Constraint info:", JSON.stringify(constraintInfo, null, 2));
  }

  // Query 2: Get all provider IDs
  console.log("\nQuery 2: Fetching all provider IDs...");
  const { data: allProviders, error: providersError } = await supabase
    .from("medical_provider_profiles")
    .select("id")
    .limit(100);

  if (providersError) {
    console.log("Provider fetch error:", providersError);
  } else {
    console.log(`Found ${allProviders?.length || 0} providers`);
    if (allProviders && allProviders.length > 0) {
      console.log("First 5 provider IDs:", allProviders.slice(0, 5).map(p => p.id));
    }
  }

  // Query 3: Check the target appointment
  console.log("\nQuery 3: Checking target appointment...");
  const { data: targetAppt, error: targetError } = await supabase
    .from("appointments")
    .select("id, provider_id, patient_id, scheduled_start")
    .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
    .single();

  if (targetError) {
    console.log("Target error:", targetError);
  } else {
    console.log("Target appointment:", JSON.stringify(targetAppt, null, 2));
  }

  // Query 4: Test with SERVICE_ROLE using raw SQL through RPC
  console.log("\nQuery 4: Testing direct SQL update with SERVICE_ROLE...");

  // First, check if we can query the constraint metadata
  try {
    const testUpdate = await supabase.rpc("exec_sql", {
      sql: `UPDATE appointments SET provider_id = '7c014c7c-f96e-4e47-905d-1929cbd33790' WHERE id = '8101feee-9bd4-4b44-b618-775b7192324a' RETURNING *;`,
    });

    if (testUpdate.error) {
      console.log("Direct SQL error:", testUpdate.error);
    } else {
      console.log("Direct SQL result:", testUpdate.data);
    }
  } catch (e) {
    console.log("exec_sql not available");
  }

  // Query 5: Test update using Supabase client
  console.log("\nQuery 5: Testing Supabase client update...");
  const { data: updateData, error: updateError } = await supabase
    .from("appointments")
    .update({ provider_id: "7c014c7c-f96e-4e47-905d-1929cbd33790" })
    .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
    .select();

  if (updateError) {
    console.log("Update error code:", updateError.code);
    console.log("Update error message:", updateError.message);
    console.log("Update error details:", updateError.details);
  } else {
    console.log("Update succeeded:", updateData);
  }

  return new Response(
    JSON.stringify({
      status: "inspection_completed",
      message: "Check function logs for full inspection results",
    }),
    { status: 200, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
  );
});
