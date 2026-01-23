import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts'

/**
 * PowerSync Token Edge Function
 *
 * Returns the Supabase Auth token for PowerSync authentication
 * PowerSync is configured to validate Supabase Auth tokens via JWKS discovery
 * This function simply passes through the existing Supabase Auth token
 */

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get the authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // PowerSync configuration
    const POWERSYNC_URL = Deno.env.get('POWERSYNC_URL')

    if (!POWERSYNC_URL) {
      console.error('POWERSYNC_URL not configured')
      return new Response(
        JSON.stringify({ error: 'PowerSync not configured' }),
        { status: 500, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract the JWT token from the Authorization header
    // Format: "Bearer <token>"
    const token = authHeader.replace('Bearer ', '')

    // Get token expiration from the user session
    const { data: { session } } = await supabaseClient.auth.getSession()
    const expiresAt = session?.expires_at
      ? new Date(session.expires_at * 1000).toISOString()
      : new Date(Date.now() + 3600000).toISOString() // Default 1 hour

    // Return the Supabase Auth token (which PowerSync will validate via JWKS)
    return new Response(
      JSON.stringify({
        token,
        powersync_url: POWERSYNC_URL,
        expires_at: expiresAt,
        user_id: user.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('PowerSync token error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
