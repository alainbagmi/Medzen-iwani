// HIPAA/GDPR Input Validation Framework
// Prevents SQL injection, XSS, and invalid data entry

/**
 * Validation patterns for common MedZen data types
 */
export const ValidationPatterns = {
  uuid: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
  email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  phone: /^\+?[1-9]\d{1,14}$/,
  firebaseUid: /^[A-Za-z0-9]{20,128}$/,
  userRole: /^(patient|medical_provider|facility_admin|system_admin)$/,
  appointmentStatus: /^(scheduled|confirmed|in_progress|completed|cancelled|rescheduled)$/,
  medicalCode: /^[A-Z0-9]{1,10}$/, // ICD-10, CPT codes
  phoneE164: /^\+[1-9]\d{1,14}$/,
  httpUrl: /^https?:\/\/.+/,
};

/**
 * Sanitize string input to prevent XSS
 */
export const sanitizeString = (input: unknown, maxLength = 10000): string => {
  if (typeof input !== 'string') {
    return '';
  }

  const trimmed = input.trim().slice(0, maxLength);

  // Remove potentially dangerous characters but allow common text
  return trimmed
    .replace(/[<>]/g, '') // Remove angle brackets
    .replace(/javascript:/gi, '') // Remove javascript: protocol
    .replace(/on\w+=/gi, ''); // Remove event handlers like onclick=
};

/**
 * Sanitize HTML entities
 */
export const sanitizeHTML = (input: string): string => {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;');
};

/**
 * Validate UUID format
 */
export const validateUUID = (value: unknown): boolean => {
  return typeof value === 'string' && ValidationPatterns.uuid.test(value);
};

/**
 * Validate email format
 */
export const validateEmail = (value: unknown): boolean => {
  return typeof value === 'string' && ValidationPatterns.email.test(value);
};

/**
 * Validate phone number format (E.164)
 */
export const validatePhone = (value: unknown): boolean => {
  return typeof value === 'string' && ValidationPatterns.phoneE164.test(value);
};

/**
 * Validate Firebase UID
 */
export const validateFirebaseUid = (value: unknown): boolean => {
  return typeof value === 'string' && ValidationPatterns.firebaseUid.test(value);
};

/**
 * Validate user role
 */
export const validateUserRole = (value: unknown): boolean => {
  return typeof value === 'string' && ValidationPatterns.userRole.test(value);
};

/**
 * Validate appointment ID
 */
export const validateAppointmentId = (value: unknown): boolean => {
  return validateUUID(value);
};

/**
 * Validate clinical note data
 */
export const validateClinicalNote = (data: unknown): {
  valid: boolean;
  errors: string[];
} => {
  const errors: string[] = [];

  if (!data || typeof data !== 'object') {
    errors.push('Clinical note must be an object');
    return { valid: false, errors };
  }

  const note = data as any;

  // Validate required fields
  if (!validateUUID(note.appointment_id)) {
    errors.push('Invalid appointment_id (must be UUID)');
  }

  if (!validateUUID(note.patient_id)) {
    errors.push('Invalid patient_id (must be UUID)');
  }

  // Validate note content
  if (typeof note.subjective !== 'string' || note.subjective.length === 0) {
    errors.push('Subjective must be non-empty string');
  } else if (note.subjective.length > 5000) {
    errors.push('Subjective exceeds 5000 characters');
  }

  if (typeof note.objective !== 'string' || note.objective.length === 0) {
    errors.push('Objective must be non-empty string');
  } else if (note.objective.length > 5000) {
    errors.push('Objective exceeds 5000 characters');
  }

  if (typeof note.assessment !== 'string' || note.assessment.length === 0) {
    errors.push('Assessment must be non-empty string');
  } else if (note.assessment.length > 3000) {
    errors.push('Assessment exceeds 3000 characters');
  }

  if (typeof note.plan !== 'string' || note.plan.length === 0) {
    errors.push('Plan must be non-empty string');
  } else if (note.plan.length > 3000) {
    errors.push('Plan exceeds 3000 characters');
  }

  if (typeof note.provider_signature !== 'string' || note.provider_signature.length === 0) {
    errors.push('Provider signature required');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Validate SOAP draft data
 */
export const validateSoapDraft = (data: unknown): {
  valid: boolean;
  errors: string[];
} => {
  const errors: string[] = [];

  if (!data || typeof data !== 'object') {
    errors.push('SOAP draft must be an object');
    return { valid: false, errors };
  }

  const draft = data as any;

  if (!validateUUID(draft.contextSnapshotId)) {
    errors.push('Invalid contextSnapshotId (must be UUID)');
  }

  if (!Array.isArray(draft.transcriptChunks)) {
    errors.push('transcriptChunks must be array');
  } else {
    for (let i = 0; i < draft.transcriptChunks.length; i++) {
      const chunk = draft.transcriptChunks[i];

      if (typeof chunk.speaker !== 'string' || chunk.speaker.length === 0) {
        errors.push(`Chunk ${i}: speaker required`);
      }

      if (typeof chunk.text !== 'string' || chunk.text.length === 0) {
        errors.push(`Chunk ${i}: text required`);
      }

      if (typeof chunk.timestamp !== 'number' || chunk.timestamp < 0) {
        errors.push(`Chunk ${i}: timestamp must be non-negative number`);
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Validate video call data
 */
export const validateVideoCallRequest = (data: unknown): {
  valid: boolean;
  errors: string[];
} => {
  const errors: string[] = [];

  if (!data || typeof data !== 'object') {
    errors.push('Video call request must be an object');
    return { valid: false, errors };
  }

  const request = data as any;

  if (!validateUUID(request.appointmentId)) {
    errors.push('Invalid appointmentId');
  }

  if (request.action && !['start', 'join', 'end', 'status'].includes(request.action)) {
    errors.push('Invalid action');
  }

  if (request.recordingEnabled && typeof request.recordingEnabled !== 'boolean') {
    errors.push('recordingEnabled must be boolean');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Generic validator that returns proper error response
 */
export const createValidationErrorResponse = (errors: string[]) => {
  return new Response(
    JSON.stringify({
      error: 'Validation failed',
      details: errors,
      code: 'INVALID_INPUT',
    }),
    {
      status: 400,
      headers: {
        'Content-Type': 'application/json',
      },
    }
  );
};
