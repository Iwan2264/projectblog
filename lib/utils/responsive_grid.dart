import 'package:flutter/material.dart';

class ResponsiveGrid {
  /// Calculate optimal cross axis count based on screen width
  static int getCrossAxisCount(double screenWidth, {
    int minItemWidth = 300,
    int maxCrossAxisCount = 4,
    int minCrossAxisCount = 1,
  }) {
    if (screenWidth <= 0) return minCrossAxisCount;
    
    int crossAxisCount = (screenWidth / minItemWidth).floor();
    
    // Ensure we're within bounds
    crossAxisCount = crossAxisCount.clamp(minCrossAxisCount, maxCrossAxisCount);
    
    return crossAxisCount;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth > 1200) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    } else if (screenWidth > 800) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    } else if (screenWidth > 600) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0);
    }
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(double screenWidth) {
    if (screenWidth > 1200) {
      return 16.0;
    } else if (screenWidth > 800) {
      return 12.0;
    } else if (screenWidth > 600) {
      return 10.0;
    } else {
      return 8.0;
    }
  }

  /// Calculate child aspect ratio based on content type
  static double getChildAspectRatio(ResponsiveCardType cardType, double screenWidth) {
    switch (cardType) {
      case ResponsiveCardType.blogCard:
        return screenWidth > 600 ? 0.75 : 0.8;
      case ResponsiveCardType.square:
        return 1.0;
      case ResponsiveCardType.wide:
        return screenWidth > 600 ? 1.5 : 1.2;
      case ResponsiveCardType.compact:
        return screenWidth > 600 ? 1.2 : 1.0;
    }
  }
}

enum ResponsiveCardType {
  blogCard,
  square,
  wide,
  compact,
}

/// A responsive grid view that adapts to screen size
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final ResponsiveCardType cardType;
  final int minItemWidth;
  final int maxCrossAxisCount;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final double? itemSpacing;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.cardType = ResponsiveCardType.blogCard,
    this.minItemWidth = 300,
    this.maxCrossAxisCount = 4,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = ResponsiveGrid.getCrossAxisCount(
          screenWidth,
          minItemWidth: minItemWidth,
          maxCrossAxisCount: maxCrossAxisCount,
        );

        final responsivePadding = padding ?? ResponsiveGrid.getResponsivePadding(screenWidth);
        final spacing = itemSpacing ?? ResponsiveGrid.getResponsiveSpacing(screenWidth);
        final aspectRatio = ResponsiveGrid.getChildAspectRatio(cardType, screenWidth);

        return Padding(
          padding: responsivePadding,
          child: GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: children.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }
}

/// Responsive wrapper for grid items to prevent overflow
class ResponsiveGridItem extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool enableSafeArea;

  const ResponsiveGridItem({
    super.key,
    required this.child,
    this.padding,
    this.enableSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = Container(
      constraints: const BoxConstraints(
        minHeight: 0,
        maxHeight: double.infinity,
      ),
      child: child,
    );

    if (padding != null) {
      wrappedChild = Padding(
        padding: padding!,
        child: wrappedChild,
      );
    }

    if (enableSafeArea) {
      wrappedChild = ClipRect(
        child: wrappedChild,
      );
    }

    return wrappedChild;
  }
}
