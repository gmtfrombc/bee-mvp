# BEE Momentum Meter - Developer Documentation

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.5.11 · Developer Documentation and Deployment Guides  
**Status:** ✅ Complete  
**Created:** December 2024  

---

## 📋 **Table of Contents**

1. [Quick Start Guide](#quick-start-guide)
2. [Architecture Overview](#architecture-overview)
3. [Setup and Installation](#setup-and-installation)
4. [API Reference](#api-reference)
5. [Testing Guide](#testing-guide)
6. [Deployment Guide](#deployment-guide)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting](#troubleshooting)
9. [Contributing Guidelines](#contributing-guidelines)

---

## 🚀 **Quick Start Guide**

### **Prerequisites**
- Flutter 3.32+ 
- Dart 3.0+
- Supabase account and project
- Firebase project (for notifications)
- iOS 12+ / Android API 21+

### **5-Minute Setup**
```bash
# 1. Clone and setup
cd app
flutter pub get

# 2. Configure environment
cp .env.example .env
# Edit .env with your Supabase credentials

# 3. Run the app
flutter run --debug
```

### **Basic Usage**
```dart
// Display momentum meter
MomentumGauge(
  state: MomentumState.rising,
  percentage: 85.0,
  size: 140,
  onTap: () => showMomentumDetailModal(context, momentumData),
)

// Watch momentum data with Riverpod
final momentumAsync = ref.watch(realtimeMomentumProvider);
```

---

## 🏗️ **Architecture Overview**

### **High-Level Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  Screens  │  Widgets  │  Providers  │  State Management    │
│           │           │             │  (Riverpod)          │
├─────────────────────────────────────────────────────────────┤
│                     Domain Layer                            │
├─────────────────────────────────────────────────────────────┤
│  Models   │  Use Cases │  Repositories │  Business Logic   │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│  API Services │  Cache │  Local Storage │  Network         │
├─────────────────────────────────────────────────────────────┤
│                   Infrastructure                            │
├─────────────────────────────────────────────────────────────┤
│  Supabase │  Firebase │  Connectivity │  Offline Support   │
└─────────────────────────────────────────────────────────────┘
```

### **Key Components**

#### **1. Momentum Gauge Widget**
- **Location**: `app/lib/features/momentum/presentation/widgets/momentum_gauge.dart`
- **Purpose**: Core circular progress indicator with state-based theming
- **Features**: Animations, haptic feedback, accessibility support

#### **2. State Management (Riverpod)**
- **Location**: `app/lib/features/momentum/presentation/providers/`
- **Purpose**: Reactive state management with offline support
- **Key Providers**: `realtimeMomentumProvider`, `momentumApiServiceProvider`

#### **3. API Service**
- **Location**: `app/lib/features/momentum/data/services/momentum_api_service.dart`
- **Purpose**: Supabase integration with caching and offline support
- **Features**: Real-time subscriptions, error handling, retry logic

#### **4. Offline Cache**
- **Location**: `app/lib/core/services/offline_cache_service.dart`
- **Purpose**: Comprehensive offline support with intelligent caching
- **Features**: Background sync, cache health monitoring, data prioritization

---

## ⚙️ **Setup and Installation**

### **Environment Configuration**

#### **1. Create .env file**
```bash
# Copy template
cp .env.example .env
```

#### **2. Configure Supabase**
```env
# .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ENVIRONMENT=development
```

#### **3. Firebase Setup (Optional - for notifications)**
```bash
# iOS
cp ios/Runner/GoogleService-Info.plist.template ios/Runner/GoogleService-Info.plist
# Edit with your Firebase config

# Android  
cp android/app/google-services.json.template android/app/google-services.json
# Edit with your Firebase config
```

### **Dependencies Installation**
```bash
# Install Flutter dependencies
flutter pub get

# iOS additional setup
cd ios && pod install && cd ..

# Android additional setup (if needed)
cd android && ./gradlew clean && cd ..
```

### **Database Setup**

#### **1. Supabase Tables**
```sql
-- Daily engagement scores
CREATE TABLE daily_engagement_scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  date DATE NOT NULL,
  score DECIMAL(5,2) NOT NULL,
  activities JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Momentum notifications
CREATE TABLE momentum_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Coach interventions
CREATE TABLE coach_interventions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  trigger_type TEXT NOT NULL,
  intervention_type TEXT NOT NULL,
  scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **2. Row Level Security (RLS)**
```sql
-- Enable RLS
ALTER TABLE daily_engagement_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE momentum_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_interventions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own engagement scores" ON daily_engagement_scores
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own engagement scores" ON daily_engagement_scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Similar policies for other tables...
```

---

## 📚 **API Reference**

### **Core Providers**

#### **realtimeMomentumProvider**
```dart
// Watch momentum data with real-time updates
final momentumAsync = ref.watch(realtimeMomentumProvider);

momentumAsync.when(
  data: (momentumData) => MomentumCard(momentumData: momentumData),
  loading: () => const SkeletonMomentumCard(),
  error: (error, stack) => MomentumErrorWidget(error: error),
);
```

#### **momentumControllerProvider**
```dart
// Manual refresh and state management
final controller = ref.read(momentumControllerProvider);

// Refresh momentum data
await controller.refresh();

// Simulate state change (for testing)
await controller.simulateStateChange(MomentumState.rising);

// Calculate momentum score
await controller.calculateMomentumScore(targetDate: '2024-12-01');
```

#### **cacheManagementProvider**
```dart
// Cache management operations
final cacheManager = ref.read(cacheManagementProvider);

// Clear all cache
await cacheManager.clearCache();

// Get cache statistics
final stats = await cacheManager.getCacheStats();

// Warm cache with fresh data
await cacheManager.warmCache();

// Process pending offline actions
await cacheManager.processPendingActions();
```

### **Widget API**

#### **MomentumGauge**
```dart
MomentumGauge(
  state: MomentumState.rising,           // Required: momentum state
  percentage: 85.0,                      // Required: progress percentage
  size: 140.0,                          // Optional: gauge size (default: 120)
  showGlow: true,                       // Optional: glow effect (default: true)
  animationDuration: Duration(milliseconds: 1500), // Optional: animation timing
  stateTransitionDuration: Duration(milliseconds: 1000), // Optional: transition timing
  onTap: () => showDetailModal(),       // Optional: tap callback
)
```

#### **MomentumCard**
```dart
MomentumCard(
  momentumData: momentumData,           // Required: momentum data object
  onTap: () => showDetailModal(),       // Optional: tap callback
  showActions: true,                    // Optional: show action buttons (default: true)
  compact: false,                       // Optional: compact layout (default: false)
)
```

#### **WeeklyTrendChart**
```dart
WeeklyTrendChart(
  weeklyTrend: weeklyTrendData,         // Required: weekly trend data
  height: 200.0,                       // Optional: chart height
  showEmojis: true,                     // Optional: show emoji markers (default: true)
  interactive: true,                    // Optional: enable touch interactions (default: true)
)
```

### **Data Models**

#### **MomentumData**
```dart
class MomentumData {
  final MomentumState state;            // Current momentum state
  final double percentage;              // Progress percentage (0-100)
  final String message;                 // Encouraging message
  final DateTime lastUpdated;           // Last update timestamp
  final List<DailyMomentum> weeklyTrend; // Weekly trend data
  final MomentumStats stats;            // Quick stats
  final bool isStale;                   // Cache staleness indicator
  
  // Factory constructors
  factory MomentumData.fromJson(Map<String, dynamic> json);
  factory MomentumData.mock({MomentumState? state, double? percentage});
  
  // Utility methods
  bool get isPositive => state == MomentumState.rising;
  bool get needsAttention => state == MomentumState.needsCare;
  Color get stateColor => AppTheme.getMomentumColor(state);
  String get stateEmoji => AppTheme.getMomentumEmoji(state);
}
```

#### **MomentumState Enum**
```dart
enum MomentumState {
  rising,     // 70%+ - Green - 🚀
  steady,     // 45-69% - Blue - 🙂  
  needsCare,  // <45% - Orange - 🌱
}

// Utility extensions
extension MomentumStateExtension on MomentumState {
  String get label => /* state label */;
  Color get color => /* state color */;
  String get emoji => /* state emoji */;
  String get message => /* encouraging message */;
}
```

---

## 🧪 **Testing Guide**

### **Test Structure**
```
app/test/
├── features/momentum/
│   ├── data/services/          # API service tests
│   ├── domain/models/          # Model tests  
│   └── presentation/
│       ├── providers/          # Provider tests
│       ├── screens/            # Screen tests
│       └── widgets/            # Widget tests
├── core/services/              # Core service tests
├── helpers/                    # Test utilities
└── integration_test/           # Integration tests
```

### **Running Tests**

#### **Unit Tests**
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/features/momentum/domain/models/momentum_data_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

#### **Widget Tests**
```bash
# Run widget tests
flutter test test/features/momentum/presentation/widgets/

# Run specific widget test
flutter test test/features/momentum/presentation/widgets/momentum_gauge_test.dart
```

#### **Integration Tests**
```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/momentum_flow_test.dart

# Run on device
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/momentum_flow_test.dart
```

#### **Performance Tests**
```bash
# Run performance tests
flutter test test/features/momentum/presentation/widgets/performance_test.dart

# Profile memory usage
flutter test --enable-vmservice test/features/momentum/presentation/widgets/performance_test.dart
```

### **Test Examples**

#### **Widget Test Example**
```dart
testWidgets('MomentumGauge displays correct state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
        ),
      ),
    ),
  );

  // Verify gauge renders
  expect(find.byType(MomentumGauge), findsOneWidget);
  
  // Verify emoji is displayed
  expect(find.text('🚀'), findsOneWidget);
  
  // Verify accessibility
  expect(
    tester.getSemantics(find.byType(MomentumGauge)),
    matchesSemantics(label: contains('Rising momentum')),
  );
});
```

#### **Provider Test Example**
```dart
testWidgets('realtimeMomentumProvider provides data', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, child) {
            final momentumAsync = ref.watch(realtimeMomentumProvider);
            return momentumAsync.when(
              data: (data) => Text('State: ${data.state}'),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            );
          },
        ),
      ),
    ),
  );

  // Wait for data to load
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));

  // Verify data is displayed
  expect(find.textContaining('State:'), findsOneWidget);
});
```

### **Test Coverage Goals**
- **Unit Tests**: 90%+ coverage for business logic
- **Widget Tests**: 80%+ coverage for UI components  
- **Integration Tests**: 70%+ coverage for user flows
- **Overall**: 80%+ combined test coverage

---

## 🚀 **Deployment Guide**

### **Environment Setup**

#### **Development Environment**
```bash
# Set development environment
export ENVIRONMENT=development

# Run with debug configuration
flutter run --debug --dart-define=ENVIRONMENT=development
```

#### **Staging Environment**
```bash
# Set staging environment
export ENVIRONMENT=staging

# Build for staging
flutter build apk --dart-define=ENVIRONMENT=staging
flutter build ios --dart-define=ENVIRONMENT=staging
```

#### **Production Environment**
```bash
# Set production environment
export ENVIRONMENT=production

# Build for production
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### **Build Configuration**

#### **Android Build**
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release

# Build with specific flavor
flutter build apk --flavor production --release
```

#### **iOS Build**
```bash
# Debug build
flutter build ios --debug

# Release build  
flutter build ios --release

# Archive for App Store
flutter build ipa --release

# Build with specific scheme
flutter build ios --release --flavor production
```

### **CI/CD Pipeline**

#### **GitHub Actions Example**
```yaml
# .github/workflows/deploy.yml
name: Deploy Momentum Meter

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
      
      - name: Install dependencies
        run: flutter pub get
        working-directory: ./app
      
      - name: Run tests
        run: flutter test --coverage
        working-directory: ./app
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./app/coverage/lcov.info

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build APK
        run: flutter build apk --release
        working-directory: ./app
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: app/build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
        working-directory: ./app
```

### **Environment Variables**

#### **Required Environment Variables**
```bash
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Environment
ENVIRONMENT=production

# Optional: Firebase (for notifications)
FIREBASE_PROJECT_ID=your-firebase-project
```

#### **Secure Environment Management**
```bash
# Use flutter_dotenv for environment management
dependencies:
  flutter_dotenv: ^5.1.0

# Load environment in main.dart
await dotenv.load(fileName: ".env");
```

### **Database Migration**

#### **Supabase Migrations**
```bash
# Install Supabase CLI
npm install -g supabase

# Initialize project
supabase init

# Create migration
supabase migration new create_momentum_tables

# Apply migrations
supabase db push

# Deploy to production
supabase db push --linked
```

### **Monitoring and Analytics**

#### **Performance Monitoring**
```dart
// Add performance monitoring
dependencies:
  firebase_performance: ^0.9.3

// Initialize in main.dart
await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
```

#### **Crash Reporting**
```dart
// Add crash reporting
dependencies:
  firebase_crashlytics: ^3.4.8

// Initialize in main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

#### **Analytics**
```dart
// Add analytics
dependencies:
  firebase_analytics: ^10.7.4

// Track momentum events
await FirebaseAnalytics.instance.logEvent(
  name: 'momentum_state_changed',
  parameters: {
    'from_state': oldState.name,
    'to_state': newState.name,
    'percentage': percentage,
  },
);
```

---

## ⚡ **Performance Optimization**

### **Animation Performance**

#### **Optimization Techniques**
```dart
// Use single animation controller for multiple animations
late AnimationController _controller;
late Animation<double> _progressAnimation;
late Animation<double> _bounceAnimation;

// Optimize with RepaintBoundary
RepaintBoundary(
  child: MomentumGauge(
    state: state,
    percentage: percentage,
  ),
);

// Use const constructors where possible
const MomentumGauge(
  state: MomentumState.rising,
  percentage: 85.0,
);
```

#### **Memory Management**
```dart
// Dispose animation controllers properly
@override
void dispose() {
  _progressController.dispose();
  _bounceController.dispose();
  _stateTransitionController.dispose();
  super.dispose();
}

// Use object pooling for frequent allocations
class MomentumDataPool {
  static final List<MomentumData> _pool = [];
  
  static MomentumData acquire() {
    return _pool.isNotEmpty ? _pool.removeLast() : MomentumData();
  }
  
  static void release(MomentumData data) {
    data.reset();
    _pool.add(data);
  }
}
```

### **Network Optimization**

#### **Caching Strategy**
```dart
// Implement intelligent caching
class MomentumCache {
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const int _maxCacheSize = 100;
  
  static final Map<String, CacheEntry> _cache = {};
  
  static Future<MomentumData?> get(String key) async {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data;
    }
    return null;
  }
  
  static void set(String key, MomentumData data) {
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }
    _cache[key] = CacheEntry(data, DateTime.now());
  }
}
```

#### **Offline Support**
```dart
// Implement robust offline support
class OfflineMomentumService {
  static Future<MomentumData> getMomentumWithFallback() async {
    try {
      // Try network first
      return await _networkService.getMomentum();
    } catch (e) {
      // Fall back to cache
      final cached = await _cacheService.getCachedMomentum();
      if (cached != null) {
        return cached.copyWith(isStale: true);
      }
      throw OfflineException('No cached data available');
    }
  }
}
```

### **Build Optimization**

#### **Code Splitting**
```dart
// Use deferred loading for large features
import 'package:momentum_analytics/analytics.dart' deferred as analytics;

// Load when needed
await analytics.loadLibrary();
analytics.trackMomentumEvent(event);
```

#### **Asset Optimization**
```yaml
# Optimize assets in pubspec.yaml
flutter:
  assets:
    - assets/images/
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
          weight: 700
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **1. Supabase Connection Issues**
```dart
// Problem: "Failed to connect to Supabase"
// Solution: Check environment configuration
if (!Environment.hasValidConfiguration) {
  debugPrint('❌ Missing Supabase configuration');
  debugPrint('Check SUPABASE_URL and SUPABASE_ANON_KEY in .env');
}

// Debug connection
try {
  final response = await supabase.from('daily_engagement_scores').select().limit(1);
  debugPrint('✅ Supabase connection successful');
} catch (e) {
  debugPrint('❌ Supabase connection failed: $e');
}
```

#### **2. Animation Performance Issues**
```dart
// Problem: Animations are choppy
// Solution: Optimize animation controllers
class OptimizedMomentumGauge extends StatefulWidget {
  @override
  State<OptimizedMomentumGauge> createState() => _OptimizedMomentumGaugeState();
}

class _OptimizedMomentumGaugeState extends State<OptimizedMomentumGauge>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    // Use single controller for better performance
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### **3. Memory Leaks**
```dart
// Problem: Memory usage keeps increasing
// Solution: Proper disposal and weak references
class MomentumProvider extends StateNotifier<AsyncValue<MomentumData>> {
  StreamSubscription? _subscription;
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

#### **4. Offline Data Sync Issues**
```dart
// Problem: Data not syncing when back online
// Solution: Implement sync queue
class SyncQueue {
  static final List<SyncAction> _queue = [];
  
  static void addAction(SyncAction action) {
    _queue.add(action);
    _processSyncQueue();
  }
  
  static Future<void> _processSyncQueue() async {
    while (_queue.isNotEmpty && await ConnectivityService.isOnline()) {
      final action = _queue.removeAt(0);
      try {
        await action.execute();
      } catch (e) {
        _queue.insert(0, action); // Re-queue on failure
        break;
      }
    }
  }
}
```

### **Debug Tools**

#### **Performance Profiling**
```dart
// Add performance monitoring
class PerformanceMonitor {
  static void startTrace(String name) {
    if (kDebugMode) {
      debugPrint('🔍 Starting trace: $name');
    }
  }
  
  static void endTrace(String name) {
    if (kDebugMode) {
      debugPrint('✅ Ending trace: $name');
    }
  }
  
  static void logMemoryUsage() {
    if (kDebugMode) {
      final info = ProcessInfo.currentRss;
      debugPrint('💾 Memory usage: ${info ~/ 1024 ~/ 1024} MB');
    }
  }
}
```

#### **Network Debugging**
```dart
// Add network request logging
class NetworkLogger {
  static void logRequest(String method, String url, Map<String, dynamic>? data) {
    if (kDebugMode) {
      debugPrint('🌐 $method $url');
      if (data != null) {
        debugPrint('📤 Request data: $data');
      }
    }
  }
  
  static void logResponse(int statusCode, dynamic data) {
    if (kDebugMode) {
      debugPrint('📥 Response $statusCode: $data');
    }
  }
}
```

### **Logging and Monitoring**

#### **Structured Logging**
```dart
// Implement structured logging
class Logger {
  static void info(String message, {Map<String, dynamic>? context}) {
    _log('INFO', message, context);
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, {'error': error?.toString(), 'stack': stackTrace?.toString()});
  }
  
  static void _log(String level, String message, Map<String, dynamic>? context) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'message': message,
      'context': context,
    };
    
    if (kDebugMode) {
      debugPrint(jsonEncode(logEntry));
    }
    
    // Send to monitoring service in production
    if (kReleaseMode) {
      MonitoringService.log(logEntry);
    }
  }
}
```

---

## 🤝 **Contributing Guidelines**

### **Development Workflow**

#### **1. Setup Development Environment**
```bash
# Fork and clone repository
git clone https://github.com/your-username/bee-mvp.git
cd bee-mvp/app

# Install dependencies
flutter pub get

# Create feature branch
git checkout -b feature/momentum-enhancement
```

#### **2. Code Standards**
```dart
// Follow Dart style guide
// Use meaningful variable names
final MomentumData currentMomentumData = await apiService.getCurrentMomentum();

// Add comprehensive documentation
/// Calculates momentum score based on engagement activities
/// 
/// [activities] List of user engagement activities
/// [timeWindow] Time window for calculation (default: 7 days)
/// 
/// Returns [MomentumScore] with calculated value and metadata
/// 
/// Throws [MomentumCalculationException] if calculation fails
Future<MomentumScore> calculateMomentumScore({
  required List<EngagementActivity> activities,
  Duration timeWindow = const Duration(days: 7),
}) async {
  // Implementation
}
```

#### **3. Testing Requirements**
```bash
# Run all tests before committing
flutter test

# Ensure coverage meets requirements
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run integration tests
flutter test integration_test/
```

#### **4. Commit Guidelines**
```bash
# Use conventional commits
git commit -m "feat(momentum): add celebration animation for positive state transitions"
git commit -m "fix(cache): resolve memory leak in offline cache service"
git commit -m "docs(api): update momentum provider documentation"
git commit -m "test(widget): add comprehensive tests for momentum gauge"
```

### **Pull Request Process**

#### **1. Pre-PR Checklist**
- [ ] All tests passing
- [ ] Code coverage meets requirements (80%+)
- [ ] Documentation updated
- [ ] Performance impact assessed
- [ ] Accessibility tested
- [ ] Cross-platform compatibility verified

#### **2. PR Template**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Performance Impact
- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance impact assessed and acceptable

## Screenshots/Videos
(If applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests passing
```

### **Code Review Guidelines**

#### **Review Criteria**
1. **Functionality**: Does the code work as intended?
2. **Performance**: Is the code efficient and optimized?
3. **Maintainability**: Is the code readable and well-structured?
4. **Testing**: Are there adequate tests with good coverage?
5. **Documentation**: Is the code properly documented?
6. **Accessibility**: Does the code meet accessibility requirements?

#### **Review Process**
1. **Automated Checks**: CI/CD pipeline runs tests and checks
2. **Code Review**: Team members review code changes
3. **Testing**: QA team tests functionality
4. **Approval**: Senior developer approves changes
5. **Merge**: Changes merged to main branch

---

## 📞 **Support and Resources**

### **Documentation Links**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

### **Team Contacts**
- **Tech Lead**: [tech-lead@momentumhealth.com]
- **Product Manager**: [product@momentumhealth.com]
- **Design Team**: [design@momentumhealth.com]
- **QA Team**: [qa@momentumhealth.com]

### **Issue Reporting**
- **Bug Reports**: Use GitHub Issues with bug template
- **Feature Requests**: Use GitHub Issues with feature template
- **Security Issues**: Email security@momentumhealth.com

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Maintainer**: BEE Development Team  
**License**: Proprietary - Momentum Health Inc. 