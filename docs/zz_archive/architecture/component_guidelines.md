# BEE Component Architecture Guidelines

**Version:** 1.0  
**Last Updated:** Post-Sprint 6  
**Status:** Active  
**Team:** BEE Development Team

## Overview

This document establishes the architectural guidelines for component design in the BEE application. These guidelines ensure consistency, maintainability, and scalability across the codebase while promoting best practices for Flutter development.

## Core Principles

### 1. Single Responsibility Principle
Every component should have one clear, well-defined purpose.

```dart
// ✅ Good: Single responsibility
class UserAvatarWidget extends StatelessWidget {
  // Focused solely on displaying user avatar
}

// ❌ Avoid: Multiple responsibilities
class UserCompleteProfileWidget extends StatelessWidget {
  // Handles avatar, profile form, validation, submission, etc.
}
```

### 2. Composition over Inheritance
Build complex UIs by composing smaller, focused components.

```dart
// ✅ Good: Composition
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileHeader(),
        ProfileForm(),
        ProfileActions(),
      ],
    );
  }
}

// ❌ Avoid: Monolithic widgets
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 200+ lines of header code
        // 300+ lines of form code
        // 100+ lines of action code
      ],
    );
  }
}
```

### 3. Clear Separation of Concerns
Separate presentation, business logic, and data concerns.

```dart
// ✅ Good: Clear separation
class MomentumCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentum = ref.watch(momentumProvider);
    return _buildCard(momentum);
  }
  
  Widget _buildCard(MomentumData momentum) {
    // Pure UI logic only
  }
}

// ❌ Avoid: Mixed concerns
class MomentumCard extends StatefulWidget {
  @override
  _MomentumCardState createState() => _MomentumCardState();
}

class _MomentumCardState extends State<MomentumCard> {
  @override
  Widget build(BuildContext context) {
    // Mixed: API calls, business logic, UI rendering all together
  }
}
```

## Component Size Guidelines

### Established Limits

| Component Type | Line Limit | Rationale |
|----------------|------------|-----------|
| **Services** | ≤500 lines | Maintain testability and single responsibility |
| **UI Widgets** | ≤300 lines | Promote reusability and reduce complexity |
| **Screen Components** | ≤400 lines | Allow complex layouts while maintaining structure |
| **Modal Components** | ≤250 lines | Ensure focused, lightweight interactions |
| **Models** | Flexible | Complex data structures are acceptable |

### Why These Limits?

- **Cognitive Load:** Easier to understand and modify
- **Testing:** Smaller components are easier to test
- **Reusability:** Focused components can be reused across features
- **Debugging:** Faster to locate and fix issues
- **Code Reviews:** More efficient review process

## Component Categories

### 1. Presentation Widgets
Pure UI components with no business logic.

```dart
class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  
  const ActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    // Pure UI rendering
  }
}
```

**Guidelines:**
- No business logic
- Accept data via constructor parameters
- Use callbacks for user interactions
- Maximum 200 lines

### 2. Smart Widgets (Consumer Widgets)
Components that interact with state management.

```dart
class MomentumGauge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentum = ref.watch(momentumProvider);
    return MomentumGaugePresentation(
      value: momentum.currentScore,
      target: momentum.targetScore,
    );
  }
}
```

**Guidelines:**
- Minimal business logic
- Delegate complex calculations to services
- Use provider/state management for data
- Maximum 250 lines

### 3. Screen Components
Top-level navigation components.

```dart
class MomentumScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: MomentumAppBar(),
      body: MomentumBody(),
      bottomNavigationBar: AppBottomNavigation(),
    );
  }
}
```

**Guidelines:**
- Coordinate layout and navigation
- Compose smaller widgets
- Handle screen-level state
- Maximum 400 lines

### 4. Service Classes
Business logic and data access.

```dart
class MomentumCalculationService {
  double calculateScore(List<EngagementEvent> events) {
    // Business logic for momentum calculation
  }
  
  Future<MomentumData> fetchMomentumData(String userId) {
    // Data fetching logic
  }
}
```

**Guidelines:**
- Pure business logic
- No UI dependencies
- Testable and mockable
- Maximum 500 lines

## Naming Conventions

### Component Names

```dart
// ✅ Good: Descriptive and specific
class UserProfileAvatarWidget extends StatelessWidget { }
class MomentumDailyScoreCard extends StatelessWidget { }
class CoachInterventionListItem extends StatelessWidget { }

// ❌ Avoid: Generic or unclear
class UserWidget extends StatelessWidget { }
class CardWidget extends StatelessWidget { }
class ListItem extends StatelessWidget { }
```

