# BEE Momentum Meter - Production Deployment Guide

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.5.11 · Developer Documentation and Deployment Guides  
**Status:** ✅ Complete  
**Created:** December 2024  

---

## 📋 **Table of Contents**

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Configuration](#environment-configuration)
3. [Database Setup](#database-setup)
4. [Build and Release Process](#build-and-release-process)
5. [Infrastructure Setup](#infrastructure-setup)
6. [Monitoring and Alerting](#monitoring-and-alerting)
7. [Rollback Procedures](#rollback-procedures)
8. [Post-Deployment Verification](#post-deployment-verification)

---

## ✅ **Pre-Deployment Checklist**

### **Code Quality Gates**
- [ ] All unit tests passing (90%+ coverage)
- [ ] All widget tests passing (80%+ coverage)
- [ ] All integration tests passing (70%+ coverage)
- [ ] Performance tests meeting benchmarks
- [ ] Accessibility tests passing (WCAG AA compliance)
- [ ] Security scan completed with no critical issues
- [ ] Code review approved by senior developers
- [ ] Documentation updated and reviewed

### **Environment Readiness**
- [ ] Production Supabase project configured
- [ ] Firebase project setup for notifications
- [ ] SSL certificates valid and configured
- [ ] CDN configured for asset delivery
- [ ] Monitoring tools configured
- [ ] Backup systems verified
- [ ] Disaster recovery plan reviewed

### **Stakeholder Approval**
- [ ] Product team sign-off
- [ ] Design team approval
- [ ] Clinical team validation
- [ ] Security team clearance
- [ ] Legal/compliance review completed

---

## 🔧 **Environment Configuration**

### **Production Environment Variables**

#### **Required Configuration**
```bash
# Production .env file
ENVIRONMENT=production
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Firebase Configuration
FIREBASE_PROJECT_ID=bee-mvp-production
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_APP_ID=your-firebase-app-id

# Security Configuration
API_RATE_LIMIT=1000
SESSION_TIMEOUT=3600
ENCRYPTION_KEY=your-encryption-key

# Monitoring Configuration
SENTRY_DSN=your-sentry-dsn
ANALYTICS_TRACKING_ID=your-analytics-id
LOG_LEVEL=info
```

#### **Environment Validation Script**
```bash
#!/bin/bash
# validate-environment.sh

echo "🔍 Validating production environment..."

# Check required environment variables
required_vars=(
  "SUPABASE_URL"
  "SUPABASE_ANON_KEY"
  "FIREBASE_PROJECT_ID"
  "ENVIRONMENT"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Missing required environment variable: $var"
    exit 1
  else
    echo "✅ $var is set"
  fi
done

# Validate Supabase connection
echo "🔍 Testing Supabase connection..."
curl -s -H "apikey: $SUPABASE_ANON_KEY" \
     -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
     "$SUPABASE_URL/rest/v1/" > /dev/null

if [ $? -eq 0 ]; then
  echo "✅ Supabase connection successful"
else
  echo "❌ Supabase connection failed"
  exit 1
fi

echo "✅ Environment validation complete"
```

### **Security Configuration**

#### **Row Level Security (RLS) Policies**
```sql
-- Production RLS policies for momentum data
CREATE POLICY "production_user_momentum_access" ON daily_engagement_scores
  FOR ALL USING (
    auth.uid() = user_id AND 
    auth.jwt() ->> 'aud' = 'authenticated'
  );

CREATE POLICY "production_coach_intervention_access" ON coach_interventions
  FOR SELECT USING (
    auth.uid() = user_id OR 
    auth.jwt() ->> 'role' = 'coach'
  );

-- Enable audit logging
CREATE TABLE audit_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  user_id UUID,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (table_name, operation, old_data, new_data, user_id)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
    auth.uid()
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
```

---

## 🗄️ **Database Setup**

### **Production Database Migration**

#### **Migration Script**
```sql
-- Production database setup script
-- Run with elevated privileges

-- 1. Create production tables
\i migrations/001_create_momentum_tables.sql
\i migrations/002_create_notification_tables.sql
\i migrations/003_create_coach_intervention_tables.sql
\i migrations/004_create_audit_tables.sql

-- 2. Set up indexes for performance
CREATE INDEX CONCURRENTLY idx_daily_engagement_user_date 
ON daily_engagement_scores(user_id, date DESC);

CREATE INDEX CONCURRENTLY idx_momentum_notifications_user_sent 
ON momentum_notifications(user_id, sent_at DESC);

CREATE INDEX CONCURRENTLY idx_coach_interventions_scheduled 
ON coach_interventions(scheduled_at) 
WHERE completed_at IS NULL;

-- 3. Enable RLS on all tables
ALTER TABLE daily_engagement_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE momentum_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_interventions ENABLE ROW LEVEL SECURITY;

-- 4. Create production policies
\i policies/production_rls_policies.sql

-- 5. Set up monitoring views
CREATE VIEW momentum_health_check AS
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN date = CURRENT_DATE THEN 1 END) as active_today,
  AVG(score) as avg_score,
  MAX(updated_at) as last_update
FROM daily_engagement_scores
WHERE date >= CURRENT_DATE - INTERVAL '7 days';

-- 6. Create backup procedures
CREATE OR REPLACE FUNCTION backup_momentum_data()
RETURNS void AS $$
BEGIN
  -- Export critical data to backup tables
  CREATE TABLE IF NOT EXISTS backup_daily_engagement_scores AS
  SELECT * FROM daily_engagement_scores WHERE false;
  
  INSERT INTO backup_daily_engagement_scores
  SELECT * FROM daily_engagement_scores
  WHERE date >= CURRENT_DATE - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;
```

#### **Database Performance Tuning**
```sql
-- Production performance optimizations

-- 1. Optimize connection pooling
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';

-- 2. Enable query optimization
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- 3. Configure logging for monitoring
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET log_checkpoints = on;
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;

-- Reload configuration
SELECT pg_reload_conf();
```

---

## 🚀 **Build and Release Process**

### **Automated Build Pipeline**

#### **GitHub Actions Production Workflow**
```yaml
# .github/workflows/app-release.yml
name: Production Deployment

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true
        type: string

env:
  FLUTTER_VERSION: '3.32.0'
  JAVA_VERSION: '17'

jobs:
  validate:
    name: Validate Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Install dependencies
        run: flutter pub get
        working-directory: ./app
        
      - name: Run security scan
        run: |
          flutter pub deps
          flutter analyze --fatal-infos
        working-directory: ./app
        
      - name: Run comprehensive tests
        run: |
          flutter test --coverage
          flutter test integration_test/
        working-directory: ./app
        
      - name: Validate test coverage
        run: |
          lcov --summary coverage/lcov.info | grep -E "lines\.*: [8-9][0-9]\.[0-9]%|lines\.*: 100\.0%"
        working-directory: ./app

  build-android:
    name: Build Android Release
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: ${{ env.JAVA_VERSION }}
          
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Configure signing
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 -d > android/app/keystore.jks
          echo "storeFile=keystore.jks" >> android/key.properties
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
        working-directory: ./app
        
      - name: Build production APK
        run: |
          flutter build apk --release \
            --dart-define=ENVIRONMENT=production \
            --dart-define=SUPABASE_URL=${{ secrets.PROD_SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.PROD_SUPABASE_ANON_KEY }}
        working-directory: ./app
        
      - name: Build App Bundle
        run: |
          flutter build appbundle --release \
            --dart-define=ENVIRONMENT=production \
            --dart-define=SUPABASE_URL=${{ secrets.PROD_SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.PROD_SUPABASE_ANON_KEY }}
        working-directory: ./app
        
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.momentumhealth.beemvp
          releaseFiles: app/build/app/outputs/bundle/release/app-release.aab
          track: production
          status: completed

  build-ios:
    name: Build iOS Release
    needs: validate
    runs-on: macos-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Install CocoaPods
        run: gem install cocoapods
        
      - name: Setup certificates
        run: |
          echo "${{ secrets.IOS_CERTIFICATE }}" | base64 -d > certificate.p12
          echo "${{ secrets.IOS_PROVISIONING_PROFILE }}" | base64 -d > profile.mobileprovision
          
          # Install certificate
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}" -A
          security set-keychain-settings build.keychain
          security unlock-keychain -p "" build.keychain
          
          # Install provisioning profile
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
          
      - name: Build iOS release
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=ENVIRONMENT=production \
            --dart-define=SUPABASE_URL=${{ secrets.PROD_SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.PROD_SUPABASE_ANON_KEY }}
        working-directory: ./app
        
      - name: Build IPA
        run: |
          xcodebuild -workspace ios/Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -destination generic/platform=iOS \
            -archivePath build/Runner.xcarchive \
            archive
            
          xcodebuild -exportArchive \
            -archivePath build/Runner.xcarchive \
            -exportPath build \
            -exportOptionsPlist ios/ExportOptions.plist
        working-directory: ./app
        
      - name: Upload to App Store
        run: |
          xcrun altool --upload-app \
            --type ios \
            --file "build/Runner.ipa" \
            --username "${{ secrets.APPLE_ID_EMAIL }}" \
            --password "${{ secrets.APPLE_ID_PASSWORD }}"
        working-directory: ./app

  deploy-backend:
    name: Deploy Backend Services
    needs: [build-android, build-ios]
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Supabase CLI
        run: npm install -g supabase
        
      - name: Deploy database migrations
        run: |
          supabase db push --linked --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          
      - name: Deploy Edge Functions
        run: |
          supabase functions deploy momentum-score-calculator --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
          supabase functions deploy push-notification-triggers --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

  post-deployment:
    name: Post-Deployment Tasks
    needs: [deploy-backend]
    runs-on: ubuntu-latest
    steps:
      - name: Run health checks
        run: |
          # Test API endpoints
          curl -f "${{ secrets.PROD_SUPABASE_URL }}/rest/v1/health" \
            -H "apikey: ${{ secrets.PROD_SUPABASE_ANON_KEY }}"
            
      - name: Warm up caches
        run: |
          # Trigger cache warming
          curl -X POST "${{ secrets.PROD_SUPABASE_URL }}/functions/v1/warm-cache" \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}"
            
      - name: Send deployment notification
        uses: 8398a7/action-slack@v3
        with:
          status: success
          text: '🚀 Momentum Meter v${{ github.ref_name }} deployed successfully to production!'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### **Manual Release Process**

#### **Pre-Release Steps**
```bash
#!/bin/bash
# manual-release.sh

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: ./manual-release.sh <version>"
  exit 1
fi

echo "🚀 Starting manual release process for version $VERSION"

# 1. Validate environment
echo "🔍 Validating environment..."
./scripts/validate-environment.sh

# 2. Run comprehensive tests
echo "🧪 Running comprehensive tests..."
cd app
flutter test --coverage
flutter test integration_test/

# 3. Build release artifacts
echo "🔨 Building release artifacts..."
flutter clean
flutter pub get

# Android
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# iOS
flutter build ios --release --dart-define=ENVIRONMENT=production

# 4. Create release tag
echo "🏷️ Creating release tag..."
git tag -a "v$VERSION" -m "Release version $VERSION"
git push origin "v$VERSION"

# 5. Deploy backend services
echo "🌐 Deploying backend services..."
supabase db push --linked
supabase functions deploy --no-verify-jwt

echo "✅ Manual release process completed for version $VERSION"
echo "📱 Upload artifacts to app stores manually"
```

---

## 🏗️ **Infrastructure Setup**

### **Supabase Production Configuration**

#### **Database Configuration**
```sql
-- Production database settings
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET pg_stat_statements.track = 'all';

-- Connection pooling
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '512MB';
ALTER SYSTEM SET effective_cache_size = '2GB';

-- Performance tuning
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET seq_page_cost = 1.0;
ALTER SYSTEM SET cpu_tuple_cost = 0.01;

-- Logging configuration
ALTER SYSTEM SET log_statement = 'mod';
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';

SELECT pg_reload_conf();
```

#### **Edge Functions Configuration**
```typescript
// supabase/functions/momentum-score-calculator/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Production-ready momentum calculation logic
    const { data, error } = await supabaseClient
      .from('daily_engagement_scores')
      .select('*')
      .order('date', { ascending: false })
      .limit(30)

    if (error) throw error

    // Calculate momentum with production algorithm
    const momentum = calculateMomentumScore(data)

    return new Response(
      JSON.stringify({ momentum }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

function calculateMomentumScore(scores: any[]): any {
  // Production momentum calculation algorithm
  // Implementation details...
}
```

### **Firebase Production Setup**

#### **Firebase Configuration**
```json
{
  "projects": {
    "production": "bee-mvp-production"
  },
  "targets": {
    "bee-mvp-production": {
      "hosting": {
        "web": ["bee-mvp-web-prod"]
      }
    }
  },
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs18"
  }
}
```

---

## 📊 **Monitoring and Alerting**

### **Application Performance Monitoring**

#### **Sentry Configuration**
```dart
// lib/core/services/monitoring_service.dart
import 'package:sentry_flutter/sentry_flutter.dart';

class MonitoringService {
  static Future<void> initialize() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = Environment.sentryDsn;
        options.environment = Environment.environment;
        options.release = Environment.appVersion;
        
        // Performance monitoring
        options.tracesSampleRate = Environment.isProduction ? 0.1 : 1.0;
        options.profilesSampleRate = Environment.isProduction ? 0.1 : 1.0;
        
        // Error filtering
        options.beforeSend = (event, hint) {
          // Filter out non-critical errors in production
          if (Environment.isProduction && event.level == SentryLevel.info) {
            return null;
          }
          return event;
        };
        
        // Performance filtering
        options.beforeSendTransaction = (transaction, hint) {
          // Sample transactions in production
          if (Environment.isProduction && 
              transaction.contexts.trace?.operation == 'navigation') {
            return Math.random() < 0.1 ? transaction : null;
          }
          return transaction;
        };
      },
    );
  }
  
  static void captureException(dynamic exception, {StackTrace? stackTrace}) {
    Sentry.captureException(exception, stackTrace: stackTrace);
  }
  
  static void captureMessage(String message, {SentryLevel? level}) {
    Sentry.captureMessage(message, level: level ?? SentryLevel.info);
  }
  
  static void addBreadcrumb(String message, {String? category}) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      timestamp: DateTime.now(),
    ));
  }
}
```

#### **Custom Metrics Dashboard**
```dart
// lib/core/services/metrics_service.dart
class MetricsService {
  static final Map<String, int> _counters = {};
  static final Map<String, List<double>> _timings = {};
  
  static void incrementCounter(String name, {Map<String, String>? tags}) {
    _counters[name] = (_counters[name] ?? 0) + 1;
    
    // Send to monitoring service
    if (Environment.isProduction) {
      _sendMetric('counter', name, _counters[name]!, tags: tags);
    }
  }
  
  static void recordTiming(String name, Duration duration, {Map<String, String>? tags}) {
    _timings[name] ??= [];
    _timings[name]!.add(duration.inMilliseconds.toDouble());
    
    // Send to monitoring service
    if (Environment.isProduction) {
      _sendMetric('timing', name, duration.inMilliseconds.toDouble(), tags: tags);
    }
  }
  
  static void recordGauge(String name, double value, {Map<String, String>? tags}) {
    // Send to monitoring service
    if (Environment.isProduction) {
      _sendMetric('gauge', name, value, tags: tags);
    }
  }
  
  static Future<void> _sendMetric(
    String type, 
    String name, 
    double value, 
    {Map<String, String>? tags}
  ) async {
    // Implementation for sending metrics to monitoring service
    // (e.g., DataDog, New Relic, CloudWatch)
  }
}
```

### **Health Check Endpoints**

#### **Application Health Check**
```dart
// lib/core/services/health_check_service.dart
class HealthCheckService {
  static Future<Map<String, dynamic>> getHealthStatus() async {
    final checks = <String, dynamic>{};
    
    // Database connectivity
    checks['database'] = await _checkDatabase();
    
    // Cache health
    checks['cache'] = await _checkCache();
    
    // External services
    checks['supabase'] = await _checkSupabase();
    checks['firebase'] = await _checkFirebase();
    
    // Application metrics
    checks['memory'] = await _checkMemoryUsage();
    checks['performance'] = await _checkPerformance();
    
    final overallHealth = checks.values.every((check) => check['status'] == 'healthy');
    
    return {
      'status': overallHealth ? 'healthy' : 'unhealthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': Environment.appVersion,
      'environment': Environment.environment,
      'checks': checks,
    };
  }
  
  static Future<Map<String, dynamic>> _checkDatabase() async {
    try {
      final stopwatch = Stopwatch()..start();
      // Test database query
      await Supabase.instance.client
          .from('daily_engagement_scores')
          .select('id')
          .limit(1);
      stopwatch.stop();
      
      return {
        'status': 'healthy',
        'response_time_ms': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _checkCache() async {
    try {
      final stats = await OfflineCacheService.getEnhancedCacheStats();
      final healthScore = stats['healthScore'] ?? 0;
      
      return {
        'status': healthScore > 70 ? 'healthy' : 'degraded',
        'health_score': healthScore,
        'cache_size': stats['totalSize'],
        'hit_rate': stats['hitRate'],
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
      };
    }
  }
}
```

### **Alerting Configuration**

#### **Alert Rules**
```yaml
# monitoring/alerts.yml
alerts:
  - name: "High Error Rate"
    condition: "error_rate > 5%"
    duration: "5m"
    severity: "critical"
    channels: ["slack", "email", "pagerduty"]
    
  - name: "Slow API Response"
    condition: "api_response_time_p95 > 2s"
    duration: "10m"
    severity: "warning"
    channels: ["slack"]
    
  - name: "Low Cache Hit Rate"
    condition: "cache_hit_rate < 80%"
    duration: "15m"
    severity: "warning"
    channels: ["slack"]
    
  - name: "Database Connection Issues"
    condition: "database_connection_errors > 0"
    duration: "1m"
    severity: "critical"
    channels: ["slack", "email", "pagerduty"]
    
  - name: "Memory Usage High"
    condition: "memory_usage > 80%"
    duration: "10m"
    severity: "warning"
    channels: ["slack"]
```

---

## 🔄 **Rollback Procedures**

### **Automated Rollback**

#### **Rollback Script**
```bash
#!/bin/bash
# rollback.sh

set -e

PREVIOUS_VERSION=$1
if [ -z "$PREVIOUS_VERSION" ]; then
  echo "Usage: ./rollback.sh <previous_version>"
  exit 1
fi

echo "🔄 Starting rollback to version $PREVIOUS_VERSION"

# 1. Verify previous version exists
if ! git tag -l | grep -q "v$PREVIOUS_VERSION"; then
  echo "❌ Version v$PREVIOUS_VERSION not found"
  exit 1
fi

# 2. Create rollback branch
git checkout -b "rollback-to-v$PREVIOUS_VERSION"
git reset --hard "v$PREVIOUS_VERSION"

# 3. Rollback database migrations (if needed)
echo "🗄️ Checking database migrations..."
./scripts/rollback-migrations.sh "$PREVIOUS_VERSION"

# 4. Rollback Edge Functions
echo "⚡ Rolling back Edge Functions..."
supabase functions deploy momentum-score-calculator --project-ref $SUPABASE_PROJECT_REF

# 5. Build and deploy previous version
echo "🔨 Building previous version..."
cd app
flutter clean
flutter pub get

# Build for both platforms
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build ios --release --dart-define=ENVIRONMENT=production

# 6. Deploy to app stores (manual step)
echo "📱 Manual step: Upload artifacts to app stores"
echo "   - Android: app/build/app/outputs/apk/release/app-release.apk"
echo "   - iOS: Build IPA from Xcode"

# 7. Update monitoring
echo "📊 Updating monitoring tags..."
curl -X POST "$MONITORING_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "{\"event\": \"rollback\", \"version\": \"$PREVIOUS_VERSION\"}"

echo "✅ Rollback to version $PREVIOUS_VERSION completed"
echo "⚠️  Remember to:"
echo "   - Update app store listings"
echo "   - Notify users if necessary"
echo "   - Monitor error rates"
```

### **Database Rollback**

#### **Migration Rollback Script**
```bash
#!/bin/bash
# rollback-migrations.sh

TARGET_VERSION=$1
CURRENT_VERSION=$(supabase migration list --linked | tail -1 | cut -d' ' -f1)

echo "🗄️ Rolling back database from $CURRENT_VERSION to $TARGET_VERSION"

# Get list of migrations to rollback
MIGRATIONS_TO_ROLLBACK=$(supabase migration list --linked | \
  awk -v target="$TARGET_VERSION" '$1 > target {print $1}' | \
  sort -r)

for migration in $MIGRATIONS_TO_ROLLBACK; do
  echo "⏪ Rolling back migration: $migration"
  
  # Check if rollback script exists
  if [ -f "supabase/migrations/${migration}_rollback.sql" ]; then
    supabase db reset --linked
    # Apply migrations up to target version
    # This is a simplified approach - in production, use proper migration tools
  else
    echo "⚠️  No rollback script found for migration $migration"
    echo "   Manual intervention may be required"
  fi
done

echo "✅ Database rollback completed"
```

---

## ✅ **Post-Deployment Verification**

### **Automated Verification Tests**

#### **Production Smoke Tests**
```dart
// test/production/smoke_tests.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Production Smoke Tests', () {
    const baseUrl = 'https://your-prod-project.supabase.co';
    const apiKey = 'your-prod-anon-key';
    
    test('API health check', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/rest/v1/health'),
        headers: {'apikey': apiKey},
      );
      
      expect(response.statusCode, 200);
    });
    
    test('Database connectivity', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/rest/v1/daily_engagement_scores?limit=1'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );
      
      expect(response.statusCode, 200);
    });
    
    test('Edge Functions responding', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/functions/v1/momentum-score-calculator'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: '{"test": true}',
      );
      
      expect(response.statusCode, 200);
    });
  });
}
```

#### **Performance Verification**
```bash
#!/bin/bash
# verify-performance.sh

