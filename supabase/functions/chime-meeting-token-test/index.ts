import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    console.log("=== Function Started ===");
    console.log("Method:", req.method);
    console.log("URL:", req.url);

    // Check if Firebase token header exists
    const firebaseTokenHeader = req.headers.get("x-firebase-token") || req.headers.get("X-Firebase-Token");
    console.log("Firebase token header present:", !!firebaseTokenHeader);
    console.log("Firebase token length:", firebaseTokenHeader?.length || 0);

    // Try to parse request body
    let body;
    try {
      body = await req.json();
      console.log("Request body:", body);
    } catch (e) {
      console.error("Failed to parse body:", e.message);
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        message: "Test function working",
        hasFirebaseToken: !!firebaseTokenHeader,
        body: body || null,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" }
      }
    );

  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Internal server error",
        details: error.stack,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
