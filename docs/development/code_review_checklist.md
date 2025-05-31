# Code Review Checklist - BEE App

**Version:** 1.0  
**Last Updated:** Post-Sprint 6  
**Status:** Active  
**Scope:** Component Size Governance & Architecture

## Overview

This checklist ensures consistent code quality and architectural compliance during code reviews. It incorporates the component size governance system and architectural guidelines established for the BEE application.

## Quick Reference

**Component Size Limits:**
- Services: ≤500 lines
- Widgets: ≤300 lines  
- Screens: ≤400 lines
- Modals: ≤250 lines

## Pre-Review Checklist (Author)

Before requesting review, ensure:

### Automated Checks
- [ ] All tests pass locally
- [ ] Component size check passes: `./scripts/check_component_sizes.sh`
- [ ] Pre-commit hooks executed successfully
- [ ] No linting errors: `flutter analyze`
- [ ] Code formatted: `dart format .`

### Self-Review
- [ ] Read through all changes
- [ ] Removed debug code and console outputs
- [ ] Updated relevant documentation
- [ ] Added tests for new functionality
- [ ] Considered performance implications

## Component Architecture Review

### Size Compliance
- [ ] **All components within size guidelines**
  - Services ≤500 lines
  - Widgets ≤300 lines
  - Screens ≤400 lines
  - Modals ≤250 lines
- [ ] **Large components properly justified**
  - Clear rationale documented
  - Extraction plan provided if applicable

### Single Responsibility Principle
- [ ] **Each component has one clear purpose**
  ```dart
  // ✅ Good: Single responsibility
  class UserAvatarWidget extends StatelessWidget {
    // Only handles user avatar display
  }
  
  // ❌ Avoid: Multiple responsibilities
  class UserDashboardWidget extends StatelessWidget {
    // Handles avatar, notifications, settings, etc.
  }
  ```

### Separation of Concerns
- [ ] **UI components contain only presentation logic**
- [ ] **Business logic delegated to services**
- [ ] **Data access isolated in repository/service layer**
- [ ] **State management properly separated**

### Component Composition
- [ ] **Complex widgets built from smaller components**
- [ ] **Reusable components identified and extracted**
- [ ] **Clear component hierarchies**

## Code Quality Review

### Naming and Documentation

#### File and Class Names
- [ ] **Descriptive, specific names**
  ```dart
  // ✅ Good
  user_profile_avatar_widget.dart
  class UserProfileAvatarWidget extends StatelessWidget {}
  
  // ❌ Avoid
  widget.dart
  class MyWidget extends StatelessWidget {}
  ```

#### Documentation
- [ ] **Public APIs documented with dartdoc comments**
- [ ] **Complex business logic explained**
- [ ] **Usage examples provided for reusable components**
- [ ] **Architecture decisions recorded**

#### Code Clarity
- [ ] **Self-documenting code with clear variable names**
- [ ] **Minimal comments explaining "why" not "what"**
- [ ] **Complex logic broken into named methods**

### Error Handling
- [ ] **Appropriate error handling for all failure cases**
- [ ] **User-friendly error messages**
- [ ] **Proper exception types used**
- [ ] **Resource cleanup in finally blocks or dispose methods**

### Performance Considerations
- [ ] **Expensive operations not in build methods**
- [ ] **Proper use of const constructors**
- [ ] **RepaintBoundary used for complex widgets**
- [ ] **ListView.builder for large lists**
- [ ] **Proper disposal of resources (controllers, subscriptions)**

## State Management Review

### Provider/Riverpod Usage
- [ ] **Providers focused on single concerns**
- [ ] **Proper provider lifecycle management**
- [ ] **No business logic in widgets**
- [ ] **State kept as close to usage as possible**

```dart
// ✅ Good: Focused provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(ref.read(userServiceProvider)),
);

// ❌ Avoid: God provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  // Manages everything: users, notifications, settings, etc.
);
```

### Local State Management
- [ ] **StatefulWidget used only for UI-specific state**
- [ ] **Business state managed globally**
- [ ] **Proper state initialization and cleanup**

## Testing Review

### Test Coverage
- [ ] **New functionality has corresponding tests**
- [ ] **Edge cases covered**
- [ ] **Error scenarios tested**
- [ ] **Integration tests for critical paths**

