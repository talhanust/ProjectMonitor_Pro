#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

API_URL="http://localhost:8080"
TEST_EMAIL="test$(date +%s)@example.com"
TEST_PASSWORD="TestPassword123"
TEST_NAME="Test User"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Testing Authentication System ${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 1. Register
echo -e "${GREEN}1. Testing Registration${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"name\": \"$TEST_NAME\"
  }")

if echo "$REGISTER_RESPONSE" | jq -e '.accessToken' > /dev/null; then
  echo "✅ Registration successful"
  ACCESS_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.accessToken')
  REFRESH_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.refreshToken')
else
  echo "❌ Registration failed"
  echo "$REGISTER_RESPONSE" | jq '.'
  exit 1
fi

# 2. Get current user
echo -e "${GREEN}2. Testing Get Current User${NC}"
ME_RESPONSE=$(curl -s "$API_URL/auth/me" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$ME_RESPONSE" | jq -e '.id' > /dev/null; then
  echo "✅ Get current user successful"
  echo "User: $(echo "$ME_RESPONSE" | jq -r '.name') ($(echo "$ME_RESPONSE" | jq -r '.email'))"
else
  echo "❌ Get current user failed"
  echo "$ME_RESPONSE" | jq '.'
fi

# 3. Logout
echo -e "${GREEN}3. Testing Logout${NC}"
LOGOUT_RESPONSE=$(curl -s -X POST "$API_URL/auth/logout" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$LOGOUT_RESPONSE" | jq -e '.message' > /dev/null; then
  echo "✅ Logout successful"
else
  echo "❌ Logout failed"
  echo "$LOGOUT_RESPONSE" | jq '.'
fi

# 4. Login
echo -e "${GREEN}4. Testing Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")

if echo "$LOGIN_RESPONSE" | jq -e '.accessToken' > /dev/null; then
  echo "✅ Login successful"
  NEW_ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken')
else
  echo "❌ Login failed"
  echo "$LOGIN_RESPONSE" | jq '.'
  exit 1
fi

# 5. Refresh token
echo -e "${GREEN}5. Testing Token Refresh${NC}"
REFRESH_RESPONSE=$(curl -s -X POST "$API_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")

if echo "$REFRESH_RESPONSE" | jq -e '.accessToken' > /dev/null; then
  echo "✅ Token refresh successful"
else
  echo "❌ Token refresh failed"
  echo "$REFRESH_RESPONSE" | jq '.'
fi

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}  All Tests Completed!          ${NC}"
echo -e "${BLUE}================================${NC}"
