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

  const appointmentId = "8101feee-9bd4-4b44-b618-775b7192324a";
  const targetProviderId = "7c014c7c-f96e-4e47-905d-1929cbd33790";

  console.log(
    `Starting fix: appointment ${appointmentId} → provider ${targetProviderId}`
  );

  // Step 1: Set provider_id to NULL to break the orphaned FK reference
  console.log("Step 1: Setting provider_id to NULL...");
  const { data: nullData, error: nullError } = await supabase
    .from("appointments")
    .update({ provider_id: null })
    .eq("id", appointmentId)
    .select();

  if (nullError) {
    console.log("Error setting to NULL:", nullError);
    return new Response(
      JSON.stringify({
        error: "Failed to set provider_id to NULL",
        details: nullError,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
      }
    );
  }

  console.log("Successfully set to NULL:", nullData);

  // Step 2: Update provider_id to the new target value
  console.log("Step 2: Updating to target provider_id...");
  const { data: updateData, error: updateError } = await supabase
    .from("appointments")
    .update({ provider_id: targetProviderId })
    .eq("id", appointmentId)
    .select();

  if (updateError) {
    console.log("Error updating to target:", updateError);
    // Try to revert to NULL to leave it in a consistent state
    await supabase
      .from("appointments")
      .update({ provider_id: null })
      .eq("id", appointmentId);

    return new Response(
      JSON.stringify({
        error: "Failed to update to target provider_id",
        details: updateError,
        note: "Reverted provider_id to NULL",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
      }
    );
  }

  console.log("Successfully updated to target provider:", updateData);

  return new Response(
    JSON.stringify({
      success: true,
      message: "Appointment provider_id updated successfully",
      steps: {
        step1_nullify: "✓ Set to NULL to break orphaned FK reference",
        step2_update: "✓ Updated to target provider_id",
      },
      data: updateData,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
    }
  );
});
