import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-firebase-token",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
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
        headers: { ...corsHeaders, "Content-Type": "application/json" }
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
