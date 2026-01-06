import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { S3Client } from "https://esm.sh/@aws-sdk/client-s3@3.400.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Environment variable access
    const awsAccessKeyId = Deno.env.get("AWS_ACCESS_KEY_ID")!;
    const awsSecretAccessKey = Deno.env.get("AWS_SECRET_ACCESS_KEY")!;
    const awsRegion = Deno.env.get("AWS_REGION") || "eu-west-1";

    // Validate required environment variables
    if (!awsAccessKeyId || !awsSecretAccessKey) {
      throw new Error("Missing AWS credentials");
    }

    // Test ONLY S3Client (no createClient)
    const s3Client = new S3Client({
      region: awsRegion,
      credentials: {
        accessKeyId: awsAccessKeyId,
        secretAccessKey: awsSecretAccessKey,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: "test-imports-s3-only executed successfully - S3 client initialized OK"
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    );
  }
});
