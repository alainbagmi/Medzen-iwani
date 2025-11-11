// Main Application Logic
let currentPage = 'dashboard';
let templatesData = [];
let ehrsData = [];
let compositionsData = [];

// Initialize app
document.addEventListener('DOMContentLoaded', function() {
    initNavigation();
    updateServerUrl();
    loadPage('dashboard');
    checkConnection();
});

// Initialize navigation
function initNavigation() {
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const page = this.getAttribute('data-page');
            loadPage(page);
            // Update active link
            document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
            this.classList.add('active');
        });
    });
}

// Update server URL display
function updateServerUrl() {
    document.getElementById('server-url').textContent = config.baseUrl;
}

// Load page
function loadPage(page) {
    currentPage = page;
    const template = document.getElementById(`${page}-template`);
    if (!template) {
        console.error(`Template not found: ${page}-template`);
        return;
    }

    const content = document.getElementById('page-content');
    content.innerHTML = template.innerHTML;

    // Load page-specific content
    switch(page) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'templates':
            loadTemplates();
            initTemplateSearch();
            break;
        case 'ehrs':
            loadEHRs();
            initEHRSearch();
            break;
        case 'compositions':
            loadCompositions();
            populateTemplateFilter();
            break;
        case 'aql':
            loadAQLPage();
            break;
        case 'settings':
            loadSettings();
            break;
    }
}

// Dashboard functions
async function loadDashboard() {
    try {
        // Load counts
        const templates = await api.getTemplates();
        document.getElementById('template-count').textContent = templates.length;

        const ehrCount = await api.getEHRCount();
        document.getElementById('ehr-count').textContent = ehrCount;

        const compositionCount = await api.getCompositionCount();
        document.getElementById('composition-count').textContent = compositionCount;

        document.getElementById('system-status').textContent = 'Online';
        document.getElementById('system-status').parentElement.classList.remove('bg-warning');
        document.getElementById('system-status').parentElement.classList.add('bg-success');

        // Load server info
        const serverInfo = `
            <tr><th>Server URL</th><td>${config.baseUrl}</td></tr>
            <tr><th>Username</th><td>${config.username}</td></tr>
            <tr><th>Templates</th><td>${templates.length}</td></tr>
            <tr><th>EHRs</th><td>${ehrCount}</td></tr>
            <tr><th>Compositions</th><td>${compositionCount}</td></tr>
            <tr><th>Status</th><td><span class="badge bg-success">Connected</span></td></tr>
        `;
        document.getElementById('server-info').innerHTML = serverInfo;

    } catch (error) {
        showError('Failed to load dashboard data: ' + error.message);
        document.getElementById('system-status').textContent = 'Error';
        document.getElementById('system-status').parentElement.classList.add('bg-danger');
    }
}

// Templates functions
async function loadTemplates() {
    const listElement = document.getElementById('templates-list');
    listElement.innerHTML = '<div class="col-12 text-center"><div class="spinner-border"></div></div>';

    try {
        templatesData = await api.getTemplates();
        displayTemplates(templatesData);
    } catch (error) {
        listElement.innerHTML = `<div class="col-12"><div class="alert alert-danger">Error loading templates: ${error.message}</div></div>`;
    }
}

