import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableMemoryCache;
  final int? maxCacheHeight;
  final int? maxCacheWidth;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    this.enableMemoryCache = true,
    this.maxCacheHeight = 1000,
    this.maxCacheWidth = 1000,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(75),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Theme.of(context).colorScheme.primary.withAlpha(175)
          ),
        ),
      ),
    );

    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: backgroundColor ?? Theme.of(context).colorScheme.errorContainer.withAlpha(50),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 24,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return defaultErrorWidget;
    }

    final imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) => errorWidget ?? defaultErrorWidget,
      fadeOutDuration: const Duration(milliseconds: 200),
      fadeInDuration: const Duration(milliseconds: 300),
      // Memory optimization
      memCacheHeight: enableMemoryCache && height != null ? height!.round() : null,
      memCacheWidth: enableMemoryCache && width != null ? width!.round() : null,
      maxHeightDiskCache: maxCacheHeight,
      maxWidthDiskCache: maxCacheWidth,
    );

    // If border radius is provided, wrap in ClipRRect
    return borderRadius != null
        ? ClipRRect(
            borderRadius: borderRadius!,
            child: imageWidget,
          )
        : imageWidget;
  }
}

// Optimized avatar widget
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? fallback;
  final String? name;
  final Color? backgroundColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallback,
    this.name,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: ClipOval(
        child: CachedImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          enableMemoryCache: true,
          maxCacheHeight: 200, // Smaller cache for avatars
          maxCacheWidth: 200,
          errorWidget: _buildFallback(context),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallback != null) return fallback!;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      child: Text(
        name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
