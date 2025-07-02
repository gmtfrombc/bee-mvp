# Component Refactoring Guide

**Project:** BEE App - Component Size Compliance  
**Version:** 1.0  
**Based on:** Sprints 1-5 Refactoring Experience  
**Status:** Active

## Overview

This guide provides practical, step-by-step instructions for refactoring oversized components in the BEE application. It's based on real experience from Sprints 1-5 of the component size audit refactor plan.

## When to Refactor

### Size Violation Thresholds

| Violation Level | Action Required | Timeline |
|----------------|-----------------|----------|
| **Critical (>50% over limit)** | Immediate refactoring | Current sprint |
| **Moderate (20-50% over limit)** | Plan refactoring | Next 1-2 sprints |
| **Minor (<20% over limit)** | Monitor and prevent growth | Ongoing |

### Quality Indicators

Refactor when you notice:
- Difficult to understand component purpose
- Multiple reasons for changes
- Hard to test specific functionality
- Performance issues
- Code duplication within component

## Refactoring Methodology

### The 5-Step Process

1. **Analyze** - Understand current structure
2. **Plan** - Identify extraction opportunities
3. **Extract** - Create focused components
4. **Test** - Verify functionality preserved
5. **Optimize** - Improve and document

## Step 1: Analyze Current Structure

### Component Analysis Checklist

```bash
# Check current size
wc -l path/to/component.dart

# Identify logical sections
grep -n "Widget\|class\|void\|Future" path/to/component.dart

# Look for repeated patterns
grep -n "Container\|Column\|Row\|Text" path/to/component.dart
```

### Identify Extraction Candidates

**Look for:**
- **Logical Groupings:** Related UI elements
- **Reusable Sections:** Code used in multiple places
- **Independent Functionality:** Self-contained features
- **Different Change Frequencies:** Code that changes together

**Example Analysis:**
```dart
// BEFORE: CoachDashboardScreen (946 lines)
class CoachDashboardScreen extends StatefulWidget {
  // Lines 1-50: State management and initialization
  // Lines 51-150: App bar building
  // Lines 151-350: Overview tab content
  // Lines 351-550: Active interventions tab
  // Lines 551-750: Scheduled interventions tab  
  // Lines 751-946: Analytics tab and helpers
}
```

**Analysis Results:**
- **5 logical sections** identified
- **4 tab contents** can be extracted
- **Different change frequencies** (tabs change independently)
- **Reusable patterns** (similar tab structure)

## Step 2: Plan Extraction Strategy

### Create Extraction Plan

```markdown
## Extraction Plan: CoachDashboardScreen

### Target: Reduce from 946 lines to ~400 lines

**Phase 1: Extract Tab Components**
- [ ] CoachOverviewTab (~200 lines)
- [ ] CoachActiveInterventionsTab (~180 lines)  
- [ ] CoachScheduledInterventionsTab (~160 lines)
- [ ] CoachAnalyticsTab (~200 lines)

**Phase 2: Extract Shared Components**
- [ ] CoachDashboardFilters (~150 lines)
- [ ] CoachStatisticsCards (~200 lines)

**Estimated Result:** 400 lines main screen + 6 focused components
```

### Define Component Boundaries

```dart
// PLANNED STRUCTURE:
class CoachDashboardScreen extends StatefulWidget {
  // ~400 lines - coordination and layout
  // Uses: TabBar, navigation, shared state
}

class CoachOverviewTab extends ConsumerWidget {
  // ~200 lines - overview dashboard content
  // Uses: CoachStatisticsCards, CoachDashboardFilters
}

class CoachStatisticsCards extends StatelessWidget {
  // ~200 lines - reusable stat card grid
  // Uses: Pure UI components
}
```

## Step 3: Extract Components

### Extraction Order

**1. Start with Pure UI Components**
- No state dependencies
- Easy to test
- Low risk

**2. Extract Business Logic Components**
- Self-contained functionality
- Clear interfaces

**3. Extract Stateful Components**
- Complex state management
- Higher risk, more testing needed

### Widget Extraction Example

**Before: Monolithic Widget**
```dart
class TodayFeedTile extends StatefulWidget {
  @override
  _TodayFeedTileState createState() => _TodayFeedTileState();
}

class _TodayFeedTileState extends State<TodayFeedTile> 
    with TickerProviderStateMixin {
  
  // 200+ lines of animation setup
  late AnimationController _entryController;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  // ... more animation code
  
  @override
  void initState() {
    super.initState();
    // 100+ lines of animation initialization
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            // 200+ lines of UI building
            child: Column(
              children: [
                // 150+ lines of header
                // 200+ lines of content
                // 100+ lines of actions
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 200+ lines of interaction handlers
  void _handleTap() { }
  void _handleShare() { }
  void _handleBookmark() { }
  
  @override
  void dispose() {
    // Animation cleanup
    super.dispose();
  }
}
```

