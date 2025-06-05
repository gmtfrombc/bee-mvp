import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum for different loading states
enum LoadingState { initial, loading, loaded, error, refreshing }

/// Loading state for different components
class ComponentLoadingState {
  final LoadingState momentumCard;
  final LoadingState weeklyTrend;
  final LoadingState quickStats;
  final LoadingState actionButtons;
  final LoadingState notifications;

  const ComponentLoadingState({
    this.momentumCard = LoadingState.initial,
    this.weeklyTrend = LoadingState.initial,
    this.quickStats = LoadingState.initial,
    this.actionButtons = LoadingState.initial,
    this.notifications = LoadingState.initial,
  });

  ComponentLoadingState copyWith({
    LoadingState? momentumCard,
    LoadingState? weeklyTrend,
    LoadingState? quickStats,
    LoadingState? actionButtons,
    LoadingState? notifications,
  }) {
    return ComponentLoadingState(
      momentumCard: momentumCard ?? this.momentumCard,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      quickStats: quickStats ?? this.quickStats,
      actionButtons: actionButtons ?? this.actionButtons,
      notifications: notifications ?? this.notifications,
    );
  }

  bool get isAnyLoading =>
      momentumCard == LoadingState.loading ||
      weeklyTrend == LoadingState.loading ||
      quickStats == LoadingState.loading ||
      actionButtons == LoadingState.loading ||
      notifications == LoadingState.loading;

  bool get isAnyRefreshing =>
      momentumCard == LoadingState.refreshing ||
      weeklyTrend == LoadingState.refreshing ||
      quickStats == LoadingState.refreshing ||
      actionButtons == LoadingState.refreshing ||
      notifications == LoadingState.refreshing;

  bool get hasAnyError =>
      momentumCard == LoadingState.error ||
      weeklyTrend == LoadingState.error ||
      quickStats == LoadingState.error ||
      actionButtons == LoadingState.error ||
      notifications == LoadingState.error;
}

/// Provider for component loading states
class ComponentLoadingNotifier extends StateNotifier<ComponentLoadingState> {
  ComponentLoadingNotifier() : super(const ComponentLoadingState());

  /// Set loading state for momentum card
  void setMomentumCardLoading(LoadingState loadingState) {
    state = state.copyWith(momentumCard: loadingState);
  }

  /// Set loading state for weekly trend
  void setWeeklyTrendLoading(LoadingState loadingState) {
    state = state.copyWith(weeklyTrend: loadingState);
  }

  /// Set loading state for quick stats
  void setQuickStatsLoading(LoadingState loadingState) {
    state = state.copyWith(quickStats: loadingState);
  }

  /// Set loading state for action buttons
  void setActionButtonsLoading(LoadingState loadingState) {
    state = state.copyWith(actionButtons: loadingState);
  }

  /// Set loading state for notifications
  void setNotificationsLoading(LoadingState loadingState) {
    state = state.copyWith(notifications: loadingState);
  }

  /// Set all components to loading
  void setAllLoading() {
    state = const ComponentLoadingState(
      momentumCard: LoadingState.loading,
      weeklyTrend: LoadingState.loading,
      quickStats: LoadingState.loading,
      actionButtons: LoadingState.loading,
      notifications: LoadingState.loading,
    );
  }

  /// Set all components to loaded
  void setAllLoaded() {
    state = const ComponentLoadingState(
      momentumCard: LoadingState.loaded,
      weeklyTrend: LoadingState.loaded,
      quickStats: LoadingState.loaded,
      actionButtons: LoadingState.loaded,
      notifications: LoadingState.loaded,
    );
  }

  /// Set all components to refreshing
  void setAllRefreshing() {
    state = state.copyWith(
      momentumCard: LoadingState.refreshing,
      weeklyTrend: LoadingState.refreshing,
      quickStats: LoadingState.refreshing,
      actionButtons: LoadingState.refreshing,
      notifications: LoadingState.refreshing,
    );
  }

  /// Reset all loading states
  void reset() {
    state = const ComponentLoadingState();
  }
}

/// Provider for component loading states
final componentLoadingProvider =
    StateNotifierProvider<ComponentLoadingNotifier, ComponentLoadingState>(
      (ref) => ComponentLoadingNotifier(),
    );

/// Individual component loading state providers
final momentumCardLoadingProvider = Provider<LoadingState>((ref) {
  return ref.watch(componentLoadingProvider).momentumCard;
});

final weeklyTrendLoadingProvider = Provider<LoadingState>((ref) {
  return ref.watch(componentLoadingProvider).weeklyTrend;
});

final quickStatsLoadingProvider = Provider<LoadingState>((ref) {
  return ref.watch(componentLoadingProvider).quickStats;
});

final actionButtonsLoadingProvider = Provider<LoadingState>((ref) {
  return ref.watch(componentLoadingProvider).actionButtons;
});

final notificationsLoadingProvider = Provider<LoadingState>((ref) {
  return ref.watch(componentLoadingProvider).notifications;
});

/// Global loading state providers
final isAnyComponentLoadingProvider = Provider<bool>((ref) {
  return ref.watch(componentLoadingProvider).isAnyLoading;
});

final isAnyComponentRefreshingProvider = Provider<bool>((ref) {
  return ref.watch(componentLoadingProvider).isAnyRefreshing;
});

final hasAnyComponentErrorProvider = Provider<bool>((ref) {
  return ref.watch(componentLoadingProvider).hasAnyError;
});

/// Loading progress provider (0.0 to 1.0)
final loadingProgressProvider = Provider<double>((ref) {
  final loadingState = ref.watch(componentLoadingProvider);

  int totalComponents =
      5; // momentum card, weekly trend, quick stats, action buttons, notifications
  int loadedComponents = 0;

  if (loadingState.momentumCard == LoadingState.loaded) loadedComponents++;
  if (loadingState.weeklyTrend == LoadingState.loaded) loadedComponents++;
  if (loadingState.quickStats == LoadingState.loaded) loadedComponents++;
  if (loadingState.actionButtons == LoadingState.loaded) loadedComponents++;
  if (loadingState.notifications == LoadingState.loaded) loadedComponents++;

  return loadedComponents / totalComponents;
});

/// Loading message provider
final loadingMessageProvider = Provider<String>((ref) {
  final loadingState = ref.watch(componentLoadingProvider);
  final progress = ref.watch(loadingProgressProvider);

  if (loadingState.isAnyRefreshing) {
    return 'Refreshing momentum data...';
  }

  if (loadingState.hasAnyError) {
    return 'Error loading momentum data';
  }

  if (loadingState.isAnyLoading) {
    if (progress < 0.2) {
      return 'Connecting to momentum engine...';
    } else if (progress < 0.4) {
      return 'Loading your momentum data...';
    } else if (progress < 0.6) {
      return 'Calculating weekly trends...';
    } else if (progress < 0.8) {
      return 'Preparing quick stats...';
    } else {
      return 'Almost ready...';
    }
  }

  return 'Momentum data loaded';
});

/// Staggered loading delay provider for smooth UX
final staggeredLoadingProvider = Provider.family<Duration, int>((ref, index) {
  // Stagger loading animations by 100ms per component
  return Duration(milliseconds: index * 100);
});
