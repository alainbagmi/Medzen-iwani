import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

interface RateLimitConfig {
  maxRequests: number;
  windowSeconds: number;
  identifier: string; // user_id or ip_address or combined
}

interface RateLimitResult {
  allowed: boolean;
  remainingRequests: number;
  resetAt: Date;
  retryAfter?: number;
}

/**
 * Check rate limit for a given identifier
 * HIPAA: Prevents abuse and DDoS attacks on PHI endpoints
 */
export const checkRateLimit = async (
  config: RateLimitConfig
): Promise<RateLimitResult> => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseKey) {
      console.error('Missing Supabase credentials for rate limiter');
      // Fail open - allow request if rate limiter fails
      return {
        allowed: true,
        remainingRequests: config.maxRequests,
        resetAt: new Date(Date.now() + config.windowSeconds * 1000),
      };
    }

    const supabase = createClient(supabaseUrl, supabaseKey);
    const windowStart = new Date(Date.now() - config.windowSeconds * 1000).toISOString();

    // Count requests in current window
    const { count, error: countError } = await supabase
      .from('rate_limit_tracking')
      .select('*', { count: 'exact', head: true })
      .eq('identifier', config.identifier)
      .gte('created_at', windowStart);

    if (countError) {
      console.error('Rate limit check failed:', countError);
      // Fail open - allow request if rate limiter fails
      return {
        allowed: true,
        remainingRequests: config.maxRequests,
        resetAt: new Date(Date.now() + config.windowSeconds * 1000),
      };
    }

    const currentRequests = count || 0;
    const allowed = currentRequests < config.maxRequests;
    const remainingRequests = Math.max(0, config.maxRequests - currentRequests);

    if (allowed) {
      // Log this request
      await supabase.from('rate_limit_tracking').insert({
        identifier: config.identifier,
        endpoint: Deno.env.get('FUNCTION_NAME') || 'unknown',
        created_at: new Date().toISOString(),
      });
    }

    return {
      allowed,
      remainingRequests,
      resetAt: new Date(Date.now() + config.windowSeconds * 1000),
      retryAfter: allowed ? undefined : config.windowSeconds,
    };
  } catch (error) {
    console.error('Rate limit check exception:', error);
    // Fail open - allow request if rate limiter fails
    return {
      allowed: true,
      remainingRequests: config.maxRequests,
      resetAt: new Date(Date.now() + config.windowSeconds * 1000),
    };
  }
};

/**
 * Get rate limit config by endpoint
 */
export const getRateLimitConfig = (
  endpoint: string,
  identifier: string
): RateLimitConfig => {
  const limits: { [key: string]: { maxRequests: number; windowSeconds: number } } = {
    'chime-meeting-token': { maxRequests: 10, windowSeconds: 60 },
    'generate-soap-draft-v2': { maxRequests: 20, windowSeconds: 60 },
    'bedrock-ai-chat': { maxRequests: 30, windowSeconds: 60 },
    'upload-profile-picture': { maxRequests: 5, windowSeconds: 60 },
    'start-medical-transcription': { maxRequests: 5, windowSeconds: 60 },
    'sync-to-ehrbase': { maxRequests: 10, windowSeconds: 60 },
    default: { maxRequests: 100, windowSeconds: 60 },
  };

  const limit = limits[endpoint] || limits.default;

  return {
    identifier,
    ...limit,
  };
};

/**
 * Create error response for rate limit exceeded
 */
export const createRateLimitErrorResponse = (result: RateLimitResult) => {
  return new Response(
    JSON.stringify({
      error: 'Rate limit exceeded',
      message: `Too many requests. Please retry after ${result.retryAfter || 60} seconds.`,
      resetAt: result.resetAt.toISOString(),
    }),
    {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': (result.retryAfter || 60).toString(),
        'X-RateLimit-Remaining': result.remainingRequests.toString(),
        'X-RateLimit-Reset': result.resetAt.toISOString(),
      },
    }
  );
};
