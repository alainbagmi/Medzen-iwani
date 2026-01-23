import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  // Handle POST requests
  return new Response(
    JSON.stringify({
      success: true,
      message: "test function executed successfully"
    }),
    {
      headers: {
        ...corsHeaders,
        ...securityHeaders,
        "Content-Type": "application/json"
      }
    }
  );
});
