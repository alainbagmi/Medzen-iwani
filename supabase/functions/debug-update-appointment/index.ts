import { createClient } from "https://esm.sh/@supabase/supabase-js@2.50.0";

export async function handler(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseKey);

  // Step 1: Verify the provider record exists
  console.log("Step 1: Checking if provider record exists...");
  const { data: providerData, error: providerError } = await supabase
    .from("medical_provider_profiles")
    .select("id, user_id")
    .eq("id", "7c014c7c-f96e-4e47-905d-1929cbd33790")
    .single();

  if (providerError) {
    console.log("Provider query error:", providerError);
    return new Response(
      JSON.stringify({
        error: "Provider not found",
        details: providerError,
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  console.log("Provider found:", providerData);

  // Step 2: Get the appointment
  console.log("Step 2: Fetching appointment...");
  const { data: appointmentData, error: appointmentError } = await supabase
    .from("appointments")
    .select("id, provider_id, patient_id")
    .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
    .single();

  if (appointmentError) {
    console.log("Appointment query error:", appointmentError);
    return new Response(
      JSON.stringify({
        error: "Appointment not found",
        details: appointmentError,
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  console.log("Appointment found:", appointmentData);

  // Step 3: Attempt the update
  console.log("Step 3: Attempting update...");
  const { data: updateData, error: updateError } = await supabase
    .from("appointments")
    .update({ provider_id: "7c014c7c-f96e-4e47-905d-1929cbd33790" })
    .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
    .select();

  if (updateError) {
    console.log("Update error:", updateError);
    return new Response(
      JSON.stringify({
        error: "Update failed with FK constraint error",
        message: updateError.message,
        code: updateError.code,
        hint: updateError.hint,
        providerExists: true,
        currentProvider: appointmentData.provider_id,
        targetProvider: "7c014c7c-f96e-4e47-905d-1929cbd33790",
        debugInfo: {
          providerRecord: providerData,
          appointmentRecord: appointmentData,
        },
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  return new Response(JSON.stringify({ success: true, data: updateData }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(handler);
