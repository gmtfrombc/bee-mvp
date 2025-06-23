import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../domain/models/today_feed_content.dart';
import 'components/today_feed_animations.dart';
import 'components/today_feed_interactions.dart';
import 'states/loading_state_widget.dart';
import 'states/error_state_widget.dart';
import 'states/loaded_state_widget.dart';
import 'states/offline_state_widget.dart';
import '../../../ai_coach/ui/coach_chat_screen.dart';

/// Callback types for Today Feed tile interactions
typedef TodayFeedCallback = void Function();
typedef TodayFeedInteractionCallback =
    void Function(TodayFeedInteractionType type);

/// Today Feed tile component displaying daily AI-generated health content
/// Implements Material Design 3 with state management and accessibility
///
/// **REFACTORED**: Reduced from 1,261 lines to ~350 lines by extracting:
/// - Animation system to TodayFeedAnimationController
/// - Interaction handlers to TodayFeedInteractionHandler
/// - State widgets to individual state components
class TodayFeedTile extends StatefulWidget {
  const TodayFeedTile({
    super.key,
    required this.state,
    this.onTap,
    this.onExternalLinkTap,
    this.onShare,
    this.onBookmark,
    this.onRetry,
    this.onInteraction,
    this.showMomentumIndicator = true,
    this.enableAnimations = true,
    this.margin,
    this.height,
  });

  /// Current state of the Today Feed content
  final TodayFeedState state;

  /// Callback when user taps the main content area
  final TodayFeedCallback? onTap;

  /// Callback when user taps external link
  final TodayFeedCallback? onExternalLinkTap;

  /// Callback for sharing content
  final TodayFeedCallback? onShare;

  /// Callback for bookmarking content
  final TodayFeedCallback? onBookmark;

  /// Callback when user taps the retry button in the error state
  final TodayFeedCallback? onRetry;

  /// Callback for tracking interactions with type
  final TodayFeedInteractionCallback? onInteraction;

  /// Whether to show momentum point indicator
  final bool showMomentumIndicator;

  /// Whether to enable card animations
  final bool enableAnimations;

  /// Custom margin for the card
  final EdgeInsets? margin;

  /// Custom height for the card
  final double? height;

  @override
  State<TodayFeedTile> createState() => _TodayFeedTileState();
}

