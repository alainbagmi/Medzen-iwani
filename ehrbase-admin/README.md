# EHRbase Admin Dashboard

A comprehensive web-based management interface for EHRbase OpenEHR Clinical Data Repository.

## Features

- **Dashboard**: System overview with real-time statistics
- **Template Management**: Browse, view, and search OpenEHR templates
- **EHR Browser**: List and view Electronic Health Records
- **Composition Viewer**: Browse compositions by template
- **AQL Query Console**: Execute custom AQL queries with syntax examples
- **System Monitoring**: Connection status and server information
- **Responsive Design**: Works on desktop, tablet, and mobile devices

## Quick Start

### Prerequisites

- Kubernetes cluster with EHRbase deployed
- `kubectl` access to the cluster
- SSH access to Kubernetes master node
- Docker installed on Kubernetes nodes

### Deployment

1. **Navigate to the ehrbase-admin directory:**
   ```bash
   cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin
   ```

2. **Run the deployment script:**
   ```bash
   ./build-and-deploy.sh
   ```

3. **Access the dashboard:**
   - Open browser to: `http://10.10.10.101:30090`
   - Or use any of the Kubernetes node IPs: 102, 103, 104, 105, 106

## Default Configuration

The dashboard comes pre-configured with:

- **Server URL**: `https://ehr.medzenhealth.app`
- **Username**: `ehrbase-user`
- **Password**: `ehrbase-password`

You can change these settings in the **Settings** page of the dashboard.

## Architecture

### Components

1. **Frontend**: Single-page application (HTML/CSS/JavaScript)
2. **Web Server**: Nginx Alpine (lightweight, ~23MB image)
3. **Deployment**: 2 replicas for high availability
4. **Service**: NodePort on port 30090

### Technology Stack

- **Framework**: Vanilla JavaScript (no dependencies)
- **UI**: Bootstrap 5.3
- **Icons**: Bootstrap Icons 1.11
- **API Client**: Fetch API with Basic Authentication
- **Storage**: LocalStorage for settings persistence

## Features Guide

### Dashboard

- **System Statistics**: Real-time counts of templates, EHRs, and compositions
- **Server Information**: Connection details and status
- **Quick Actions**: Direct links to common tasks
- **Connection Status**: Real-time monitoring indicator

### Templates

- **Browse**: View all available OpenEHR templates
- **Search**: Filter templates by template ID
- **View**: Inspect complete template definitions
- **Example**: Generate example compositions for templates

### EHRs

- **List**: View all Electronic Health Records
- **Search**: Filter EHRs by ID or subject
- **View**: Inspect EHR details and metadata

### Compositions

- **Filter by Template**: View compositions for specific templates
- **Filter by EHR**: Search compositions by EHR ID
- **View**: Inspect complete composition data

### AQL Console

- **Query Editor**: Write custom AQL queries
- **Sample Queries**: Pre-built query examples
- **Results View**: Tabular display of query results
- **Export**: Download results as JSON

### Settings

- **Server Configuration**: Set EHRbase URL and credentials
- **Connection Test**: Verify connection to EHRbase server
- **Persistent Storage**: Settings saved in browser localStorage

## API Integration

The dashboard uses the EHRbase REST API endpoints:

- **Templates**: `/ehrbase/rest/openehr/v1/definition/template/adl1.4`
- **EHRs**: `/ehrbase/rest/openehr/v1/ehr`
- **Compositions**: `/ehrbase/rest/openehr/v1/ehr/{ehrId}/composition`
- **AQL Queries**: `/ehrbase/rest/openehr/v1/query/aql`

### Authentication

- **Method**: HTTP Basic Authentication
- **Header**: `Authorization: Basic <base64(username:password)>`

### CORS

The dashboard makes direct API calls from the browser. Ensure EHRbase has CORS enabled for your domain, or access the dashboard from the same domain as EHRbase.

## Deployment Details

### Kubernetes Resources

**Deployment** (`ehrbase-admin-ui`):
- **Replicas**: 2
- **Namespace**: `ehrbase`
- **Image**: `ehrbase-admin-ui:latest`
- **Resources**:
  - Requests: 50m CPU, 64Mi Memory
  - Limits: 200m CPU, 128Mi Memory
- **Health Checks**: Liveness and readiness probes on `/health`

**Service** (`ehrbase-admin-ui`):
- **Type**: NodePort
- **Port**: 80 (internal)
- **NodePort**: 30090 (external)
- **Selector**: `app=ehrbase-admin-ui`

### Manual Deployment

If you prefer to deploy manually:

1. **Build Docker image:**
   ```bash
   docker build -t ehrbase-admin-ui:latest .
   ```

