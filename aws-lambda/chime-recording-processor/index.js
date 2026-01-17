/**
 * AWS Lambda: Chime Recording Processor
 *
 * Processes completed Chime meeting recordings from S3.
 * Triggered by S3 ObjectCreated events when recordings are saved.
 *
 * Features:
 * - Extracts recording metadata
 * - Updates Supabase database
 * - Triggers medical transcription
 * - Sends notification webhooks
 *
 * Environment Variables:
 * - SUPABASE_URL: Supabase project URL
 * - SUPABASE_SERVICE_KEY: Supabase service role key
 * - TRANSCRIBE_FUNCTION_ARN: ARN of transcription Lambda
 * - WEBHOOK_URL: Optional webhook for notifications
 */

const { S3Client, HeadObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { LambdaClient, InvokeCommand } = require('@aws-sdk/client-lambda');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { createClient } = require('@supabase/supabase-js');

// Initialize AWS clients
const s3Client = new S3Client({ region: process.env.AWS_REGION });
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const dynamoDocClient = DynamoDBDocumentClient.from(dynamoClient);

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// DynamoDB table for audit logs
const AUDIT_TABLE = process.env.DYNAMODB_TABLE || 'medzen-meeting-audit';

/**
 * Extract appointment ID from S3 key
 * @param {string} s3Key - S3 object key (e.g., "recordings/appt-123/2025-01-15/video.mp4")
 * @returns {string|null} Appointment ID
 */
function extractAppointmentId(s3Key) {
  const match = s3Key.match(/recordings\/([^/]+)\//);
  return match ? match[1] : null;
}

/**
 * Get recording metadata from S3
 * @param {string} bucket - S3 bucket name
 * @param {string} key - S3 object key
 * @returns {Promise<Object>} Recording metadata
 */
async function getRecordingMetadata(bucket, key) {
  try {
    const headCommand = new HeadObjectCommand({
      Bucket: bucket,
      Key: key
    });

    const response = await s3Client.send(headCommand);

    return {
      size: response.ContentLength,
      contentType: response.ContentType,
      lastModified: response.LastModified,
      metadata: response.Metadata || {},
      duration: response.Metadata?.duration ? parseInt(response.Metadata.duration) : null
    };
  } catch (error) {
    console.error('Error getting recording metadata:', error);
    throw error;
  }
}

/**
 * Update Supabase with recording information
 * @param {string} appointmentId - Appointment ID
 * @param {Object} recordingData - Recording data
 * @returns {Promise<Object>} Updated session
 */
async function updateVideoCallSession(appointmentId, recordingData) {
  try {
    // Get the video call session
    const { data: session, error: sessionError } = await supabase
      .from('video_call_sessions')
      .select('id, meeting_id, appointment_id')
      .eq('appointment_id', appointmentId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (sessionError || !session) {
      console.error('Session not found:', sessionError);
      throw new Error(`Video call session not found for appointment: ${appointmentId}`);
    }

    // Update session with recording info
    const { data: updatedSession, error: updateError } = await supabase
      .from('video_call_sessions')
      .update({
        recording_url: recordingData.url,
        recording_bucket: recordingData.bucket,
        recording_key: recordingData.key,
        recording_file_size: recordingData.size,
        recording_duration_seconds: recordingData.duration,
        recording_format: recordingData.format,
        recording_completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', session.id)
      .select()
      .single();

    if (updateError) {
      console.error('Error updating session:', updateError);
      throw updateError;
    }

    // Log to audit trail
    await supabase.from('video_call_audit_log').insert({
      session_id: session.id,
      event_type: 'RECORDING_COMPLETED',
      event_data: {
        recordingUrl: recordingData.url,
        fileSize: recordingData.size,
        duration: recordingData.duration
      },
      created_at: new Date().toISOString()
    });

    return updatedSession;
  } catch (error) {
    console.error('Error updating video call session:', error);
    throw error;
  }
}

/**
 * Trigger medical transcription Lambda
 * @param {string} bucket - S3 bucket name
 * @param {string} key - S3 object key
 * @param {Object} session - Video call session data
 * @returns {Promise<Object>} Transcription job info
 */
async function triggerTranscription(bucket, key, session) {
  try {
    if (!process.env.TRANSCRIBE_FUNCTION_ARN) {
      console.log('TRANSCRIBE_FUNCTION_ARN not set, skipping transcription');
      return null;
    }

    // Only trigger if transcription was enabled for this session
    if (!session.transcription_enabled) {
      console.log('Transcription not enabled for this session');
      return null;
    }

    const payload = {
      bucket,
      key,
      sessionId: session.id,
      appointmentId: session.appointment_id,
      meetingId: session.meeting_id,
      language: session.transcription_language || 'en-US',
      specialty: session.medical_specialty || 'PRIMARYCARE'
    };

    const invokeCommand = new InvokeCommand({
      FunctionName: process.env.TRANSCRIBE_FUNCTION_ARN,
      InvocationType: 'Event', // Async invocation
      Payload: JSON.stringify(payload)
    });

    await lambdaClient.send(invokeCommand);

    console.log('Transcription Lambda triggered');

    return {
      status: 'triggered',
      functionArn: process.env.TRANSCRIBE_FUNCTION_ARN
    };
  } catch (error) {
    console.error('Error triggering transcription:', error);
    // Don't fail the whole process if transcription fails
    return { status: 'error', error: error.message };
  }
}

/**
 * Send webhook notification
 * @param {Object} data - Notification data
 */
async function sendWebhookNotification(data) {
  try {
    if (!process.env.WEBHOOK_URL) {
      return;
    }

    const response = await fetch(process.env.WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        event: 'recording_completed',
        timestamp: new Date().toISOString(),
        data
      })
    });

    if (!response.ok) {
      console.error('Webhook notification failed:', response.status);
    }
  } catch (error) {
    console.error('Error sending webhook notification:', error);
    // Don't fail the process if webhook fails
  }
}

/**
 * Log event to DynamoDB
 */
async function logEvent(eventType, data) {
  try {
    await dynamoDocClient.send(new PutCommand({
      TableName: AUDIT_TABLE,
      Item: {
        pk: `RECORDING#${data.appointmentId}`,
        sk: `EVENT#${Date.now()}#${eventType}`,
        eventType,
        timestamp: new Date().toISOString(),
        data,
        ttl: Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60) // 90 days
      }
    }));
  } catch (error) {
    console.error('Failed to log event:', error);
  }
}

/**
 * Lambda handler
 */
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    // Process each S3 record
    const results = [];

    for (const record of event.Records) {
      // Extract S3 information
      const bucket = record.s3.bucket.name;
      const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
      const size = record.s3.object.size;

      console.log('Processing recording:', { bucket, key, size });

      // Extract appointment ID from S3 key
      const appointmentId = extractAppointmentId(key);
      if (!appointmentId) {
        console.error('Could not extract appointment ID from S3 key:', key);
        continue;
      }

      // Get recording metadata
      const metadata = await getRecordingMetadata(bucket, key);

      // Determine format from key
      const format = key.split('.').pop().toLowerCase();

      // Build recording URL (S3 presigned URL or CloudFront URL)
      const recordingUrl = `https://${bucket}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;

      const recordingData = {
        url: recordingUrl,
        bucket,
        key,
        size,
        duration: metadata.duration,
        format,
        contentType: metadata.contentType
      };

      // Update Supabase
      const session = await updateVideoCallSession(appointmentId, recordingData);

      // Trigger transcription if enabled
      const transcriptionResult = await triggerTranscription(bucket, key, session);

      // Send webhook notification
      await sendWebhookNotification({
        appointmentId,
        sessionId: session.id,
        meetingId: session.meeting_id,
        recordingUrl,
        size,
        duration: metadata.duration,
        transcriptionTriggered: transcriptionResult?.status === 'triggered'
      });

      // Log to DynamoDB
      await logEvent('RECORDING_PROCESSED', {
        appointmentId,
        bucket,
        key,
        size,
        transcriptionStatus: transcriptionResult?.status
      });

      results.push({
        appointmentId,
        status: 'success',
        recordingUrl,
        transcriptionTriggered: transcriptionResult?.status === 'triggered'
      });

      console.log('Recording processed successfully:', appointmentId);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Recordings processed successfully',
        results
      })
    };
  } catch (error) {
    console.error('Error processing recordings:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing recordings',
        error: error.message
      })
    };
  }
};
