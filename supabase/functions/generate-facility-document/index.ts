import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { PDFDocument, PDFPage, rgb } from 'https://esm.sh/pdfkit@0.13.0';
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';

interface FacilityData {
  id: string;
  name: string;
  facility_type: string;
  address: string;
  city: string;
  province: string;
  country: string;
  phone: string;
  email: string;
  registration_number: string;
  license_number?: string;
  operational_since?: string;
  [key: string]: any;
}

interface PrefilledResponse {
  success: boolean;
  error?: string;
  status?: number;
  document?: {
    id: string;
    documentBase64?: string;
    title: string;
    version: number;
    status: string;
    aiConfidence: number;
    aiFlags?: any;
    createdAt: string;
  };
}

serve(async (req): Promise<Response> => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200 });
  }

  try {
    // 1. Extract Firebase token
    const firebaseToken = req.headers.get('x-firebase-token');
    if (!firebaseToken) {
      return new Response(
        JSON.stringify({ error: 'Missing Firebase token', code: 'NO_AUTH_TOKEN', status: 401 }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 2. Verify authentication
    const auth = await verifyFirebaseJWT(firebaseToken);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 3. Parse request
    const { facilityId, templatePath, documentType } = await req.json();
    if (!facilityId || !templatePath) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters', code: 'INVALID_REQUEST', status: 400 }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[generate-facility-document] User ${auth.uid} generating document for facility ${facilityId}`);

    // 4. Initialize Supabase Admin Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // 5. Verify user is facility admin for this facility
    const { data: adminProfile } = await supabaseAdmin
      .from('facility_admin_profiles')
      .select('primary_facility_id, managed_facilities')
      .eq('user_id', auth.uid)
      .single();

    const hasAccess =
      adminProfile?.primary_facility_id === facilityId ||
      adminProfile?.managed_facilities?.includes(facilityId);

    if (!hasAccess) {
      console.warn(`[generate-facility-document] User ${auth.uid} lacks access to facility ${facilityId}`);
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions', code: 'INSUFFICIENT_PERMISSIONS', status: 403 }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 6. Fetch facility data (comprehensive)
    const { data: facility, error: facilityError } = await supabaseAdmin
      .from('facilities')
      .select('*')
      .eq('id', facilityId)
      .single();

    if (facilityError || !facility) {
      console.error(`[generate-facility-document] Facility not found:`, facilityError);
      return new Response(
        JSON.stringify({ error: 'Facility not found', code: 'FACILITY_NOT_FOUND', status: 404 }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[generate-facility-document] Fetched facility: ${facility.name}`);

    // 7. Download PDF template from public MiniSanteTemplate bucket
    console.log(`[generate-facility-document] Downloading template: ${templatePath}`);
    const { data: templateFile, error: downloadError } = await supabaseAdmin
      .storage
      .from('MiniSanteTemplate')
      .download(templatePath);

    if (downloadError || !templateFile) {
      console.error(`[generate-facility-document] Template download error:`, downloadError);
      return new Response(
        JSON.stringify({ error: 'Template not found', code: 'TEMPLATE_NOT_FOUND', status: 404 }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 8. Convert PDF to base64
    const templateBytes = await templateFile.arrayBuffer();
    const templateBase64 = btoa(String.fromCharCode(...new Uint8Array(templateBytes)));

    // 9. Call AWS Bedrock Lambda to analyze PDF and determine field mappings
    console.log(`[generate-facility-document] Calling Bedrock to analyze PDF structure`);
    const bedrockLambdaUrl = Deno.env.get('BEDROCK_LAMBDA_URL');
    if (!bedrockLambdaUrl) {
      console.error('[generate-facility-document] BEDROCK_LAMBDA_URL not configured');
      return new Response(
        JSON.stringify({ error: 'AI service unavailable', code: 'BEDROCK_UNAVAILABLE', status: 503 }),
        { status: 503, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const bedrockPrompt = `You are a healthcare facility document specialist analyzing a PDF template.

TASK: Analyze this PDF form and determine which facility data should fill which fields.

FACILITY DATA:
${JSON.stringify({
  name: facility.name,
  facility_type: facility.facility_type,
  address: facility.address,
  city: facility.city,
  province: facility.province,
  country: facility.country,
  phone: facility.phone,
  email: facility.email,
  registration_number: facility.registration_number,
  license_number: facility.license_number || 'Not provided',
  operational_since: facility.operational_since || 'Not provided',
}, null, 2)}

PDF DOCUMENT TYPE: ${documentType || 'General facility form'}

INSTRUCTIONS:
1. Analyze the PDF template structure
2. Identify key fields (text fields, checkboxes, tables)
3. Map facility data to each field
4. Return JSON with field fill instructions

RESPONSE FORMAT (valid JSON only):
{
  "fields": [
    {"name": "facility_name", "value": "${facility.name}", "page": 1, "x": 100, "y": 200, "type": "text"},
    {"name": "facility_address", "value": "${facility.address}, ${facility.city}", "page": 1, "x": 100, "y": 220, "type": "text"}
  ],
  "missingFields": [],
  "overallConfidence": 0.85,
  "notes": "PDF structure analyzed successfully"
}

Respond ONLY with valid JSON.`;

    const bedrockResponse = await fetch(bedrockLambdaUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'anthropic.claude-3-5-sonnet-20241022-v2:0',
        prompt: bedrockPrompt,
        pdfBase64: templateBase64,
        maxTokens: 2048,
        temperature: 0.3,
      }),
    });

    if (!bedrockResponse.ok) {
      console.error(`[generate-facility-document] Bedrock error: ${bedrockResponse.status}`);
      return new Response(
        JSON.stringify({ error: 'AI analysis failed', code: 'AI_ANALYSIS_FAILED', status: 500 }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const aiResult = await bedrockResponse.json();
    console.log(`[generate-facility-document] Bedrock analysis confidence: ${aiResult.overallConfidence}`);

    // 10. For MVP: Return base64 PDF + metadata without actual field filling
    // (Actual PDF field filling would require additional libraries or a separate service)
    // The user will verify the data in the preview and we'll fill on client-side or manually

    // 11. Calculate next version number
    const { data: existingDocs } = await supabaseAdmin
      .from('facility_generated_documents')
      .select('version')
      .eq('facility_id', facilityId)
      .eq('document_type', documentType || 'general')
      .order('version', { ascending: false })
      .limit(1);

    const nextVersion = (existingDocs?.[0]?.version || 0) + 1;

    // 12. Generate title
    const dateStr = new Date().toLocaleDateString();
    const title = `${documentType || 'Document'} - ${facility.name} - ${dateStr}`;

    // 13. Insert draft database record
    const { data: document, error: dbError } = await supabaseAdmin
      .from('facility_generated_documents')
      .insert({
        facility_id: facilityId,
        document_type: documentType || 'general',
        template_path: templatePath,
        title: title,
        version: nextVersion,
        status: 'preview',
        ai_prefill_data: {
          facility: facility,
          fieldsToFill: aiResult.fields || [],
        },
        ai_confidence_score: aiResult.overallConfidence || 0.85,
        ai_flags: aiResult.missingFields || [],
        generated_by: auth.uid,
        generated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (dbError) {
      console.error('[generate-facility-document] Database error:', dbError);
      return new Response(
        JSON.stringify({ error: 'Failed to save document record', code: 'DB_INSERT_FAILED', status: 500 }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[generate-facility-document] Document created: ${document.id}`);

    // 14. Return success response with base64 PDF for preview
    const response: PrefilledResponse = {
      success: true,
      document: {
        id: document.id,
        documentBase64: templateBase64, // Return template as-is for MVP; user verifies in preview
        title: document.title,
        version: document.version,
        status: document.status,
        aiConfidence: document.ai_confidence_score,
        aiFlags: document.ai_flags,
        createdAt: document.created_at,
      },
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('[generate-facility-document] Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        code: 'INTERNAL_ERROR',
        status: 500,
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
