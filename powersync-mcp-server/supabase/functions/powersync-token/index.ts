import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as jose from 'https://deno.land/x/jose@v5.1.0/index.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get environment variables
    const POWERSYNC_URL = Deno.env.get('POWERSYNC_URL')
    const POWERSYNC_KEY_ID = Deno.env.get('POWERSYNC_KEY_ID')
    const POWERSYNC_PRIVATE_KEY = Deno.env.get('POWERSYNC_PRIVATE_KEY')

    if (!POWERSYNC_URL || !POWERSYNC_KEY_ID || !POWERSYNC_PRIVATE_KEY) {
      throw new Error('Missing required environment variables')
    }

    // Get authenticated user from Supabase
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user's firebase_uid from users table
    const { data: userData, error: dbError } = await supabaseClient
      .from('users')
      .select('firebase_uid')
      .eq('id', user.id)
      .single()

    if (dbError || !userData?.firebase_uid) {
      return new Response(
        JSON.stringify({ error: 'User not found in database' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate PowerSync JWT token
    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + 24) // Token valid for 24 hours

    // Import private key
    const privateKey = await jose.importPKCS8(POWERSYNC_PRIVATE_KEY, 'RS256')

    // Create JWT
    const token = await new jose.SignJWT({
      sub: userData.firebase_uid, // Use Firebase UID as subject
      aud: POWERSYNC_URL,
    })
      .setProtectedHeader({
        alg: 'RS256',
        kid: POWERSYNC_KEY_ID,
      })
      .setIssuedAt()
      .setExpirationTime(expiresAt)
      .sign(privateKey)

    return new Response(
      JSON.stringify({
        token,
        powersync_url: POWERSYNC_URL,
        expires_at: expiresAt.toISOString(),
        user_id: user.id,
        firebase_uid: userData.firebase_uid,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
