#!/bin/bash

################################################################################
# Process Real MMR Files Script
# Processes your uploaded MMR Excel files
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                      ║${NC}"
echo -e "${BLUE}║              Processing Your MMR Files                               ║${NC}"
echo -e "${BLUE}║                                                                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check service health
echo -e "${CYAN}Checking service health...${NC}"
HEALTH=$(curl -s http://localhost:3001/health)
STATUS=$(echo $HEALTH | jq -r '.status')

if [ "$STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Service is healthy${NC}"
else
    echo -e "${RED}✗ Service is not healthy${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Processing File 1: PRJ-002 Revised & Updated MMR${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

FILE_PATH="/workspaces/ProjectMonitor_Pro/test-files/PRJ-002 Revised & Updated MMR  C-15 Jul 2025.xlsx"

if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}✗ File not found: $FILE_PATH${NC}"
    exit 1
fi

FILE_SIZE=$(stat -c%s "$FILE_PATH")
echo -e "File: PRJ-002 Revised & Updated MMR  C-15 Jul 2025.xlsx"
echo -e "Size: $(echo "scale=2; $FILE_SIZE/1024" | bc) KB"
echo ""

# Submit the job
echo -e "${CYAN}Submitting job...${NC}"
RESPONSE=$(curl -s -X POST http://localhost:3001/api/mmr/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d "{
    \"fileName\": \"PRJ-002 Revised & Updated MMR  C-15 Jul 2025.xlsx\",
    \"filePath\": \"$FILE_PATH\",
    \"fileSize\": $FILE_SIZE,
    \"uploadId\": \"upload-prj002-$(date +%s)\"
  }")

JOB_ID=$(echo $RESPONSE | jq -r '.jobId')

if [ "$JOB_ID" = "null" ] || [ -z "$JOB_ID" ]; then
    echo -e "${RED}✗ Failed to submit job${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Job submitted${NC}"
echo -e "Job ID: ${YELLOW}$JOB_ID${NC}"
echo ""

# Monitor progress
echo -e "${CYAN}Monitoring progress...${NC}"
for i in {1..30}; do
    sleep 2
    
    JOB_STATUS=$(curl -s http://localhost:3001/api/mmr/jobs/$JOB_ID \
        -H "Authorization: Bearer test-token")
    
    STATUS=$(echo $JOB_STATUS | jq -r '.status')
    PROGRESS=$(echo $JOB_STATUS | jq -r '.progress.percentage')
    
    echo -e "  ${BLUE}Status:${NC} $STATUS | ${BLUE}Progress:${NC} $PROGRESS%"
    
    if [ "$STATUS" = "completed" ]; then
        echo ""
        echo -e "${GREEN}✅ Processing Complete!${NC}"
        echo ""
        echo -e "${CYAN}═══ Results ═══${NC}"
        echo ""
        
        # Extract metadata
        SHEET_COUNT=$(echo $JOB_STATUS | jq -r '.result.metadata.sheetCount')
        TOTAL_ROWS=$(echo $JOB_STATUS | jq -r '.result.metadata.totalRows')
        MMR_COUNT=$(echo $JOB_STATUS | jq -r '.result.mmrData | length')
        WORD_COUNT=$(echo $JOB_STATUS | jq -r '.result.metadata.wordCount')
        PROC_TIME=$(echo $JOB_STATUS | jq -r '.result.metadata.processingTime')
        IS_MMR=$(echo $JOB_STATUS | jq -r '.result.metadata.isMMRDocument')
        
        echo -e "${YELLOW}Metadata:${NC}"
        echo "  • Sheets: $SHEET_COUNT"
        echo "  • Total Rows: $TOTAL_ROWS"
        echo "  • MMR Document: $IS_MMR"
        echo "  • MMR Records Found: $MMR_COUNT"
        echo "  • Word Count: $WORD_COUNT"
        echo "  • Processing Time: ${PROC_TIME}ms"
        echo ""
        
        echo -e "${YELLOW}Sheet Names:${NC}"
        echo $JOB_STATUS | jq -r '.result.metadata.sheetNames[]' | sed 's/^/  • /'
        echo ""
        
        if [ "$MMR_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}Sample MMR Records (first 3):${NC}"
            echo $JOB_STATUS | jq '.result.mmrData[0:3]'
            echo ""
        fi
        
        # Save full results
        echo $JOB_STATUS | jq '.result' > /tmp/prj-002-results.json
        echo -e "${GREEN}Full results saved to: /tmp/prj-002-results.json${NC}"
        echo ""
        
        break
    fi
    
    if [ "$STATUS" = "failed" ]; then
        echo ""
        echo -e "${RED}✗ Processing Failed${NC}"
        ERROR=$(echo $JOB_STATUS | jq -r '.error')
        echo "Error: $ERROR"
        exit 1
    fi
done

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Processing File 2: PRJ-006 MMR July 25${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

FILE_PATH2="/workspaces/ProjectMonitor_Pro/test-files/PRJ-006 MMR July 25 - (10th Avenue).xlsx"

if [ ! -f "$FILE_PATH2" ]; then
    echo -e "${RED}✗ File not found: $FILE_PATH2${NC}"
    exit 1
fi

FILE_SIZE2=$(stat -c%s "$FILE_PATH2")
echo -e "File: PRJ-006 MMR July 25 - (10th Avenue).xlsx"
echo -e "Size: $(echo "scale=2; $FILE_SIZE2/1024" | bc) KB"
echo ""

# Submit the job
echo -e "${CYAN}Submitting job...${NC}"
RESPONSE2=$(curl -s -X POST http://localhost:3001/api/mmr/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d "{
    \"fileName\": \"PRJ-006 MMR July 25 - (10th Avenue).xlsx\",
    \"filePath\": \"$FILE_PATH2\",
    \"fileSize\": $FILE_SIZE2,
    \"uploadId\": \"upload-prj006-$(date +%s)\"
  }")

JOB_ID2=$(echo $RESPONSE2 | jq -r '.jobId')

if [ "$JOB_ID2" = "null" ] || [ -z "$JOB_ID2" ]; then
    echo -e "${RED}✗ Failed to submit job${NC}"
    echo "Response: $RESPONSE2"
    exit 1
fi

echo -e "${GREEN}✓ Job submitted${NC}"
echo -e "Job ID: ${YELLOW}$JOB_ID2${NC}"
echo ""

# Monitor progress
echo -e "${CYAN}Monitoring progress...${NC}"
for i in {1..30}; do
    sleep 2
    
    JOB_STATUS2=$(curl -s http://localhost:3001/api/mmr/jobs/$JOB_ID2 \
        -H "Authorization: Bearer test-token")
    
    STATUS2=$(echo $JOB_STATUS2 | jq -r '.status')
    PROGRESS2=$(echo $JOB_STATUS2 | jq -r '.progress.percentage')
    
    echo -e "  ${BLUE}Status:${NC} $STATUS2 | ${BLUE}Progress:${NC} $PROGRESS2%"
    
    if [ "$STATUS2" = "completed" ]; then
        echo ""
        echo -e "${GREEN}✅ Processing Complete!${NC}"
        echo ""
        echo -e "${CYAN}═══ Results ═══${NC}"
        echo ""
        
        # Extract metadata
        SHEET_COUNT2=$(echo $JOB_STATUS2 | jq -r '.result.metadata.sheetCount')
        TOTAL_ROWS2=$(echo $JOB_STATUS2 | jq -r '.result.metadata.totalRows')
        MMR_COUNT2=$(echo $JOB_STATUS2 | jq -r '.result.mmrData | length')
        WORD_COUNT2=$(echo $JOB_STATUS2 | jq -r '.result.metadata.wordCount')
        PROC_TIME2=$(echo $JOB_STATUS2 | jq -r '.result.metadata.processingTime')
        IS_MMR2=$(echo $JOB_STATUS2 | jq -r '.result.metadata.isMMRDocument')
        
        echo -e "${YELLOW}Metadata:${NC}"
        echo "  • Sheets: $SHEET_COUNT2"
        echo "  • Total Rows: $TOTAL_ROWS2"
        echo "  • MMR Document: $IS_MMR2"
        echo "  • MMR Records Found: $MMR_COUNT2"
        echo "  • Word Count: $WORD_COUNT2"
        echo "  • Processing Time: ${PROC_TIME2}ms"
        echo ""
        
        echo -e "${YELLOW}Sheet Names:${NC}"
        echo $JOB_STATUS2 | jq -r '.result.metadata.sheetNames[]' | sed 's/^/  • /'
        echo ""
        
        if [ "$MMR_COUNT2" -gt 0 ]; then
            echo -e "${YELLOW}Sample MMR Records (first 3):${NC}"
            echo $JOB_STATUS2 | jq '.result.mmrData[0:3]'
            echo ""
        fi
        
        # Save full results
        echo $JOB_STATUS2 | jq '.result' > /tmp/prj-006-results.json
        echo -e "${GREEN}Full results saved to: /tmp/prj-006-results.json${NC}"
        echo ""
        
        break
    fi
    
    if [ "$STATUS2" = "failed" ]; then
        echo ""
        echo -e "${RED}✗ Processing Failed${NC}"
        ERROR2=$(echo $JOB_STATUS2 | jq -r '.error')
        echo "Error: $ERROR2"
        exit 1
    fi
done

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                      ║${NC}"
echo -e "${BLUE}║                  ✅ Both Files Processed!                           ║${NC}"
echo -e "${BLUE}║                                                                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}View full results:${NC}"
echo "  cat /tmp/prj-002-results.json | jq"
echo "  cat /tmp/prj-006-results.json | jq"
echo ""
echo -e "${CYAN}View all your jobs:${NC}"
echo "  curl http://localhost:3001/api/mmr/jobs -H \"Authorization: Bearer test-token\" | jq"
echo ""