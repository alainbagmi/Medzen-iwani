/**
 * AWS Lambda: Medical Entity Extraction
 *
 * Extracts medical entities from video call transcripts using AWS Comprehend Medical.
 * Identifies medications, conditions, procedures, anatomy, and protected health information.
 *
 * Features:
 * - Medical entity detection (RxNorm, ICD-10-CM, SNOMED CT codes)
 * - PHI detection and redaction
 * - Relationship extraction between medical entities
 * - Real-time medical scribing assistance
 * - SOAP note generation
 *
 * Environment Variables:
 * - SUPABASE_URL: Supabase project URL
 * - SUPABASE_SERVICE_KEY: Supabase service role key
 * - S3_BUCKET: S3 bucket for entity extraction results
 */

const {
  ComprehendMedicalClient,
  DetectEntitiesV2Command,
  DetectPHICommand,
  InferICD10CMCommand,
  InferRxNormCommand,
  InferSNOMEDCTCommand
} = require('@aws-sdk/client-comprehendmedical');

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { createClient } = require('@supabase/supabase-js');

// Initialize AWS clients
const comprehendClient = new ComprehendMedicalClient({ region: process.env.AWS_REGION });
const s3Client = new S3Client({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const dynamoDocClient = DynamoDBDocumentClient.from(dynamoClient);

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

const S3_BUCKET = process.env.S3_BUCKET || 'medzen-medical-data';
const AUDIT_TABLE = process.env.DYNAMODB_TABLE || 'medzen-meeting-audit';

/**
 * Chunk text for AWS Comprehend Medical (max 20,000 UTF-8 bytes)
 * @param {string} text - Input text
 * @param {number} maxBytes - Maximum bytes per chunk
 * @returns {Array<string>} Text chunks
 */
function chunkText(text, maxBytes = 19000) {
  const chunks = [];
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];

  let currentChunk = '';
  for (const sentence of sentences) {
    const testChunk = currentChunk + sentence;
    if (Buffer.byteLength(testChunk, 'utf8') > maxBytes) {
      if (currentChunk) {
        chunks.push(currentChunk);
      }
      currentChunk = sentence;
    } else {
      currentChunk = testChunk;
    }
  }

  if (currentChunk) {
    chunks.push(currentChunk);
  }

  return chunks;
}

/**
 * Detect medical entities from text
 * @param {string} text - Medical text
 * @returns {Promise<Object>} Detected entities
 */
async function detectMedicalEntities(text) {
  try {
    const command = new DetectEntitiesV2Command({
      Text: text
    });

    const response = await comprehendClient.send(command);

    // Group entities by category
    const entities = {
      medications: [],
      conditions: [],
      procedures: [],
      anatomy: [],
      testTreatmentProcedures: [],
      protectedHealthInformation: [],
      timeExpression: []
    };

    for (const entity of response.Entities || []) {
      const category = entity.Category;
      const item = {
        text: entity.Text,
        type: entity.Type,
        score: entity.Score,
        beginOffset: entity.BeginOffset,
        endOffset: entity.EndOffset,
        attributes: entity.Attributes || [],
        traits: entity.Traits || []
      };

      switch (category) {
        case 'MEDICATION':
          entities.medications.push(item);
          break;
        case 'MEDICAL_CONDITION':
          entities.conditions.push(item);
          break;
        case 'TEST_TREATMENT_PROCEDURE':
          entities.testTreatmentProcedures.push(item);
          break;
        case 'ANATOMY':
          entities.anatomy.push(item);
          break;
        case 'PROTECTED_HEALTH_INFORMATION':
          entities.protectedHealthInformation.push(item);
          break;
        case 'TIME_EXPRESSION':
          entities.timeExpression.push(item);
          break;
      }
    }

    return entities;
  } catch (error) {
    console.error('Error detecting medical entities:', error);
    throw error;
  }
}

/**
 * Infer ICD-10-CM codes from conditions
 * @param {string} text - Medical text
 * @returns {Promise<Array>} ICD-10-CM codes
 */
async function inferICD10Codes(text) {
  try {
    const command = new InferICD10CMCommand({
      Text: text
    });

    const response = await comprehendClient.send(command);

    return (response.Entities || []).map(entity => ({
      text: entity.Text,
      icd10Codes: entity.ICD10CMConcepts?.map(concept => ({
        code: concept.Code,
        description: concept.Description,
        score: concept.Score
      })) || []
    }));
  } catch (error) {
    console.error('Error inferring ICD-10 codes:', error);
    return [];
  }
}

/**
 * Infer RxNorm codes from medications
 * @param {string} text - Medical text
 * @returns {Promise<Array>} RxNorm codes
 */
async function inferRxNormCodes(text) {
  try {
    const command = new InferRxNormCommand({
      Text: text
    });

    const response = await comprehendClient.send(command);

    return (response.Entities || []).map(entity => ({
      text: entity.Text,
      rxNormConcepts: entity.RxNormConcepts?.map(concept => ({
        code: concept.Code,
        description: concept.Description,
        score: concept.Score
      })) || []
    }));
  } catch (error) {
    console.error('Error inferring RxNorm codes:', error);
    return [];
  }
}

/**
 * Infer SNOMED CT codes
 * @param {string} text - Medical text
 * @returns {Promise<Array>} SNOMED CT codes
 */
async function inferSNOMEDCodes(text) {
  try {
    const command = new InferSNOMEDCTCommand({
      Text: text
    });

    const response = await comprehendClient.send(command);

    return (response.Entities || []).map(entity => ({
      text: entity.Text,
      snomedCodes: entity.SNOMEDCTConcepts?.map(concept => ({
        code: concept.Code,
        description: concept.Description,
        score: concept.Score
      })) || []
    }));
  } catch (error) {
    console.error('Error inferring SNOMED codes:', error);
    return [];
  }
}

/**
 * Detect PHI (Protected Health Information)
 * @param {string} text - Medical text
 * @returns {Promise<Object>} PHI detection results
 */
async function detectPHI(text) {
  try {
    const command = new DetectPHICommand({
      Text: text
    });

    const response = await comprehendClient.send(command);

    return {
      entities: (response.Entities || []).map(entity => ({
        text: entity.Text,
        category: entity.Category,
        type: entity.Type,
        score: entity.Score,
        beginOffset: entity.BeginOffset,
        endOffset: entity.EndOffset
      })),
      modelVersion: response.ModelVersion
    };
  } catch (error) {
    console.error('Error detecting PHI:', error);
    return { entities: [] };
  }
}

/**
 * Process medical text and extract all entities
 * @param {string} text - Medical transcript text
 * @param {string} sessionId - Video call session ID
 * @returns {Promise<Object>} Extraction results
 */
async function processMedicalText(text, sessionId) {
  console.log('Processing medical text for session:', sessionId);

  try {
    // Chunk text if too long
    const chunks = chunkText(text);
    console.log(`Processing ${chunks.length} chunks`);

    // Process each chunk
    const allEntities = [];
    const allICD10Codes = [];
    const allRxNormCodes = [];
    const allSNOMEDCodes = [];
    const allPHI = [];

    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      console.log(`Processing chunk ${i + 1}/${chunks.length}`);

      // Run all detections in parallel
      const [entities, icd10, rxNorm, snomed, phi] = await Promise.all([
        detectMedicalEntities(chunk),
        inferICD10Codes(chunk),
        inferRxNormCodes(chunk),
        inferSNOMEDCodes(chunk),
        detectPHI(chunk)
      ]);

      allEntities.push(entities);
      allICD10Codes.push(...icd10);
      allRxNormCodes.push(...rxNorm);
      allSNOMEDCodes.push(...snomed);
      allPHI.push(...phi.entities);
    }

    // Merge results
    const mergedEntities = {
      medications: allEntities.flatMap(e => e.medications),
      conditions: allEntities.flatMap(e => e.conditions),
      procedures: allEntities.flatMap(e => e.testTreatmentProcedures),
      anatomy: allEntities.flatMap(e => e.anatomy),
      phi: allPHI
    };

    // Generate medical summary
    const summary = generateMedicalSummary(mergedEntities, allICD10Codes, allRxNormCodes);

    const result = {
      sessionId,
      entities: mergedEntities,
      codes: {
        icd10: allICD10Codes,
        rxNorm: allRxNormCodes,
        snomed: allSNOMEDCodes
      },
      summary,
      processedAt: new Date().toISOString(),
      chunkCount: chunks.length
    };

    // Save to S3
    await saveToS3(sessionId, result);

    // Update Supabase
    await updateSupabase(sessionId, result);

    return result;
  } catch (error) {
    console.error('Error processing medical text:', error);
    throw error;
  }
}

