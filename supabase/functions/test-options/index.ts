import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Simplified CORS headers matching what appears in verbose response
// Removed "content-type" from Access-Control-Allow-Headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
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
        "Content-Type": "application/json"
      }
    }
  );
});
