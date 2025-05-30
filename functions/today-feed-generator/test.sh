#!/bin/bash

# Today Feed Content Generator - Test Script
# Usage: ./test.sh [SERVICE_URL]

set -e

# Configuration
SERVICE_URL=${1:-"http://localhost:8080"}
echo "🧪 Testing Today Feed Content Generator"
echo "Service URL: ${SERVICE_URL}"
echo ""

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "${SERVICE_URL}/health" | jq '.'
echo "✅ Health check complete"
echo ""

# Test content generation
echo "2. Testing content generation..."
curl -s -X POST "${SERVICE_URL}/generate" \
  -H "Content-Type: application/json" \
  -d '{"topic": "nutrition", "date": "2024-12-15"}' | jq '.'
echo "✅ Content generation test complete"
echo ""

# Test current content retrieval
echo "3. Testing current content retrieval..."
curl -s "${SERVICE_URL}/current" | jq '.'
echo "✅ Current content test complete"
echo ""

# Test content validation
echo "4. Testing content validation..."
curl -s -X POST "${SERVICE_URL}/validate" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Health Title",
    "summary": "This is a test summary for validation testing.",
    "topic_category": "nutrition"
  }' | jq '.'
echo "✅ Content validation test complete"
echo ""

# Test error handling (invalid endpoint)
echo "5. Testing error handling..."
curl -s "${SERVICE_URL}/nonexistent" | jq '.'
echo "✅ Error handling test complete"
echo ""

echo "🎉 All tests completed successfully!" 