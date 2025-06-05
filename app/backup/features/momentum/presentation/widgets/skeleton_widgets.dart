/// Skeleton widget components for loading states
///
/// This file serves as the main entry point for all skeleton widgets.
/// Individual components are organized in specialized files for better maintainability.
library;

// Base components - fundamental building blocks
export 'skeleton_base_components.dart';

// Specialized skeleton components
export 'skeleton_momentum_card.dart';
export 'skeleton_weekly_trend_chart.dart';
export 'skeleton_quick_stats_cards.dart';
export 'skeleton_action_buttons.dart';

// Complete skeleton screens
export 'skeleton_screen.dart';

/// Convenience imports for common use cases:
/// 
/// ```dart
/// import '../widgets/skeleton_widgets.dart';
/// 
/// // Use any skeleton component:
/// const SkeletonMomentumCard();
/// const SkeletonWeeklyTrendChart();
/// const SkeletonQuickStatsCards();
/// const SkeletonActionButtons();
/// const SkeletonMomentumScreen();
/// 
/// // Use base components for custom skeletons:
/// ShimmerWidget(child: myWidget);
/// SkeletonContainer(width: 100, height: 20);
/// SkeletonText(width: 80);
/// PulseLoadingWidget(child: myWidget);
/// ```
/// 
/// For responsive design, all skeleton components automatically adapt to:
/// - Screen size (compact vs regular layouts)
/// - Theme colors and styling
/// - Platform-specific design guidelines
/// 
/// Performance optimizations:
/// - Cached dimension calculations
/// - Optimized animation curves
/// - Minimal widget rebuilds
/// - Memory-efficient shimmer effects
