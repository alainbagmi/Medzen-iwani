/**
 * AWS Lambda: Chime Meeting Manager
 *
 * Production-grade Lambda function for managing Amazon Chime SDK meetings.
 * Handles meeting creation, attendee management, and meeting termination.
 *
 * Actions supported:
 * - create: Create new Chime meeting
 * - join: Create attendee for existing meeting
 * - end: Terminate meeting
 *
 * Environment Variables:
 * - SUPABASE_URL: Supabase project URL
 * - SUPABASE_SERVICE_KEY: Supabase service role key
 * - DYNAMODB_TABLE: DynamoDB table name for audit logs
 */

const {
  ChimeSDKMeetingsClient,
  CreateMeetingCommand,
  CreateAttendeeCommand,
  DeleteMeetingCommand,
  GetMeetingCommand
} = require('@aws-sdk/client-chime-sdk-meetings');

// Media Pipelines for recording
const {
  ChimeSDKMediaPipelinesClient,
  CreateMediaCapturePipelineCommand,
  DeleteMediaCapturePipelineCommand
} = require('@aws-sdk/client-chime-sdk-media-pipelines');

// Transcribe for medical transcription
const {
  TranscribeClient,
  StartMedicalTranscriptionJobCommand,
  StartStreamTranscriptionCommand
} = require('@aws-sdk/client-transcribe');

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { createClient } = require('@supabase/supabase-js');

// Initialize AWS clients
const chimeClient = new ChimeSDKMeetingsClient({ region: process.env.AWS_REGION });
const mediaPipelinesClient = new ChimeSDKMediaPipelinesClient({ region: process.env.AWS_REGION });
const transcribeClient = new TranscribeClient({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const dynamoDocClient = DynamoDBDocumentClient.from(dynamoClient);

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// DynamoDB table for audit logs
const AUDIT_TABLE = process.env.DYNAMODB_TABLE || 'medzen-meeting-audit';

// S3 bucket for recordings and transcriptions
const RECORDINGS_BUCKET = process.env.RECORDINGS_BUCKET || 'medzen-chime-recordings';
const TRANSCRIPTS_BUCKET = process.env.TRANSCRIPTS_BUCKET || 'medzen-chime-transcripts';

/**
 * CORS headers for API responses
 */
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
  'Access-Control-Allow-Methods': 'OPTIONS,POST',
  'Content-Type': 'application/json'
};

/**
 * Log meeting event to DynamoDB for audit trail
 */
async function logMeetingEvent(eventType, meetingId, data) {
  try {
    const item = {
      pk: `MEETING#${meetingId}`,
      sk: `EVENT#${Date.now()}#${eventType}`,
      eventType,
      meetingId,
      timestamp: new Date().toISOString(),
      data,
      ttl: Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60) // 90 days retention
    };

    await dynamoDocClient.send(new PutCommand({
      TableName: AUDIT_TABLE,
      Item: item
    }));
  } catch (error) {
    console.error('Failed to log meeting event:', error);
    // Don't fail the request if logging fails
  }
}

/**
 * Start media capture pipeline for recording
 * @param {string} meetingId - Chime meeting ID
 * @param {string} appointmentId - Appointment ID for naming
 * @returns {Promise<Object>} Media capture pipeline details
 */
async function startRecording(meetingId, appointmentId) {
  console.log('Starting recording for meeting:', meetingId);

  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const s3KeyPrefix = `recordings/${appointmentId}/${timestamp}`;

    const createPipelineCommand = new CreateMediaCapturePipelineCommand({
      SourceType: 'ChimeSdkMeeting',
      SourceArn: `arn:aws:chime:${process.env.AWS_REGION}:${process.env.AWS_ACCOUNT_ID}:meeting/${meetingId}`,
      SinkType: 'S3Bucket',
      SinkArn: `arn:aws:s3:::${RECORDINGS_BUCKET}`,
      SinkConfiguration: {
        S3BucketSinkConfiguration: {
          Destination: `s3://${RECORDINGS_BUCKET}/${s3KeyPrefix}`
        }
      },
      ChimeSdkMeetingConfiguration: {
        ArtifactsConfiguration: {
          Audio: {
            MuxType: 'AudioWithActiveSpeakerVideo' // Audio with active speaker video
          },
          Video: {
            State: 'Enabled',
            MuxType: 'VideoOnly'
          },
          Content: {
            State: 'Enabled',
            MuxType: 'ContentOnly'
          },
          CompositedVideo: {
            Layout: 'GridView', // GridView, ActiveSpeaker, or Horizontal
            Resolution: 'HD',
            GridViewConfiguration: {
              ContentShareLayout: 'PresenterOnly'
            }
          }
        }
      }
    });

    const response = await mediaPipelinesClient.send(createPipelineCommand);
    const pipeline = response.MediaCapturePipeline;

    console.log('Recording started:', pipeline.MediaPipelineId);

    // Log to DynamoDB
    await logMeetingEvent('RECORDING_STARTED', meetingId, {
      pipelineId: pipeline.MediaPipelineId,
      s3KeyPrefix,
      bucket: RECORDINGS_BUCKET
    });

    return {
      pipelineId: pipeline.MediaPipelineId,
      s3KeyPrefix,
      bucket: RECORDINGS_BUCKET
    };
  } catch (error) {
    console.error('Error starting recording:', error);
    throw new Error(`Failed to start recording: ${error.message}`);
  }
}