### Test Quality
- [ ] **Tests are focused and readable**
- [ ] **Proper use of mocks and stubs**
- [ ] **Tests follow AAA pattern (Arrange, Act, Assert)**
- [ ] **No test logic duplication**

```dart
// ✅ Good: Focused test
testWidgets('UserAvatarWidget displays initials when no image', (tester) async {
  // Arrange
  const user = User(name: 'John Doe');
  
  // Act
  await tester.pumpWidget(MaterialApp(
    home: UserAvatarWidget(user: user),
  ));
  
  // Assert
  expect(find.text('JD'), findsOneWidget);
});
```

### Widget Testing
- [ ] **Widget rendering tests for UI components**
- [ ] **Interaction tests for user inputs**
- [ ] **Golden tests for visual regression (where applicable)**

### Service Testing
- [ ] **Unit tests for all public methods**
- [ ] **Mock dependencies properly**
- [ ] **Test error conditions**

## Security Review

### Data Handling
- [ ] **Sensitive data properly encrypted**
- [ ] **No hardcoded secrets or API keys**
- [ ] **Proper input validation**
- [ ] **SQL injection prevention (if applicable)**

### User Input
- [ ] **All user inputs validated**
- [ ] **XSS prevention measures**
- [ ] **Proper sanitization of displayed data**

## Performance Review

### Build Performance
- [ ] **No expensive operations in build methods**
- [ ] **Proper const usage**
- [ ] **Efficient widget rebuilding**

### Memory Management
- [ ] **Controllers and streams properly disposed**
- [ ] **No memory leaks in long-running operations**
- [ ] **Proper image caching and disposal**

### Network Efficiency
- [ ] **Proper error handling for network requests**
- [ ] **Caching strategies implemented**
- [ ] **Pagination for large data sets**

## Accessibility Review

### Widget Accessibility
- [ ] **Semantic labels provided**
- [ ] **Proper contrast ratios**
- [ ] **Screen reader support**
- [ ] **Keyboard navigation support**

```dart
// ✅ Good: Accessible widget
Semantics(
  label: 'User avatar for ${user.name}',
  child: CircleAvatar(
    backgroundImage: user.avatarUrl != null 
        ? NetworkImage(user.avatarUrl!) 
        : null,
    child: user.avatarUrl == null 
        ? Text(user.initials)
        : null,
  ),
)
```

## Integration Review

### API Integration
- [ ] **Proper error handling for API failures**
- [ ] **Timeout handling**
- [ ] **Retry logic where appropriate**
- [ ] **Proper data transformation**

### Database Integration
- [ ] **Efficient queries**
- [ ] **Proper indexing considerations**
- [ ] **Transaction management**
- [ ] **Data consistency maintained**

## Specific Review Scenarios

### New Component Creation

**For New Widgets:**
- [ ] Component size within 300-line limit
- [ ] Single responsibility maintained
- [ ] Reusability considered
- [ ] Proper prop interface design
- [ ] Tests included

**For New Services:**
- [ ] Service size within 500-line limit
- [ ] Clear interface definition
- [ ] Dependency injection used
- [ ] Error handling comprehensive
- [ ] Unit tests cover all methods

**For New Screens:**
- [ ] Screen size within 400-line limit
- [ ] Composed from smaller widgets
- [ ] Navigation properly handled
- [ ] State management appropriate
- [ ] Responsive design considered

### Refactoring Review

**Component Extraction:**
- [ ] Original functionality preserved
- [ ] Tests still pass
- [ ] Performance not degraded
- [ ] Clear component boundaries
- [ ] Documentation updated

**Service Decomposition:**
- [ ] Single responsibility maintained
- [ ] Interface contracts preserved
- [ ] Dependencies properly managed
- [ ] Test coverage maintained
- [ ] Migration path documented

### Bug Fixes

**Fix Quality:**
- [ ] Root cause addressed, not just symptoms
- [ ] No introduction of new bugs
- [ ] Edge cases considered
- [ ] Regression tests added

**Code Changes:**
- [ ] Minimal changes to fix the issue
- [ ] No unrelated refactoring mixed in
- [ ] Clear explanation of the fix

