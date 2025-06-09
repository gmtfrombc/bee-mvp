#!/bin/bash

echo "🚀 Testing Today Feed AI Generation Production Deployment"
echo "========================================================"

# Get today's date
TODAY=$(date +%Y-%m-%d)
echo "📅 Testing content generation for: $TODAY"

# Extract environment variables
SUPABASE_URL=$(grep SUPABASE_URL ../.env | cut -d '=' -f2)
SUPABASE_ANON_KEY=$(grep SUPABASE_ANON_KEY ../.env | cut -d '=' -f2)

echo "🌐 Supabase URL: $SUPABASE_URL"
echo "🔑 API Key: ${SUPABASE_ANON_KEY:0:10}..."

echo ""
echo "🔍 Step 1: Testing AI Coaching Engine endpoint..."
echo "================================================"

# Test AI Coaching Engine
response=$(curl -s -X POST "$SUPABASE_URL/functions/v1/ai-coaching-engine/generate-daily-content" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"content_date\": \"$TODAY\", \"force_regenerate\": true}" \
  --max-time 30)

echo "Response: $response"

if echo "$response" | grep -q "success"; then
    echo "✅ AI Coaching Engine: WORKING"
else
    echo "❌ AI Coaching Engine: FAILED"
fi

echo ""
echo "🔍 Step 2: Testing Daily Content Generator..."
echo "============================================="

# Test Daily Content Generator
response=$(curl -s -X POST "$SUPABASE_URL/functions/v1/daily-content-generator" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"target_date\": \"$TODAY\", \"force_regenerate\": false}" \
  --max-time 30)

echo "Response: $response"

if echo "$response" | grep -q "success"; then
    echo "✅ Daily Content Generator: WORKING"
else
    echo "❌ Daily Content Generator: FAILED"
fi

echo ""
echo "🔍 Step 3: Testing database connectivity..."
echo "=========================================="

# Test database connectivity by checking for existing content
response=$(curl -s -X GET "$SUPABASE_URL/rest/v1/daily_feed_content?content_date=eq.$TODAY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY")

echo "Response: $response"

if echo "$response" | grep -q "\[\]" || echo "$response" | grep -q "content_date"; then
    echo "✅ Database connectivity: WORKING"
else
    echo "❌ Database connectivity: FAILED"
fi

echo ""
echo "🎉 Production deployment test complete!"
echo "======================================" 