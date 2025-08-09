import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Get responsive grid configuration
  static GridConfig getGridConfig(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      // Mobile: 1-2 columns
      return GridConfig(
        crossAxisCount: screenWidth < 400 ? 1 : 2,
        spacing: 8.0,
        padding: 8.0,
        childAspectRatio: 0.85,
      );
    } else if (screenWidth < tabletBreakpoint) {
      // Tablet Portrait: 2-3 columns
      return GridConfig(
        crossAxisCount: 2,
        spacing: 12.0,
        padding: 12.0,
        childAspectRatio: 0.9,
      );
    } else if (screenWidth < desktopBreakpoint) {
      // Tablet Landscape: 3 columns
      return GridConfig(
        crossAxisCount: 3,
        spacing: 16.0,
        padding: 16.0,
        childAspectRatio: 0.95,
      );
    } else {
      // Desktop: 4+ columns
      return GridConfig(
        crossAxisCount: screenWidth > 1600 ? 5 : 4,
        spacing: 20.0,
        padding: 20.0,
        childAspectRatio: 1.0,
      );
    }
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  // Get responsive font sizes
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize * 0.9;
    } else if (isTablet(context)) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  // Get max content width for better readability
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return screenWidth * 0.8; // 80% on desktop
    } else if (isTablet(context)) {
      return screenWidth * 0.9; // 90% on tablet
    } else {
      return screenWidth; // Full width on mobile
    }
  }
}

class GridConfig {
  final int crossAxisCount;
  final double spacing;
  final double padding;
  final double childAspectRatio;

  GridConfig({
    required this.crossAxisCount,
    required this.spacing,
    required this.padding,
    required this.childAspectRatio,
  });
}

// Responsive SliverGridDelegate
class ResponsiveSliverGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  ResponsiveSliverGridDelegate({
    required double screenWidth,
    double? childAspectRatio,
  }) : super(
          crossAxisCount: _getCrossAxisCount(screenWidth),
          mainAxisSpacing: _getSpacing(screenWidth),
          crossAxisSpacing: _getSpacing(screenWidth),
          childAspectRatio: childAspectRatio ?? _getChildAspectRatio(screenWidth),
        );

  static int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 400) return 1;
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 2;
    if (screenWidth < 1200) return 3;
    if (screenWidth < 1600) return 4;
    return 5;
  }

  static double _getSpacing(double screenWidth) {
    if (screenWidth < 600) return 8.0;
    if (screenWidth < 900) return 12.0;
    if (screenWidth < 1200) return 16.0;
    return 20.0;
  }

  static double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 600) return 0.85;
    if (screenWidth < 900) return 0.9;
    if (screenWidth < 1200) return 0.95;
    return 1.0;
  }
}
