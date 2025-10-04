#!/bin/bash

API_URL="${API_URL:-http://localhost:3001}"
TOKEN="${JWT_TOKEN:-test-token}"

echo "🧪 Quick Test Script"
echo ""

echo "1. Checking service health..."
curl -s $API_URL/health | jq
echo ""

echo "2. Generating test Excel file..."
node scripts/generate-test-mmr.js 50 /tmp/test-mmr.xlsx
FILE_SIZE=$(stat -f%z /tmp/test-mmr.xlsx 2>/dev/null || stat -c%s /tmp/test-mmr.xlsx)
echo ""

echo "3. Submitting processing job..."
RESPONSE=$(curl -s -X POST $API_URL/api/mmr/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"fileName\": \"test-mmr.xlsx\",
    \"filePath\": \"/tmp/test-mmr.xlsx\",
    \"fileSize\": $FILE_SIZE,
    \"uploadId\": \"test-$(date +%s)\"
  }")

JOB_ID=$(echo $RESPONSE | jq -r '.jobId')
echo "Job ID: $JOB_ID"
echo ""

echo "4. Monitoring job (30 seconds max)..."
for i in {1..15}; do
  sleep 2
  JOB_STATUS=$(curl -s $API_URL/api/mmr/jobs/$JOB_ID -H "Authorization: Bearer $TOKEN")
  STATUS=$(echo $JOB_STATUS | jq -r '.status')
  PROGRESS=$(echo $JOB_STATUS | jq -r '.progress.percentage')
  echo "  Status: $STATUS | Progress: $PROGRESS%"
  
  if [ "$STATUS" = "completed" ]; then
    echo ""
    echo "✅ Job completed successfully!"
    echo ""
    echo "Results:"
    echo $JOB_STATUS | jq '.result.metadata'
    break
  fi
done

rm -f /tmp/test-mmr.xlsx
