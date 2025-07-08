#!/usr/bin/env bash
# setup_project.sh — One-time helper script to configure Supabase settings locally.
# Usage: ./scripts/setup_project.sh
# Requires SUPABASE_ACCESS_TOKEN and SUPABASE_URL environment variables.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 Enforcing Supabase password policy..."

if bash "$DIR/enforce_supabase_password_policy.sh"; then
  echo "✅ Supabase password policy enforced successfully."
else
  echo "❌ Failed to enforce password policy."
  echo "   • Ensure SUPABASE_ACCESS_TOKEN and SUPABASE_URL are set correctly."
  echo "   • Check network connectivity."
  echo "   • You can retry: ./scripts/setup_project.sh"
  exit 1
fi 