/**
 * Start medical transcription for the meeting
 * @param {string} meetingId - Chime meeting ID
 * @param {string} appointmentId - Appointment ID for naming
 * @param {string} language - Language code (e.g., 'en-US')
 * @param {string} specialty - Medical specialty ('PRIMARYCARE', 'CARDIOLOGY', 'NEUROLOGY', 'ONCOLOGY', 'RADIOLOGY', 'UROLOGY')
 * @returns {Promise<Object>} Transcription job details
 */
async function startMedicalTranscription(meetingId, appointmentId, language = 'en-US', specialty = 'PRIMARYCARE') {
  console.log('Starting medical transcription for meeting:', meetingId);

  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const jobName = `medical-transcript-${appointmentId}-${timestamp}`;
    const outputKey = `transcripts/${appointmentId}/${timestamp}/medical-transcript.json`;

    // Note: For real-time transcription during the call, we'll need to use
    // StartStreamTranscriptionCommand with WebSockets
    // For now, this sets up post-call transcription from the recording

    const transcribeCommand = new StartMedicalTranscriptionJobCommand({
      MedicalTranscriptionJobName: jobName,
      LanguageCode: language,
      MediaFormat: 'mp4', // Format from Chime recording
      Media: {
        MediaFileUri: `s3://${RECORDINGS_BUCKET}/recordings/${appointmentId}/` // Will be updated with actual file
      },
      OutputBucketName: TRANSCRIPTS_BUCKET,
      OutputKey: outputKey,
      Specialty: specialty,
      Type: 'CONVERSATION', // CONVERSATION or DICTATION
      Settings: {
        ShowSpeakerLabels: true,
        MaxSpeakerLabels: 10,
        ChannelIdentification: false,
        ShowAlternatives: true,
        MaxAlternatives: 3,
        VocabularyName: process.env.MEDICAL_VOCABULARY_NAME // Custom medical vocabulary
      }
    });

    const response = await transcribeClient.send(transcribeCommand);
    const job = response.MedicalTranscriptionJob;

    console.log('Medical transcription started:', jobName);

    // Log to DynamoDB
    await logMeetingEvent('TRANSCRIPTION_STARTED', meetingId, {
      jobName,
      language,
      specialty,
      outputKey
    });

    return {
      jobName,
      status: job.TranscriptionJobStatus,
      language,
      specialty,
      outputKey
    };
  } catch (error) {
    console.error('Error starting medical transcription:', error);
    throw new Error(`Failed to start medical transcription: ${error.message}`);
  }
}

/**
 * Stop recording for a meeting
 * @param {string} pipelineId - Media pipeline ID
 * @param {string} meetingId - Meeting ID for logging
 */
async function stopRecording(pipelineId, meetingId) {
  console.log('Stopping recording:', pipelineId);

  try {
    const deleteCommand = new DeleteMediaCapturePipelineCommand({
      MediaPipelineId: pipelineId
    });

    await mediaPipelinesClient.send(deleteCommand);

    console.log('Recording stopped:', pipelineId);

    // Log to DynamoDB
    await logMeetingEvent('RECORDING_STOPPED', meetingId, {
      pipelineId
    });

    return { success: true };
  } catch (error) {
    console.error('Error stopping recording:', error);
    throw new Error(`Failed to stop recording: ${error.message}`);
  }
}

/**
 * Create a new Chime SDK meeting
 * @param {string} appointmentId - Appointment ID
 * @param {string} userId - User ID creating the meeting
 * @param {Object} options - Meeting options
 * @param {boolean} options.enableRecording - Enable automatic recording
 * @param {boolean} options.enableTranscription - Enable medical transcription
 * @param {string} options.transcriptionLanguage - Language for transcription
 * @param {string} options.medicalSpecialty - Medical specialty for transcription
 */
