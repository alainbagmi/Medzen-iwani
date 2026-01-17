/**
 * AWS Lambda: Chime Transcription Processor
 *
 * Processes medical transcription for Chime meeting recordings using AWS Transcribe Medical.
 * Triggered by recording processor Lambda after a recording is saved.
 *
 * Features:
 * - Medical transcription with speaker identification
 * - Custom medical vocabulary support
 * - Real-time progress tracking
 * - Medical entity extraction integration
 * - HIPAA-compliant transcription
 *
 * Environment Variables:
 * - SUPABASE_URL: Supabase project URL
 * - SUPABASE_SERVICE_KEY: Supabase service role key
 * - TRANSCRIPTS_BUCKET: S3 bucket for transcripts
 * - MEDICAL_VOCABULARY_NAME: Custom medical vocabulary name
 * - COMPREHEND_MEDICAL_FUNCTION_ARN: ARN of medical entity extraction Lambda
 */

const {
  TranscribeClient,
  StartMedicalTranscriptionJobCommand,
  GetMedicalTranscriptionJobCommand
} = require('@aws-sdk/client-transcribe');

const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { LambdaClient, InvokeCommand } = require('@aws-sdk/client-lambda');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { createClient } = require('@supabase/supabase-js');

// Initialize AWS clients
const transcribeClient = new TranscribeClient({ region: process.env.AWS_REGION });
const s3Client = new S3Client({ region: process.env.AWS_REGION });
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const dynamoDocClient = DynamoDBDocumentClient.from(dynamoClient);

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Configuration
const TRANSCRIPTS_BUCKET = process.env.TRANSCRIPTS_BUCKET || 'medzen-chime-transcripts';
const AUDIT_TABLE = process.env.DYNAMODB_TABLE || 'medzen-meeting-audit';

/**
 * Start medical transcription job
 * @param {Object} params - Transcription parameters
 * @returns {Promise<Object>} Transcription job info
 */
async function startMedicalTranscription(params) {
  const {
    bucket,
    key,
    appointmentId,
    sessionId,
    language = 'en-US',
    specialty = 'PRIMARYCARE'
  } = params;

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const jobName = `medical-transcript-${appointmentId}-${timestamp}`;
  const outputKey = `transcripts/${appointmentId}/${timestamp}/medical-transcript.json`;

  console.log('Starting medical transcription job:', jobName);

  try {
    const command = new StartMedicalTranscriptionJobCommand({
      MedicalTranscriptionJobName: jobName,
      LanguageCode: language,
      MediaFormat: key.split('.').pop().toLowerCase(), // mp4, mp3, wav, etc.
      Media: {
        MediaFileUri: `s3://${bucket}/${key}`
      },
      OutputBucketName: TRANSCRIPTS_BUCKET,
      OutputKey: outputKey,
      Specialty: specialty, // PRIMARYCARE, CARDIOLOGY, NEUROLOGY, ONCOLOGY, RADIOLOGY, UROLOGY
      Type: 'CONVERSATION', // CONVERSATION or DICTATION
      Settings: {
        ShowSpeakerLabels: true,
        MaxSpeakerLabels: 10, // Max speakers in the conversation
        ChannelIdentification: false,
        ShowAlternatives: true, // Show alternative transcriptions
        MaxAlternatives: 3,
        VocabularyName: process.env.MEDICAL_VOCABULARY_NAME || undefined
      }
    });

    const response = await transcribeClient.send(command);
    const job = response.MedicalTranscriptionJob;

    console.log('Transcription job started:', {
      jobName,
      status: job.TranscriptionJobStatus,
      outputKey
    });

    // Update Supabase with job info
    await supabase
      .from('video_call_sessions')
      .update({
        transcription_job_name: jobName,
        transcription_status: job.TranscriptionJobStatus,
        transcription_output_key: outputKey,
        updated_at: new Date().toISOString()
      })
      .eq('id', sessionId);

    // Log to audit
    await supabase.from('video_call_audit_log').insert({
      session_id: sessionId,
      event_type: 'TRANSCRIPTION_STARTED',
      event_data: {
        jobName,
        language,
        specialty,
        outputKey
      },
      created_at: new Date().toISOString()
    });

    return {
      jobName,
      status: job.TranscriptionJobStatus,
      outputKey,
      sessionId
    };
  } catch (error) {
    console.error('Error starting transcription:', error);

    // Update Supabase with error
    await supabase
      .from('video_call_sessions')
      .update({
        transcription_status: 'FAILED',
        transcription_error: error.message,
        updated_at: new Date().toISOString()
      })
      .eq('id', sessionId);

    throw error;
  }
}

/**
 * Check transcription job status
 * @param {string} jobName - Transcription job name
 * @returns {Promise<Object>} Job status and results
 */
async function checkTranscriptionStatus(jobName) {
  try {
    const command = new GetMedicalTranscriptionJobCommand({
      MedicalTranscriptionJobName: jobName
    });

    const response = await transcribeClient.send(command);
    const job = response.MedicalTranscriptionJob;

    return {
      status: job.TranscriptionJobStatus,
      transcriptUri: job.Transcript?.TranscriptFileUri,
      failureReason: job.FailureReason,
      createdAt: job.CreationTime,
      completedAt: job.CompletionTime,
      mediaFormat: job.MediaFormat,
      languageCode: job.LanguageCode,
      specialty: job.Specialty
    };
  } catch (error) {
    console.error('Error checking transcription status:', error);
    throw error;
  }
}

/**
 * Download and parse transcript from S3
 * @param {string} transcriptUri - S3 URI of transcript
 * @returns {Promise<Object>} Parsed transcript
 */
