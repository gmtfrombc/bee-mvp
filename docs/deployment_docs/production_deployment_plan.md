# BEE MVP Production Deployment Plan

> **Comprehensive plan to deploy current features from mock data to production app functionality**

**Document Version**: 1.0  
**Created**: December 2024  
**Last Updated**: December 2024  

---

## 🎯 **Deployment Overview**

### **Current State Analysis**
- **Flutter App**: Running with mock/sample data for testing
- **Supabase Database**: Deployed with full schema and migrations
- **Edge Functions**: `momentum-score-calculator` ready, others need audit
- **Infrastructure**: GCP Cloud Run configured but targeting legacy functions

### **Target State** 
- **Flutter App**: Connected to live Supabase backend
- **Real Data Flow**: Live momentum calculations, engagement tracking
- **Edge Functions**: Only essential functions deployed and monitored
- **Production Ready**: Error handling, monitoring, and scaling

---

## 📋 **Pre-Deployment Requirements**

### **1. Function Audit Completion**
- [x] ✅ **Sprint 1**: today-feed-generator (DELETE - completed)
- [x] ✅ **Sprint 2**: momentum-score-calculator (KEEP - completed & fixed)
- [ ] 🔄 **Sprint 3**: push-notification-triggers (KEEP - pending audit)
- [ ] 🔄 **Sprint 4**: realtime-momentum-sync (TBD - pending audit)
- [x] ✅ **Sprint 5**: momentum-intervention-engine (DELETE - functionality moved to CoachInterventionService)
- [x] ✅ **Sprint 6**: batch-events (DELETE - uses native Supabase batch insert)

### **2. Database Migration Status**
- [x] ✅ Core engagement events schema
- [x] ✅ Momentum tracking tables
- [x] ✅ FCM token management
- [x] ✅ Today feed content system
- [x] ✅ Push notification infrastructure
- [x] ✅ Performance optimization

### **3. Infrastructure Prerequisites**
- [ ] 🔄 Supabase Production Project setup
- [ ] 🔄 GCP Project configuration for production
- [ ] 🔄 Environment secrets management
- [ ] 🔄 Monitoring and alerting setup

---

## 🚀 **Phase 1: Core Backend Deployment** 
**Timeline**: Week 1  
**Goal**: Deploy essential functions and connect database

### **Step 1.1: Supabase Production Setup**
```bash
# 1. Create production Supabase project
supabase projects create bee-mvp-prod

# 2. Deploy database migrations
supabase db push --linked --include-all

# 3. Set up Edge Functions (essential only)
supabase functions deploy momentum-score-calculator
supabase functions deploy push-notification-triggers  # After audit

# 4. Configure environment variables
supabase secrets set --env-file .env.prod
```

**Required Environment Variables**:
```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# GCP (for monitoring)
GCP_PROJECT_ID=bee-mvp-prod
GCP_REGION=us-central1

# Firebase (for push notifications)
FCM_SERVER_KEY=your-fcm-server-key
```

### **Step 1.2: Edge Functions Deployment**
```bash
# Deploy momentum-score-calculator (already audited)
cd functions/momentum-score-calculator
supabase functions deploy momentum-score-calculator \
  --project-ref your-project-ref

# Verify deployment
curl -X POST "https://your-project.supabase.co/functions/v1/momentum-score-calculator" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","target_date":"2024-01-01"}'
```

### **Step 1.3: Database Row Level Security (RLS)**
```sql
-- Enable RLS on all tables
ALTER TABLE engagement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_engagement_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Create user-specific policies
CREATE POLICY "Users can only see their own data" ON engagement_events
FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only see their own scores" ON daily_engagement_scores
FOR ALL USING (auth.uid() = user_id);
```

---

## 📱 **Phase 2: Flutter App Migration**
**Timeline**: Week 2  
**Goal**: Switch from mock data to live backend

### **Step 2.1: Environment Configuration**
Create `app/lib/core/config/app_config.dart`:
```dart
class AppConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);
  
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-local-supabase-url.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-local-anon-key',
  );
}
```

