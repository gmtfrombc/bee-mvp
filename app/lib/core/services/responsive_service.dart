import 'package:flutter/material.dart';

/// Spacing multipliers for consistent spacing across the app
class SpacingMultipliers {
  static const double tiny = 0.25; // 4px on mobile
  static const double small = 0.5; // 8px on mobile
  static const double medium = 0.8; // 12px on mobile
  static const double large = 1.5; // 24px on mobile
  static const double extraLarge = 2.0; // 32px on mobile
}

/// Device type enumeration
enum DeviceType { mobileSmall, mobile, mobileLarge, tablet, desktop }

/// Service for responsive design utilities
/// Provides breakpoints, sizing, and layout helpers for different screen sizes
class ResponsiveService {
  // Screen size breakpoints
  static const double mobileSmall = 375.0;
  static const double mobileLarge = 428.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;

  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width <= mobileSmall) {
      return DeviceType.mobileSmall;
    } else if (width < mobileLarge) {
      return DeviceType.mobile;
    } else if (width < tablet) {
      return DeviceType.mobileLarge;
    } else if (width < desktop) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return const EdgeInsets.all(14.0);
      case DeviceType.mobile:
        return const EdgeInsets.all(18.0);
      case DeviceType.mobileLarge:
        return const EdgeInsets.all(20.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(24.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return const EdgeInsets.symmetric(horizontal: 10.0);
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case DeviceType.mobileLarge:
        return const EdgeInsets.symmetric(horizontal: 20.0);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32.0);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 48.0);
    }
  }

  /// Get responsive spacing between elements
  static double getResponsiveSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 18.0;
      case DeviceType.mobile:
        return 22.0;
      case DeviceType.mobileLarge:
        return 24.0;
      case DeviceType.tablet:
        return 28.0;
      case DeviceType.desktop:
        return 32.0;
    }
  }

  /// Get tiny spacing (4px on mobile, scales responsively)
  static double getTinySpacing(BuildContext context) =>
      getResponsiveSpacing(context) * SpacingMultipliers.tiny;

  /// Get small spacing (8px on mobile, scales responsively)
  static double getSmallSpacing(BuildContext context) =>
      getResponsiveSpacing(context) * SpacingMultipliers.small;

  /// Get medium spacing (12px on mobile, scales responsively)
  static double getMediumSpacing(BuildContext context) =>
      getResponsiveSpacing(context) * SpacingMultipliers.medium;

  /// Get large spacing (24px on mobile, scales responsively)
  static double getLargeSpacing(BuildContext context) =>
      getResponsiveSpacing(context) * SpacingMultipliers.large;

  /// Get extra large spacing (32px on mobile, scales responsively)
  static double getExtraLargeSpacing(BuildContext context) =>
      getResponsiveSpacing(context) * SpacingMultipliers.extraLarge;

  /// Get custom spacing with multiplier
  static double getCustomSpacing(BuildContext context, double multiplier) =>
      getResponsiveSpacing(context) * multiplier;

  /// Get small responsive padding
  static EdgeInsets getSmallPadding(BuildContext context) {
    final base = getSmallSpacing(context);
    return EdgeInsets.all(base);
  }

  /// Get medium responsive padding
  static EdgeInsets getMediumPadding(BuildContext context) {
    final base = getMediumSpacing(context);
    return EdgeInsets.all(base);
  }

  /// Get large responsive padding
  static EdgeInsets getLargePadding(BuildContext context) {
    final base = getLargeSpacing(context);
    return EdgeInsets.all(base);
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(
    BuildContext context, {
    double multiplier = 1.0,
  }) {
    final base = getResponsiveSpacing(context) * multiplier;
    return EdgeInsets.symmetric(horizontal: base);
  }

  /// Get responsive vertical padding
  static EdgeInsets getVerticalPadding(
    BuildContext context, {
    double multiplier = 1.0,
  }) {
    final base = getResponsiveSpacing(context) * multiplier;
    return EdgeInsets.symmetric(vertical: base);
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 0.95;
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.mobileLarge:
        return 1.05;
      case DeviceType.tablet:
        return 1.15;
      case DeviceType.desktop:
        return 1.25;
    }
  }

  /// Get responsive momentum gauge size
  static double getMomentumGaugeSize(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 110.0;
      case DeviceType.mobile:
        return 130.0;
      case DeviceType.mobileLarge:
        return 140.0;
      case DeviceType.tablet:
        return 160.0;
      case DeviceType.desktop:
        return 180.0;
    }
  }

  /// Get responsive momentum card height
  static double getMomentumCardHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 250.0;
      case DeviceType.mobile:
        return 270.0;
      case DeviceType.mobileLarge:
        return 290.0;
      case DeviceType.tablet:
        return 310.0;
      case DeviceType.desktop:
        return 330.0;
    }
  }

  /// Get responsive quick stats card height
  static double getQuickStatsCardHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 82.0;
      case DeviceType.mobile:
        return 90.0;
      case DeviceType.mobileLarge:
        return 92.0;
      case DeviceType.tablet:
        return 100.0;
      case DeviceType.desktop:
        return 108.0;
    }
  }

  /// Get responsive weekly chart height
  static double getWeeklyChartHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 120.0;
      case DeviceType.mobile:
        return 140.0;
      case DeviceType.mobileLarge:
        return 160.0;
      case DeviceType.tablet:
        return 180.0;
      case DeviceType.desktop:
        return 200.0;
    }
  }

  /// Get responsive Today Feed tile height
  static double getTodayFeedTileHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 370.0;
      case DeviceType.mobile:
        return 400.0;
      case DeviceType.mobileLarge:
        return 430.0;
      case DeviceType.tablet:
        return 470.0;
      case DeviceType.desktop:
        return 500.0;
    }
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive column count for grid layouts
  static int getGridColumnCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return isLandscapeMode ? 2 : 1;
      case DeviceType.mobile:
        return isLandscapeMode ? 2 : 1;
      case DeviceType.mobileLarge:
        return isLandscapeMode ? 3 : 2;
      case DeviceType.tablet:
        return isLandscapeMode ? 4 : 3;
      case DeviceType.desktop:
        return isLandscapeMode ? 5 : 4;
    }
  }

  /// Get maximum content width for larger screens
  static double getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
      case DeviceType.mobile:
      case DeviceType.mobileLarge:
        return double.infinity;
      case DeviceType.tablet:
        return 600.0;
      case DeviceType.desktop:
        return 800.0;
    }
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 8.0;
      case DeviceType.mobile:
        return 12.0;
      case DeviceType.mobileLarge:
        return 14.0;
      case DeviceType.tablet:
        return 16.0;
      case DeviceType.desktop:
        return 18.0;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24.0}) {
    final multiplier = getFontSizeMultiplier(context);
    return baseSize * multiplier;
  }

  /// Check if device should use compact layout
  static bool shouldUseCompactLayout(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.mobileSmall;
  }

  /// Check if device should use expanded layout
  static bool shouldUseExpandedLayout(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveService.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive layout wrapper for content
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final EdgeInsets? customPadding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.centerContent = false,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveService.getMaxContentWidth(context);
    final padding =
        customPadding ?? ResponsiveService.getResponsivePadding(context);

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      child: child,
    );

    if (centerContent && maxWidth != double.infinity) {
      content = Center(child: content);
    }

    return content;
  }
}
