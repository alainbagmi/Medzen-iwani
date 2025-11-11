// EHRbase API Client
const api = {
    // Generic API call
    async call(endpoint, method = 'GET', body = null) {
        const url = `${config.baseUrl}/ehrbase/rest/openehr/v1${endpoint}`;
        const options = {
            method,
            headers: {
                'Authorization': config.getAuthHeader(),
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        };

        if (body && method !== 'GET') {
            options.body = JSON.stringify(body);
        }

        try {
            const response = await fetch(url, options);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            }
            return await response.text();
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    },

    // Get all templates
    async getTemplates() {
        return await this.call('/definition/template/adl1.4');
    },

    // Get specific template
    async getTemplate(templateId) {
        return await this.call(`/definition/template/adl1.4/${templateId}`);
    },

    // Get template example
    async getTemplateExample(templateId) {
        return await this.call(`/definition/template/adl1.4/${templateId}/example`);
    },

    // Create EHR
    async createEHR(ehrStatus = null) {
        return await this.call('/ehr', 'POST', ehrStatus ? { ehr_status: ehrStatus } : null);
    },

    // Get EHR by ID
    async getEHR(ehrId) {
        return await this.call(`/ehr/${ehrId}`);
    },

    // Get EHR by subject
    async getEHRBySubject(subjectId, subjectNamespace) {
        return await this.call(`/ehr?subject_id=${subjectId}&subject_namespace=${subjectNamespace}`);
    },

    // Create composition
    async createComposition(ehrId, composition) {
        return await this.call(`/ehr/${ehrId}/composition`, 'POST', composition);
    },

    // Get composition
    async getComposition(ehrId, compositionId) {
        return await this.call(`/ehr/${ehrId}/composition/${compositionId}`);
    },

    // Update composition
    async updateComposition(ehrId, compositionId, composition) {
        return await this.call(`/ehr/${ehrId}/composition/${compositionId}`, 'PUT', composition);
    },

    // Delete composition
    async deleteComposition(ehrId, compositionId) {
        return await this.call(`/ehr/${ehrId}/composition/${compositionId}`, 'DELETE');
    },

    // Execute AQL query
    async executeAQL(query, parameters = null) {
        const body = { q: query };
        if (parameters) {
            body.query_parameters = parameters;
        }
        return await this.call('/query/aql', 'POST', body);
    },

    // Get all EHRs (using AQL)
    async getAllEHRs(limit = 100) {
        const query = `SELECT e/ehr_id/value, e/time_created/value
                       FROM EHR e
                       LIMIT ${limit}`;
        return await this.executeAQL(query);
    },

    // Get compositions by template
    async getCompositionsByTemplate(templateId, limit = 50) {
        const query = `SELECT c/uid/value as uid,
                              c/archetype_details/template_id/value as template_id,
                              c/context/start_time/value as start_time
                       FROM EHR e
                       CONTAINS COMPOSITION c
                       WHERE c/archetype_details/template_id/value = '${templateId}'
                       LIMIT ${limit}`;
        return await this.executeAQL(query);
    },

    // Get composition count
    async getCompositionCount() {
        const query = `SELECT COUNT(c) as total
                       FROM EHR e
                       CONTAINS COMPOSITION c`;
        try {
            const result = await this.executeAQL(query);
            return result.rows && result.rows.length > 0 ? result.rows[0][0] : 0;
        } catch (error) {
            return 0;
        }
    },

    // Get EHR count
    async getEHRCount() {
        const query = `SELECT COUNT(e) as total FROM EHR e`;
        try {
            const result = await this.executeAQL(query);
            return result.rows && result.rows.length > 0 ? result.rows[0][0] : 0;
        } catch (error) {
            return 0;
        }
    }
};
