import { createClient } from "https://esm.sh/@supabase/supabase-js@2.50.0";

export async function handler(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseKey);

  // Test 1: Check if constraint exists
  console.log("Test 1: Checking if FK constraint exists...");
  const { data: constraintData, error: constraintError } = await supabase.rpc(
    "sql_raw",
    {
      sql: `
        SELECT constraint_name, table_name, column_name
        FROM information_schema.key_column_usage
        WHERE table_name = 'appointments'
        AND column_name = 'provider_id'
        AND constraint_name LIKE '%fkey%';
      `,
    }
  );

  if (constraintError) {
    console.log("RPC sql_raw not available, trying alternative...");
  } else {
    console.log("Constraint data:", constraintData);
  }

  // Test 2: Check provider_id values directly in DB
  console.log("\nTest 2: Checking medical_provider_profiles records...");
  const { data: providerData, error: providerError } = await supabase
    .from("medical_provider_profiles")
    .select("id, user_id")
    .limit(3);

  if (providerError) {
    return new Response(
      JSON.stringify({
        error: "Cannot query medical_provider_profiles",
        details: providerError,
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  console.log(`Found ${providerData.length} providers`);

  // Test 3: Try to insert a test appointment with a known provider
  if (providerData.length > 0) {
    const testProviderId = providerData[0].id;
    console.log(
      `\nTest 3: Attempting update with provider: ${testProviderId}`
    );

    const { data: updateData, error: updateError } = await supabase
      .from("appointments")
      .update({ provider_id: testProviderId })
      .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
      .select();

    if (updateError) {
      console.log("Update failed:", updateError);
      return new Response(
        JSON.stringify({
          test_results: {
            constraint_exists: !!constraintData,
            providers_found: providerData.length,
            first_provider_id: testProviderId,
            update_error: updateError,
            error_code: updateError.code,
            error_message: updateError.message,
            error_details: updateError.details,
          },
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log("Update succeeded:", updateData);
    return new Response(
      JSON.stringify({
        success: true,
        test_results: {
          constraint_exists: !!constraintData,
          providers_found: providerData.length,
          update_succeeded: true,
          first_provider_id: testProviderId,
          data: updateData,
        },
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({
      error: "No providers found in database",
    }),
    { status: 400, headers: { "Content-Type": "application/json" } }
  );
}

Deno.serve(handler);
