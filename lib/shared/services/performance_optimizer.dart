import 'package:flutter/material.dart';

/// Performance optimization service for caching, debouncing, and efficient UIs
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();

  factory PerformanceOptimizer() => _instance;

  PerformanceOptimizer._internal();

  // Image caching strategy
  final Map<String, ImageProvider> _imageCache = {};

  // Network request debouncing
  final Map<String, DateTime> _lastRequestTime = {};
  final Duration _debounceThreshold = const Duration(milliseconds: 500);

  /// Get cached image or create new provider
  ImageProvider getCachedImage(String url) {
    if (!_imageCache.containsKey(url)) {
      _imageCache[url] = NetworkImage(url);
    }
    return _imageCache[url]!;
  }

  /// Check if request should be debounced
  bool shouldDebounce(String requestKey) {
    final lastTime = _lastRequestTime[requestKey];
    if (lastTime == null) {
      _lastRequestTime[requestKey] = DateTime.now();
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(lastTime);

    if (difference.compareTo(_debounceThreshold) > 0) {
      _lastRequestTime[requestKey] = now;
      return false;
    }
    return true;
  }

  /// Clear old cache entries
  void clearOldCache(Duration age) {
    final now = DateTime.now();
    _lastRequestTime.removeWhere((_, time) => now.difference(time) > age);
  }

  /// Memory-efficient list rendering hint
  static const int optimalListChunkSize = 20;
  static const int optimalGridColumns = 2;
}

/// Efficient animation mixin for smooth transitions
mixin EfficientAnimationMixin {
  AnimationController? _controller;

  void initAnimation(TickerProvider vsync, Duration duration) {
    _controller = AnimationController(duration: duration, vsync: vsync);
  }

  void startAnimation() => _controller?.forward();
  void stopAnimation() => _controller?.reverse();
  void disposeAnimation() => _controller?.dispose();

  Animation<double> get fadeAnimation => Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));

  Animation<Offset> get slideAnimation => Tween<Offset>(
    begin: const Offset(0, 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
}
