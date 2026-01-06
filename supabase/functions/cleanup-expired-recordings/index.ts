import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { S3Client, DeleteObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.400.0";

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
    // Get environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const awsAccessKeyId = Deno.env.get("AWS_ACCESS_KEY_ID")!;
    const awsSecretAccessKey = Deno.env.get("AWS_SECRET_ACCESS_KEY")!;
    const awsRegion = Deno.env.get("AWS_REGION") || "eu-west-1";

    // Validate required environment variables
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase credentials");
    }
    if (!awsAccessKeyId || !awsSecretAccessKey) {
      throw new Error("Missing AWS credentials. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Initialize S3 client
    const s3Client = new S3Client({
      region: awsRegion,
      credentials: {
        accessKeyId: awsAccessKeyId,
        secretAccessKey: awsSecretAccessKey,
      },
    });

    // Get recordings past retention date that aren't deleted
    // Using the helper function from the migration for consistent logic
    const { data: expiredRecordings, error: queryError } = await supabase
      .from("medical_recording_metadata")
      .select("id, recording_bucket, recording_key, session_id, retention_until")
      .lte("retention_until", new Date().toISOString())
      .eq("deletion_scheduled", false)
      .is("deleted_at", null)
      .limit(100); // Process in batches to avoid timeout

    if (queryError) {
      console.error("Error querying expired recordings:", queryError);
      throw queryError;
    }

    if (!expiredRecordings || expiredRecordings.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No expired recordings to delete",
          count: 0,
          timestamp: new Date().toISOString()
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Found ${expiredRecordings.length} expired recordings to process`);

    const results = {
      total: expiredRecordings.length,
      deleted: 0,
      failed: 0,
      errors: [] as string[],
    };

    // Delete from S3 and mark as deleted in database
    for (const recording of expiredRecordings) {
      try {
        console.log(`Processing recording ${recording.id} from bucket ${recording.recording_bucket}`);

        // Delete from S3
        const deleteCommand = new DeleteObjectCommand({
          Bucket: recording.recording_bucket,
          Key: recording.recording_key,
        });

        await s3Client.send(deleteCommand);
        console.log(`Deleted S3 object: s3://${recording.recording_bucket}/${recording.recording_key}`);

        // Mark as deleted in database (soft delete for audit trail)
        const { error: updateError } = await supabase
          .from("medical_recording_metadata")
          .update({
            deletion_scheduled: true,
            deleted_at: new Date().toISOString(),
          })
          .eq("id", recording.id);

        if (updateError) {
          console.error(`Error updating metadata for ${recording.id}:`, updateError);
          throw updateError;
        }

        // Log deletion to audit trail
        const { error: auditError } = await supabase
          .from("video_call_audit_log")
          .insert({
            session_id: recording.session_id,
            event_type: "RECORDING_DELETED",
            event_data: {
              recording_id: recording.id,
              bucket: recording.recording_bucket,
              key: recording.recording_key,
              retention_until: recording.retention_until,
              reason: "HIPAA retention period expired (7 years)",
              deleted_by: "automated-cleanup",
            },
            created_at: new Date().toISOString(),
          });

        if (auditError) {
          console.error(`Error creating audit log for ${recording.id}:`, auditError);
          // Don't fail the entire operation if audit log fails
        }

        results.deleted++;
        console.log(`Successfully deleted recording ${recording.id}`);
      } catch (error) {
        results.failed++;
        const errorMessage = `Failed to delete ${recording.id}: ${error.message}`;
        results.errors.push(errorMessage);
        console.error(errorMessage, error);

        // Continue processing other recordings even if one fails
        continue;
      }
    }

    const response = {
      success: true,
      message: `Processed ${results.total} expired recordings`,
      results: {
        total: results.total,
        deleted: results.deleted,
        failed: results.failed,
        errors: results.errors,
      },
      timestamp: new Date().toISOString(),
    };

    console.log("Cleanup completed:", JSON.stringify(response, null, 2));

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in cleanup-expired-recordings:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
        timestamp: new Date().toISOString()
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
