import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/momentum_api_service.dart';
import '../../domain/models/momentum_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:flutter/material.dart';

/// Provider for the momentum API service
/// This waits for Supabase to be initialized before creating the service
final momentumApiServiceProvider = FutureProvider<MomentumApiService>((
  ref,
) async {
  final supabaseClient = await ref.watch(supabaseProvider.future);
  return MomentumApiService(supabaseClient);
});

/// Provider for real-time momentum subscription
final realtimeMomentumProvider =
    AsyncNotifierProvider<RealtimeMomentumNotifier, MomentumData>(() {
      return RealtimeMomentumNotifier();
    });

/// Notifier for managing real-time momentum updates
class RealtimeMomentumNotifier extends AsyncNotifier<MomentumData> {
  MomentumApiService? _apiService;
  RealtimeChannel? _subscription;

  @override
  Future<MomentumData> build() async {
    // Wait for the API service to be ready
    _apiService = await ref.watch(momentumApiServiceProvider.future);

    try {
      // Load initial data
      final initialData = await _apiService!.getCurrentMomentum();

      // Set up real-time subscription (only if authenticated)
      _setupRealtimeSubscription();

      return initialData;
    } catch (error) {
      // If initialization fails, provide sample data for demo
      debugPrint('Failed to initialize momentum data: $error');
      return MomentumData.sample();
    }
  }

  /// Set up real-time subscription for momentum updates
  void _setupRealtimeSubscription() {
    if (_apiService == null) return;

    // Add a small delay to ensure authentication is complete
    Future.delayed(const Duration(seconds: 2), () {
      try {
        _subscription = _apiService!.subscribeToMomentumUpdates(
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
    if (_apiService == null) return;

    state = const AsyncValue.loading();
    try {
      final refreshedData = await _apiService!.getCurrentMomentum();
      state = AsyncValue.data(refreshedData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Calculate new momentum score
  Future<void> calculateMomentumScore({String? targetDate}) async {
    if (_apiService == null) return;

    try {
      final calculatedData = await _apiService!.calculateMomentumScore(
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
    if (_apiService == null) {
      throw Exception('API service not initialized');
    }

    return await _apiService!.getMomentumHistory(
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

  void dispose() {
    _subscription?.unsubscribe();
  }
}

/// Provider for momentum history data
final momentumHistoryProvider =
    FutureProvider.family<List<DailyMomentum>, DateRange>((
      ref,
      dateRange,
    ) async {
      final apiService = await ref.watch(momentumApiServiceProvider.future);
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
