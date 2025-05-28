#!/bin/bash

# API Test Script for Engagement Events Logging
# Tests REST API, GraphQL API, and Service Role access
# 
# Prerequisites:
# - Supabase project with engagement_events table deployed
# - Environment variables set: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
# - Test user JWT token available

set -e

# Configuration
SUPABASE_URL="${SUPABASE_URL:-https://your-project.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-your_anon_key_here}"
SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-your_service_role_key_here}"
USER_JWT_TOKEN="${USER_JWT_TOKEN:-your_user_jwt_token_here}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

test_api_endpoint() {
    local description="$1"
    local method="$2"
    local url="$3"
    local headers="$4"
    local data="$5"
    local expected_status="$6"
    
    log_info "Testing: $description"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "$url" $headers)
    else
        response=$(curl -s -w "\n%{http_code}" -X POST "$url" $headers -d "$data")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "$description - Status: $status_code"
        echo "Response: $body" | head -c 200
        echo ""
    else
        log_error "$description - Expected: $expected_status, Got: $status_code"
        echo "Response: $body"
    fi
    echo ""
}

# Test 3.1: REST API Setup
log_info "=== Testing 3.1: REST API Setup ==="

# Test GET engagement_events with user JWT
test_api_endpoint \
    "GET engagement_events with user JWT" \
    "GET" \
    "$SUPABASE_URL/rest/v1/engagement_events" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Authorization: Bearer $USER_JWT_TOKEN' -H 'Content-Type: application/json'" \
    "" \
    "200"

# Test POST engagement_events with user JWT
test_data='{
    "event_type": "app_open",
    "value": {"session_id": "test123", "platform": "test"}
}'

test_api_endpoint \
    "POST engagement_events with user JWT" \
    "POST" \
    "$SUPABASE_URL/rest/v1/engagement_events" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Authorization: Bearer $USER_JWT_TOKEN' -H 'Content-Type: application/json'" \
    "$test_data" \
    "201"

# Test unauthorized access (no JWT)
test_api_endpoint \
    "GET engagement_events without JWT (should fail)" \
    "GET" \
    "$SUPABASE_URL/rest/v1/engagement_events" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Content-Type: application/json'" \
    "" \
    "401"

# Test 3.2: GraphQL API Setup
log_info "=== Testing 3.2: GraphQL API Setup ==="

# Test GraphQL query
graphql_query='{
    "query": "query { engagement_events { id timestamp event_type value } }"
}'

test_api_endpoint \
    "GraphQL query for engagement_events" \
    "POST" \
    "$SUPABASE_URL/graphql/v1" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Authorization: Bearer $USER_JWT_TOKEN' -H 'Content-Type: application/json'" \
    "$graphql_query" \
    "200"

# Test GraphQL mutation
graphql_mutation='{
    "query": "mutation($event: engagement_events_insert_input!) { insert_engagement_events_one(object: $event) { id timestamp event_type } }",
    "variables": {
        "event": {
            "event_type": "goal_complete",
            "value": {"goal_id": "test_goal", "points": 10}
        }
    }
}'

test_api_endpoint \
    "GraphQL mutation for engagement_events" \
    "POST" \
    "$SUPABASE_URL/graphql/v1" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Authorization: Bearer $USER_JWT_TOKEN' -H 'Content-Type: application/json'" \
    "$graphql_mutation" \
    "200"

# Test 3.4: Service Role Access
log_info "=== Testing 3.4: Service Role Access ==="

# Test bulk insert with service role
bulk_data='[
    {
        "user_id": "123e4567-e89b-12d3-a456-426614174000",
        "event_type": "steps_import",
        "value": {"steps": 5000, "source": "fitbit"}
    },
    {
        "user_id": "123e4567-e89b-12d3-a456-426614174000",
        "event_type": "coach_message_sent",
        "value": {"message_id": "msg123", "type": "encouragement"}
    }
]'

test_api_endpoint \
    "Bulk insert with service role" \
    "POST" \
    "$SUPABASE_URL/rest/v1/engagement_events" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY' -H 'Content-Type: application/json'" \
    "$bulk_data" \
    "201"

# Test service role can read all events
test_api_endpoint \
    "Service role read all events" \
    "GET" \
    "$SUPABASE_URL/rest/v1/engagement_events" \
    "-H 'apikey: $SUPABASE_ANON_KEY' -H 'Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY' -H 'Content-Type: application/json'" \
    "" \
    "200"

# Summary
echo ""
log_info "=== Test Summary ==="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    log_success "All API tests passed!"
    exit 0
else
    log_error "Some API tests failed. Check the output above."
    exit 1
fi 