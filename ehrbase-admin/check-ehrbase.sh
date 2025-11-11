#!/bin/bash

# EHRbase Health Check Script

echo "========================================="
echo "EHRbase Server Health Check"
echo "========================================="
echo ""

EHRBASE_URL="https://ehr.medzenhealth.app"
USERNAME="ehrbase-user"
PASSWORD="ehrbase-password"

echo "Server: $EHRBASE_URL"
echo ""

# Function to test endpoint
test_endpoint() {
    local path=$1
    local description=$2

    echo -n "Testing: $description ... "

    response=$(curl -s -w "\n%{http_code}" -u "$USERNAME:$PASSWORD" "$EHRBASE_URL$path" 2>/dev/null)
    status_code=$(echo "$response" | tail -n1)

    if [ "$status_code" = "200" ]; then
        echo "✓ OK (200)"
    elif [ "$status_code" = "401" ]; then
        echo "❌ Unauthorized (401) - Check credentials"
    elif [ "$status_code" = "404" ]; then
        echo "❌ Not Found (404)"
    elif [ "$status_code" = "000" ]; then
        echo "❌ Cannot connect to server"
    else
        echo "⚠️  HTTP $status_code"
    fi
}

echo "1. Checking EHRbase Endpoints:"
echo ""

# Test root
test_endpoint "" "Root URL"

# Test EHRbase REST API paths
test_endpoint "/ehrbase/rest/openehr/v1/definition/template/adl1.4" "Templates List API"
test_endpoint "/ehrbase/rest/openehr/v1/ehr" "EHR API"
test_endpoint "/ehrbase/rest/openehr/v1/query/aql" "AQL Query API (POST)"

echo ""
echo "2. Checking if EHRbase is running in Kubernetes:"
echo ""
echo "Run this command on the cluster:"
echo "  kubectl get pods -n ehrbase -l app=ehrbase"
echo "  kubectl get svc -n ehrbase ehrbase"
echo ""

echo "3. Expected EHRbase pod status:"
echo "  - Should have 3 pods running (ehrbase-0, ehrbase-1, ehrbase-2)"
echo "  - Status should be 'Running' with 1/1 ready"
echo ""

echo "4. Expected EHRbase service:"
echo "  - Type: ClusterIP or LoadBalancer"
echo "  - Port: 8080"
echo ""

echo "========================================="
echo "Troubleshooting Steps"
echo "========================================="
echo ""

if curl -s -u "$USERNAME:$PASSWORD" "$EHRBASE_URL/ehrbase/rest/openehr/v1/definition/template/adl1.4" &>/dev/null; then
    echo "✓ EHRbase API is accessible"
    echo ""
    echo "Templates available:"
    curl -s -u "$USERNAME:$PASSWORD" "$EHRBASE_URL/ehrbase/rest/openehr/v1/definition/template/adl1.4" | python3 -m json.tool 2>/dev/null || echo "  (Response is not JSON or empty)"
else
    echo "❌ Cannot access EHRbase API"
    echo ""
    echo "Possible issues:"
    echo ""
    echo "  1. EHRbase pods are not running:"
    echo "     kubectl get pods -n ehrbase -l app=ehrbase"
    echo "     kubectl logs -n ehrbase ehrbase-0"
    echo ""
    echo "  2. EHRbase service is not exposed correctly:"
    echo "     kubectl get svc -n ehrbase"
    echo "     kubectl describe svc -n ehrbase ehrbase"
    echo ""
    echo "  3. Ingress/DNS is misconfigured:"
    echo "     kubectl get ingress -n ehrbase"
    echo "     Check Cloudflare DNS settings for ehr.medzenhealth.app"
    echo ""
    echo "  4. Wrong credentials:"
    echo "     Current: $USERNAME / $PASSWORD"
    echo "     Check: kubectl get secret -n ehrbase"
    echo ""
    echo "  5. Database connection issues:"
    echo "     kubectl logs -n ehrbase ehrbase-0 | grep -i error"
    echo "     Check PostgreSQL is running and accessible"
    echo ""
fi

echo "========================================="
echo "Correct URL Patterns"
echo "========================================="
echo ""
echo "❌ Wrong:  https://ehr.medzenhealth.app"
echo "✓ Correct: https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4"
echo ""
echo "The root URL / will return 404."
echo "You must access specific API endpoints under /ehrbase/rest/openehr/v1/"
echo ""