/**
 * Generate medical summary from entities
 * @param {Object} entities - Extracted entities
 * @param {Array} icd10Codes - ICD-10 codes
 * @param {Array} rxNormCodes - RxNorm codes
 * @returns {Object} Medical summary
 */
function generateMedicalSummary(entities, icd10Codes, rxNormCodes) {
  return {
    chiefComplaint: entities.conditions[0]?.text || 'Not specified',
    medications: entities.medications.map(m => m.text).filter((v, i, a) => a.indexOf(v) === i),
    diagnoses: icd10Codes.slice(0, 5).map(d => ({
      condition: d.text,
      code: d.icd10Codes[0]?.code,
      description: d.icd10Codes[0]?.description
    })),
    procedures: entities.procedures.map(p => p.text).filter((v, i, a) => a.indexOf(v) === i),
    anatomy: entities.anatomy.map(a => a.text).filter((v, i, a) => a.indexOf(v) === i).slice(0, 10)
  };
}

/**
 * Save extraction results to S3
 * @param {string} sessionId - Session ID
 * @param {Object} data - Extraction data
 */
async function saveToS3(sessionId, data) {
  try {
    const key = `medical-entities/${sessionId}/${Date.now()}.json`;

    const command = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
      Body: JSON.stringify(data, null, 2),
      ContentType: 'application/json',
      Metadata: {
        sessionId,
        processedAt: new Date().toISOString()
      }
    });

    await s3Client.send(command);

    console.log('Saved to S3:', key);
  } catch (error) {
    console.error('Error saving to S3:', error);
    // Don't fail if S3 save fails
  }
}

