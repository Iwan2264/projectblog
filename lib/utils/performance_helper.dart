import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Performance optimizations for state management
class PerformanceHelper {
  /// Debounce function calls to avoid excessive updates
  static void debounce(String tag, VoidCallback function, [Duration delay = const Duration(milliseconds: 300)]) {
    Timer? timer = _timers[tag];
    timer?.cancel();
    
    _timers[tag] = Timer(delay, () {
      function();
      _timers.remove(tag);
    });
  }
  
  static final Map<String, Timer> _timers = {};
  
  /// Throttle function calls to limit frequency
  static void throttle(String tag, VoidCallback function, [Duration delay = const Duration(milliseconds: 100)]) {
    if (_throttles.containsKey(tag)) return;
    
    _throttles[tag] = true;
    function();
    
    Timer(delay, () {
      _throttles.remove(tag);
    });
  }
  
  static final Map<String, bool> _throttles = {};
  
  /// Memory-efficient list updates
  static void updateListEfficiently<T>(RxList<T> list, List<T> newItems, {
    bool Function(T oldItem, T newItem)? areEqual,
  }) {
    // If lists are identical, don't update
    if (listEquals(list, newItems)) return;
    
    // If custom equality check is provided, use it
    if (areEqual != null && list.length == newItems.length) {
      bool allEqual = true;
      for (int i = 0; i < list.length; i++) {
        if (!areEqual(list[i], newItems[i])) {
          allEqual = false;
          break;
        }
      }
      if (allEqual) return;
    }
    
    // Update the list
    list.assignAll(newItems);
  }
  
  /// Check if UI update is necessary based on data changes
  static bool shouldUpdateUI<T>(T? oldValue, T newValue) {
    if (oldValue == null) return true;
    if (oldValue == newValue) return false;
    
    // For collections, check if content changed
    if (oldValue is List && newValue is List) {
      return !listEquals(oldValue, newValue);
    }
    
    if (oldValue is Map && newValue is Map) {
      return !mapEquals(oldValue, newValue);
    }
    
    return true;
  }
  
  /// Optimize image memory usage by calculating optimal cache size
  static Size getOptimalImageCacheSize(Size displaySize, double devicePixelRatio) {
    // Calculate actual pixel size needed
    double width = displaySize.width * devicePixelRatio;
    double height = displaySize.height * devicePixelRatio;
    
    // Cap at reasonable maximums to prevent memory issues
    width = width.clamp(50, 2048);
    height = height.clamp(50, 2048);
    
    return Size(width, height);
  }
  
  /// Memory management for large lists
  static const int defaultListPageSize = 20;
  static const int maxCachedItems = 100;
  
  /// Check if device has sufficient memory for operation
  static bool hasAvailableMemory({int estimatedMemoryMB = 10}) {
    // This is a simplified check - in a real app you might use
    // platform-specific methods to check actual memory usage
    return true; // For now, always return true
  }
  
  /// Lazy loading helper for efficient data loading
  static List<T> getVisibleItems<T>(
    List<T> allItems, 
    int currentIndex, 
    int viewportSize,
  ) {
    if (allItems.isEmpty) return [];
    
    int startIndex = (currentIndex - viewportSize).clamp(0, allItems.length);
    int endIndex = (currentIndex + viewportSize).clamp(0, allItems.length);
    
    return allItems.sublist(startIndex, endIndex);
  }
  
  /// Clean up resources and timers
  static void dispose() {
    _timers.values.forEach((timer) => timer.cancel());
    _timers.clear();
    _throttles.clear();
  }
}

/// Extension for performance monitoring
extension PerformanceMonitoring on Widget {
  Widget withPerformanceMonitoring(String widgetName) {
    return Builder(
      builder: (context) {
        if (kDebugMode) {
          final stopwatch = Stopwatch()..start();
          
          // Monitor build time
          WidgetsBinding.instance.addPostFrameCallback((_) {
            stopwatch.stop();
            if (stopwatch.elapsedMilliseconds > 16) { // More than one frame
              debugPrint('🐌 Slow widget build: $widgetName took ${stopwatch.elapsedMilliseconds}ms');
            }
          });
        }
        
        return this;
      },
    );
  }
}

/// Timer utility for dart:async compatibility
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _isActive = true;
  
  Timer(this.duration, this.callback) {
    Future.delayed(duration, () {
      if (_isActive) {
        callback();
      }
    });
  }
  
  void cancel() {
    _isActive = false;
  }
  
  bool get isActive => _isActive;
}
