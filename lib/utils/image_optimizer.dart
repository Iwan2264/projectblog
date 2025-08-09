import 'dart:io';
import 'package:flutter/material.dart';

class ImageOptimizer {
  /// Get optimal image dimensions for different use cases
  static Size getOptimalSize(ImageType imageType, Size screenSize) {
    switch (imageType) {
      case ImageType.avatar:
        return const Size(200, 200);
      case ImageType.blogThumbnail:
        // Scale based on screen size but cap at reasonable limits
        double width = (screenSize.width * 0.8).clamp(300, 600);
        double height = width * 0.6; // 5:3 aspect ratio
        return Size(width, height);
      case ImageType.blogCover:
        double width = screenSize.width.clamp(400, 1200);
        double height = width * 0.5; // 2:1 aspect ratio
        return Size(width, height);
      case ImageType.fullImage:
        // For full-screen images, use screen dimensions
        return Size(
          screenSize.width.clamp(400, 1920),
          screenSize.height.clamp(600, 1080),
        );
    }
  }

  /// Get memory cache dimensions based on image type and widget size
  static Size getMemoryCacheSize(ImageType imageType, Size? widgetSize) {
    if (widgetSize != null) {
      // Use widget size with some padding for cache efficiency
      return Size(
        (widgetSize.width * 1.2).clamp(100, 1000),
        (widgetSize.height * 1.2).clamp(100, 1000),
      );
    }

    // Fallback to type-based sizing
    switch (imageType) {
      case ImageType.avatar:
        return const Size(100, 100);
      case ImageType.blogThumbnail:
        return const Size(400, 240);
      case ImageType.blogCover:
        return const Size(800, 400);
      case ImageType.fullImage:
        return const Size(1200, 800);
    }
  }

  /// Calculate appropriate quality based on image size and type
  static int getCompressionQuality(ImageType imageType, Size imageSize) {
    // Base quality on image type
    int baseQuality = switch (imageType) {
      ImageType.avatar => 85,
      ImageType.blogThumbnail => 80,
      ImageType.blogCover => 90,
      ImageType.fullImage => 92,
    };

    // Adjust based on image size
    double sizeRatio = (imageSize.width * imageSize.height) / (1920 * 1080);
    
    if (sizeRatio > 2.0) {
      // Very large images, reduce quality more
      return (baseQuality * 0.85).round();
    } else if (sizeRatio > 1.0) {
      // Large images, reduce quality slightly
      return (baseQuality * 0.95).round();
    }
    
    return baseQuality;
  }

  /// Check if image file is too large and needs compression
  static bool needsCompression(File imageFile, {int maxSizeBytes = 2 * 1024 * 1024}) {
    try {
      int fileSizeBytes = imageFile.lengthSync();
      return fileSizeBytes > maxSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Get optimal file size limit based on image type
  static int getMaxFileSize(ImageType imageType) {
    switch (imageType) {
      case ImageType.avatar:
        return 500 * 1024; // 500KB
      case ImageType.blogThumbnail:
        return 1024 * 1024; // 1MB
      case ImageType.blogCover:
        return 2 * 1024 * 1024; // 2MB
      case ImageType.fullImage:
        return 5 * 1024 * 1024; // 5MB
    }
  }

  /// Estimate memory usage for an image
  static int estimateMemoryUsage(Size imageSize, {int bytesPerPixel = 4}) {
    return (imageSize.width * imageSize.height * bytesPerPixel).round();
  }

  /// Check if device can handle the image size in memory
  static bool canHandleImageSize(Size imageSize, {int maxMemoryMB = 50}) {
    int estimatedBytes = estimateMemoryUsage(imageSize);
    int maxBytes = maxMemoryMB * 1024 * 1024;
    return estimatedBytes <= maxBytes;
  }
}

enum ImageType {
  avatar,
  blogThumbnail,
  blogCover,
  fullImage,
}

/// Extension to get image type from context
extension ImageTypeExtension on ImageType {
  String get name {
    switch (this) {
      case ImageType.avatar:
        return 'avatar';
      case ImageType.blogThumbnail:
        return 'thumbnail';
      case ImageType.blogCover:
        return 'cover';
      case ImageType.fullImage:
        return 'full';
    }
  }
}
