import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../domain/models/today_feed_content.dart';
import 'rich_content_renderer.dart';

/// Callback types for Today Feed tile interactions
typedef TodayFeedCallback = void Function();
typedef TodayFeedInteractionCallback =
    void Function(TodayFeedInteractionType type);

/// Today Feed tile component displaying daily AI-generated health content
/// Implements Material Design 3 with state management and accessibility
class TodayFeedTile extends StatefulWidget {
  const TodayFeedTile({
    super.key,
    required this.state,
    this.onTap,
    this.onExternalLinkTap,
    this.onShare,
    this.onBookmark,
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
  late AnimationController _entryController;
  late AnimationController _tapController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  // Animation durations - responsive to motion preferences
  Duration get _entryDuration =>
      widget.enableAnimations
          ? const Duration(milliseconds: 600)
          : Duration.zero;

  Duration get _tapDuration =>
      widget.enableAnimations
          ? const Duration(milliseconds: 200)
          : Duration.zero;

  Duration get _pulseDuration =>
      widget.enableAnimations
          ? const Duration(milliseconds: 1500)
          : Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Defer animation starts until dependencies are available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enableAnimations) {
      _startEntryAnimation();
      _startPulseAnimationIfFresh();
      _startShimmerAnimationIfLoading();
    }
  }