echo "🚀 Running production performance verification..."

# 1. API response time check
echo "📡 Testing API response times..."
for endpoint in "/rest/v1/health" "/functions/v1/momentum-score-calculator"; do
  response_time=$(curl -w "%{time_total}" -s -o /dev/null \
    -H "apikey: $SUPABASE_ANON_KEY" \
    "$SUPABASE_URL$endpoint")
  
  if (( $(echo "$response_time > 2.0" | bc -l) )); then
    echo "⚠️  Slow response time for $endpoint: ${response_time}s"
  else
    echo "✅ $endpoint: ${response_time}s"
  fi
done

# 2. Database query performance
echo "🗄️ Testing database performance..."
query_time=$(psql "$DATABASE_URL" -c "\timing on" -c "SELECT COUNT(*) FROM daily_engagement_scores;" 2>&1 | \
  grep "Time:" | awk '{print $2}' | sed 's/ms//')

if (( $(echo "$query_time > 100" | bc -l) )); then
  echo "⚠️  Slow database query: ${query_time}ms"
else
  echo "✅ Database query: ${query_time}ms"
fi

# 3. Cache hit rate check
echo "💾 Checking cache performance..."
cache_stats=$(curl -s -H "apikey: $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/functions/v1/cache-stats")

hit_rate=$(echo "$cache_stats" | jq -r '.hit_rate')
if (( $(echo "$hit_rate < 0.8" | bc -l) )); then
  echo "⚠️  Low cache hit rate: $hit_rate"