async function createMeeting(appointmentId, userId, options = {}) {
  console.log('Creating meeting for appointment:', appointmentId);
  console.log('Options:', options);

  // Generate unique external meeting ID
  const externalMeetingId = `appointment-${appointmentId}`;
  const {
    enableRecording = false,
    enableTranscription = false,
    transcriptionLanguage = 'en-US',
    medicalSpecialty = 'PRIMARYCARE'
  } = options;

  try {
    // Create Chime meeting with optional transcription configuration
    const createMeetingCommand = new CreateMeetingCommand({
      ClientRequestToken: `${appointmentId}-${Date.now()}`,
      ExternalMeetingId: externalMeetingId,
      MediaRegion: process.env.AWS_REGION,
      MeetingFeatures: {
        Audio: {
          EchoReduction: 'AVAILABLE'
        },
        Video: {
          MaxResolution: 'HD'
        },
        Content: {
          MaxResolution: 'FHD'
        }
      },
      NotificationsConfiguration: {
        SnsTopicArn: process.env.SNS_TOPIC_ARN,
        SqsQueueArn: process.env.SQS_QUEUE_ARN
      },
      // ✅ CRITICAL FIX: Add TranscriptionConfiguration at meeting creation
      // This enables audio routing to AWS Transcribe Medical for real-time transcription
      ...(enableTranscription && {
        TranscriptionConfiguration: {
          EngineTranscribeMedicalSettings: {
            LanguageCode: transcriptionLanguage,
            Specialty: medicalSpecialty,
            Type: 'CONVERSATION',
            VocabularyName: process.env.MEDICAL_VOCABULARY_NAME,
            ContentIdentificationType: 'PHI' // Identify Protected Health Information
          }
        }
      })
    });

    const meetingResponse = await chimeClient.send(createMeetingCommand);
    const meeting = meetingResponse.Meeting;

    console.log('Meeting created:', meeting.MeetingId);

    // Initialize result
    const result = {
      meeting,
      recording: null,
      transcription: null
    };

    // Start recording if enabled
    if (enableRecording) {
      try {
        console.log('Starting recording for meeting:', meeting.MeetingId);
        const recordingInfo = await startRecording(meeting.MeetingId, appointmentId);
        result.recording = recordingInfo;
        console.log('Recording started successfully');
      } catch (error) {
        console.error('Failed to start recording:', error);
        // Don't fail the meeting creation if recording fails
        result.recording = { error: error.message };
      }
    }

    // Start transcription if enabled
    if (enableTranscription) {
      try {
        console.log('Starting medical transcription for meeting:', meeting.MeetingId);
        const transcriptionInfo = await startMedicalTranscription(
          meeting.MeetingId,
          appointmentId,
          transcriptionLanguage,
          medicalSpecialty
        );
        result.transcription = transcriptionInfo;
        console.log('Transcription started successfully');
      } catch (error) {
        console.error('Failed to start transcription:', error);
        // Don't fail the meeting creation if transcription fails
        result.transcription = { error: error.message };
      }
    }

    // Log to DynamoDB
    await logMeetingEvent('MEETING_CREATED', meeting.MeetingId, {
      appointmentId,
      userId,
      externalMeetingId,
      mediaRegion: meeting.MediaRegion,
      recordingEnabled: enableRecording,
      transcriptionEnabled: enableTranscription,
      recordingPipelineId: result.recording?.pipelineId,
      transcriptionJobName: result.transcription?.jobName
    });

    return result;
  } catch (error) {
    console.error('Error creating meeting:', error);
    throw new Error(`Failed to create meeting: ${error.message}`);
  }
}

/**
 * Create attendee for a meeting
 */
async function createAttendee(meetingId, userId, capabilities = {}) {
  console.log('Creating attendee for meeting:', meetingId, 'user:', userId);

  try {
    // Default capabilities: full audio/video/content
    const attendeeCapabilities = {
      Audio: capabilities.audio || 'SendReceive',
      Video: capabilities.video || 'SendReceive',
      Content: capabilities.content || 'SendReceive'
    };

    const createAttendeeCommand = new CreateAttendeeCommand({
      MeetingId: meetingId,
      ExternalUserId: userId,
      Capabilities: attendeeCapabilities
    });

    const attendeeResponse = await chimeClient.send(createAttendeeCommand);
    const attendee = attendeeResponse.Attendee;

    console.log('Attendee created:', attendee.AttendeeId);

    // Log to DynamoDB
    await logMeetingEvent('ATTENDEE_CREATED', meetingId, {
      attendeeId: attendee.AttendeeId,
      userId,
      capabilities: attendeeCapabilities
    });

    return attendee;
  } catch (error) {
    console.error('Error creating attendee:', error);
    throw new Error(`Failed to create attendee: ${error.message}`);
  }
}

