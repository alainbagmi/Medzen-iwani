import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.50.0";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseKey);

  // Use RPC to execute raw SQL update with full privileges
  const { data, error } = await supabase.rpc("exec_sql", {
    sql: `
      UPDATE appointments
      SET provider_id = '7c014c7c-f96e-4e47-905d-1929cbd33790'
      WHERE id = '8101feee-9bd4-4b44-b618-775b7192324a'
      RETURNING id, provider_id, patient_id;
    `,
  });

  if (error) {
    console.log("RPC error:", error);
    // If RPC doesn't exist, try direct UPDATE
    const { data: updateData, error: updateError } = await supabase
      .from("appointments")
      .update({ provider_id: "7c014c7c-f96e-4e47-905d-1929cbd33790" })
      .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
      .select();

    if (updateError) {
      return new Response(
        JSON.stringify({
          error: "Both RPC and direct update failed",
          rpc_error: error.message,
          update_error: updateError.message,
          update_code: updateError.code,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify({ success: true, data: updateData }), {
      status: 200,
      headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true, data }), {
    status: 200,
    headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
  });
});
