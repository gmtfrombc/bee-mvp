import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/momentum_data.dart';
import 'momentum_api_provider.dart';

/// Provider for momentum data
/// Now connected to Supabase API with real-time updates (T1.1.3.9)
final momentumProvider = realtimeMomentumProvider;

/// Provider for current momentum state only
final momentumStateProvider = Provider<MomentumState?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    data: (data) => data.state,
    orElse: () => null,
  );
});

/// Provider for momentum percentage only
final momentumPercentageProvider = Provider<double?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    data: (data) => data.percentage,
    orElse: () => null,
  );
});

/// Provider for momentum stats only
final momentumStatsProvider = Provider<MomentumStats?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    data: (data) => data.stats,
    orElse: () => null,
  );
});

/// Provider for weekly trend data only
final weeklyTrendProvider = Provider<List<DailyMomentum>?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    data: (data) => data.weeklyTrend,
    orElse: () => null,
  );
});

/// Provider for momentum message only
final momentumMessageProvider = Provider<String?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    data: (data) => data.message,
    orElse: () => null,
  );
});

/// Provider for last updated timestamp
final lastUpdatedProvider = Provider<DateTime?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    data: (data) => data.lastUpdated,
    orElse: () => null,
  );
});

/// Provider for demo state management (for the demo section)
final demoStateProvider = StateProvider<MomentumState>((ref) {
  // Initialize with the current momentum state if available
  final currentState = ref.watch(momentumStateProvider);
  return currentState ?? MomentumState.rising;
});

/// Provider for demo percentage based on demo state
final demoPercentageProvider = Provider<double>((ref) {
  final demoState = ref.watch(demoStateProvider);
  switch (demoState) {
    case MomentumState.rising:
      return 85.0;
    case MomentumState.steady:
      return 65.0;
    case MomentumState.needsCare:
      return 35.0;
  }
});

/// Provider for loading state
final isLoadingProvider = Provider<bool>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.isLoading;
});

/// Provider for error state
final errorProvider = Provider<String?>((ref) {
  final momentumAsync = ref.watch(momentumProvider);
  return momentumAsync.maybeWhen(
    error: (error, _) => error.toString(),
    orElse: () => null,
  );
});

/// Legacy momentum notifier - now replaced by RealtimeMomentumNotifier
/// Keeping for backward compatibility with existing demo functionality
class MomentumNotifier extends StateNotifier<AsyncValue<MomentumData>> {
  MomentumNotifier() : super(const AsyncValue.loading()) {
    // Initialize with sample data for demo purposes
    state = AsyncValue.data(MomentumData.sample());
  }

  /// Refresh momentum data (delegates to real-time provider)
  Future<void> refresh() async {
    // This method is kept for compatibility but should use the real API
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 500));
    state = AsyncValue.data(MomentumData.sample());
  }

  /// Update momentum data (for real-time updates)
  void updateMomentumData(MomentumData newData) {
    state = AsyncValue.data(newData);
  }

  /// Update only the momentum state (useful for partial updates)
  void updateMomentumState(MomentumState newState) {
    state.whenData((currentData) {
      final updatedData = currentData.copyWith(
        state: newState,
        lastUpdated: DateTime.now(),
      );
      state = AsyncValue.data(updatedData);
    });
  }

  /// Update only the momentum percentage
  void updateMomentumPercentage(double newPercentage) {
    state.whenData((currentData) {
      final updatedData = currentData.copyWith(
        percentage: newPercentage,
        lastUpdated: DateTime.now(),
      );
      state = AsyncValue.data(updatedData);
    });
  }

  /// Update momentum stats
  void updateMomentumStats(MomentumStats newStats) {
    state.whenData((currentData) {
      final updatedData = currentData.copyWith(
        stats: newStats,
        lastUpdated: DateTime.now(),
      );
      state = AsyncValue.data(updatedData);
    });
  }

  /// Simulate a momentum state change (for testing/demo purposes)
  Future<void> simulateStateChange(MomentumState newState) async {
    state.whenData((currentData) {
      // Create updated data with new state and appropriate percentage
      final newPercentage = switch (newState) {
        MomentumState.rising => 85.0,
        MomentumState.steady => 65.0,
        MomentumState.needsCare => 35.0,
      };

      final newMessage = switch (newState) {
        MomentumState.rising => "You're on fire! Keep up the great momentum!",
        MomentumState.steady => "Steady progress! You're doing great!",
        MomentumState.needsCare => "Let's get back on track together! 🌱",
      };

      final updatedData = currentData.copyWith(
        state: newState,
        percentage: newPercentage,
        message: newMessage,
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(updatedData);
    });
  }
}
