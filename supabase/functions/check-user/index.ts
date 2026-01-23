import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Check for the specific Firebase UID from the failed production test
    const firebaseUid = "jt3xBjcPEdQzltsC9hEkzBzqbWz1";

    console.log("=== Diagnostic Check ===");
    console.log("Searching for Firebase UID:", firebaseUid);

    // Query users table
    const { data: user, error: userError } = await supabaseAdmin
      .from("users")
      .select("id, email, firebase_uid, created_at")
      .eq("firebase_uid", firebaseUid)
      .maybeSingle();

    console.log("User found:", !!user);
    if (user) {
      console.log("User ID:", user.id);
      console.log("Email:", user.email);
    }
    if (userError) {
      console.error("Query error:", userError);
    }

    // Also check if ANY users exist with this firebase_uid (in case of case sensitivity issues)
    const { count, error: countError } = await supabaseAdmin
      .from("users")
      .select("*", { count: "exact", head: true })
      .eq("firebase_uid", firebaseUid);

    // Check total users in table for context
    const { count: totalCount } = await supabaseAdmin
      .from("users")
      .select("*", { count: "exact", head: true });

    return new Response(
      JSON.stringify({
        firebaseUid,
        userExists: !!user,
        userData: user,
        userError: userError?.message,
        matchCount: count,
        countError: countError?.message,
        totalUsersInDatabase: totalCount,
        diagnosis: !user
          ? "USER_NOT_FOUND - This explains the 401 error"
          : "USER_EXISTS - Issue must be elsewhere in JWT validation",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" }
      }
    );
  } catch (error) {
    console.error("Diagnostic function error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" }
      }
    );
  }
});
