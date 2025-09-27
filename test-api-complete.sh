#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Testing Complete API Gateway${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# 1. Health check
echo -e "${GREEN}1. Health Check${NC}"
curl -s "$API_URL/health" | jq '.'
echo ""

# 2. Register a new user
echo -e "${GREEN}2. Register User${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "Password123",
    "name": "John Doe"
  }')
echo "$REGISTER_RESPONSE" | jq '.'
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token')
echo ""

# 3. Login
echo -e "${GREEN}3. Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "Password123"
  }')
echo "$LOGIN_RESPONSE" | jq '.'
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo ""

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  # 4. Get user profile
  echo -e "${GREEN}4. Get User Profile (/api/v1/users/me)${NC}"
  curl -s "$API_URL/api/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # 5. Update user profile
  echo -e "${GREEN}5. Update User Profile${NC}"
  curl -s -X PATCH "$API_URL/api/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "John Updated"
    }' | jq '.'
  echo ""

  # 6. Test Protected Route
  echo -e "${GREEN}6. Protected Route Test (/api/v1/protected)${NC}"
  curl -s "$API_URL/api/v1/protected" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # 7. Test via frontend proxy
  echo -e "${GREEN}7. Test via Frontend Proxy${NC}"
  curl -s "$FRONTEND_URL/api/gateway/api/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # 8. Refresh token
  echo -e "${GREEN}8. Refresh Token${NC}"
  curl -s -X POST "$API_URL/auth/refresh" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""
else
  echo -e "${RED}No valid token received${NC}"
fi

echo -e "${YELLOW}================================${NC}"
echo -e "${GREEN}Tests Complete!${NC}"
echo -e "${YELLOW}================================${NC}"
