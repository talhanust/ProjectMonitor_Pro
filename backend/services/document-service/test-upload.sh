#!/bin/bash

API_URL="http://localhost:8082/api/v1/documents"

echo "Testing Document Upload Service"
echo ""

# Create test files
echo "Creating test files..."
echo "This is a test document" > test.txt
echo "PDF content would go here" > test.pdf

# Test single upload
echo "1. Testing single file upload..."
curl -X POST $API_URL/upload \
  -F "file=@test.txt" \
  -F "projectId=test-project-1" \
  -F "category=PMMS" \
  -F "description=Test document"

echo ""
echo "2. Listing documents..."
curl $API_URL

# Cleanup
rm test.txt test.pdf

echo ""
echo "Tests completed!"
