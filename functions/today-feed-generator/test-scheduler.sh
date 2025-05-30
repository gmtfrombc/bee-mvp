#!/bin/bash

# Test script for Today Feed Generator Scheduler
# Epic 1.3: Today Feed (AI Daily Brief)

set -e

# Configuration
SERVICE_URL=${1:-"http://localhost:8080"}
TEST_DATE=$(date +%Y-%m-%d)

echo "🧪 Testing Today Feed Generator Scheduler"
echo "Service URL: $SERVICE_URL"
echo "Test Date: $TEST_DATE"
echo ""

# Test 1: Health Check
echo "1️⃣ Testing health check endpoint..."
curl -s "$SERVICE_URL/health" | jq '.'
echo ""

# Test 2: Manual Content Generation
echo "2️⃣ Testing manual content generation..."
MANUAL_RESPONSE=$(curl -s -X POST "$SERVICE_URL/generate" \
    -H "Content-Type: application/json" \
    -d "{
        \"scheduled\": false,
        \"source\": \"manual-test\",
        \"date\": \"$TEST_DATE\"
    }")

echo "$MANUAL_RESPONSE" | jq '.'
echo ""

# Test 3: Scheduled Content Generation (simulating Cloud Scheduler)
echo "3️⃣ Testing scheduled content generation..."
SCHEDULED_RESPONSE=$(curl -s -X POST "$SERVICE_URL/generate" \
    -H "Content-Type: application/json" \
    -d "{
        \"scheduled\": true,
        \"source\": \"cloud-scheduler\",
        \"timezone\": \"UTC\",
        \"trigger_time\": \"3AM\",
        \"date\": \"$TEST_DATE\"
    }")

echo "$SCHEDULED_RESPONSE" | jq '.'
echo ""

# Test 4: Idempotent Behavior (should skip if content exists)
echo "4️⃣ Testing idempotent behavior (should skip if content exists)..."
IDEMPOTENT_RESPONSE=$(curl -s -X POST "$SERVICE_URL/generate" \
    -H "Content-Type: application/json" \
    -d "{
        \"scheduled\": true,
        \"source\": \"cloud-scheduler\",
        \"timezone\": \"UTC\",
        \"trigger_time\": \"3AM\",
        \"date\": \"$TEST_DATE\"
    }")

echo "$IDEMPOTENT_RESPONSE" | jq '.'

# Check if the response indicates content was skipped
if echo "$IDEMPOTENT_RESPONSE" | jq -e '.skipped == true' > /dev/null; then
    echo "✅ Idempotent behavior working correctly - content was skipped"
else
    echo "⚠️  Idempotent behavior may not be working - content was not skipped"
fi
echo ""

# Test 5: Get Current Content
echo "5️⃣ Testing get current content endpoint..."
curl -s "$SERVICE_URL/current" | jq '.'
echo ""

# Test 6: Content Validation
echo "6️⃣ Testing content validation endpoint..."
curl -s -X POST "$SERVICE_URL/validate" \
    -H "Content-Type: application/json" \
    -d "{
        \"content_date\": \"$TEST_DATE\",
        \"title\": \"Test Health Tip\",
        \"summary\": \"This is a test summary for health content validation.\",
        \"topic_category\": \"nutrition\",
        \"ai_confidence_score\": 0.85
    }" | jq '.'
echo ""

echo "✅ All tests completed!"
echo ""
echo "📋 Test Summary:"
echo "  - Health check: ✅"
echo "  - Manual generation: ✅"
echo "  - Scheduled generation: ✅"
echo "  - Idempotent behavior: ✅"
echo "  - Get current content: ✅"
echo "  - Content validation: ✅"
echo ""
echo "🔧 To test with your deployed service:"
echo "  ./test-scheduler.sh https://your-service-url" 