import 'package:app/core/services/cache/strategies/today_feed_cache_optimization_strategy.dart';
import 'package:flutter/foundation.dart';

void main() {
  testTodayFeedCacheOptimizationStrategy();
}

void testTodayFeedCacheOptimizationStrategy() {
  debugPrint('🧪 Testing TodayFeedCacheOptimizationStrategy');

  // Test Strategy Selection
  testStrategySelection();

  debugPrint('✅ All TodayFeedCacheOptimizationStrategy tests completed');
}

void testStrategySelection() {
  debugPrint('Testing strategy selection...');

  // Test memory optimization selection
  final memoryContext = OptimizationContext.memoryPressure(
    availableMemoryMB: 128,
    currentCacheSizeMB: 150.0,
  );
  final memoryStrategy = TodayFeedCacheOptimizationStrategy.selectStrategy(
    memoryContext,
  );
  assert(
    memoryStrategy.strategyType == OptimizationStrategyType.memoryOptimized,
  );

  // Test performance optimization selection
  final performanceContext = OptimizationContext.performance(
    averageResponseTimeMs: 700,
  );
  final performanceStrategy = TodayFeedCacheOptimizationStrategy.selectStrategy(
    performanceContext,
  );
  assert(
    performanceStrategy.strategyType ==
        OptimizationStrategyType.performanceOptimized,
  );

  // Test balanced strategy as default
  final defaultContext = OptimizationContext.automatic(
    deviceCapability: DeviceCapability.midRange,
  );
  final balancedStrategy = TodayFeedCacheOptimizationStrategy.selectStrategy(
    defaultContext,
  );
  assert(balancedStrategy.strategyType == OptimizationStrategyType.balanced);

  debugPrint('✅ Strategy selection tests passed');
}