function displayTemplates(templates) {
    const listElement = document.getElementById('templates-list');
    if (templates.length === 0) {
        listElement.innerHTML = '<div class="col-12"><div class="alert alert-info">No templates found</div></div>';
        return;
    }

    let html = '';
    templates.forEach(template => {
        html += `
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-header">
                        <h6 class="mb-0">${template.template_id || template}</h6>
                    </div>
                    <div class="card-body">
                        <p class="card-text text-muted small">
                            <i class="bi bi-calendar"></i> ${template.created_timestamp || 'Unknown'}
                        </p>
                        <div class="btn-group btn-group-sm" role="group">
                            <button class="btn btn-outline-primary" onclick="viewTemplate('${template.template_id || template}')">
                                <i class="bi bi-eye"></i> View
                            </button>
                            <button class="btn btn-outline-info" onclick="viewTemplateExample('${template.template_id || template}')">
                                <i class="bi bi-code"></i> Example
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
    });
    listElement.innerHTML = html;
}

function initTemplateSearch() {
    const searchInput = document.getElementById('template-search');
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase();
            const filtered = templatesData.filter(t => {
                const id = (t.template_id || t).toLowerCase();
                return id.includes(query);
            });
            displayTemplates(filtered);
        });
    }
}

async function viewTemplate(templateId) {
    try {
        const template = await api.getTemplate(templateId);
        showModal('Template: ' + templateId, `<pre class="bg-light p-3"><code>${JSON.stringify(template, null, 2)}</code></pre>`);
    } catch (error) {
        showError('Failed to load template: ' + error.message);
    }
}

async function viewTemplateExample(templateId) {
    try {
        const example = await api.getTemplateExample(templateId);
        showModal('Example: ' + templateId, `<pre class="bg-light p-3"><code>${JSON.stringify(example, null, 2)}</code></pre>`);
    } catch (error) {
        showError('Failed to load template example: ' + error.message);
    }
}

// EHR functions
async function loadEHRs() {
    const listElement = document.getElementById('ehrs-list');
    listElement.innerHTML = '<div class="text-center"><div class="spinner-border"></div></div>';

    try {
        const result = await api.getAllEHRs();
        ehrsData = result.rows || [];
        displayEHRs(ehrsData);
    } catch (error) {
        listElement.innerHTML = `<div class="alert alert-danger">Error loading EHRs: ${error.message}</div>`;
    }
}

function displayEHRs(ehrs) {
    const listElement = document.getElementById('ehrs-list');
    if (ehrs.length === 0) {
        listElement.innerHTML = '<div class="alert alert-info">No EHRs found</div>';
        return;
    }

    let html = '<div class="table-responsive"><table class="table table-hover"><thead><tr><th>EHR ID</th><th>Created</th><th>Actions</th></tr></thead><tbody>';
    ehrs.forEach(ehr => {
        html += `
            <tr>
                <td><code>${ehr[0]}</code></td>
                <td>${new Date(ehr[1]).toLocaleString()}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="viewEHR('${ehr[0]}')">
                        <i class="bi bi-eye"></i> View
                    </button>
                </td>
            </tr>
        `;
    });
    html += '</tbody></table></div>';
    listElement.innerHTML = html;
}

function initEHRSearch() {
    const searchInput = document.getElementById('ehr-search');
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase();
            const filtered = ehrsData.filter(ehr => {
                return ehr[0].toLowerCase().includes(query);
            });
            displayEHRs(filtered);
        });
    }
}

async function viewEHR(ehrId) {
    try {
        const ehr = await api.getEHR(ehrId);
        showModal('EHR: ' + ehrId, `<pre class="bg-light p-3"><code>${JSON.stringify(ehr, null, 2)}</code></pre>`);
    } catch (error) {
        showError('Failed to load EHR: ' + error.message);
    }
}

// Compositions functions
async function loadCompositions() {
    const listElement = document.getElementById('compositions-list');
    listElement.innerHTML = '<div class="text-center"><div class="spinner-border"></div></div>';

    const templateFilter = document.getElementById('composition-template-filter');
    const selectedTemplate = templateFilter ? templateFilter.value : '';

    try {
        if (selectedTemplate) {
            const result = await api.getCompositionsByTemplate(selectedTemplate);
            compositionsData = result.rows || [];
        } else {
            compositionsData = [];
        }
        displayCompositions(compositionsData);
    } catch (error) {
        listElement.innerHTML = `<div class="alert alert-danger">Error loading compositions: ${error.message}</div>`;
    }
}

async function populateTemplateFilter() {
    const filterElement = document.getElementById('composition-template-filter');
    if (!filterElement) return;

    try {
        const templates = await api.getTemplates();
        let html = '<option value="">Select template...</option>';
        templates.forEach(template => {
            const id = template.template_id || template;
            html += `<option value="${id}">${id}</option>`;
        });
        filterElement.innerHTML = html;

        filterElement.addEventListener('change', loadCompositions);
    } catch (error) {
        console.error('Failed to load templates:', error);
    }
}

function displayCompositions(compositions) {
    const listElement = document.getElementById('compositions-list');
    if (compositions.length === 0) {
        listElement.innerHTML = '<div class="alert alert-info">No compositions found. Select a template to view compositions.</div>';
        return;
    }

    let html = '<div class="table-responsive"><table class="table table-hover"><thead><tr><th>UID</th><th>Template</th><th>Time</th><th>Actions</th></tr></thead><tbody>';
    compositions.forEach(comp => {
        html += `
            <tr>
                <td><code>${comp[0]}</code></td>
                <td>${comp[1]}</td>
                <td>${new Date(comp[2]).toLocaleString()}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="viewComposition('${comp[0]}')">
                        <i class="bi bi-eye"></i> View
                    </button>
                </td>
            </tr>
        `;
    });
    html += '</tbody></table></div>';
    listElement.innerHTML = html;
}

async function viewComposition(compositionUid) {
    // Extract EHR ID from composition UID
    const ehrId = compositionUid.split('::')[0];
    try {
        const composition = await api.getComposition(ehrId, compositionUid);
        showModal('Composition: ' + compositionUid, `<pre class="bg-light p-3"><code>${JSON.stringify(composition, null, 2)}</code></pre>`);
    } catch (error) {
        showError('Failed to load composition: ' + error.message);
    }
}

// AQL functions
function loadAQLPage() {
    loadSampleQueries();
}

function loadSampleQueries() {
    const samples = [
        {
            name: 'Get all EHRs',
            query: 'SELECT e/ehr_id/value FROM EHR e LIMIT 10'
        },
        {
            name: 'Get all compositions',
            query: 'SELECT c/uid/value, c/archetype_details/template_id/value FROM EHR e CONTAINS COMPOSITION c LIMIT 10'
        },
        {
            name: 'Get vital signs',
            query: 'SELECT c/content[openEHR-EHR-OBSERVATION.pulse.v2]/data[at0002]/events[at0003]/data[at0001]/items[at0004]/value/magnitude as pulse FROM EHR e CONTAINS COMPOSITION c LIMIT 10'
        },
        {
            name: 'Count compositions by template',
            query: "SELECT c/archetype_details/template_id/value as template, COUNT(c) as count FROM EHR e CONTAINS COMPOSITION c GROUP BY template"
        }
    ];

    const container = document.getElementById('sample-queries');
    let html = '';
    samples.forEach(sample => {
        html += `
            <a href="#" class="list-group-item list-group-item-action" onclick="loadSampleAQLQuery('${sample.query.replace(/'/g, "\\'")}'); return false;">
                ${sample.name}
            </a>
        `;
    });
    container.innerHTML = html;
}

function loadSampleAQLQuery(query) {
    document.getElementById('aql-query').value = query;
}

function loadSampleAQL() {
    loadSampleAQLQuery('SELECT e/ehr_id/value FROM EHR e LIMIT 10');
}

async function executeAQL() {
    const query = document.getElementById('aql-query').value;
    const resultsElement = document.getElementById('aql-results');

    if (!query.trim()) {
        showError('Please enter an AQL query');
        return;
    }

    resultsElement.innerHTML = '<div class="text-center"><div class="spinner-border"></div></div>';

    try {
        const result = await api.executeAQL(query);
        displayAQLResults(result);
    } catch (error) {
        resultsElement.innerHTML = `<div class="alert alert-danger">Query Error: ${error.message}</div>`;
    }
}

function displayAQLResults(result) {
    const resultsElement = document.getElementById('aql-results');

    let html = `<div class="mb-3">
        <strong>Result Set:</strong> ${result.rows ? result.rows.length : 0} rows
    </div>`;

    if (result.rows && result.rows.length > 0) {
        html += '<div class="table-responsive"><table class="table table-sm table-striped"><thead><tr>';

        // Headers
        if (result.columns) {
            result.columns.forEach(col => {
                html += `<th>${col.name || col.path || 'Column'}</th>`;
            });
        }
        html += '</tr></thead><tbody>';

        // Rows
        result.rows.forEach(row => {
            html += '<tr>';
            row.forEach(cell => {
                const value = typeof cell === 'object' ? JSON.stringify(cell) : cell;
                html += `<td>${value || '-'}</td>`;
            });
            html += '</tr>';
        });
        html += '</tbody></table></div>';
    } else {
        html += '<div class="alert alert-info">No results found</div>';
    }

    html += `<div class="mt-3"><small class="text-muted">Full response:</small>
             <pre class="bg-light p-2 mt-2"><code>${JSON.stringify(result, null, 2)}</code></pre></div>`;

    resultsElement.innerHTML = html;
}

function exportResults() {
    const query = document.getElementById('aql-query').value;
    if (!query.trim()) {
        showError('No query to export');
        return;
    }

    api.executeAQL(query).then(result => {
        const blob = new Blob([JSON.stringify(result, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `aql-results-${Date.now()}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }).catch(error => {
        showError('Export failed: ' + error.message);
    });
}

