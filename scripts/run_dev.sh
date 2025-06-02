#!/usr/bin/env bash
set -e

# Auto‑provision .env if missing
if [ ! -f app/.env ]; then
  echo "🛠  Creating app/.env from template"
  cp app/.env.example app/.env
  echo "🔑  >> Edit app/.env with real Supabase credentials <<"
  echo ""
  echo "Replace these placeholder lines in app/.env:"
  echo "SUPABASE_URL=https://okptsizouuanwnpqjfui.supabase.co"
  echo "SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6..."
  echo ""
  echo "Then run this script again to launch the app."
  exit 0
fi

# Read Supabase credentials from .env file
if [ -f app/.env ]; then
  echo "🚀 Loading Supabase credentials from app/.env"
  
  # Extract values from .env file
  SUPABASE_URL=$(grep "^SUPABASE_URL=" app/.env | cut -d '=' -f2-)
  SUPABASE_ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" app/.env | cut -d '=' -f2-)
  
  if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in app/.env"
    echo "Please edit app/.env with your real Supabase credentials"
    exit 1
  fi
  
  echo "✅ Found Supabase credentials, launching app..."
  cd app
  flutter run \
    --dart-define "SUPABASE_URL=$SUPABASE_URL" \
    --dart-define "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
else
  echo "❌ app/.env file not found"
  echo "Run: bash scripts/dev_setup.sh"
  exit 1
fi 