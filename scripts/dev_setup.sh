#!/usr/bin/env bash
set -euo pipefail

echo "🛠  BEE-MVP Development Setup"

# Auto‑provision .env if missing
if [ ! -f app/.env ]; then
  echo "📝 Creating app/.env from template"
  cp app/.env.example app/.env
  echo ""
  echo "🔑 Please edit app/.env with your real Supabase credentials:"
  echo "   SUPABASE_URL=https://okptsizouuanwnpqjfui.supabase.co"
  echo "   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6..."
  echo ""
  echo "📱 Then launch with:"
  echo "   • VS Code: Run 'BEE-MVP dev' configuration"
  echo "   • CLI: bash run_dev.sh"
else
  echo "✅ app/.env already exists"
  echo ""
  echo "📱 Ready to launch with:"
  echo "   • VS Code: Run 'BEE-MVP dev' configuration"
  echo "   • CLI: bash run_dev.sh"
fi 