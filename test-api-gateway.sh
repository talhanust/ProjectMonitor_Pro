#!/bin/bash

API_URL="http://localhost:8080"
EMAIL="test@example.com"
PASSWORD="Test1234"
NAME="Test User"

echo "================================"
echo "Testing API Gateway Endpoints"
echo "================================"
echo ""

# Health check
echo "1. Testing health endpoint..."
curl -s "$API_URL/health" | jq '.'
echo ""

# API Status
echo "2. Testing API status..."
curl -s "$API_URL/api/v1/status" | jq '.'
echo ""

# Register
echo "3. Testing registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"$NAME\"}")
echo "$REGISTER_RESPONSE" | jq '.'
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token')
echo ""

# Login
echo "4. Testing login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
echo "$LOGIN_RESPONSE" | jq '.'
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo ""

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  # Protected endpoint
  echo "5. Testing protected profile endpoint..."
  curl -s "$API_URL/api/v1/profile" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # Admin endpoint (will fail with user role)
  echo "6. Testing admin endpoint (should fail with user role)..."
  curl -s "$API_URL/api/v1/admin" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # Create item
  echo "7. Testing create item..."
  curl -s -X POST "$API_URL/api/v1/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Item","description":"This is a test item"}' | jq '.'
  echo ""
else
  echo "No token received, skipping authenticated endpoints"
fi

# Paginated items
echo "8. Testing paginated items..."
curl -s "$API_URL/api/v1/items?page=1&limit=5" | jq '.'
echo ""

echo "================================"
echo "Tests completed!"
echo "================================"
