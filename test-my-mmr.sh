#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./test-my-mmr.sh <path-to-excel-file>"
  echo "Example: ./test-my-mmr.sh test-files/my-mmr.xlsx"
  exit 1
fi

FILE_PATH="$1"

if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File not found: $FILE_PATH"
  echo ""
  echo "Files in test-files directory:"
  ls -la test-files/
  exit 1
fi

# Get absolute path
FILE_PATH=$(realpath "$FILE_PATH")
FILE_SIZE=$(stat -c%s "$FILE_PATH")
FILE_NAME=$(basename "$FILE_PATH")

echo "📊 Processing MMR File"
echo "  File: $FILE_NAME"
echo "  Size: $(echo "scale=2; $FILE_SIZE/1024" | bc) KB"
echo ""

# Submit job
RESPONSE=$(curl -s -X POST http://localhost:3001/api/mmr/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d "{
    \"fileName\": \"$FILE_NAME\",
    \"filePath\": \"$FILE_PATH\",
    \"fileSize\": $FILE_SIZE,
    \"uploadId\": \"upload-$(date +%s)\"
  }")

JOB_ID=$(echo $RESPONSE | jq -r '.jobId')
echo "Job ID: $JOB_ID"
echo ""
echo "Monitoring job..."

# Monitor progress
for i in {1..30}; do
  sleep 2
  JOB_STATUS=$(curl -s http://localhost:3001/api/mmr/jobs/$JOB_ID \
    -H "Authorization: Bearer test-token")
  
  STATUS=$(echo $JOB_STATUS | jq -r '.status')
  PROGRESS=$(echo $JOB_STATUS | jq -r '.progress.percentage')
  
  echo "  Status: $STATUS | Progress: $PROGRESS%"
  
  if [ "$STATUS" = "completed" ]; then
    echo ""
    echo "✅ Processing Complete!"
    echo ""
    echo "Metadata:"
    echo $JOB_STATUS | jq '.result.metadata'
    echo ""
    echo "MMR Records Found:"
    MMR_COUNT=$(echo $JOB_STATUS | jq '.result.mmrData | length')
    echo "  Total: $MMR_COUNT records"
    echo ""
    echo "Sample Records (first 3):"
    echo $JOB_STATUS | jq '.result.mmrData[0:3]'
    echo ""
    echo "View full results:"
    echo "  curl http://localhost:3001/api/mmr/jobs/$JOB_ID -H \"Authorization: Bearer test-token\" | jq"
    break
  fi
  
  if [ "$STATUS" = "failed" ]; then
    echo ""
    echo "❌ Processing Failed"
    echo $JOB_STATUS | jq '.error'
    break
  fi
done
