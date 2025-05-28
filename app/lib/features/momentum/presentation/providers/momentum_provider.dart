import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/momentum_data.dart';

/// Provider for momentum data
/// Currently returns sample data, will be connected to API in T1.1.3.9
final momentumProvider =
    StateNotifierProvider<MomentumNotifier, AsyncValue<MomentumData>>((ref) {
      return MomentumNotifier();
    });

/// Momentum state notifier
class MomentumNotifier extends StateNotifier<AsyncValue<MomentumData>> {
  MomentumNotifier() : super(const AsyncValue.loading()) {
    _loadMomentumData();
  }

  /// Load momentum data (currently sample data)
  Future<void> _loadMomentumData() async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // TODO: Replace with actual API call in T1.1.3.9
      final momentumData = MomentumData.sample();

      state = AsyncValue.data(momentumData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh momentum data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadMomentumData();
  }

  /// Update momentum data (for real-time updates)
  void updateMomentumData(MomentumData newData) {
    state = AsyncValue.data(newData);
  }
}
