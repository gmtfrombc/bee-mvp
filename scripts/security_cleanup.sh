#!/bin/bash
set -e

# BEE Momentum Meter - Security Cleanup Script
# This script helps clean up exposed secrets and implement the new security approach

echo "🔒 BEE Security Cleanup & Implementation"
echo "========================================"

# Check if GitLeaks is installed
if ! command -v gitleaks >/dev/null 2>&1; then
    echo "❌ GitLeaks not installed. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install gitleaks
    else
        echo "⚠️  Please install GitLeaks manually: https://github.com/gitleaks/gitleaks#installation"
        exit 1
    fi
fi

echo "✅ GitLeaks installed"

# Step 1: Scan for current secrets
echo ""
echo "🔍 Step 1: Scanning for exposed secrets..."
if gitleaks detect --source . --config .gitleaks.toml --no-git; then
    echo "✅ No secrets detected by GitLeaks"
else
    echo "⚠️  Secrets detected! See above output for details."
    echo ""
    echo "📋 ACTION REQUIRED:"
    echo "   1. Remove real secrets from the files listed above"
    echo "   2. Replace with placeholder values or remove entirely"
    echo "   3. Run this script again to verify cleanup"
    echo ""
    read -p "Press Enter after cleaning up secrets to continue..."
fi

# Step 2: Remove sensitive files that should not be committed
echo ""
echo "🧹 Step 2: Removing sensitive files..."

# Remove real .env files from git tracking (if accidentally added)
if git ls-files | grep -q "\.env$"; then
    echo "📁 Removing .env files from git tracking..."
    git rm --cached app/.env 2>/dev/null || true
    git rm --cached .env 2>/dev/null || true
    echo "✅ .env files removed from git tracking"
fi

# Remove real Google Services files
if git ls-files | grep -q "google-services.json"; then
    echo "📁 Removing google-services.json from git tracking..."
    git rm --cached app/android/app/google-services.json 2>/dev/null || true
    git rm --cached "**/google-services.json" 2>/dev/null || true
    echo "✅ Google Services files removed from git tracking"
fi

if git ls-files | grep -q "GoogleService-Info.plist"; then
    echo "📁 Removing GoogleService-Info.plist from git tracking..."
    git rm --cached app/ios/Runner/GoogleService-Info.plist 2>/dev/null || true
    git rm --cached "**/GoogleService-Info.plist" 2>/dev/null || true
    echo "✅ GoogleService-Info.plist removed from git tracking"
fi

# Step 3: Create .env.example template
echo ""
echo "📝 Step 3: Creating .env.example template..."
cat > app/.env.example << 'EOF'
# BEE Momentum Meter - Environment Configuration Template
# Copy this file to .env and replace with your actual values
# NEVER commit .env files to version control

# Supabase Configuration
# Get these from: https://app.supabase.com/project/_/settings/api
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Development Mode Settings
FLUTTER_ENV=development

# Notes:
# 1. The anon key is safe to use in client-side code (it's public by design)
# 2. Never use SERVICE_ROLE_KEY in client applications
# 3. Firebase config is handled via firebase_options.dart (not environment variables)
EOF

echo "✅ Created app/.env.example template"

# Step 4: Setup Git hooks
echo ""
echo "🔗 Step 4: Configuring Git hooks..."
git config core.hooksPath .githooks
echo "✅ Git hooks configured"

# Step 5: Test the security setup
echo ""
echo "🧪 Step 5: Testing security setup..."

# Test pre-commit hook
if [ -f ".githooks/pre-commit" ]; then
    echo "✅ Pre-commit hook exists"
else
    echo "⚠️  Pre-commit hook missing"
fi

# Test GitLeaks config
if [ -f ".gitleaks.toml" ]; then
    echo "✅ GitLeaks configuration exists"
else
    echo "⚠️  GitLeaks configuration missing"
fi

# Step 6: Create local .env template for development
echo ""
echo "📋 Step 6: Setting up development environment..."

if [ ! -f "app/.env" ]; then
    echo "Creating app/.env from template..."
    cp app/.env.example app/.env
    echo ""
    echo "📝 IMPORTANT: Edit app/.env with your real Supabase credentials:"
    echo "   1. Go to: https://app.supabase.com/project/_/settings/api"
    echo "   2. Copy your Project URL and anon/public key"
    echo "   3. Replace the placeholder values in app/.env"
    echo ""
else
    echo "⚠️  app/.env already exists - please verify it contains real credentials"
fi

# Step 7: Final security scan
echo ""
echo "🔍 Step 7: Final security verification..."
if gitleaks detect --source . --config .gitleaks.toml --no-git; then
    echo "✅ Security scan passed!"
else
    echo "❌ Security issues still detected. Please review and fix before continuing."
    exit 1
fi

# Step 8: Summary and next steps
echo ""
echo "🎉 Security Setup Complete!"
echo "=========================="
echo ""
echo "✅ What's been done:"
echo "   • GitLeaks installed and configured"
echo "   • Sensitive files removed from git tracking"
echo "   • .env.example template created"
echo "   • Git hooks configured for automatic scanning"
echo "   • Development .env template created"
echo ""
echo "📋 Next steps:"
echo "   1. Edit app/.env with your real Supabase credentials"
echo "   2. Test the app: ./run_dev.sh"
echo "   3. Verify pre-commit protection: git commit (should scan automatically)"
echo "   4. Review SECURITY.md for full guidelines"
echo ""
echo "🔄 To rotate keys in the future:"
echo "   1. Generate new keys in Supabase dashboard"
echo "   2. Update app/.env locally"
echo "   3. Update GitHub Secrets for CI/CD"
echo "   4. Revoke old keys"
echo ""
echo "💡 Remember: Never commit .env files or real credentials!"

# Optional: Create a baseline for GitLeaks
echo ""
read -p "📊 Create GitLeaks baseline for existing warnings? (y/N): " create_baseline
if [[ $create_baseline =~ ^[Yy]$ ]]; then
    gitleaks detect --source . --config .gitleaks.toml --no-git --report-path .gitleaks-baseline.json
    echo "✅ GitLeaks baseline created in .gitleaks-baseline.json"
    echo "   Use --baseline-path .gitleaks-baseline.json to ignore existing issues"
fi

echo ""
echo "🔒 Security setup complete! Your secrets are now properly protected." 