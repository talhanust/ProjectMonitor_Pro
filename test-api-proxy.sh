#!/bin/bash
# test-api-proxy.sh
# Automates registration, login, and testing a protected route
# Tests both backend and frontend proxy

# --- Config ---
BACKEND_API="http://localhost:8080"
FRONTEND_PROXY="http://localhost:3000/api/gateway"
PROTECTED_ROUTE="api/v1/users/me"  # Change to an actual protected route

# --- Helper function ---
function extract_token() {
  echo $1 | jq -r '.token'
}

echo "=== 1. Register user (Backend) ==="
REGISTER_RESPONSE=$(curl -s -X POST $BACKEND_API/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"testuser@example.com","password":"Test1234","name":"Test User"}')
echo "Register Response: $REGISTER_RESPONSE"
REGISTER_TOKEN=$(extract_token "$REGISTER_RESPONSE")
echo "Token from registration: $REGISTER_TOKEN"
echo ""

echo "=== 2. Login user (Backend) ==="
LOGIN_RESPONSE=$(curl -s -X POST $BACKEND_API/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"testuser@example.com","password":"Test1234"}')
echo "Login Response: $LOGIN_RESPONSE"
LOGIN_TOKEN=$(extract_token "$LOGIN_RESPONSE")
echo "Token from login: $LOGIN_TOKEN"
echo ""

echo "=== 3. Test protected route (Backend) ==="
PROTECTED_RESPONSE=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $BACKEND_API/$PROTECTED_ROUTE)
echo "Protected Route Response (Backend): $PROTECTED_RESPONSE"
echo ""

echo "=== 4. Register user via Frontend Proxy ==="
FRONTEND_REGISTER=$(curl -s -X POST $FRONTEND_PROXY/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"proxyuser@example.com","password":"Proxy1234","name":"Proxy User"}')
echo "Register Response (Frontend Proxy): $FRONTEND_REGISTER"
PROXY_REGISTER_TOKEN=$(extract_token "$FRONTEND_REGISTER")
echo "Token from frontend proxy registration: $PROXY_REGISTER_TOKEN"
echo ""

echo "=== 5. Login via Frontend Proxy ==="
FRONTEND_LOGIN=$(curl -s -X POST $FRONTEND_PROXY/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"proxyuser@example.com","password":"Proxy1234"}')
echo "Login Response (Frontend Proxy): $FRONTEND_LOGIN"
PROXY_LOGIN_TOKEN=$(extract_token "$FRONTEND_LOGIN")
echo "Token from frontend proxy login: $PROXY_LOGIN_TOKEN"
echo ""

echo "=== 6. Test protected route via Frontend Proxy ==="
PROXY_PROTECTED=$(curl -s -H "Authorization: Bearer $PROXY_LOGIN_TOKEN" $FRONTEND_PROXY/$PROTECTED_ROUTE)
echo "Protected Route Response (Frontend Proxy): $PROXY_PROTECTED"
echo ""