## Common Review Patterns

### Anti-Pattern Detection

**God Components:**
```dart
// ❌ Red flag: Too many responsibilities
class UserDashboardScreen extends StatefulWidget {
  // Handles user profile, notifications, settings, analytics, etc.
  // 800+ lines of mixed concerns
}
```

**Tight Coupling:**
```dart
// ❌ Red flag: Direct service instantiation
class UserWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = UserService(); // Direct coupling
    // ...
  }
}
```

**Mixed Concerns:**
```dart
// ❌ Red flag: API calls in widgets
class DataWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: http.get(apiUrl), // Business logic in UI
      // ...
    );
  }
}
```

### Good Pattern Recognition

**Composition:**
```dart
// ✅ Good: Clear composition
class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserProfileHeader(),
        UserProfileForm(),
        UserProfileActions(),
      ],
    );
  }
}
```

**Dependency Injection:**
```dart
// ✅ Good: Proper dependency injection
class UserProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return UserProfileCardUI(user: user);
  }
}
```

## Review Comments Templates

### Component Size Violations

```markdown
**Component Size Violation**

This component exceeds our size guidelines:
- Current: XXX lines
- Limit: XXX lines (YY% over)

Please consider extracting:
1. [Specific section] - could be a separate widget
2. [Another section] - could be extracted as a helper service

See: docs/development/refactoring_guide.md
```

### Architecture Concerns

```markdown
**Architecture Concern: Mixed Responsibilities**

This component appears to handle multiple concerns:
- UI rendering
- Business logic
- Data fetching

Consider:
- Moving business logic to a service
- Using state management for data
- Keeping this component focused on UI

See: docs/architecture/component_guidelines.md
```

### Performance Issues

```markdown
**Performance Concern**

Expensive operation in build method:
```dart
// Line XX
final result = expensiveCalculation();
```

Consider:
- Moving to initState() or provider
- Caching the result
- Using useMemoized if using Hooks

See: docs/architecture/component_guidelines.md#performance-guidelines
```

## Review Process

### For Reviewers

1. **Quick Scan:**
   - Check automated compliance (size, tests, linting)
   - Review overall architecture approach

2. **Detailed Review:**
   - Go through checklist systematically
   - Focus on areas of highest risk/complexity
   - Verify test coverage for new functionality

3. **Feedback:**
   - Be specific and constructive
   - Provide examples of better approaches
   - Reference documentation and guidelines

### For Authors

1. **Pre-Review:**
   - Complete author checklist
   - Self-review using reviewer perspective
   - Ensure all automated checks pass

2. **During Review:**
   - Respond promptly to feedback
   - Ask clarifying questions if needed
   - Make requested changes systematically

3. **Post-Review:**
   - Verify all feedback addressed
   - Update documentation if needed
   - Share learnings with team

## Escalation Guidelines

### When to Escalate

- **Architecture disagreements**
- **Major performance concerns**
- **Security vulnerabilities**
- **Breaking changes without proper planning**

### Escalation Process

1. Discussion between author and reviewer
2. Team lead consultation
3. Architecture review meeting (if needed)
4. Documentation of decision (ADR)

## Tools and Automation

### Automated Checks

```bash
# Pre-review validation
./scripts/check_component_sizes.sh
flutter test
flutter analyze
dart format --set-exit-if-changed .
```

### Review Tools

- **GitHub PR templates**
- **Automated size reporting**
- **Test coverage reports**
- **Performance benchmarks**

---

## Quick Reference Checklist

### Must Have
- [ ] All tests pass
- [ ] Component size compliance
- [ ] No linting errors
- [ ] Documentation updated

### Architecture
- [ ] Single responsibility
- [ ] Proper separation of concerns
- [ ] Clear component boundaries
- [ ] Appropriate abstractions

### Code Quality
- [ ] Clear naming
- [ ] Proper error handling
- [ ] Performance considerations
- [ ] Accessibility support

### Testing
- [ ] New functionality tested
- [ ] Edge cases covered
- [ ] Integration tests updated
- [ ] No test regressions

---

*This checklist should be updated as new patterns emerge and guidelines evolve. Consider it a living document that grows with the team's experience.* 