/**
 * Refresh PowerSync Materialized Views Edge Function
 *
 * This function refreshes all materialized views used by PowerSync
 * for multi-role data access. Call this periodically (every 5-15 minutes)
 * via a cron scheduler.
 *
 * Deployment:
 *   npx supabase functions deploy refresh-powersync-views
 *
 * Manual test:
 *   npx supabase functions invoke refresh-powersync-views
 *
 * Schedule with external cron:
 *   curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/refresh-powersync-views \
 *     -H "Authorization: Bearer YOUR_ANON_KEY"
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  const startTime = Date.now();

  try {
    // Get Supabase credentials from environment
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    }

    // Create Supabase client with service role key
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    console.log("Starting materialized view refresh...");

    // Call the database function to refresh all views
    const { data, error } = await supabase.rpc(
      "refresh_powersync_materialized_views"
    );

    if (error) {
      throw new Error(`Database error: ${error.message}`);
    }

    const duration = Date.now() - startTime;

    const response = {
      success: true,
      message: "All PowerSync materialized views refreshed successfully",
      refreshed_at: new Date().toISOString(),
      duration_ms: duration,
      views_refreshed: [
        "v_provider_accessible_patients",
        "v_provider_accessible_vital_signs",
        "v_provider_accessible_lab_results",
        "v_provider_accessible_prescriptions",
        "v_provider_accessible_medical_records",
        "v_provider_appointments",
        "v_facility_admin_accessible_appointments",
        "v_facility_admin_accessible_providers",
        "v_facility_admin_accessible_patients",
      ],
    };

    console.log(`✓ Refresh completed in ${duration}ms`);

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const duration = Date.now() - startTime;

    const errorResponse = {
      success: false,
      error: error.message,
      error_type: error.name,
      timestamp: new Date().toISOString(),
      duration_ms: duration,
    };

    console.error("✗ Refresh failed:", error.message);

    return new Response(JSON.stringify(errorResponse), {
      status: 500,
      headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
    });
  }
});