**After: Step 1 - Extract Animation Controller**
```dart
// NEW FILE: today_feed_animation_controller.dart
class TodayFeedAnimationController {
  late AnimationController entryController;
  late AnimationController tapController;
  late Animation<double> scaleAnimation;
  
  TodayFeedAnimationController({required TickerProvider vsync}) {
    _initializeAnimations(vsync);
  }
  
  void _initializeAnimations(TickerProvider vsync) {
    // ~200 lines - focused animation logic
  }
  
  void dispose() {
    entryController.dispose();
    tapController.dispose();
  }
}

// UPDATED: today_feed_tile.dart  
class _TodayFeedTileState extends State<TodayFeedTile> 
    with TickerProviderStateMixin {
  
  late TodayFeedAnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = TodayFeedAnimationController(vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController.entryController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.scaleAnimation.value,
          child: TodayFeedTileContent(
            onTap: _handleTap,
            onShare: _handleShare,
            onBookmark: _handleBookmark,
          ),
        );
      },
    );
  }
  
  // Interaction handlers remain here for now
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

**After: Step 2 - Extract UI Content**
```dart
// NEW FILE: today_feed_tile_content.dart
class TodayFeedTileContent extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  
  const TodayFeedTileContent({
    super.key,
    this.onTap,
    this.onShare,
    this.onBookmark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // ~200 lines - pure UI logic
      child: Column(
        children: [
          TodayFeedTileHeader(),
          TodayFeedTileBody(),
          TodayFeedTileActions(
            onTap: onTap,
            onShare: onShare,
            onBookmark: onBookmark,
          ),
        ],
      ),
    );
  }
}
```

### Service Extraction Example

**Before: Monolithic Service**
```dart
class TodayFeedCacheService {
  // Data management (200 lines)
  Future<List<FeedItem>> fetchItems() { }
  Future<void> cacheItems(List<FeedItem> items) { }
  
  // Validation (150 lines)
  bool validateItem(FeedItem item) { }
  List<ValidationError> getValidationErrors(FeedItem item) { }
  
  // Statistics (200 lines)
  CacheStats getCacheStatistics() { }
  PerformanceMetrics getPerformanceMetrics() { }
  
  // Health monitoring (150 lines)
  HealthStatus getHealthStatus() { }
  List<HealthIssue> getHealthIssues() { }
  
  // 693 total lines
}
```

**After: Focused Services**
```dart
// NEW FILE: today_feed_cache_data_service.dart
class TodayFeedCacheDataService {
  // ~200 lines - core data operations
  Future<List<FeedItem>> fetchItems() { }
  Future<void> cacheItems(List<FeedItem> items) { }
  Future<void> clearCache() { }
}

// NEW FILE: today_feed_cache_validation_service.dart
class TodayFeedCacheValidationService {
  // ~150 lines - validation logic
  bool validateItem(FeedItem item) { }
  List<ValidationError> getValidationErrors(FeedItem item) { }
}

// NEW FILE: today_feed_cache_statistics_service.dart
class TodayFeedCacheStatisticsService {
  // ~200 lines - statistics and metrics
  CacheStats getCacheStatistics() { }
  PerformanceMetrics getPerformanceMetrics() { }
}

// NEW FILE: today_feed_cache_health_service.dart
class TodayFeedCacheHealthService {
  // ~150 lines - health monitoring
  HealthStatus getHealthStatus() { }
  List<HealthIssue> getHealthIssues() { }
}

// UPDATED: today_feed_cache_service.dart
class TodayFeedCacheService {
  // ~100 lines - coordination and facade
  final TodayFeedCacheDataService _dataService;
  final TodayFeedCacheValidationService _validationService;
  final TodayFeedCacheStatisticsService _statisticsService;
  final TodayFeedCacheHealthService _healthService;
  
  TodayFeedCacheService({
    required TodayFeedCacheDataService dataService,
    required TodayFeedCacheValidationService validationService,
    required TodayFeedCacheStatisticsService statisticsService,
    required TodayFeedCacheHealthService healthService,
  }) : _dataService = dataService,
       _validationService = validationService,
       _statisticsService = statisticsService,
       _healthService = healthService;
  
  // Facade methods that delegate to appropriate services
}
```

## Step 4: Test After Each Extraction

### Testing Strategy

**1. Run Existing Tests**
```bash
# Run all tests
flutter test

# Run specific feature tests
flutter test test/features/today_feed/