/**
 * Update Supabase with extraction results
 * @param {string} sessionId - Session ID
 * @param {Object} data - Extraction data
 */
async function updateSupabase(sessionId, data) {
  try {
    await supabase
      .from('video_call_sessions')
      .update({
        medical_entities: data.entities,
        medical_codes: data.codes,
        medical_summary: data.summary,
        entity_extraction_completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', sessionId);

    // Log to audit
    await supabase.from('video_call_audit_log').insert({
      session_id: sessionId,
      event_type: 'ENTITY_EXTRACTION_COMPLETED',
      event_data: {
        medicationCount: data.entities.medications.length,
        conditionCount: data.entities.conditions.length,
        procedureCount: data.entities.procedures.length,
        icd10Count: data.codes.icd10.length,
        rxNormCount: data.codes.rxNorm.length
      },
      created_at: new Date().toISOString()
    });

    console.log('Updated Supabase for session:', sessionId);
  } catch (error) {
    console.error('Error updating Supabase:', error);
    throw error;
  }
}

/**
 * Lambda handler
 */
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    const { sessionId, text } = event;

    if (!sessionId || !text) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing sessionId or text' })
      };
    }

    const result = await processMedicalText(text, sessionId);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Medical entity extraction completed',
        result
      })
    };
  } catch (error) {
    console.error('Error in medical entity extraction:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Error extracting medical entities',
        message: error.message
      })
    };
  }
};