async function getTranscript(transcriptUri) {
  try {
    // Extract bucket and key from S3 URI
    const match = transcriptUri.match(/s3:\/\/([^/]+)\/(.*)/);
    if (!match) {
      throw new Error('Invalid S3 URI');
    }

    const [, bucket, key] = match;

    const command = new GetObjectCommand({
      Bucket: bucket,
      Key: key
    });

    const response = await s3Client.send(command);
    const body = await response.Body.transformToString();
    const transcript = JSON.parse(body);

    return transcript;
  } catch (error) {
    console.error('Error getting transcript:', error);
    throw error;
  }
}

/**
 * Process completed transcription
 * @param {string} jobName - Transcription job name
 * @param {string} sessionId - Video call session ID
 * @returns {Promise<Object>} Processing result
 */
async function processCompletedTranscription(jobName, sessionId) {
  try {
    // Get job status
    const jobStatus = await checkTranscriptionStatus(jobName);

    if (jobStatus.status !== 'COMPLETED') {
      console.log('Transcription not completed yet:', jobStatus.status);
      return { status: jobStatus.status };
    }

    // Download transcript
    const transcript = await getTranscript(jobStatus.transcriptUri);

    // Extract text and speaker segments
    const fullText = transcript.results?.transcripts?.[0]?.transcript || '';
    const speakerSegments = extractSpeakerSegments(transcript);

    // Update Supabase
    await supabase
      .from('video_call_sessions')
      .update({
        transcript: fullText,
        transcription_status: 'COMPLETED',
        speaker_segments: speakerSegments,
        transcription_completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', sessionId);

    // Log to audit
    await supabase.from('video_call_audit_log').insert({
      session_id: sessionId,
      event_type: 'TRANSCRIPTION_COMPLETED',
      event_data: {
        jobName,
        wordCount: fullText.split(/\s+/).length,
        speakerCount: speakerSegments?.length || 0
      },
      created_at: new Date().toISOString()
    });

    // Trigger medical entity extraction if configured
    if (process.env.COMPREHEND_MEDICAL_FUNCTION_ARN) {
      await triggerMedicalEntityExtraction(sessionId, fullText);
    }

    return {
      status: 'COMPLETED',
      transcript: fullText,
      speakerSegments,
      wordCount: fullText.split(/\s+/).length
    };
  } catch (error) {
    console.error('Error processing completed transcription:', error);

    // Update Supabase with error
    await supabase
      .from('video_call_sessions')
      .update({
        transcription_status: 'FAILED',
        transcription_error: error.message,
        updated_at: new Date().toISOString()
      })
      .eq('id', sessionId);

    throw error;
  }
}

/**
 * Extract speaker segments from transcript
 * @param {Object} transcript - Raw transcript from Transcribe
 * @returns {Array} Speaker segments
 */
function extractSpeakerSegments(transcript) {
  try {
    const segments = transcript.results?.speaker_labels?.segments || [];

    return segments.map(segment => ({
      speaker: segment.speaker_label,
      startTime: parseFloat(segment.start_time),
      endTime: parseFloat(segment.end_time),
      items: segment.items?.map(item => ({
        startTime: parseFloat(item.start_time),
        endTime: parseFloat(item.end_time),
        content: transcript.results?.items?.find(
          i => i.start_time === item.start_time
        )?.alternatives?.[0]?.content || ''
      })) || []
    }));
  } catch (error) {
    console.error('Error extracting speaker segments:', error);
    return [];
  }
}

/**
 * Trigger medical entity extraction using AWS Comprehend Medical
 * @param {string} sessionId - Video call session ID
 * @param {string} text - Transcript text
 */
async function triggerMedicalEntityExtraction(sessionId, text) {
  try {
    const payload = {
      sessionId,
      text,
      timestamp: new Date().toISOString()
    };

    const command = new InvokeCommand({
      FunctionName: process.env.COMPREHEND_MEDICAL_FUNCTION_ARN,
      InvocationType: 'Event', // Async invocation
      Payload: JSON.stringify(payload)
    });

    await lambdaClient.send(command);

    console.log('Medical entity extraction triggered for session:', sessionId);
  } catch (error) {
    console.error('Error triggering medical entity extraction:', error);
    // Don't fail the process if entity extraction fails
  }
}

/**
 * Lambda handler
 */
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    // Handle direct invocation (from recording processor)
    if (event.bucket && event.key) {
      const result = await startMedicalTranscription(event);
      return {
        statusCode: 200,
        body: JSON.stringify(result)
      };
    }

    // Handle EventBridge scheduled check (poll for completed jobs)
    if (event.source === 'aws.events') {
      // Get all in-progress transcription jobs
      const { data: sessions } = await supabase
        .from('video_call_sessions')
        .select('id, transcription_job_name')
        .eq('transcription_status', 'IN_PROGRESS')
        .limit(100);

      const results = [];
      for (const session of sessions || []) {
        const result = await processCompletedTranscription(
          session.transcription_job_name,
          session.id
        );
        results.push({ sessionId: session.id, ...result });
      }

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'Transcription status check complete',
          processed: results.length,
          results
        })
      };
    }

    // Handle SNS notification from Transcribe (if configured)
    if (event.Records && event.Records[0].Sns) {
      const message = JSON.parse(event.Records[0].Sns.Message);
      const jobName = message.TranscriptionJobName;

      // Get session from database
      const { data: session } = await supabase
        .from('video_call_sessions')
        .select('id')
        .eq('transcription_job_name', jobName)
        .single();

      if (session) {
        const result = await processCompletedTranscription(jobName, session.id);
        return {
          statusCode: 200,
          body: JSON.stringify(result)
        };
      }
    }

    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid event format' })
    };
  } catch (error) {
    console.error('Error in transcription processor:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Error processing transcription',
        message: error.message
      })
    };
  }
};
