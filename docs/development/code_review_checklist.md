# Code Review Checklist - BEE App

**Version:** 2.0  
**Last Updated:** Post-Polish UX Refactor Planning  
**Status:** Active  
**Scope:** Complexity-Aware Component Size Governance & Architecture

## Overview

This checklist ensures consistent code quality and architectural compliance during code reviews. It incorporates the updated complexity-aware component size governance system and architectural guidelines established for the BEE application.

## Quick Reference

**Component Size Limits (Updated 2025):**
- Services: ≤500 lines
- Simple Widgets: ≤200 lines (basic presentation)
- Standard Widgets: ≤300 lines (interactive components)  
- Complex Widgets: ≤500 lines (with justification)
- Screens: ≤400 lines
- Modals: ≤250 lines

**Complex Widget Criteria (2+ factors apply):**
- Multiple animation controllers (3+ animations)
- Custom painting/rendering logic
- Multiple UI states (loading/error/success)
- Complex responsive design logic
- Accessibility integrations
- Performance optimizations

## AI-Assisted Development Guidelines

### **🤖 For AI Assistants: Component Size Decision Tree**

When encountering components that exceed guidelines, follow this decision tree:

#### **Step 1: Assess Violation Severity**
```
≤110% of limit (e.g., 330 lines for standard widget):
  → SOFT VIOLATION: Document and monitor, refactor only if clear improvement
  
111-150% of limit (e.g., 331-450 lines):
  → MEDIUM VIOLATION: Evaluate complexity factors before refactoring
  
>150% of limit (e.g., >450 lines):
  → HARD VIOLATION: Refactoring required
```

#### **Step 2: Complexity Factor Analysis**
For components 300+ lines, evaluate complexity factors:
```
0-1 complexity factors: → REFACTOR (likely over-sized simple component)
2+ complexity factors: → DOCUMENT as complex widget (up to 500 lines OK)
3+ complexity factors: → APPROVE as justified complex widget
```

#### **Step 3: Refactoring Decision Matrix**

**🟢 PROCEED with refactoring if:**
- Clear separation of concerns visible
- Natural component boundaries exist
- Repeated patterns can be extracted
- Business logic mixed with UI logic
- Multiple unrelated responsibilities

**🟡 DOCUMENT & MONITOR if:**
- Component is cohesive but slightly over limit
- No clear extraction boundaries
- Complexity factors justify size
- Refactoring would create tight coupling

**🔴 DO NOT refactor if:**
- Would create artificial splits
- No logical component boundaries
- Extraction would increase overall complexity
- Component is cohesive and serves single purpose

### **🧠 AI Decision Examples**

#### **Example 1: Soft Violation - Document & Monitor**
```dart
class MomentumGauge extends StatefulWidget {  // 330 lines (110% of 300)
  // Complexity factors:
  // - 4 animation controllers ✓
  // - Custom painting ✓
  // - Responsive design ✓
  // = 3+ factors = APPROVE & DOCUMENT
  
  // AI Action: Add complexity documentation, do NOT refactor
}
```

#### **Example 2: Clear Refactoring Opportunity**
```dart
class UserDashboard extends StatelessWidget {  // 450 lines (150% of 300)
  // Contains:
  // - User profile display (100 lines)
  // - Notification list (150 lines)  
  // - Settings panel (100 lines)
  // - Analytics widgets (100 lines)
  // = 0 complexity factors, multiple responsibilities
  
  // AI Action: Extract 4 separate components
}
```

#### **Example 3: Cohesive Component - Do Not Split**
```dart
class ComplexFormWidget extends StatefulWidget {  // 380 lines (127% of 300)
  // Single responsibility: User registration form
  // Cohesive validation logic throughout
  // No clear separation boundaries
  // High coupling between form sections
  
  // AI Action: Document as justified complex widget
  // DO NOT artificially split - would create tight coupling
}
```

### **🚨 AI Anti-Patterns to Avoid**

