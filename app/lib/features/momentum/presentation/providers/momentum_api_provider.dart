import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/momentum_api_service.dart';
import '../../domain/models/momentum_data.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Provider for the momentum API service
final momentumApiServiceProvider = Provider<MomentumApiService>((ref) {
  return MomentumApiService();
});

/// Provider for real-time momentum subscription
final realtimeMomentumProvider =
    StateNotifierProvider<RealtimeMomentumNotifier, AsyncValue<MomentumData>>((
      ref,
    ) {
      final apiService = ref.watch(momentumApiServiceProvider);
      return RealtimeMomentumNotifier(apiService);
    });

/// Notifier for managing real-time momentum updates
class RealtimeMomentumNotifier extends StateNotifier<AsyncValue<MomentumData>> {
  final MomentumApiService _apiService;
  RealtimeChannel? _subscription;

  RealtimeMomentumNotifier(this._apiService)
    : super(const AsyncValue.loading()) {
    _initializeData();
  }

  /// Initialize momentum data and set up real-time subscription
  Future<void> _initializeData() async {
    try {
      // Load initial data
      final initialData = await _apiService.getCurrentMomentum();
      state = AsyncValue.data(initialData);

      // Set up real-time subscription (only if authenticated)
      _setupRealtimeSubscription();
    } catch (error) {
      // If initialization fails, provide sample data for demo
      debugPrint('Failed to initialize momentum data: $error');
      state = AsyncValue.data(MomentumData.sample());
    }
  }

  /// Set up real-time subscription for momentum updates
  void _setupRealtimeSubscription() {
    // Add a small delay to ensure authentication is complete
    Future.delayed(const Duration(seconds: 2), () {
      try {
        _subscription = _apiService.subscribeToMomentumUpdates(
          onUpdate: (updatedData) {
            state = AsyncValue.data(updatedData);
          },
          onError: (error) {
            // Log error but don't update state to avoid disrupting UI
            debugPrint('Real-time update error: $error');
          },
        );
      } catch (e) {
        debugPrint('Failed to set up real-time subscription: $e');
      }
    });
  }

  /// Manually refresh momentum data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final refreshedData = await _apiService.getCurrentMomentum();
      state = AsyncValue.data(refreshedData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Calculate new momentum score
  Future<void> calculateMomentumScore({String? targetDate}) async {
    try {
      final calculatedData = await _apiService.calculateMomentumScore(
        targetDate: targetDate,
      );
      state = AsyncValue.data(calculatedData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Get momentum history for a date range
  Future<List<DailyMomentum>> getMomentumHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _apiService.getMomentumHistory(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Simulate a momentum state change (for demo purposes)
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

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

/// Provider for momentum history data
final momentumHistoryProvider =
    FutureProvider.family<List<DailyMomentum>, DateRange>((
      ref,
      dateRange,
    ) async {
      final apiService = ref.watch(momentumApiServiceProvider);
      return await apiService.getMomentumHistory(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

/// Helper class for date range parameters
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}