### File Naming

```
✅ Good:
user_profile_avatar_widget.dart
momentum_daily_score_card.dart
coach_intervention_list_item.dart

❌ Avoid:
user.dart
card.dart
widget1.dart
```

## Directory Structure

### Recommended Organization

```
lib/
├── core/
│   ├── services/               # ≤500 lines each
│   ├── providers/              # State management
│   ├── models/                 # Data models
│   └── theme/                  # App theming
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   └── services/       # ≤500 lines each
│       ├── domain/
│       │   └── models/         # Business models
│       └── presentation/
│           ├── screens/        # ≤400 lines each
│           ├── widgets/        # ≤300 lines each
│           └── providers/      # Feature-specific state
└── shared/
    └── widgets/                # Reusable UI components
```

### File Organization Principles

1. **Feature-based Structure:** Group related functionality
2. **Layer Separation:** Separate data, domain, and presentation
3. **Clear Dependencies:** Higher layers depend on lower layers
4. **Shared Components:** Common widgets in shared directory

## State Management Guidelines

### Provider Pattern (Riverpod)

```dart
// ✅ Good: Focused provider
final momentumScoreProvider = StateNotifierProvider<MomentumScoreNotifier, MomentumScore>(
  (ref) => MomentumScoreNotifier(ref.read(momentumServiceProvider)),
);

// ✅ Good: Provider usage in widget
class MomentumCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(momentumScoreProvider);
    return _buildCard(score);
  }
}
```

**Guidelines:**
- One provider per data concern
- Use StateNotifier for complex state
- Keep providers focused and testable
- Avoid provider composition in widgets

### Local State Management

```dart
// ✅ Good: Local state for UI-only concerns
class ExpandableCard extends StatefulWidget {
  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    // UI state management only
  }
}
```

**Guidelines:**
- Use local state for UI-only concerns
- Use global state for business data
- Keep state as close to usage as possible

## Testing Guidelines

### Widget Testing

```dart
// ✅ Good: Focused widget test
void main() {
  group('UserAvatarWidget', () {
    testWidgets('displays user initials when no image provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserAvatarWidget(
            user: User(name: 'John Doe'),
          ),
        ),
      );
      
      expect(find.text('JD'), findsOneWidget);
    });
  });
}
```

### Service Testing

```dart
// ✅ Good: Service unit test
void main() {
  group('MomentumCalculationService', () {
    late MomentumCalculationService service;
    
    setUp(() {
      service = MomentumCalculationService();
    });
    
    test('calculates momentum score correctly', () {
      final events = [/* test data */];
      final score = service.calculateScore(events);
      expect(score, equals(85.0));
    });
  });
}
```

**Testing Guidelines:**
- Test public interfaces, not implementation details
- Use mocks for dependencies
- Keep tests focused and readable
- Aim for high coverage on business logic

## Performance Guidelines

### Widget Performance

```dart
// ✅ Good: Performance optimized
class OptimizedListItem extends StatelessWidget {
  final ItemData data;
  
  const OptimizedListItem({super.key, required this.data});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        child: ListTile(
          title: Text(data.title),
          subtitle: Text(data.subtitle),
        ),
      ),
    );
  }
}

// ❌ Avoid: Performance issues
class NonOptimizedListItem extends StatefulWidget {
  @override
  _NonOptimizedListItemState createState() => _NonOptimizedListItemState();
}

class _NonOptimizedListItemState extends State<NonOptimizedListItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(expensiveCalculation()), // Calculated every build
      ),
    );
  }
}
```

**Performance Guidelines:**
- Use `const` constructors when possible
- Implement `RepaintBoundary` for complex widgets
- Avoid expensive calculations in build methods
- Use `ListView.builder` for large lists

### Memory Management

```dart
// ✅ Good: Proper resource management
class TimerWidget extends StatefulWidget {
  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), _updateTimer);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _updateTimer(Timer timer) {
    // Update logic
  }
}
```

## Code Review Guidelines

### Review Checklist

**Component Design:**
- [ ] Single responsibility principle followed
- [ ] Appropriate component size (within limits)
- [ ] Clear separation of concerns
- [ ] Proper naming conventions

**Code Quality:**
- [ ] No duplicate code
- [ ] Proper error handling
- [ ] Performance considerations addressed
- [ ] Tests included for new functionality

**Architecture:**
- [ ] Follows established patterns
- [ ] Proper state management usage
- [ ] Dependencies correctly injected
- [ ] Documentation updated if needed