  @override
  void didUpdateWidget(TodayFeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.runtimeType != widget.state.runtimeType) {
      _handleStateTransition();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tapController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    // Entry animation
    _entryController = AnimationController(
      duration: _entryDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Tap animation
    _tapController = AnimationController(duration: _tapDuration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));

    // Pulse animation for fresh state
    _pulseController = AnimationController(
      duration: _pulseDuration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    // Shimmer animation for loading state
    _shimmerController = AnimationController(
      duration: _pulseDuration,
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  void _startEntryAnimation() {
    if (widget.enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context)) {
      _entryController.forward();
    } else {
      _entryController.value = 1.0;
    }
  }

  void _startPulseAnimationIfFresh() {
    if (widget.enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context) &&
        _isFreshState()) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startShimmerAnimationIfLoading() {
    if (widget.enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context) &&
        widget.state.isLoading) {
      _shimmerController.repeat();
    }
  }

  void _handleStateTransition() {
    if (widget.enableAnimations) {
      _fadeAnimation.addListener(() {
        if (_fadeAnimation.value == 0.0) {
          _entryController.forward();
        }
      });
      _entryController.reverse().then((_) {
        if (mounted) {
          _entryController.forward();
          _updateAnimationsForNewState();
        }
      });
    } else {
      _updateAnimationsForNewState();
    }
  }

  void _updateAnimationsForNewState() {
    _pulseController.stop();
    _shimmerController.stop();

    if (_isFreshState()) {
      _startPulseAnimationIfFresh();
    } else if (widget.state.isLoading) {
      _startShimmerAnimationIfLoading();
    }
  }

  bool _isFreshState() {
    final content = widget.state.content;
    return widget.state.isLoaded &&
        content != null &&
        content.isFresh &&
        !content.hasUserEngaged;
  }

  void _handleTap() {
    if (widget.onTap != null) {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Scale animation
      if (widget.enableAnimations &&
          !AccessibilityService.shouldReduceMotion(context)) {
        _tapController.forward().then((_) {
          if (mounted) {
            _tapController.reverse();
          }
        });
      }

      // Track interaction
      widget.onInteraction?.call(TodayFeedInteractionType.tap);

      widget.onTap!();
    }
  }

  Future<void> _handleExternalLinkTap(String url, String? linkText) async {
    try {
      // Show preview dialog first for user confirmation
      final shouldLaunch = await UrlLauncherService().showUrlPreviewDialog(
        context,
        url,
        linkText: linkText,
        description:
            "This will open external health content in a secure browser view.",
      );

      if (shouldLaunch) {
        // Try launching with in-app browser first
        final launched = await UrlLauncherService().launchHealthContentUrl(
          url,
          linkText: linkText,
          sourceContext: "Today Feed",
        );

        if (!launched) {
          // Fallback to external browser if in-app browser fails
          await UrlLauncherService().launchInExternalBrowser(
            url,
            linkText: linkText,
            sourceContext: "Today Feed",
          );
        }

        // Call the original callback if provided
        widget.onExternalLinkTap?.call();
      }
    } catch (e) {
      debugPrint('TodayFeedTile: Error handling external link: $e');
      // Still call the callback on error for backward compatibility
      widget.onExternalLinkTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = _getCardHeight(context);
    final cardMargin = _getCardMargin(context);
    final borderRadius = _getBorderRadius(context);

    // Safe accessibility check with fallback
    bool shouldAnimateMotion = widget.enableAnimations;
    try {
      shouldAnimateMotion =
          widget.enableAnimations &&
          !AccessibilityService.shouldReduceMotion(context);
    } catch (e) {
      // Fallback to widget setting if context not available
      shouldAnimateMotion = widget.enableAnimations;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _scaleAnimation,
        _pulseAnimation,
        _shimmerAnimation,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: shouldAnimateMotion ? _fadeAnimation.value : 1.0,
          child: SlideTransition(
            position:
                shouldAnimateMotion
                    ? _slideAnimation
                    : const AlwaysStoppedAnimation(Offset.zero),
            child: Transform.scale(
              scale: shouldAnimateMotion ? _scaleAnimation.value : 1.0,
              child: Container(
                margin: cardMargin,
                child: _buildCard(context, cardHeight, borderRadius),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    double cardHeight,
    double borderRadius,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap != null ? _handleTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
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
              child: widget.state.when(
                loading: () => _buildLoadingState(context),
                loaded: (content) => _buildLoadedState(context, content),
                error: (message) => _buildErrorState(context, message),
                offline:
                    (cachedContent) =>
                        _buildOfflineState(context, cachedContent),
                fallback:
                    (fallbackResult) =>
                        _buildFallbackState(context, fallbackResult),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeader(context, showStatus: true, statusText: "Loading..."),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShimmerBox(
                height: _getTitleHeight(context),
                width: double.infinity,
              ),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              _buildShimmerBox(
                height: _getBodyHeight(context),
                width: double.infinity,
              ),
              SizedBox(height: ResponsiveService.getTinySpacing(context)),
              _buildShimmerBox(
                height: _getBodyHeight(context),
                width: _getPartialWidth(context),
              ),
              SizedBox(height: ResponsiveService.getMediumSpacing(context)),
              _buildShimmerBox(
                height: _getBadgeHeight(context),
                width: _getBadgeWidth(context),
              ),
            ],
          ),
        ),
        _buildActionSection(
          context,
          readingTime: "-- min read",
          showMomentum: false,
          showLoading: true,
        ),
      ],
    );
  }

  Widget _buildLoadedState(BuildContext context, TodayFeedContent content) {
    final isFresh = content.isFresh && !content.hasUserEngaged;
    final isEngaged = content.hasUserEngaged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeader(
          context,
          showStatus: true,
          statusText: isEngaged ? "VIEWED" : (isFresh ? "NEW" : "TODAY"),
          statusColor:
              isEngaged
                  ? AppTheme.getTextTertiary(context)
                  : (isFresh ? AppTheme.momentumRising : null),
        ),
        Expanded(child: _buildContentSection(context, content)),
        _buildActionSection(
          context,
          readingTime: content.readingTimeText,
          showMomentum: widget.showMomentumIndicator,
          isEngaged: isEngaged,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeader(context, showStatus: true, statusText: "ERROR"),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveService.getIconSize(context, baseSize: 48),
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: ResponsiveService.getLargeSpacing(context)),
              Text(
                "Unable to load today's insight",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildActionSection(
          context,
          readingTime: "",
          showMomentum: false,
          showRetry: true,
        ),
      ],
    );
  }

  Widget _buildOfflineState(
    BuildContext context,
    TodayFeedContent cachedContent,
  ) {
    return Opacity(
      opacity: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeader(
            context,
            showStatus: true,
            statusText: "OFFLINE",
            statusIcon: Icons.cloud_off,
            statusColor: AppTheme.getTextTertiary(context),
          ),
          Expanded(child: _buildContentSection(context, cachedContent)),
          _buildActionSection(
            context,
            readingTime: cachedContent.readingTimeText,
            showMomentum: false,
            isOffline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackState(
    BuildContext context,
    TodayFeedFallbackResult fallbackResult,
  ) {
    // Calculate opacity based on content staleness
    final opacity = fallbackResult.isStale ? 0.7 : 0.85;

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeader(
            context,
            showStatus: true,
            statusText: _getFallbackStatusText(fallbackResult.fallbackType),
            statusIcon: _getFallbackStatusIcon(fallbackResult.fallbackType),
            statusColor: _getFallbackStatusColor(fallbackResult.fallbackType),
          ),

          // Show age warning if needed
          if (fallbackResult.shouldShowAgeWarning) ...[
            Container(
              margin: EdgeInsets.symmetric(
                vertical: ResponsiveService.getTinySpacing(context),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveService.getSmallSpacing(context),
                vertical: ResponsiveService.getTinySpacing(context),
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveService.getBorderRadius(context) / 2,
                ),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: ResponsiveService.getIconSize(context, baseSize: 14),
                    color: Colors.amber.shade700,
                  ),
                  SizedBox(width: ResponsiveService.getTinySpacing(context)),
                  Expanded(
                    child: Text(
                      fallbackResult.userMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Display content if available
          if (fallbackResult.content != null)
            Expanded(
              child: _buildContentSection(context, fallbackResult.content!),
            )
          else
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.content_paste_off,
                    size: ResponsiveService.getIconSize(context, baseSize: 48),
                    color: AppTheme.getTextTertiary(context),
                  ),
                  SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                  Text(
                    "No cached content available",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                  Text(
                    fallbackResult.userMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          _buildActionSection(
            context,
            readingTime: fallbackResult.content?.readingTimeText ?? "",
            showMomentum: false, // No momentum awards for fallback content
            isOffline: true,
            showRetry: fallbackResult.content == null,
            isFallback: true,
          ),
        ],
      ),
    );
  }

  /// Get appropriate status text for different fallback types
  String _getFallbackStatusText(TodayFeedFallbackType fallbackType) {
    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        return "CACHED";
      case TodayFeedFallbackType.contentHistory:
        return "ARCHIVED";
      case TodayFeedFallbackType.none:
        return "NO CONTENT";
      case TodayFeedFallbackType.error:
        return "ERROR";
    }
  }

  /// Get appropriate status icon for different fallback types
  IconData _getFallbackStatusIcon(TodayFeedFallbackType fallbackType) {
    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        return Icons.cached;
      case TodayFeedFallbackType.contentHistory:
        return Icons.archive;
      case TodayFeedFallbackType.none:
        return Icons.content_paste_off;
      case TodayFeedFallbackType.error:
        return Icons.error_outline;
    }
  }

  /// Get appropriate status color for different fallback types
  Color _getFallbackStatusColor(TodayFeedFallbackType fallbackType) {
    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        return Colors.blue;
      case TodayFeedFallbackType.contentHistory:
        return Colors.orange;
      case TodayFeedFallbackType.none:
      case TodayFeedFallbackType.error:
        return Colors.red;
    }
  }

  Widget _buildHeader(
    BuildContext context, {
    bool showStatus = false,
    String? statusText,
    IconData? statusIcon,
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Health Insight",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveService.getTinySpacing(context) / 2),
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (showStatus && statusText != null) ...[
          SizedBox(width: ResponsiveService.getTinySpacing(context)),
          Flexible(
            child: _buildStatusBadge(
              context,
              statusText,
              statusIcon,
              statusColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String text,
    IconData? icon,
    Color? color,
  ) {
    final badgeColor = color ?? AppTheme.momentumRising;
    final spacing = ResponsiveService.getTinySpacing(context);
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 12);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2,
        ),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: badgeColor),
            SizedBox(width: spacing),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, TodayFeedContent content) {
    // Use rich content if available, otherwise fall back to basic content
    if (content.fullContent != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          // Title
          Flexible(
            child: Text(
              content.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: _getResponsiveFontSize(context, baseFontSize: 20),
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: -0.3,
              ),
              maxLines: _getMaxTitleLines(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          // Rich content in a scrollable container for tile view
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: RichContentRenderer(
                content: content.fullContent!,
                onLinkTap:
                    widget.onExternalLinkTap != null
                        ? (url, linkText) {
                          HapticFeedback.lightImpact();
                          widget.onInteraction?.call(
                            TodayFeedInteractionType.externalLinkClick,
                          );
                          _handleExternalLinkTap(url, linkText);
                        }
                        : null,
                isCompact: true,
                enableInteractions: true,
              ),
            ),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          _buildTopicBadge(context, content.topicCategory),
        ],
      );
    }

    // Fallback to original basic content display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Flexible(
          child: Text(
            content.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: _getResponsiveFontSize(context, baseFontSize: 20),
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            maxLines: _getMaxTitleLines(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Flexible(
          flex: 2,
          child: Text(
            content.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
              height: 1.4,
              letterSpacing: 0.1,
              color: AppTheme.getTextSecondary(context),
            ),
            maxLines: _getMaxSummaryLines(context),
            overflow: TextOverflow.fade,
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        _buildTopicBadge(context, content.topicCategory),
      ],
    );
  }

  Widget _buildTopicBadge(BuildContext context, HealthTopic topic) {
    final spacing = ResponsiveService.getTinySpacing(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: _getTopicColor(topic).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2.5,
        ),
      ),
      child: Text(
        topic.value.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _getTopicColor(topic),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context, {
    required String readingTime,
    bool showMomentum = false,
    bool isEngaged = false,
    bool isOffline = false,
    bool showLoading = false,
    bool showRetry = false,
    bool isFallback = false,
  }) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final spacing = ResponsiveService.getTinySpacing(context);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reading time - wrapped with Flexible
        Flexible(
          child:
              readingTime.isNotEmpty
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: iconSize,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          readingTime,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextTertiary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),

        // Action button - wrapped with Flexible
        Flexible(
          child:
              showRetry
                  ? ElevatedButton.icon(
                    onPressed: widget.onTap,
                    icon: Icon(Icons.refresh, size: iconSize),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(80, buttonHeight),
                      padding: ResponsiveService.getHorizontalPadding(
                        context,
                        multiplier: 0.75,
                      ),
                      textStyle: _getButtonTextStyle(context),
                    ),
                  )
                  : showLoading
                  ? SizedBox(
                    width: 100,
                    height: buttonHeight,
                    child: _buildShimmerBox(height: buttonHeight, width: 100),
                  )
                  : ElevatedButton.icon(
                    onPressed: isEngaged ? null : widget.onTap,
                    icon:
                        showMomentum
                            ? _buildMomentumIcon(context, isEngaged)
                            : Icon(Icons.arrow_forward, size: iconSize),
                    label: Text(isEngaged ? "Read Again" : "Read More"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, buttonHeight),
                      padding: ResponsiveService.getHorizontalPadding(
                        context,
                        multiplier: 0.75,
                      ),
                      textStyle: _getButtonTextStyle(context),
                      backgroundColor:
                          isEngaged ? null : AppTheme.momentumRising,
                      foregroundColor: isEngaged ? null : Colors.white,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildMomentumIcon(BuildContext context, bool isEngaged) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);

    if (isEngaged) {
      return Icon(
        Icons.check_circle,
        size: iconSize,
        color: AppTheme.momentumRising,
      );
    }

    final momentumSize = iconSize;
    final fontSize = ResponsiveService.getFontSizeMultiplier(context) * 10;

    if (widget.enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context) &&
        _isFreshState()) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: momentumSize,
              height: momentumSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.momentumRising,
              ),
              child: Center(
                child: Text(
                  '+1',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: momentumSize,
      height: momentumSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.momentumRising,
      ),
      child: Center(
        child: Text(
          '+1',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context) / 4,
            ),
            gradient: LinearGradient(
              colors: [
                AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
                AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
                AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
              ],
              stops:
                  [
                    _shimmerAnimation.value - 0.3,
                    _shimmerAnimation.value,
                    _shimmerAnimation.value + 0.3,
                  ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }

  // Helper methods for responsive design and styling

  double _getCardHeight(BuildContext context) {
    if (widget.height != null) return widget.height!;

    final deviceType = ResponsiveService.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 230.0;
      case DeviceType.mobile:
        return 250.0;
      case DeviceType.mobileLarge:
        return 270.0;
      case DeviceType.tablet:
        return 290.0;
      case DeviceType.desktop:
        return 310.0;
    }
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
    if (!_isFreshState()) return null;

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

  Border? _getCardBorder() {
    if (!_isFreshState()) return null;

    return Border.all(
      color: AppTheme.momentumRising.withValues(alpha: 0.1),
      width: 1,
    );
  }

  double _getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
  }) {
    final accessibleScale = AccessibilityService.getAccessibleTextScale(
      context,
    );
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return baseFontSize * responsiveMultiplier * accessibleScale;
  }

  int _getMaxTitleLines(BuildContext context) {
    return ResponsiveService.shouldUseCompactLayout(context) ? 2 : 3;
  }

  int _getMaxSummaryLines(BuildContext context) {
    return ResponsiveService.shouldUseCompactLayout(context) ? 3 : 4;
  }

  TextStyle _getButtonTextStyle(BuildContext context) {
    final baseSize =
        ResponsiveService.shouldUseCompactLayout(context) ? 14.0 : 16.0;
    return TextStyle(
      fontSize: _getResponsiveFontSize(context, baseFontSize: baseSize),
      fontWeight: FontWeight.w600,
    );
  }

  // Shimmer-specific measurements
  double _getTitleHeight(BuildContext context) =>
      _getResponsiveFontSize(context, baseFontSize: 20) * 1.2;

  double _getBodyHeight(BuildContext context) =>
      _getResponsiveFontSize(context, baseFontSize: 16) * 1.4;

  double _getBadgeHeight(BuildContext context) =>
      _getResponsiveFontSize(context, baseFontSize: 12) * 1.3 +
      (ResponsiveService.getTinySpacing(context) * 2);

  double _getBadgeWidth(BuildContext context) =>
      ResponsiveService.getResponsiveSpacing(context) * 4;

  double _getPartialWidth(BuildContext context) =>
      MediaQuery.of(context).size.width * 0.6;

  Color _getTopicColor(HealthTopic topic) {
    switch (topic) {
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
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
