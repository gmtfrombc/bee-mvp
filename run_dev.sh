#!/bin/bash
set -e

# BEE Momentum Meter - Secure Development Runner
echo "🚀 Starting BEE Momentum Meter in development mode..."

# Check if secrets are provided via environment variables or .env file
if [ -f "app/.env" ]; then
    echo "🔑 Loading environment variables from app/.env"
    export $(grep -v '^#' app/.env | xargs)
fi

# Validate required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo ""
    echo "❌ Missing required environment variables!"
    echo ""
    echo "📋 SETUP INSTRUCTIONS:"
    echo "   1. Create app/.env file with your credentials:"
    echo "      SUPABASE_URL=https://your-project.supabase.co"
    echo "      SUPABASE_ANON_KEY=your_anon_key_here"
    echo ""
    echo "   2. Get your credentials from:"
    echo "      https://app.supabase.com/project/_/settings/api"
    echo ""
    echo "   3. OR run with --dart-define flags:"
    echo "      flutter run --dart-define=\"SUPABASE_URL=your_url\" --dart-define=\"SUPABASE_ANON_KEY=your_key\""
    echo ""
    exit 1
fi

echo "✅ Environment configured, launching app..."
cd app

# Launch Flutter app with environment variables
flutter run \
    --dart-define="SUPABASE_URL=$SUPABASE_URL" \
    --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
    --dart-define="FLUTTER_ENV=development" 