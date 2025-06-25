#!/bin/bash
set -e

# BEE Momentum Meter - Secure Development Runner
echo "🚀 Starting BEE Momentum Meter in development mode..."

# Check if secrets are provided via environment variables or .env file
if [ -f "app/.env" ]; then
    echo "🔑 Loading environment variables from app/.env"
    set -a  # automatically export all variables
    source app/.env
    set +a  # turn off automatic export
fi

# ------------------------------------------------------------------
# Fallback: if required vars still not set, try supabase/.env.local
# This is useful when the developer forgets to copy local keys into
# app/.env. We only export SUPABASE_URL and SUPABASE_ANON_KEY from the
# supabase env to avoid polluting the Flutter process with unrelated
# secrets.
# ------------------------------------------------------------------
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    if [ -f "supabase/.env.local" ]; then
        echo "🔑 app/.env missing keys – loading fallback from supabase/.env.local"
        # shellcheck disable=SC1091
        SUPABASE_URL_FALLBACK=$(grep -E "^(SITE_URL|SUPABASE_URL)=" supabase/.env.local | head -n1 | cut -d '=' -f2-)
        ANON_KEY_FALLBACK=$(grep -E "^(ANON_KEY|SUPABASE_ANON_KEY)=" supabase/.env.local | head -n1 | cut -d '=' -f2-)

        if [ -n "$SUPABASE_URL_FALLBACK" ] && [ -z "$SUPABASE_URL" ]; then
            export SUPABASE_URL=$SUPABASE_URL_FALLBACK
        fi
        if [ -n "$ANON_KEY_FALLBACK" ] && [ -z "$SUPABASE_ANON_KEY" ]; then
            export SUPABASE_ANON_KEY=$ANON_KEY_FALLBACK
        fi
    fi
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
    --dart-define="FLUTTER_ENV=development" \
    "$@" 