### **Step 2.2: Service Layer Migration**
Modify `app/lib/features/momentum/data/services/momentum_api_service.dart`:
```dart
class MomentumApiService {
  Future<MomentumData> getCurrentMomentum() async {
    if (AppConfig.useMockData) {
      return MomentumData.sample(); // Keep for testing
    }
    
    // Production API call
    return await _callProductionMomentumAPI();
  }
  
  Future<MomentumData> _callProductionMomentumAPI() async {
    final response = await Supabase.instance.client.functions.invoke(
      'momentum-score-calculator',
      body: {
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'target_date': DateTime.now().toIso8601String(),
      },
    );
    
    if (response.status == 200) {
      return MomentumData.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch momentum: ${response.status}');
    }
  }
}
```

### **Step 2.3: Flutter Build Configuration**
Update `app/android/app/build.gradle`:
```gradle
android {
    ...
    buildTypes {
        debug {
            buildConfigField "boolean", "USE_MOCK_DATA", "true"
            buildConfigField "String", "SUPABASE_URL", "\"https://local-supabase.co\""
        }
        release {
            buildConfigField "boolean", "USE_MOCK_DATA", "false"
            buildConfigField "boolean", "PRODUCTION", "true"
            buildConfigField "String", "SUPABASE_URL", "\"https://prod-supabase.co\""
        }
    }
}
```

### **Step 2.4: Feature Flag Implementation**
```dart
class FeatureFlags {
  static bool get useRealTimeUpdates => AppConfig.isProduction;
  static bool get enablePushNotifications => AppConfig.isProduction;
  static bool get enableAnalytics => AppConfig.isProduction;
  static bool get showDebugInfo => !AppConfig.isProduction;
}
```

---

## 🔄 **Phase 3: Real-Time Features**
**Timeline**: Week 3  
**Goal**: Enable live data synchronization

### **Step 3.1: Supabase Real-Time Setup**
```dart
class RealtimeMomentumProvider extends StateNotifier<AsyncValue<MomentumData>> {
  RealtimeChannel? _subscription;
  
  @override
  void build() {
    if (FeatureFlags.useRealTimeUpdates) {
      _setupRealtimeSubscription();
    }
    return const AsyncValue.loading();
  }
  
  void _setupRealtimeSubscription() {
    _subscription = Supabase.instance.client
        .channel('momentum-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_engagement_scores',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: Supabase.instance.client.auth.currentUser?.id,
          ),
          callback: (payload) => _handleMomentumUpdate(payload),
        )
        .subscribe();
  }
}
```

### **Step 3.2: Push Notification Integration**
After `push-notification-triggers` audit completion:
```dart
class NotificationService {
  Future<void> initializeNotifications() async {
    if (!FeatureFlags.enablePushNotifications) return;
    
    // Initialize FCM
    await FirebaseMessaging.instance.requestPermission();
    
    // Get FCM token and register with backend
    final token = await FirebaseMessaging.instance.getToken();
    await _registerFCMToken(token);
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
```

---

## 📊 **Phase 4: Monitoring & Analytics** 
**Timeline**: Week 4  
**Goal**: Production monitoring and error handling

### **Step 4.1: Supabase Monitoring Setup**
```sql
-- Create monitoring functions
CREATE OR REPLACE FUNCTION public.log_function_call(
  function_name TEXT,
  user_id UUID,
  execution_time_ms INTEGER,
  success BOOLEAN,
  error_message TEXT DEFAULT NULL
) RETURNS void AS $$
BEGIN
  INSERT INTO function_call_logs (
    function_name, user_id, execution_time_ms, success, error_message, created_at
  ) VALUES (
    function_name, user_id, execution_time_ms, success, error_message, NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **Step 4.2: Flutter Error Reporting**
```dart
class ErrorReportingService {
  static Future<void> initialize() async {
    if (!AppConfig.isProduction) return;
    
    await SentryFlutter.init((options) {
      options.dsn = 'your-sentry-dsn';
      options.tracesSampleRate = 0.1;
    });
    
    FlutterError.onError = (details) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    };
  }
}
```

### **Step 4.3: Performance Monitoring**
```dart
class PerformanceMonitor {
  static Future<T> trackAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      _logSuccess(operationName, stopwatch.elapsedMilliseconds);
      return result;
    } catch (error, stackTrace) {
      _logError(operationName, stopwatch.elapsedMilliseconds, error);
      rethrow;
    }
  }
}
```

---

## 🧪 **Phase 5: Testing & Validation**
**Timeline**: Week 5  
**Goal**: Comprehensive testing in production environment

### **Step 5.1: Automated Testing Setup**
```bash
# Flutter integration tests against production
flutter test integration_test/production_flow_test.dart \
  --dart-define=PRODUCTION=true \
  --dart-define=SUPABASE_URL=$PROD_SUPABASE_URL