### Common Review Comments

```dart
// Review Comment: "Consider extracting this into a separate widget"
class LargeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 50+ lines of header code - EXTRACT
        Container(/* complex header */),
        // Widget body
      ],
    );
  }
}

// Suggested Fix:
class LargeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LargeWidgetHeader(), // Extracted component
        // Widget body
      ],
    );
  }
}
```

## Migration Guidelines

### Refactoring Large Components

**Step 1: Identify Extraction Candidates**
- Look for logical groupings of related code
- Identify reusable sections
- Find code with different change frequencies

**Step 2: Extract Gradually**
```dart
// Before: Large component
class LargeComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),    // Extract candidate
        _buildBody(),      // Extract candidate
        _buildFooter(),    // Extract candidate
      ],
    );
  }
}

// After: Step 1 - Extract first section
class LargeComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ComponentHeader(), // Extracted
        _buildBody(),      // Next extraction target
        _buildFooter(),    // Next extraction target
      ],
    );
  }
}
```

**Step 3: Test After Each Extraction**
- Run all tests after each component extraction
- Verify no functionality is broken
- Check performance hasn't degraded

## Common Anti-Patterns

### 1. God Widgets
```dart
// ❌ Anti-pattern: God widget
class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // 50+ lines of state variables
  // 100+ lines of business logic
  // 200+ lines of UI building
  // 100+ lines of event handlers
}

// ✅ Better: Composed from smaller widgets
class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          UserProfileHeader(),
          UserProfileForm(),
          UserProfileActions(),
        ],
      ),
    );
  }
}
```

### 2. Tight Coupling
```dart
// ❌ Anti-pattern: Tight coupling
class NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = NotificationService(); // Direct instantiation
    final data = service.getNotifications(); // Direct call
    return Card(/* ... */);
  }
}

// ✅ Better: Loose coupling through dependency injection
class NotificationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    return Card(/* ... */);
  }
}
```

### 3. Mixed Concerns
```dart
// ❌ Anti-pattern: Mixed concerns
class DataDisplayWidget extends StatefulWidget {
  @override
  _DataDisplayWidgetState createState() => _DataDisplayWidgetState();
}

class _DataDisplayWidgetState extends State<DataDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: http.get(Uri.parse('api/data')), // API call in widget
      builder: (context, snapshot) {
        final processedData = complexCalculation(snapshot.data); // Business logic
        return Text(processedData); // UI rendering
      },
    );
  }
}

// ✅ Better: Separated concerns
class DataDisplayWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider); // Data from provider
    return Text(data.displayValue); // Pure UI
  }
}
```

## Tools and Enforcement

### Automated Checking
- **Component Size Monitoring:** `./scripts/check_component_sizes.sh`
- **Pre-commit Hooks:** Automatic size validation
- **CI/CD Integration:** Build-time compliance checking

### IDE Configuration
```json
// .vscode/settings.json
{
  "editor.rulers": [300, 400, 500],
  "dart.lineLength": 300,
  "editor.wordWrap": "bounded",
  "editor.wordWrapColumn": 300
}
```

### Linting Rules
```yaml
# analysis_options.yaml
linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    sized_box_for_whitespace: true
    use_build_context_synchronously: true
```

## Training and Onboarding

### New Team Member Checklist
- [ ] Read component architecture guidelines
- [ ] Review existing component examples
- [ ] Complete code review checklist training
- [ ] Practice component extraction exercises
- [ ] Understand automated governance tools

### Ongoing Education
- **Weekly:** Component design discussions in team meetings
- **Monthly:** Architecture review sessions
- **Quarterly:** Guidelines updates based on team feedback

---

## Quick Reference

### Size Limits
- **Services:** ≤500 lines
- **Widgets:** ≤300 lines  
- **Screens:** ≤400 lines
- **Modals:** ≤250 lines

### Key Commands
```bash
# Check component sizes
./scripts/check_component_sizes.sh

# Generate audit report
./scripts/component_size_audit.sh

# Test pre-commit hook
git add . && git commit -m "Test"
```

### Resources
- **Governance System:** `docs/architecture/component_governance.md`
- **Developer Workflow:** `docs/development/component_size_workflow.md`
- **Refactoring Guide:** `docs/development/refactoring_guide.md`
- **Code Review Checklist:** `docs/development/code_review_checklist.md`

---

*These guidelines are living documents that should evolve with the team's needs and Flutter ecosystem best practices.* 