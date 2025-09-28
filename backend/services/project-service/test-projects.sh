#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="http://localhost:8081/api/v1/projects"

echo -e "${BLUE}Testing Project Management API${NC}"
echo ""

# Test 1: Create project
echo -e "${YELLOW}1. Creating project...${NC}"
RESPONSE=$(curl -s -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Engineering Project",
    "description": "Test project with GPS coordinates",
    "status": "PLANNING",
    "priority": "HIGH",
    "budget": 1000000,
    "startDate": "2025-01-01",
    "endDate": "2025-12-31",
    "location": "San Francisco, CA",
    "gpsLatitude": 37.7749,
    "gpsLongitude": -122.4194,
    "projectManager": "John Doe",
    "teamMembers": ["Alice", "Bob", "Charlie"],
    "tags": ["engineering", "infrastructure"]
  }')

if echo "$RESPONSE" | grep -q "projectId"; then
  echo -e "${GREEN}✅ Project created successfully${NC}"
  echo "$RESPONSE" | jq .
  PROJECT_ID=$(echo "$RESPONSE" | jq -r .id)
else
  echo -e "${RED}❌ Failed to create project${NC}"
  echo "$RESPONSE"
  exit 1
fi

echo ""

# Test 2: Get project
echo -e "${YELLOW}2. Getting project...${NC}"
curl -s $API_URL/$PROJECT_ID | jq .

echo ""

# Test 3: List projects
echo -e "${YELLOW}3. Listing projects...${NC}"
curl -s "$API_URL?limit=10&status=PLANNING" | jq .

echo ""

# Test 4: Get statistics
echo -e "${YELLOW}4. Getting statistics...${NC}"
curl -s $API_URL/stats/overview | jq .

echo ""
echo -e "${GREEN}All tests completed!${NC}"
