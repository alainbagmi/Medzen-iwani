#!/bin/bash

EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

SUCCESS=0
FAILED=0
SKIPPED=0

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Uploading Templates to AWS EHRbase              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

for opt_file in opt-templates/*.opt; do
    filename=$(basename "$opt_file")
    echo -n "Uploading: $filename ... "
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$EHRBASE_URL" \
        -H "Content-Type: application/xml" \
        -u "$EHRBASE_USER:$EHRBASE_PASS" \
        --data-binary "@$opt_file" 2>&1)
    
    http_code=$(echo "$response" | tail -1)
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        echo "✅ Success"
        SUCCESS=$((SUCCESS + 1))
    elif [ "$http_code" = "409" ]; then
        echo "⏭️  Already exists"
        SKIPPED=$((SKIPPED + 1))
    else
        echo "❌ Failed (HTTP $http_code)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Upload Summary                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Successfully uploaded: $SUCCESS"
echo "⏭️  Already existed:      $SKIPPED"
echo "❌ Failed:                $FAILED"
echo "📊 Total processed:       $((SUCCESS + SKIPPED + FAILED))"
echo ""
