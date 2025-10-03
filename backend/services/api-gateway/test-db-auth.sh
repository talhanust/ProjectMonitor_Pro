#!/bin/bash

# Test registration with database
echo "Testing registration with database..."
curl -X POST http://localhost:8080/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"dbuser@example.com","password":"Test1234!","name":"Database User"}' \
  | jq .

echo ""
echo "Testing login with the same user..."
curl -X POST http://localhost:8080/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"dbuser@example.com","password":"Test1234!"}' \
  | jq .
