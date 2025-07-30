import 'package:flutter/material.dart';

/// Responsive design utilities for different screen sizes
class ResponsiveLayout {
  // Breakpoints for different device types
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get appropriate grid column count based on screen size
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get appropriate font scale based on screen size and accessibility settings
  static double getFontScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);

    // Ensure minimum readable size on all devices
    if (isMobile(context)) {
      return (textScaleFactor * 1.0).clamp(1.0, 1.3);
    } else if (isTablet(context)) {
      return (textScaleFactor * 1.1).clamp(1.0, 1.4);
    } else {
      return (textScaleFactor * 1.2).clamp(1.0, 1.5);
    }
  }

  /// Get appropriate icon size based on screen size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.4;
    }
  }

  /// Get appropriate button height based on screen size
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48;
    } else if (isTablet(context)) {
      return 56;
    } else {
      return 64;
    }
  }

  /// Get appropriate app bar height based on screen size
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else if (isTablet(context)) {
      return kToolbarHeight * 1.2;
    } else {
      return kToolbarHeight * 1.4;
    }
  }

  /// Get maximum content width for better readability
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isMobile(context)) {
      return screenWidth;
    } else if (isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }

  /// Widget that adapts layout based on screen size
  static Widget adaptive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get appropriate list tile content padding
  static EdgeInsets getListTilePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  /// Get appropriate card margin
  static EdgeInsets getCardMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get appropriate border radius based on screen size
  static double getBorderRadius(BuildContext context,
      {double baseRadius = 12}) {
    if (isMobile(context)) {
      return baseRadius;
    } else if (isTablet(context)) {
      return baseRadius * 1.2;
    } else {
      return baseRadius * 1.4;
    }
  }

  /// Get horizontal padding based on screen size
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 32;
    }
  }

  /// Build responsive grid with appropriate spacing
  static Widget buildResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double? spacing,
  }) {
    final cols = getGridColumns(context);
    final actualSpacing = spacing ?? (isMobile(context) ? 12 : 16);

    if (cols == 1) {
      return Column(
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(bottom: actualSpacing),
                  child: child,
                ))
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += cols) {
      final rowChildren = <Widget>[];
      for (int j = 0; j < cols && (i + j) < children.length; j++) {
        rowChildren.add(Expanded(child: children[i + j]));
        if (j < cols - 1 && (i + j + 1) < children.length) {
          rowChildren.add(SizedBox(width: actualSpacing));
        }
      }
      // Fill remaining space if needed
      while (rowChildren.length < (cols * 2 - 1)) {
        rowChildren.add(const Expanded(child: SizedBox()));
        if (rowChildren.length < (cols * 2 - 1)) {
          rowChildren.add(SizedBox(width: actualSpacing));
        }
      }

      rows.add(Padding(
        padding: EdgeInsets.only(
            bottom: i + cols < children.length ? actualSpacing : 0),
        child: Row(children: rowChildren),
      ));
    }

    return Column(children: rows);
  }
}