// Settings functions
function loadSettings() {
    document.getElementById('server-url-input').value = config.baseUrl;
    document.getElementById('username-input').value = config.username;
    document.getElementById('password-input').value = config.password;

    document.getElementById('settings-form').addEventListener('submit', function(e) {
        e.preventDefault();
        const url = document.getElementById('server-url-input').value;
        const username = document.getElementById('username-input').value;
        const password = document.getElementById('password-input').value;

        config.save(url, username, password);
        updateServerUrl();
        showSuccess('Settings saved successfully');
        checkConnection();
    });
}

async function testConnection() {
    try {
        await api.getTemplates();
        showSuccess('Connection successful!');
        updateConnectionStatus(true);
    } catch (error) {
        showError('Connection failed: ' + error.message);
        updateConnectionStatus(false);
    }
}

async function checkConnection() {
    try {
        await api.getTemplates();
        updateConnectionStatus(true);
    } catch (error) {
        updateConnectionStatus(false);
    }
}

function updateConnectionStatus(connected) {
    const statusElement = document.getElementById('connection-status');
    if (connected) {
        statusElement.innerHTML = '<i class="bi bi-wifi"></i> Connected';
        statusElement.classList.remove('bg-danger');
        statusElement.classList.add('bg-success');
    } else {
        statusElement.innerHTML = '<i class="bi bi-wifi-off"></i> Disconnected';
        statusElement.classList.remove('bg-success');
        statusElement.classList.add('bg-danger');
    }
}

// Utility functions
function showModal(title, content) {
    const modalHtml = `
        <div class="modal fade" id="contentModal" tabindex="-1">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">${title}</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body" style="max-height: 70vh; overflow-y: auto;">
                        ${content}
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    `;

    // Remove existing modal if any
    const existing = document.getElementById('contentModal');
    if (existing) existing.remove();

    // Add new modal
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modal = new bootstrap.Modal(document.getElementById('contentModal'));
    modal.show();
}

function showSuccess(message) {
    showToast(message, 'success');
}

function showError(message) {
    showToast(message, 'danger');
}

function showToast(message, type = 'info') {
    const toastHtml = `
        <div class="position-fixed bottom-0 end-0 p-3" style="z-index: 11">
            <div class="toast align-items-center text-white bg-${type} border-0" role="alert">
                <div class="d-flex">
                    <div class="toast-body">${message}</div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
                </div>
            </div>
        </div>
    `;

    document.body.insertAdjacentHTML('beforeend', toastHtml);
    const toastElement = document.querySelector('.toast:last-child');
    const toast = new bootstrap.Toast(toastElement, { delay: 3000 });
    toast.show();

    toastElement.addEventListener('hidden.bs.toast', () => {
        toastElement.parentElement.remove();
    });
}
