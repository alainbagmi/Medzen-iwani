/**
 * storage-sign-url Edge Function
 *
 * Generates signed URLs for private storage bucket files.
 * Used for secure access to chat attachments.
 *
 * @author MedZen AI Team
 * @version 1.0.0
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyFirebaseToken } from "../_shared/verify-firebase-jwt.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";

interface SignUrlRequest {
  bucket: string;
  path: string;
  expiresIn?: number; // seconds, default 3600 (1 hour)
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    console.log("=== Storage Sign URL Request ===");

    // Get Firebase token from custom header
    const firebaseTokenHeader =
      req.headers.get("x-firebase-token") ||
      req.headers.get("X-Firebase-Token");

    if (!firebaseTokenHeader) {
      return new Response(
        JSON.stringify({ error: "Missing x-firebase-token header" }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify Firebase JWT token
    let userId: string;

    try {
      const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
      if (!firebaseProjectId) {
        throw new Error("FIREBASE_PROJECT_ID not configured");
      }

      console.log("Verifying Firebase token...");
      const payload = await verifyFirebaseToken(
        firebaseTokenHeader,
        firebaseProjectId
      );
      const firebaseUid = payload.user_id || payload.sub;

      if (!firebaseUid) {
        throw new Error("No user ID in verified token");
      }

      // Look up user in Supabase
      const { data: userData, error: userError } = await supabaseAdmin
        .from("users")
        .select("id")
        .eq("firebase_uid", firebaseUid)
        .single();

      if (userError || !userData) {
        console.error("User lookup failed for UID:", firebaseUid);
        throw new Error("User not found in database");
      }

      userId = userData.id;
      console.log("Auth Success - User:", userId);
    } catch (error) {
      console.error("Auth Error:", error);
      return new Response(
        JSON.stringify({
          error: "Invalid or expired token",
          details: error.message,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Rate limiting check (HIPAA: Prevents DDoS and abuse)
    const rateLimitConfig = getRateLimitConfig('storage-sign-url', userId);
    const rateLimit = await checkRateLimit(rateLimitConfig);
    if (!rateLimit.allowed) {
      console.warn(`🚫 Rate limit exceeded for user ${userId}`);
      return createRateLimitErrorResponse(rateLimit);
    }

    // Parse request body
    const body: SignUrlRequest = await req.json();
    const { bucket, path, expiresIn = 3600 } = body;

    // Validate required fields
    if (!bucket || !path) {
      return new Response(
        JSON.stringify({ error: "Missing bucket or path" }),
        {
          status: 400,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate expires time (max 7 days)
    const maxExpires = 7 * 24 * 60 * 60; // 7 days in seconds
    const expires = Math.min(Math.max(expiresIn, 60), maxExpires);

    console.log(`Generating signed URL for ${bucket}/${path}`);
    console.log(`Expires in: ${expires} seconds`);

    // For call_attachments bucket, verify user has access to the appointment
    if (bucket === "call_attachments") {
      // Path format: calls/{appointmentId}/{filename}
      const pathParts = path.split("/");
      if (pathParts.length >= 2 && pathParts[0] === "calls") {
        const appointmentId = pathParts[1];

        // Verify user is a participant in the appointment
        const { data: appointment, error: appointmentError } = await supabaseAdmin
          .from("appointments")
          .select(`
            id,
            patient_id,
            medical_provider_profiles!appointments_provider_id_fkey(
              user_id
            )
          `)
          .eq("id", appointmentId)
          .single();

        if (appointmentError || !appointment) {
          console.log("Appointment not found for path:", path);
          return new Response(
            JSON.stringify({ error: "Appointment not found" }),
            {
              status: 404,
              headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
            }
          );
        }

        const providerProfile = appointment.medical_provider_profiles as {
          user_id: string;
        } | null;
        const providerUserId = providerProfile?.user_id;

        if (appointment.patient_id !== userId && providerUserId !== userId) {
          console.log(`User ${userId} is not authorized to access ${path}`);
          return new Response(
            JSON.stringify({ error: "Not authorized to access this file" }),
            {
              status: 403,
              headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
            }
          );
        }
      }
    }

    // Generate signed URL
    const { data, error } = await supabaseAdmin.storage
      .from(bucket)
      .createSignedUrl(path, expires);

    if (error) {
      console.error("Error generating signed URL:", error);
      return new Response(
        JSON.stringify({ error: "Failed to generate signed URL", details: error.message }),
        {
          status: 500,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("Signed URL generated successfully");

    return new Response(
      JSON.stringify({
        signedUrl: data.signedUrl,
        expiresIn: expires,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Internal server error",
        details: error.stack,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