1. **Arbitrary Line Splitting**: Never split components just to hit line counts
2. **Premature Extraction**: Don't extract components that aren't naturally reusable
3. **Creating Tight Coupling**: Avoid splits that require props drilling or shared state
4. **Over-Abstraction**: Don't create unnecessary intermediate components

### **✅ AI Best Practices**

1. **Evaluate Before Acting**: Always assess complexity factors first
2. **Prefer Documentation**: For borderline cases, document rather than refactor
3. **Seek Natural Boundaries**: Only extract at logical component seams
4. **Preserve Cohesion**: Maintain single responsibility principle
5. **Consider Maintainability**: Is the refactored code easier to understand?

### **🔧 AI Refactoring Checklist**

Before refactoring an oversized component:
- [ ] **Severity Assessment**: Is this a hard violation (>150% limit)?
- [ ] **Complexity Analysis**: Are there <2 complexity factors?
- [ ] **Natural Boundaries**: Can I identify logical separation points?
- [ ] **Cohesion Check**: Will split components remain cohesive?
- [ ] **Coupling Analysis**: Will extraction create tight coupling?
- [ ] **Reusability Assessment**: Are extracted components genuinely reusable?
- [ ] **Maintainability**: Is the result easier to understand and maintain?

**If ANY of these fail, consider documentation over refactoring.**

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

### Size Compliance (Updated)
- [ ] **All components within complexity-appropriate guidelines**
  - Services ≤500 lines
  - Simple widgets ≤200 lines (basic presentation only)
  - Standard widgets ≤300 lines (interactive components)
  - Complex widgets ≤500 lines (with clear justification)
  - Screens ≤400 lines
  - Modals ≤250 lines
- [ ] **Complex widgets properly justified**
  - Clear rationale documented for >300 line widgets
  - Complexity factors identified and validated
  - Extraction plan provided if widget lacks sufficient complexity

### Widget Complexity Assessment
- [ ] **Complex widget criteria evaluation** (for widgets >300 lines)
  ```dart
  // ✅ Justified complexity factors:
  class ComplexAnimatedWidget extends StatefulWidget {
    // Multiple animation controllers ✓
    // Custom painting logic ✓  
    // Responsive design ✓
    // Accessibility features ✓
    // = 4 complexity factors = Justified at 450 lines
  }
  
  // ❌ Unjustified size - needs refactoring:
  class BasicListWidget extends StatelessWidget {
    // Simple list rendering only
    // No animations, custom painting, or complex logic
    // = 0 complexity factors = Should be ≤200 lines
  }
  ```

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
- [ ] **Complex widget justification documented**

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

### Responsive Design Compliance
- [ ] **No hardcoded values - uses ResponsiveService**
  ```dart
  // ❌ Wrong - Hardcoded values
  padding: EdgeInsets.all(16.0)
  
  // ✅ Correct - Responsive service
  padding: ResponsiveService.getResponsivePadding(context)
  ```
- [ ] **Device-specific logic properly handled**
- [ ] **Consistent spacing using responsive utilities**

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
- [ ] Component size within complexity-appropriate guidelines
- [ ] Single responsibility maintained
- [ ] Reusability considered
- [ ] Proper prop interface design
- [ ] Tests included
- [ ] Complexity justification (if >300 lines)

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

**Unjustified Complexity:**
```dart
// ❌ Red flag: Large widget without complexity justification
class SimpleTextWidget extends StatelessWidget {
  // 400+ lines but only displays text
  // No animations, responsive logic, or complex state
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

**Justified Complex Widget:**
```dart
// ✅ Good: Complex widget with clear justification
class MomentumGauge extends StatefulWidget {
  // Complexity factors:
  // - Multiple animation controllers (4 animations)
  // - Custom painting for gauge rendering
  // - Multi-state transitions (Rising/Steady/Care)
  // - Responsive sizing logic
  // - Accessibility integration (haptic feedback, screen reader)
  // - Performance optimizations (reduced motion, disposal)
  // Total: 530 lines with 6 complexity factors = JUSTIFIED
}
```

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

**Simple Widget Violation:**
```markdown
**Component Size Violation - Simple Widget**