else
  echo "✅ Cache hit rate: $hit_rate"
fi

echo "✅ Performance verification completed"
```

### **User Acceptance Testing**

#### **Production UAT Checklist**
```markdown
# Production User Acceptance Testing

## Core Functionality
- [ ] User can view momentum meter
- [ ] Momentum states display correctly (Rising/Steady/Needs Care)
- [ ] Real-time updates work properly
- [ ] Offline mode functions correctly
- [ ] Notifications are received and actionable

## Performance
- [ ] App loads within 3 seconds
- [ ] Animations are smooth (60 FPS)
- [ ] Memory usage stays under 100MB
- [ ] Battery drain is minimal

## Accessibility
- [ ] Screen reader compatibility verified
- [ ] High contrast mode works
- [ ] Text scaling functions properly
- [ ] Voice control works correctly

## Cross-Platform
- [ ] iOS functionality verified
- [ ] Android functionality verified
- [ ] Consistent behavior across platforms

## Security
- [ ] User data is properly protected
- [ ] API endpoints are secure
- [ ] Authentication works correctly
- [ ] Data encryption is functioning

## Integration
- [ ] Supabase integration working
- [ ] Firebase notifications working
- [ ] Coach dashboard integration working
- [ ] Analytics tracking functioning
```

### **Monitoring Dashboard Setup**

#### **Key Metrics to Monitor**
```yaml
# monitoring/dashboard.yml
dashboard:
  name: "Momentum Meter Production"
  
  sections:
    - name: "Application Health"
      widgets:
        - type: "status"
          title: "Overall Health"
          query: "health_check.status"
          
        - type: "gauge"
          title: "Error Rate"
          query: "error_rate_5m"
          thresholds: [1, 5, 10]
          
        - type: "line_chart"
          title: "Response Time"
          query: "api_response_time_p95"
          timeframe: "1h"
    
    - name: "User Engagement"
      widgets:
        - type: "counter"
          title: "Active Users"
          query: "active_users_24h"
          
        - type: "line_chart"
          title: "Momentum State Distribution"
          query: "momentum_states"
          timeframe: "24h"
          
        - type: "heatmap"
          title: "Usage Patterns"
          query: "user_activity_heatmap"
    
    - name: "Infrastructure"
      widgets:
        - type: "gauge"
          title: "Database CPU"
          query: "database_cpu_usage"
          thresholds: [70, 85, 95]
          
        - type: "gauge"
          title: "Cache Hit Rate"
          query: "cache_hit_rate"
          thresholds: [60, 80, 90]
          
        - type: "line_chart"
          title: "Memory Usage"
          query: "memory_usage"
          timeframe: "6h"