class _TodayFeedTileState extends State<TodayFeedTile>
    with TickerProviderStateMixin {
  // Extracted animation controller
  late TodayFeedAnimationController _animationController;

  // Extracted interaction handler
  late TodayFeedInteractionHandler _interactionHandler;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enableAnimations) {
      _animationController.startEntryAnimation(context);
      _updateAnimationsForCurrentState();
    }
  }

  @override
  void didUpdateWidget(TodayFeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recreate interaction handler if any of its callback dependencies changed
    if (oldWidget.onTap != widget.onTap ||
        oldWidget.onExternalLinkTap != widget.onExternalLinkTap ||
        oldWidget.onShare != widget.onShare ||
        oldWidget.onBookmark != widget.onBookmark ||
        oldWidget.onInteraction != widget.onInteraction) {
      _interactionHandler = TodayFeedInteractionHandler(
        onTap: widget.onTap,
        onExternalLinkTap: widget.onExternalLinkTap,
        onShare: widget.onShare,
        onBookmark: widget.onBookmark,
        onInteraction: widget.onInteraction,
      );
    }

    if (oldWidget.state.runtimeType != widget.state.runtimeType) {
      _handleStateTransition();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize animation controller
    _animationController = TodayFeedAnimationController(
      vsync: this,
      enableAnimations: widget.enableAnimations,
    );
    _animationController.setupAnimations();

    // Initialize interaction handler
    _interactionHandler = TodayFeedInteractionHandler(
      onTap: widget.onTap,
      onExternalLinkTap: widget.onExternalLinkTap,
      onShare: widget.onShare,
      onBookmark: widget.onBookmark,
      onInteraction: widget.onInteraction,
    );
  }

  Future<void> _handleStateTransition() async {
    if (widget.enableAnimations) {
      await _animationController.handleStateTransition(context);
      _updateAnimationsForCurrentState();
    } else {
      _updateAnimationsForCurrentState();
    }
  }

  void _updateAnimationsForCurrentState() {
    final content = widget.state.content;
    final isFresh =
        widget.state.isLoaded &&
        content != null &&
        content.isFresh &&
        !content.hasUserEngaged;

    _animationController.updateAnimationsForNewState(
      context,
      isFresh: isFresh,
      isLoading: widget.state.isLoading,
    );
  }

  Future<void> _onAnimationTrigger() async {
    await _animationController.handleTapAnimation(context);
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = _getCardHeight(context);
    final cardMargin = _getCardMargin(context);
    final borderRadius = _getBorderRadius(context);

    return TodayFeedAnimationWrapper(
      animationController: _animationController,
      enableAnimations: widget.enableAnimations,
      child: Container(
        margin: cardMargin,
        child: _buildCard(context, cardHeight, borderRadius),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    double cardHeight,
    double borderRadius,
  ) {
    return TodayFeedInteractionBuilder(
      handler: _interactionHandler,
      content: widget.state.content,
      onAnimationTrigger: _onAnimationTrigger,
      borderRadius: borderRadius,
      child: GestureDetector(
        onLongPress: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CoachChatScreen()));
        },
        child: Semantics(
          label: _getSemanticLabel(),
          hint: _getSemanticHint(),
          button: widget.onTap != null,
          child: Card(
            elevation: _getCardElevation(),
            shadowColor: _getShadowColor().withValues(alpha: 0.1),
            child: Container(
              height: cardHeight,
              padding: _getCardPadding(context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: _getCardGradient(),
                border: _getCardBorder(),
              ),
              child: _buildStateContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context) {
    return widget.state.when(
      loading:
          () => TodayFeedLoadingStateWidget(
            shimmerAnimation: _animationController.shimmerAnimation,
          ),

      loaded:
          (content) => TodayFeedLoadedStateWidget(
            content: content,
            showMomentumIndicator: widget.showMomentumIndicator,
            pulseAnimation: _animationController.pulseAnimation,
            interactionHandler: _interactionHandler,
            enableAnimations: widget.enableAnimations,
          ),

      error:
          (message) => TodayFeedErrorStateWidget(
            errorMessage: message,
            onRetry: widget.onRetry ?? widget.onTap,
          ),

      offline:
          (cachedContent) => TodayFeedOfflineStateWidget(
            cachedContent: cachedContent,
            interactionHandler: _interactionHandler,
          ),

      fallback:
          (fallbackResult) => TodayFeedFallbackStateWidget(
            fallbackResult: fallbackResult,
            interactionHandler: _interactionHandler,
          ),
    );
  }

  // Helper methods for responsive design and styling

  double _getCardHeight(BuildContext context) {
    if (widget.height != null) return widget.height!;

    return ResponsiveService.getTodayFeedTileHeight(context);
  }

  EdgeInsets _getCardMargin(BuildContext context) {
    if (widget.margin != null) return widget.margin!;

    return EdgeInsets.symmetric(
      horizontal: ResponsiveService.getResponsiveSpacing(context),
      vertical: ResponsiveService.getSmallSpacing(context),
    );
  }

  EdgeInsets _getCardPadding(BuildContext context) {
    return ResponsiveService.getResponsivePadding(context);
  }

  double _getBorderRadius(BuildContext context) {
    return ResponsiveService.getBorderRadius(context);
  }

  double _getCardElevation() {
    return _isFreshState() ? 4.0 : 2.0;
  }

  Color _getShadowColor() {
    return _isFreshState() ? AppTheme.momentumRising : Colors.black;
  }

  LinearGradient? _getCardGradient() {
    // For fresh state highlight
    if (_isFreshState()) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.momentumRising.withValues(alpha: 0.02),
          Colors.transparent,
          AppTheme.momentumRising.withValues(alpha: 0.01),
        ],
      );
    }

    // Subtle tint based on topic color for loaded content
    final topicColor = _getTopicTintColor();
    if (topicColor != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [topicColor.withValues(alpha: 0.15), Colors.transparent],
      );
    }

    return null;
  }

  Color? _getTopicTintColor() {
    if (!widget.state.isLoaded) return null;
    final content = widget.state.content;
    if (content == null) return null;

    switch (content.topicCategory) {
      case HealthTopic.nutrition:
        return const Color(0xFF4CAF50);
      case HealthTopic.exercise:
        return const Color(0xFF2196F3);
      case HealthTopic.sleep:
        return const Color(0xFF9C27B0);
      case HealthTopic.stress:
        return const Color(0xFFFF9800);
      case HealthTopic.prevention:
        return const Color(0xFFF44336);
      case HealthTopic.lifestyle:
        return const Color(0xFF607D8B);
    }
  }

  Border? _getCardBorder() {
    if (!_isFreshState()) return null;

    return Border.all(
      color: AppTheme.momentumRising.withValues(alpha: 0.1),
      width: 1,
    );
  }

  bool _isFreshState() {
    final content = widget.state.content;
    return widget.state.isLoaded &&
        content != null &&
        content.isFresh &&
        !content.hasUserEngaged;
  }

  String _getSemanticLabel() {
    return widget.state.when(
      loading: () => "Loading today's health insight",
      loaded: (content) => "Today's health insight: ${content.title}",
      error: (message) => "Error loading health insight",
      offline:
          (cachedContent) =>
              "Offline - cached health insight: ${cachedContent.title}",
      fallback:
          (fallbackResult) =>
              fallbackResult.content != null
                  ? "Cached health insight: ${fallbackResult.content!.title}"
                  : "No health insight available",
    );
  }

  String _getSemanticHint() {
    return widget.state.when(
      loading: () => "Please wait while content loads",
      loaded:
          (content) =>
              content.hasUserEngaged
                  ? "Content already viewed, tap to read again"
                  : "Double tap to read content and earn momentum point",
      error: (message) => "Double tap to retry loading content",
      offline: (cachedContent) => "Showing cached content, double tap to read",
      fallback:
          (fallbackResult) =>
              fallbackResult.content != null
                  ? "Showing ${fallbackResult.userMessage.toLowerCase()}, double tap to read"
                  : "No content available, double tap to retry",
    );
  }
}