2. **Apply Kubernetes manifests:**
   ```bash
   kubectl apply -f kubernetes/deployment.yaml
   ```

3. **Verify deployment:**
   ```bash
   kubectl get pods -n ehrbase -l app=ehrbase-admin-ui
   kubectl get svc -n ehrbase ehrbase-admin-ui
   ```

## Troubleshooting

### Cannot Access Dashboard

1. Check pod status:
   ```bash
   kubectl get pods -n ehrbase -l app=ehrbase-admin-ui
   ```

2. Check logs:
   ```bash
   kubectl logs -n ehrbase -l app=ehrbase-admin-ui
   ```

3. Check service:
   ```bash
   kubectl get svc -n ehrbase ehrbase-admin-ui
   kubectl describe svc -n ehrbase ehrbase-admin-ui
   ```

### Connection to EHRbase Failed

1. Verify EHRbase is running:
   ```bash
   kubectl get pods -n ehrbase -l app=ehrbase
   ```

2. Test EHRbase API directly:
   ```bash
   curl -u ehrbase-user:ehrbase-password \
     https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4
   ```

3. Check settings in dashboard **Settings** page
4. Verify credentials are correct
5. Check browser console for CORS errors

### Slow Performance

1. Check resource usage:
   ```bash
   kubectl top pods -n ehrbase
   ```

2. Scale up replicas if needed:
   ```bash
   kubectl scale deployment ehrbase-admin-ui -n ehrbase --replicas=3
   ```

3. Check network latency to EHRbase server

## Development

### Local Development

1. **Start a local web server:**
   ```bash
   cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin
   python3 -m http.server 8080
   ```

2. **Open browser:**
   ```
   http://localhost:8080
   ```

3. **Configure settings:**
   - Go to Settings page
   - Set EHRbase URL, username, password
   - Save settings

### File Structure

```
ehrbase-admin/
├── index.html           # Main HTML file
├── css/
│   └── style.css        # Custom styles
├── js/
│   ├── config.js        # Configuration management
│   ├── api.js           # EHRbase API client
│   └── app.js           # Main application logic
├── Dockerfile           # Docker image definition
├── nginx.conf           # Nginx configuration
├── kubernetes/
│   └── deployment.yaml  # Kubernetes manifests
├── build-and-deploy.sh  # Deployment script
└── README.md            # This file
```

### Customization

#### Changing Colors/Branding

Edit `css/style.css`:
```css
:root {
    --primary-color: #0d6efd;    /* Change primary color */
    --success-color: #198754;    /* Change success color */
    /* ... */
}
```

#### Adding Custom Queries

Edit `js/app.js`, function `loadSampleQueries()`:
```javascript
const samples = [
    {
        name: 'My Custom Query',
        query: 'SELECT ... FROM ...'
    },
    // ... add more
];
```

#### Changing NodePort

Edit `kubernetes/deployment.yaml`:
```yaml
spec:
  ports:
  - nodePort: 30090  # Change to desired port
```

## Security Considerations

1. **Credentials Storage**: Credentials are stored in browser localStorage
   - Not suitable for production if shared computers are used
   - Consider implementing server-side session management

2. **HTTPS**: The dashboard itself uses HTTP
   - Should be served behind HTTPS reverse proxy in production
   - Configure Cloudflare or ingress controller with TLS

3. **Authentication**: Uses Basic Auth to EHRbase
   - Credentials transmitted in Authorization header
   - Ensure EHRbase is accessed via HTTPS only

4. **CORS**: Direct browser-to-EHRbase API calls
   - May expose EHRbase API to cross-origin requests
   - Consider implementing backend proxy for production

## Production Recommendations

1. **HTTPS**: Serve dashboard via HTTPS
2. **Ingress**: Use Ingress controller instead of NodePort
3. **Authentication**: Implement proper authentication layer
4. **Secrets**: Use Kubernetes secrets for EHRbase credentials
5. **Monitoring**: Add Prometheus metrics and Grafana dashboards
6. **Logging**: Configure structured logging to centralized system
7. **Backup**: Regular backups of configuration and customizations

## Version

**Version**: 1.0.0
**Release Date**: 2025-10-28
**Compatibility**: EHRbase 2.x, OpenEHR RM 1.0.4

## License

This dashboard is provided as-is for managing EHRbase installations. Modify and distribute freely.

## Support

For issues and questions:
- EHRbase Documentation: https://docs.ehrbase.org
- OpenEHR Specifications: https://specifications.openehr.org
- AQL Documentation: https://specifications.openehr.org/releases/QUERY/latest/AQL.html

## Acknowledgments

- Built for MedZen-Iwani healthcare application
- Uses EHRbase OpenEHR server
- Follows OpenEHR specifications
- Bootstrap UI framework
- Bootstrap Icons