This widget exceeds guidelines for simple components:
- Current: XXX lines
- Simple widget limit: 200 lines (XX% over)
- Standard widget limit: 300 lines (XX% over)

This widget appears to have minimal complexity. Consider:
1. Extracting helper widgets for repeated patterns
2. Moving business logic to services
3. Simplifying the component structure

If this widget has hidden complexity, please document the complexity factors.
```

**Unjustified Complex Widget:**
```markdown
**Component Size Violation - Insufficient Complexity Justification**

This widget exceeds the 300-line standard limit but lacks complexity justification:
- Current: XXX lines
- Complex widget limit: 500 lines
- **Missing complexity documentation**

For widgets >300 lines, please document 2+ complexity factors:
- [ ] Multiple animation controllers (3+ animations)
- [ ] Custom painting/rendering logic  
- [ ] Multiple UI states (loading/error/success)
- [ ] Complex responsive design logic
- [ ] Accessibility integrations
- [ ] Performance optimizations

If insufficient complexity factors exist, please refactor to ≤300 lines.

See: docs/development/refactoring_guide.md
```

**Justified Complex Widget:**
```markdown
**Component Size - Complex Widget Approved**

This widget exceeds 300 lines but demonstrates sufficient complexity:
- Current: XXX lines
- Complexity factors: [list factors]
- Status: ✅ **APPROVED** for complex widget classification

Consider monitoring for future extraction opportunities while maintaining the justified complexity.
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

### Responsive Design Issues

```markdown
**Responsive Design Violation**

Hardcoded values detected:
```dart
// Line XX
padding: EdgeInsets.all(16.0)  // Should use ResponsiveService
```

Please use ResponsiveService for all spacing and sizing:
```dart
padding: ResponsiveService.getResponsivePadding(context)
```

See: Technical Considerations in refactor plan
```

## Review Process

### For Reviewers

1. **Quick Scan:**
   - Check automated compliance (size, tests, linting)
   - Review overall architecture approach
   - Assess widget complexity vs. size

2. **Detailed Review:**
   - Go through checklist systematically
   - Focus on areas of highest risk/complexity
   - Verify test coverage for new functionality
   - Validate complexity justifications for large widgets

3. **Feedback:**
   - Be specific and constructive
   - Provide examples of better approaches
   - Reference documentation and guidelines
   - Distinguish between critical issues and suggestions

### For Authors

1. **Pre-Review:**
   - Complete author checklist
   - Self-review using reviewer perspective
   - Ensure all automated checks pass
   - Document complexity factors for large widgets

2. **During Review:**
   - Respond promptly to feedback
   - Ask clarifying questions if needed
   - Make requested changes systematically
   - Provide additional context for complexity decisions

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
- **Disputes over widget complexity classification**

### Escalation Process

1. Discussion between author and reviewer
2. Team lead consultation
3. Architecture review meeting (if needed)
4. Documentation of decision (ADR)

## Tools and Automation

### Automated Checks

```bash
# Pre-review validation with complexity awareness
./scripts/check_component_sizes.sh  # Now includes complexity detection
flutter test
flutter analyze
dart format --set-exit-if-changed .
```

### Review Tools

- **GitHub PR templates** with complexity assessment
- **Automated size reporting** with complexity context
- **Test coverage reports**
- **Performance benchmarks**

---

## Quick Reference Checklist

### Must Have
- [ ] All tests pass
- [ ] Component size compliance (complexity-aware)
- [ ] No linting errors
- [ ] Documentation updated
- [ ] Complex widgets properly justified

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
- [ ] Responsive design compliance

### Testing
- [ ] New functionality tested
- [ ] Edge cases covered
- [ ] Integration tests updated
- [ ] No test regressions

---

*This checklist should be updated as new patterns emerge and guidelines evolve. Consider it a living document that grows with the team's experience and the evolution of Flutter best practices.* 