# Run integration tests
flutter test integration_test/
```

**2. Create New Tests for Extracted Components**
```dart
// TEST: today_feed_animation_controller_test.dart
void main() {
  group('TodayFeedAnimationController', () {
    late TodayFeedAnimationController controller;
    late TickerProvider mockVsync;
    
    setUp(() {
      mockVsync = TestVSync();
      controller = TodayFeedAnimationController(vsync: mockVsync);
    });
    
    test('initializes animations correctly', () {
      expect(controller.entryController, isNotNull);
      expect(controller.tapController, isNotNull);
      expect(controller.scaleAnimation, isNotNull);
    });
    
    test('disposes animations properly', () {
      controller.dispose();
      // Verify no memory leaks
    });
  });
}
```

**3. Visual Regression Testing**
```bash
# Take screenshots before refactoring
flutter test --plain-name="golden test"

# Compare after refactoring
flutter test --update-goldens
```

### Verification Checklist

- [ ] All existing tests pass
- [ ] New component tests created
- [ ] Visual appearance unchanged
- [ ] Performance not degraded
- [ ] Memory usage not increased
- [ ] All functionality preserved

## Step 5: Optimize and Document

### Code Optimization

**1. Remove Duplication**
```dart
// BEFORE: Duplicated code
class ComponentA extends StatelessWidget {
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text('Header'),
    );
  }
}

class ComponentB extends StatelessWidget {
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text('Header'),
    );
  }
}

// AFTER: Shared component
class SharedHeader extends StatelessWidget {
  final String title;
  
  const SharedHeader({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(title),
    );
  }
}
```

**2. Improve Interfaces**
```dart
// BEFORE: Unclear interface
class DataWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  
  DataWidget({required this.data});
}

// AFTER: Clear, typed interface
class UserProfileCard extends StatelessWidget {
  final User user;
  final VoidCallback? onEdit;
  final bool isEditable;
  
  const UserProfileCard({
    super.key,
    required this.user,
    this.onEdit,
    this.isEditable = false,
  });
}
```

### Documentation Updates

**1. Component Documentation**
```dart
/// A card widget that displays user profile information.
/// 
/// This widget shows the user's avatar, name, email, and optional
/// edit button. It follows the BEE design system guidelines.
/// 
/// Example usage:
/// ```dart
/// UserProfileCard(
///   user: currentUser,
///   onEdit: () => navigateToEditProfile(),
///   isEditable: true,
/// )
/// ```
class UserProfileCard extends StatelessWidget {
  /// The user whose profile to display
  final User user;
  
  /// Callback invoked when edit button is tapped
  final VoidCallback? onEdit;
  
  /// Whether to show the edit button
  final bool isEditable;
  
  // Implementation...
}
```

**2. Update Architecture Documentation**
```markdown
## Updated Component Structure

### TodayFeedTile (was 1,261 lines → now ~300 lines)

**Main Component:**
- `TodayFeedTile` - Main widget, coordinates animations and interactions

**Extracted Components:**
- `TodayFeedAnimationController` - Animation logic (200 lines)
- `TodayFeedTileContent` - UI content (200 lines)
- `TodayFeedInteractionHandler` - User interactions (150 lines)
- `TodayFeedStateManager` - State management (100 lines)

**Benefits:**
- ✅ Easier to test individual concerns
- ✅ Reusable animation controller
- ✅ Clear separation of responsibilities
- ✅ Improved maintainability
```

## Common Refactoring Patterns

### Pattern 1: Extract Helper Widgets

**Use When:** UI building methods are large

```dart
// BEFORE
class ComplexForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),      // 50+ lines
        _buildFormFields(),  // 100+ lines
        _buildActions(),     // 30+ lines
      ],
    );
  }
  
  Widget _buildHeader() {
    // 50+ lines of header building
  }
  
  // More large helper methods...
}

// AFTER
class ComplexForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormHeader(),
        FormFields(),
        FormActions(),
      ],
    );
  }
}

class FormHeader extends StatelessWidget {
  // Focused header widget
}
```

### Pattern 2: Extract State Logic

**Use When:** State management becomes complex

```dart
// BEFORE
class _ComplexScreenState extends State<ComplexScreen> {
  // 20+ state variables
  bool _isLoading = false;
  String _searchTerm = '';
  List<Item> _items = [];
  // ... more state
  
  // 100+ lines of state management methods
  void _handleSearch(String term) { }
  void _loadItems() { }
  void _updateFilter(Filter filter) { }
  
  @override
  Widget build(BuildContext context) {
    // UI building
  }
}

// AFTER
class ComplexScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(complexScreenProvider);
    return ComplexScreenUI(state: state);
  }
}

