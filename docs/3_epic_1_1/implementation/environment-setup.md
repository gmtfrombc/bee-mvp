# Environment Setup Guide

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