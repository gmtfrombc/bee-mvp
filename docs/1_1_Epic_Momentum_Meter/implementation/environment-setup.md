# Environment Setup Guide

## VS Code Configuration

To fix "Context access might be invalid" warnings in VS Code, ensure you have the following files:

### 1. `.vscode/launch.json` (Already created)
This file configures VS Code debug launches with proper environment variables.

### 2. `.vscode/settings.json` (Already created)  
This file configures the Dart analyzer for development.

### 3. Environment Variables for Development

Create a `.env` file in the `app/` directory with the following structure:

```bash
# BEE App Environment Configuration
# Required for local development

ENVIRONMENT=development
SUPABASE_URL=your-development-supabase-url
SUPABASE_ANON_KEY=your-development-anon-key
SENTRY_DSN=your-sentry-dsn-for-error-tracking
APP_VERSION=1.0.0
FLUTTER_TEST=false
```

## Environment Variable Categories

### Local Development (Required in .env)
- `ENVIRONMENT` - development/staging/production
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anonymous key
- `SENTRY_DSN` - Error tracking (optional for dev)
- `FLUTTER_TEST` - Testing flag

### CI/CD Only (GitHub Secrets)
These variables are only used in GitHub Actions and should NOT be in your local .env:
- `PROD_SUPABASE_URL` - Production Supabase URL
- `PROD_SUPABASE_ANON_KEY` - Production Supabase key
- `ANDROID_KEYSTORE_BASE64` - Android signing keystore
- `KEYSTORE_PASSWORD` - Android keystore password
- `KEY_ALIAS` - Android key alias
- `KEY_PASSWORD` - Android key password
- `IOS_CERTIFICATE_BASE64` - iOS signing certificate
- `IOS_PROVISIONING_PROFILE_BASE64` - iOS provisioning profile
- `IOS_CERTIFICATE_PASSWORD` - iOS certificate password
- `SLACK_WEBHOOK_URL` - Slack notifications
- `MONITORING_WEBHOOK` - Monitoring alerts
- `GOOGLE_PLAY_SERVICE_ACCOUNT` - Google Play deployment

## Fixing VS Code Warnings

After creating the files above:

1. **Restart VS Code** - Close and reopen VS Code completely
2. **Reload Dart Analyzer** - Run "Dart: Restart Analysis Server" from command palette (Cmd+Shift+P)
3. **Run Flutter Clean** - Execute `flutter clean && flutter pub get` in the app directory

The "Context access might be invalid" warnings should disappear because:
- VS Code now knows about development environment variables via `.vscode/settings.json`
- The Dart analyzer is configured to ignore deployment-only variables
- Environment variable access is properly typed with default values

## Troubleshooting

If warnings persist:
1. Verify `.vscode/` files are in the project root
2. Check that `analysis_options.yaml` is in the `app/` directory
3. Ensure Flutter extension is updated
4. Restart VS Code completely

## Development Environment Configuration

Create a `.env` file in the `app/` directory with the following configuration:

```bash
# BEE Momentum Meter - Environment Configuration
# Copy this file to .env and fill in your actual values

# Environment type (development, staging, production)
ENVIRONMENT=development

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Monitoring Configuration (optional for development)
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# App Version (will be overridden by build system)
APP_VERSION=1.0.0-dev

# Firebase Configuration (optional for development)
FIREBASE_PROJECT_ID=your-firebase-project-id

# Monitoring Webhooks (optional)
MONITORING_WEBHOOK=https://your-monitoring-webhook-url
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

## Production Environment Variables

For production deployment, set these environment variables in your CI/CD system:

### Required Variables
- `ENVIRONMENT=production`
- `SUPABASE_URL` - Production Supabase URL
- `SUPABASE_ANON_KEY` - Production Supabase anonymous key
- `APP_VERSION` - Version being deployed
- `SENTRY_DSN` - Sentry DSN for error tracking

### Optional Variables
- `MONITORING_WEBHOOK` - Webhook for deployment notifications
- `SLACK_WEBHOOK_URL` - Slack webhook for alerts

## GitHub Secrets

Configure these secrets in your GitHub repository:

### Production Deployment
- `PROD_SUPABASE_URL`
- `PROD_SUPABASE_ANON_KEY`
- `SENTRY_DSN`
- `SLACK_WEBHOOK_URL`
- `MONITORING_WEBHOOK`

### Android Signing
- `ANDROID_KEYSTORE_BASE64` - Base64 encoded keystore file
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

### iOS Signing
- `IOS_CERTIFICATE_BASE64` - Base64 encoded certificate
- `IOS_PROVISIONING_PROFILE_BASE64` - Base64 encoded provisioning profile
- `IOS_CERTIFICATE_PASSWORD`

### App Store Deployment
- `GOOGLE_PLAY_SERVICE_ACCOUNT` - Google Play service account JSON
- `APPLE_ID` - Apple ID for App Store Connect
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password 