import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { S3Client, DeleteObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.400.0";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  // Simple response for testing
  return new Response(
    JSON.stringify({
      success: true,
      message: "test-imports executed successfully - imports loaded OK"
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