# Edge Function testing
deno test --allow-net --allow-env functions/momentum-score-calculator/test/
```

### **Step 5.2: User Acceptance Testing**
```yaml
# Test scenarios
scenarios:
  - name: "User Registration & First Momentum Score"
    steps:
      - Register new user account
      - Complete initial onboarding
      - Log first engagement event
      - Verify momentum score calculation
      - Check UI updates correctly
  
  - name: "Real-time Momentum Updates"
    steps:
      - User logs multiple engagement events
      - Verify real-time score updates
      - Check weekly trend visualization
      - Validate push notification triggers
  
  - name: "Offline/Online Synchronization"
    steps:
      - Log events while offline
      - Go back online
      - Verify event synchronization
      - Check score recalculation
```

### **Step 5.3: Load Testing**
```bash
# Test Edge Function performance
k6 run scripts/load-test-momentum-calculator.js

# Test database performance
pgbench -h your-db-host -p 5432 -U postgres -d bee_mvp \
  -c 10 -j 2 -T 60 -P 1
```

---

## 🔐 **Security Checklist**

### **Authentication & Authorization**
- [ ] ✅ Row Level Security enabled on all tables
- [ ] ✅ JWT token validation in Edge Functions
- [ ] ✅ User data isolation verified
- [ ] ✅ API rate limiting configured

### **Data Protection**
- [ ] ✅ Environment variables secured
- [ ] ✅ Database backup strategy implemented
- [ ] ✅ HTTPS enforced for all endpoints
- [ ] ✅ Sensitive data encryption at rest

### **Function Security**
- [ ] ✅ Input validation on all Edge Functions
- [ ] ✅ SQL injection prevention
- [ ] ✅ Error messages don't leak sensitive data
- [ ] ✅ Function timeout limits configured

---

## 📈 **Rollback Plan**

### **Immediate Rollback (< 5 minutes)**
```bash
# Revert Flutter app to mock data
flutter build apk --dart-define=USE_MOCK_DATA=true

# Disable problematic Edge Functions
supabase functions delete momentum-score-calculator --project-ref $PROJECT_REF
```

### **Database Rollback (< 15 minutes)**
```bash
# Restore from latest backup
supabase db reset --linked

# Revert specific migration if needed
supabase migration repair --status reverted
```

### **Infrastructure Rollback**
```bash
# Revert Terraform changes
cd infra/
terraform apply -var="deploy_functions=false"
```

---

## 📋 **Go-Live Checklist**

### **Pre-Launch (T-1 week)**
- [ ] All Edge Functions audited and essential ones deployed
- [ ] Database migrations applied and tested
- [ ] Flutter app tested with production backend
- [ ] Monitoring and alerting configured
- [ ] Security review completed
- [ ] Backup and recovery procedures tested

### **Launch Day (T-0)**
- [ ] Deploy production Flutter app with feature flags
- [ ] Monitor Edge Function performance
- [ ] Check database connection pool usage
- [ ] Verify user registration and authentication
- [ ] Confirm push notifications working
- [ ] Monitor error rates and response times

### **Post-Launch (T+1 day)**
- [ ] User feedback collection
- [ ] Performance metrics analysis
- [ ] Error rate review
- [ ] Database performance optimization
- [ ] Scale adjustments if needed

---

## 🎯 **Success Metrics**

### **Technical Metrics**
- **Edge Function Response Time**: < 2 seconds p95
- **Database Query Performance**: < 500ms p95  
- **App Launch Time**: < 3 seconds cold start
- **Error Rate**: < 1% for critical functions
- **Uptime**: > 99.9% availability

### **User Experience Metrics**
- **Momentum Score Accuracy**: Real-time updates within 30 seconds
- **Push Notification Delivery**: > 95% success rate
- **App Stability**: < 0.1% crash rate
- **User Engagement**: Increased session time with real data

### **Business Metrics**
- **User Retention**: Maintain > 80% week 1 retention
- **Feature Adoption**: > 60% users actively using momentum meter
- **Data Quality**: < 5% data discrepancies vs. expected values

---

**Document Status**: READY FOR EXECUTION  
**Next Review**: After Phase 1 completion  
**Owner**: Development Team  
**Approvers**: Product Team, DevOps Team 