/**
 * End a meeting
 */
async function endMeeting(meetingId) {
  console.log('Ending meeting:', meetingId);

  try {
    const deleteMeetingCommand = new DeleteMeetingCommand({
      MeetingId: meetingId
    });

    await chimeClient.send(deleteMeetingCommand);

    console.log('Meeting ended:', meetingId);

    // Log to DynamoDB
    await logMeetingEvent('MEETING_ENDED', meetingId, {
      endedAt: new Date().toISOString()
    });

    return { success: true };
  } catch (error) {
    console.error('Error ending meeting:', error);
    throw new Error(`Failed to end meeting: ${error.message}`);
  }
}

/**
 * Get meeting details
 */
async function getMeeting(meetingId) {
  console.log('Getting meeting:', meetingId);

  try {
    const getMeetingCommand = new GetMeetingCommand({
      MeetingId: meetingId
    });

    const response = await chimeClient.send(getMeetingCommand);
    return response.Meeting;
  } catch (error) {
    if (error.name === 'NotFoundException') {
      return null;
    }
    console.error('Error getting meeting:', error);
    throw new Error(`Failed to get meeting: ${error.message}`);
  }
}

/**
 * Lambda handler
 */
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  // Handle CORS preflight
  if (event.httpMethod === 'OPTIONS' || event.requestContext?.http?.method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ message: 'OK' })
    };
  }

  try {
    // Parse request body
    let body;
    try {
      if (typeof event.body === 'string') {
        body = JSON.parse(event.body);
      } else if (event.body) {
        body = event.body;
      } else {
        // Handle direct invocation where payload is in event itself
        body = event;
      }
    } catch (parseError) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Invalid JSON in request body' })
      };
    }

    const {
      action,
      appointmentId,
      meetingId,
      userId,
      capabilities,
      enableRecording,
      enableTranscription,
      transcriptionLanguage,
      medicalSpecialty,
      pipelineId
    } = body;

    // Validate required fields
    if (!action) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Missing action parameter' })
      };
    }

    // Handle different actions
    switch (action) {
      case 'create': {
        if (!appointmentId || !userId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Missing appointmentId or userId' })
          };
        }

        // Create meeting with optional recording and transcription
        const meetingResult = await createMeeting(appointmentId, userId, {
          enableRecording,
          enableTranscription,
          transcriptionLanguage,
          medicalSpecialty
        });

        // Create first attendee (creator)
        const attendee = await createAttendee(meetingResult.meeting.MeetingId, userId, capabilities);

        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({
            meeting: meetingResult.meeting,
            attendee,
            recording: meetingResult.recording,
            transcription: meetingResult.transcription
          })
        };
      }

      case 'join': {
        if (!meetingId || !userId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Missing meetingId or userId' })
          };
        }

        // Verify meeting exists
        const meeting = await getMeeting(meetingId);
        if (!meeting) {
          return {
            statusCode: 404,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Meeting not found or ended' })
          };
        }

        // Create attendee
        const attendee = await createAttendee(meetingId, userId, capabilities);

        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({
            meeting,
            attendee
          })
        };
      }

      case 'end': {
        if (!meetingId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Missing meetingId' })
          };
        }

        // Stop recording if pipeline ID provided
        if (pipelineId) {
          try {
            await stopRecording(pipelineId, meetingId);
          } catch (error) {
            console.error('Failed to stop recording:', error);
            // Continue with meeting deletion even if recording stop fails
          }
        }

        await endMeeting(meetingId);

        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({ message: 'Meeting ended successfully' })
        };
      }

      case 'start-recording': {
        if (!meetingId || !appointmentId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Missing meetingId or appointmentId' })
          };
        }

        const recordingInfo = await startRecording(meetingId, appointmentId);

        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify(recordingInfo)
        };
      }

      case 'stop-recording': {
        if (!pipelineId || !meetingId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Missing pipelineId or meetingId' })
          };
        }

        await stopRecording(pipelineId, meetingId);

        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({ message: 'Recording stopped successfully' })
        };
      }

      case 'start-transcription': {
        if (!meetingId || !appointmentId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Missing meetingId or appointmentId' })
          };
        }

        const transcriptionInfo = await startMedicalTranscription(
          meetingId,
          appointmentId,
          transcriptionLanguage,
          medicalSpecialty
        );

        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify(transcriptionInfo)
        };
      }

      default:
        return {
          statusCode: 400,
          headers: corsHeaders,
          body: JSON.stringify({ error: `Unknown action: ${action}` })
        };
    }
  } catch (error) {
    console.error('Lambda error:', error);

    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message
      })
    };
  }
};
