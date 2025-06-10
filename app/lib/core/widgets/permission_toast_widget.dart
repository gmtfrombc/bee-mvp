/// Permission Toast Widget
///
/// This widget displays toast notifications for missing health permissions
/// using the app's consistent styling and responsive design patterns.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_permission_provider.dart';
import '../services/responsive_service.dart';

/// Toast widget for displaying permission-related notifications
class PermissionToastWidget extends ConsumerStatefulWidget {
  const PermissionToastWidget({super.key});

  @override
  ConsumerState<PermissionToastWidget> createState() =>
      _PermissionToastWidgetState();
}

class _PermissionToastWidgetState extends ConsumerState<PermissionToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  String? _currentMessage;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _showToast(String message) async {
    if (_isVisible) {
      // Hide current toast first
      await _hideToast();
    }

    setState(() {
      _currentMessage = message;
      _isVisible = true;
    });

    await _animationController.forward();

    // Auto-hide after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isVisible) {
        _hideToast();
      }
    });
  }

  Future<void> _hideToast() async {
    if (!_isVisible) return;

    await _animationController.reverse();
    if (mounted) {
      setState(() {
        _isVisible = false;
        _currentMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to permission toast stream
    ref.listen<AsyncValue<String>>(permissionToastStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((message) {
        if (message.isNotEmpty) {
          _showToast(message);
        }
      });
    });

    if (!_isVisible || _currentMessage == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top:
          MediaQuery.of(context).padding.top +
          ResponsiveService.getSmallSpacing(context),
      left: ResponsiveService.getResponsiveMargin(context).left,
      right: ResponsiveService.getResponsiveMargin(context).right,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * 100),
            child: Opacity(opacity: _opacityAnimation.value, child: child),
          );
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: ResponsiveService.getMediumPadding(context),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  color: colorScheme.onErrorContainer,
                  size: 24,
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Health Permissions Required',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveService.getTinySpacing(context),
                      ),
                      Text(
                        _currentMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer.withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                IconButton(
                  onPressed: _hideToast,
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent permission status indicator
class PermissionStatusIndicator extends ConsumerWidget {
  const PermissionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionStatusProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (permissionState.hasAllRequiredPermissions) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: ResponsiveService.getResponsiveMargin(context),
      padding: ResponsiveService.getSmallPadding(context),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Text(
              '${permissionState.missingPermissions.length} health permission(s) needed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(permissionStatusProvider.notifier)
                  .requestAllPermissions();
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.secondary,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveService.getSmallSpacing(context),
                vertical: ResponsiveService.getTinySpacing(context),
              ),
            ),
            child: Text(
              'Enable',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for permission requests
class PermissionActionButton extends ConsumerWidget {
  const PermissionActionButton({
    super.key,
    this.onPressed,
    this.text = 'Enable Health Permissions',
  });

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionStatusProvider);
    final theme = Theme.of(context);

    if (permissionState.hasAllRequiredPermissions) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: ResponsiveService.getResponsiveMargin(context),
      child: ElevatedButton.icon(
        onPressed:
            permissionState.isLoading
                ? null
                : onPressed ??
                    () async {
                      await ref
                          .read(permissionStatusProvider.notifier)
                          .requestAllPermissions();
                    },
        icon:
            permissionState.isLoading
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                : const Icon(Icons.health_and_safety_outlined),
        label: Text(permissionState.isLoading ? 'Requesting...' : text),
        style: ElevatedButton.styleFrom(
          padding: ResponsiveService.getMediumPadding(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