class ComplexScreenNotifier extends StateNotifier<ComplexScreenState> {
  // Focused state management
}
```

### Pattern 3: Extract Service Facades

**Use When:** Service has multiple responsibilities

```dart
// BEFORE
class LargeService {
  // Multiple concerns mixed together
}

// AFTER
class LargeService {
  // Coordinates specialized services
  final DataService _dataService;
  final ValidationService _validationService;
  final CacheService _cacheService;
  
  // Facade methods
}
```

## Common Pitfalls and Solutions

### Pitfall 1: Over-extraction

**Problem:** Creating too many tiny components

```dart
// ❌ Over-extracted
class UserName extends StatelessWidget {
  final String name;
  UserName({required this.name});
  
  @override
  Widget build(BuildContext context) {
    return Text(name);
  }
}

class UserEmail extends StatelessWidget {
  final String email;
  UserEmail({required this.email});
  
  @override
  Widget build(BuildContext context) {
    return Text(email);
  }
}
```

**Solution:** Keep related simple elements together

```dart
// ✅ Appropriately sized
class UserInfo extends StatelessWidget {
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(user.name),
        Text(user.email),
      ],
    );
  }
}
```

### Pitfall 2: Unclear Interfaces

**Problem:** Components with unclear responsibilities

```dart
// ❌ Unclear interface
class DataWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function callback;
  final bool flag;
}
```

**Solution:** Clear, typed interfaces

```dart
// ✅ Clear interface
class UserProfileCard extends StatelessWidget {
  final User user;
  final VoidCallback? onEdit;
  final bool showEditButton;
}
```

### Pitfall 3: Breaking Existing Functionality

**Problem:** Refactoring breaks existing behavior

**Solutions:**
- Test after each small change
- Use feature flags during refactoring
- Keep old and new code side by side initially
- Use comprehensive test coverage

## Success Metrics

### Quantitative Metrics

**Before Refactoring:**
- Component size: XXX lines
- Test coverage: XX%
- Build time: XX seconds
- Cyclomatic complexity: XX

**After Refactoring:**
- Component size: XXX lines (within guidelines)
- Test coverage: XX% (maintained or improved)
- Build time: XX seconds (maintained or improved)
- Number of components: XX (focused components)

### Qualitative Metrics

**Developer Experience:**
- ✅ Easier to understand component purpose
- ✅ Faster to locate specific functionality
- ✅ Simpler to add new features
- ✅ More confident making changes

**Code Quality:**
- ✅ Clear separation of concerns
- ✅ Reusable components
- ✅ Better test coverage
- ✅ Reduced code duplication

## Tools and Resources

### Analysis Tools

```bash
# Component size analysis
find app/lib -name "*.dart" -exec wc -l {} + | sort -nr

# Complexity analysis (if available)
dart analyze --packages

# Test coverage
flutter test --coverage
```

### IDE Support

**VS Code Extensions:**
- Dart/Flutter extensions
- Test coverage visualization
- Code metrics

**Refactoring Shortcuts:**
- Extract Method: `Ctrl+Shift+R`
- Extract Widget: Custom quick fix
- Rename: `F2`

### Team Tools

```bash
# Check compliance
./scripts/check_component_sizes.sh

# Generate refactoring report
./scripts/component_size_audit.sh

# Test pre-commit hooks
git add . && git commit -m "Test refactoring"
```

## Checklist for Successful Refactoring

### Pre-Refactoring
- [ ] Understand current component structure
- [ ] Identify extraction opportunities
- [ ] Create refactoring plan
- [ ] Ensure good test coverage
- [ ] Set up feature flags if needed

### During Refactoring
- [ ] Extract one component at a time
- [ ] Test after each extraction
- [ ] Maintain clear interfaces
- [ ] Document extracted components
- [ ] Update related tests

### Post-Refactoring
- [ ] Verify all tests pass
- [ ] Check performance hasn't degraded
- [ ] Update documentation
- [ ] Remove old, unused code
- [ ] Share learnings with team

---

## Quick Reference

### When to Extract
- Component > size guidelines
- Multiple responsibilities
- Hard to understand/test
- Code duplication

### Extraction Order
1. Pure UI components (lowest risk)
2. Business logic components
3. Stateful components (highest risk)

### Success Criteria
- ✅ Component within size guidelines
- ✅ All tests passing
- ✅ Functionality preserved
- ✅ Performance maintained
- ✅ Clear component boundaries

### Resources
- **Size Guidelines:** `docs/architecture/component_guidelines.md`
- **Developer Workflow:** `docs/development/component_size_workflow.md`
- **Architecture Governance:** `docs/architecture/component_governance.md`

---

*This guide is based on real refactoring experience from the BEE app component size audit project. Update it as new patterns and techniques are discovered.* 