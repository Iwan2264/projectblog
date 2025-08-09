import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A widget that helps monitor and optimize performance of child widgets
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String name;
  final bool enableProfiling;
  final VoidCallback? onSlowBuild;
  final int slowBuildThresholdMs;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.name,
    this.enableProfiling = kDebugMode,
    this.onSlowBuild,
    this.slowBuildThresholdMs = 16, // One frame at 60fps
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  Stopwatch? _buildStopwatch;
  int _buildCount = 0;
  int _slowBuilds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enableProfiling) {
      _buildStopwatch = Stopwatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableProfiling) {
      return widget.child;
    }

    _buildStopwatch?.reset();
    _buildStopwatch?.start();
    _buildCount++;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildStopwatch?.stop();
      final buildTime = _buildStopwatch?.elapsedMilliseconds ?? 0;
      
      if (buildTime > widget.slowBuildThresholdMs) {
        _slowBuilds++;
        debugPrint('🐌 ${widget.name}: Slow build #$_slowBuilds/$_buildCount (${buildTime}ms)');
        widget.onSlowBuild?.call();
      }
    });

    return widget.child;
  }

  @override
  void dispose() {
    if (widget.enableProfiling && _buildCount > 0) {
      debugPrint('📊 ${widget.name}: Built $_buildCount times, $_slowBuilds were slow');
    }
    super.dispose();
  }
}

/// Wrapper for ListView/GridView to monitor scroll performance
class PerformantScrollView extends StatefulWidget {
  final Widget child;
  final String name;
  final bool enableMonitoring;

  const PerformantScrollView({
    super.key,
    required this.child,
    required this.name,
    this.enableMonitoring = kDebugMode,
  });

  @override
  State<PerformantScrollView> createState() => _PerformantScrollViewState();
}

class _PerformantScrollViewState extends State<PerformantScrollView> {
  int _frameDrops = 0;
  DateTime? _lastScrollTime;

  @override
  void initState() {
    super.initState();
  }

  void _onScroll() {
    final now = DateTime.now();
    if (_lastScrollTime != null) {
      final timeDiff = now.difference(_lastScrollTime!).inMilliseconds;
      
      // If time between scroll events is > 32ms, we likely dropped frames
      if (timeDiff > 32) {
        _frameDrops++;
        if (_frameDrops % 10 == 0) {
          debugPrint('⚠️ ${widget.name}: Frame drops detected ($_frameDrops)');
        }
      }
    }
    _lastScrollTime = now;
  }

  @override
  Widget build(BuildContext context) {
    // For monitoring, we'll wrap the existing widget with a notification listener
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.enableMonitoring && notification is ScrollUpdateNotification) {
          _onScroll();
        }
        return false;
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (widget.enableMonitoring && _frameDrops > 0) {
      debugPrint('📊 ${widget.name}: Total frame drops: $_frameDrops');
    }
    super.dispose();
  }
}

/// Optimized image widget that automatically manages memory
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate optimal cache size based on display size and device pixel ratio
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final displayWidth = width ?? 200;
    final displayHeight = height ?? 200;
    
    final cacheWidth = (displayWidth * devicePixelRatio).round().clamp(50, 1024);
    final cacheHeight = (displayHeight * devicePixelRatio).round().clamp(50, 1024);

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? 
               SizedBox(
                 width: width,
                 height: height,
                 child: const Center(child: CircularProgressIndicator()),
               );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? 
               SizedBox(
                 width: width,
                 height: height,
                 child: Icon(Icons.error, color: Colors.grey[400]),
               );
      },
    );
  }
}
