import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyFirebaseToken } from "../chime-meeting-token/verify-firebase-jwt.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    console.log("=== Chime Meeting Token Request (Test - No AWS SDK) ===");

    // Get Firebase token from custom header
    const firebaseTokenHeader = req.headers.get("x-firebase-token") || req.headers.get("X-Firebase-Token");

    if (!firebaseTokenHeader) {
      return new Response(
        JSON.stringify({ error: "Missing x-firebase-token header" }),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify Firebase JWT token
    let userId: string;
    let userEmail: string;

    try {
      const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
      if (!firebaseProjectId) {
        throw new Error("FIREBASE_PROJECT_ID not configured");
      }

      console.log("🔍 Verifying Firebase token...");
      const payload = await verifyFirebaseToken(firebaseTokenHeader, firebaseProjectId);
      const firebaseUid = payload.user_id || payload.sub;

      console.log("📋 Token payload - user_id:", payload.user_id);
      console.log("📋 Token payload - sub:", payload.sub);
      console.log("📋 Token payload - email:", payload.email);
      console.log("📋 Extracted UID:", firebaseUid);

      if (!firebaseUid) {
        throw new Error("No user ID in verified token");
      }

      console.log("🔍 Looking up user with Firebase UID:", firebaseUid);

      // Look up user in Supabase
      const { data: userData, error: userError } = await supabaseAdmin
        .from("users")
        .select("id, email, firebase_uid, full_name")
        .eq("firebase_uid", firebaseUid)
        .single();

      console.log("📊 Query found user:", !!userData);
      if (userError) {
        console.error("📊 Query error code:", userError.code);
        console.error("📊 Query error message:", userError.message);
      }
      if (userData) {
        console.log("📊 User ID:", userData.id);
        console.log("📊 User email:", userData.email);
        console.log("📊 User Firebase UID:", userData.firebase_uid);
      }

      if (userError || !userData) {
        console.error("❌ User lookup failed for UID:", firebaseUid);
        console.error("❌ Error:", userError?.message || "No error message");
        throw new Error("User not found in database");
      }

      userId = userData.id;
      userEmail = userData.email;

      console.log("✓ Auth Success - User:", userId, userEmail);

    } catch (error) {
      console.error("Auth Error:", error);
      return new Response(
        JSON.stringify({ error: "Invalid or expired token", details: error.message }),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // Return success (without actually calling AWS Chime SDK)
    return new Response(
      JSON.stringify({
        success: true,
        message: "Authentication successful (test version - no AWS SDK)",
        userId: userId,
        userEmail: userEmail,
      }),
      { status: 200, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Internal server error",
        details: error.stack,
      }),
      { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
    );
  }
});
