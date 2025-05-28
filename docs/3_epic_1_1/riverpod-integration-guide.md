# Riverpod State Management Integration Guide

## Overview

This document outlines the Riverpod state management integration for the BEE Momentum Meter feature (Epic 1.1). The integration replaces StatefulWidget patterns with reactive state management using Riverpod providers.

## Architecture

### Provider Structure

The Riverpod integration follows a layered architecture:

```
app/lib/features/momentum/presentation/providers/
├── momentum_provider.dart      # Core momentum data providers
└── ui_state_provider.dart      # UI-specific state providers
```

### Core Providers

#### 1. Main Momentum Provider
```dart
final momentumProvider = StateNotifierProvider<MomentumNotifier, AsyncValue<MomentumData>>
```
- **Purpose**: Main provider for momentum data
- **State**: `AsyncValue<MomentumData>` (loading, data, error states)
- **Usage**: Primary data source for all momentum-related widgets

#### 2. Derived Providers
```dart
final momentumStateProvider = Provider<MomentumState?>
final momentumPercentageProvider = Provider<double?>
final momentumStatsProvider = Provider<MomentumStats?>
final weeklyTrendProvider = Provider<List<DailyMomentum>?>
final momentumMessageProvider = Provider<String?>
final lastUpdatedProvider = Provider<DateTime?>
```
- **Purpose**: Granular access to specific momentum data properties
- **Benefits**: Widgets only rebuild when their specific data changes
- **Pattern**: Derived from main momentum provider using `ref.watch()`

#### 3. Demo State Providers
```dart
final demoStateProvider = StateProvider<MomentumState>
final demoPercentageProvider = Provider<double>
```
- **Purpose**: Manage demo section state transitions
- **Usage**: Interactive demo showing state changes with animations

#### 4. Utility Providers
```dart
final isLoadingProvider = Provider<bool>
final errorProvider = Provider<String?>
```
- **Purpose**: Convenient access to loading and error states
- **Usage**: Conditional rendering and UI feedback

### UI State Providers

#### 1. Modal Visibility
```dart
final modalVisibilityProvider = StateProvider<bool>
```

#### 2. User Interactions
```dart
final userInteractionProvider = StateProvider<UserInteractionState>
final cardInteractionProvider = StateNotifierProvider<CardInteractionNotifier, CardInteractionState>
```

#### 3. Animation States
```dart
final animationStateProvider = StateProvider<AnimationState>
```

## Implementation Patterns

### 1. Basic Provider Watching

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentumState = ref.watch(momentumStateProvider);
    final percentage = ref.watch(momentumPercentageProvider);
    
    return Text('State: ${momentumState?.name}, ${percentage}%');
  }
}
```

### 2. Conditional Rendering

```dart
class ConditionalWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);
    final data = ref.watch(momentumStatsProvider);
    
    if (isLoading) return CircularProgressIndicator();
    if (error != null) return ErrorWidget(error);
    if (data != null) return DataWidget(data);
    return EmptyWidget();
  }
}
```

### 3. State Mutation

```dart
class StateMutationWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Update state using notifier
        ref.read(momentumProvider.notifier).simulateStateChange(MomentumState.rising);
        
        // Update simple state
        ref.read(demoStateProvider.notifier).state = MomentumState.steady;
      },
      child: Text('Change State'),
    );
  }
}
```

### 4. ConsumerStatefulWidget for Animations

```dart
class AnimatedWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<AnimatedWidget> createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends ConsumerState<AnimatedWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
  }
  
  @override
  Widget build(BuildContext context) {
    final momentumState = ref.watch(momentumStateProvider);
    // Use both Riverpod state and local animation state
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => /* animated widget */,
    );
  }
}
```

## Migration from StatefulWidget

### Before (StatefulWidget)
```dart
class OldWidget extends StatefulWidget {
  @override
  _OldWidgetState createState() => _OldWidgetState();
}

class _OldWidgetState extends State<OldWidget> {
  MomentumData? _data;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() async {
    final data = await api.getMomentumData();
    setState(() => _data = data);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_data == null) return CircularProgressIndicator();
    return Text(_data!.message);
  }
}
```

### After (Riverpod)
```dart
class NewWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(momentumMessageProvider);
    final isLoading = ref.watch(isLoadingProvider);
    
    if (isLoading) return CircularProgressIndicator();
    return Text(message ?? 'No message');
  }
}
```

## Benefits of Riverpod Integration

### 1. Reactive Updates
- Widgets automatically rebuild when their watched providers change
- No manual `setState()` calls needed
- Granular updates (only affected widgets rebuild)

### 2. State Sharing
- Multiple widgets can watch the same provider
- Consistent state across the app
- No prop drilling

### 3. Testability
- Providers can be easily mocked for testing
- State changes are predictable and traceable
- Better separation of concerns

### 4. Performance
- Widgets only rebuild when their specific data changes
- Automatic disposal of unused providers
- Efficient memory management

### 5. Developer Experience
- Compile-time safety with strong typing
- Better debugging with Riverpod Inspector
- Clear data flow patterns

## Testing with Riverpod

### Provider Testing
```dart
void main() {
  test('momentum provider loads data correctly', () async {
    final container = ProviderContainer();
    
    // Wait for provider to load
    await container.read(momentumProvider.future);
    
    // Verify state
    final state = container.read(momentumStateProvider);
    expect(state, equals(MomentumState.rising));
    
    container.dispose();
  });
}
```

### Widget Testing
```dart
void main() {
  testWidgets('widget displays momentum state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          momentumStateProvider.overrideWith((ref) => MomentumState.rising),
        ],
        child: MaterialApp(home: MyWidget()),
      ),
    );
    
    expect(find.text('rising'), findsOneWidget);
  });
}
```

## Best Practices

### 1. Provider Organization
- Keep providers in separate files by feature
- Use descriptive names for providers
- Group related providers together

### 2. State Structure
- Use immutable data models
- Implement `copyWith` methods for updates
- Keep state as flat as possible

### 3. Performance
- Use derived providers for computed values
- Avoid watching providers unnecessarily
- Use `select` for specific property watching

### 4. Error Handling
- Use `AsyncValue` for async operations
- Provide meaningful error messages
- Implement retry mechanisms

### 5. Testing
- Mock providers in tests
- Test provider logic separately from UI
- Use `ProviderContainer` for unit tests

## Future Enhancements

### 1. Real-time Updates (T1.1.3.9)
- Integrate Supabase real-time subscriptions
- Update providers when backend data changes
- Handle connection states and reconnection

### 2. Offline Support
- Cache provider state locally
- Sync when connection restored
- Handle offline/online state transitions

### 3. Advanced State Management
- Implement undo/redo functionality
- Add state persistence
- Create complex state machines

## Files Modified

### Core Files
- `app/lib/features/momentum/presentation/providers/momentum_provider.dart` - Enhanced with additional providers
- `app/lib/features/momentum/presentation/providers/ui_state_provider.dart` - New UI state providers
- `app/lib/features/momentum/presentation/screens/momentum_screen.dart` - Converted to use Riverpod

### Example Files
- `app/lib/features/momentum/presentation/widgets/riverpod_quick_stats_cards.dart` - Riverpod version of stats cards
- `app/lib/features/momentum/presentation/widgets/riverpod_momentum_example.dart` - Comprehensive examples

### Documentation
- `docs/3_epic_1_1/riverpod-integration-guide.md` - This guide

## Conclusion

The Riverpod integration provides a robust, scalable state management solution for the momentum meter feature. It replaces StatefulWidget patterns with reactive providers, improving performance, testability, and developer experience while preparing the foundation for real-time updates and advanced features. 