```

---

## 📞 **Support and Escalation**

### **Incident Response Plan**

#### **Severity Levels**
- **P0 (Critical)**: App completely down, data loss, security breach
- **P1 (High)**: Major functionality broken, significant user impact
- **P2 (Medium)**: Minor functionality issues, limited user impact
- **P3 (Low)**: Cosmetic issues, no user impact

#### **Escalation Matrix**
```yaml
escalation:
  P0:
    immediate: ["on-call-engineer", "tech-lead", "product-manager"]
    15min: ["engineering-manager", "cto"]
    30min: ["ceo", "legal-team"]
    
  P1:
    immediate: ["on-call-engineer"]
    30min: ["tech-lead"]
    2h: ["engineering-manager"]
    
  P2:
    immediate: ["on-call-engineer"]
    4h: ["tech-lead"]
    
  P3:
    next_business_day: ["assigned-engineer"]
```

#### **Contact Information**
```yaml
contacts:
  on_call_engineer: "+1-555-0123"
  tech_lead: "tech-lead@momentumhealth.com"
  product_manager: "product@momentumhealth.com"
  engineering_manager: "eng-manager@momentumhealth.com"
  
  external_services:
    supabase_support: "support@supabase.com"
    firebase_support: "firebase-support@google.com"
    app_store_support: "developer.apple.com/contact"
    play_store_support: "support.google.com/googleplay"
```

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Maintainer**: BEE Development Team  
**Next Review**: January 2025 