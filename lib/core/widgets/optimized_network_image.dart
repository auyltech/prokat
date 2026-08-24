import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final int? maxCacheWidth;
  final int? maxCacheHeight;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.backgroundColor,
    this.maxCacheWidth,
    this.maxCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final child = LayoutBuilder(
      builder: (context, constraints) {
        final cacheSize = _cacheSize(context, constraints);

        if (url.isEmpty) {
          return _ErrorImage(
            icon: fallbackIcon,
            backgroundColor: backgroundColor,
          );
        }

        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: cacheSize.width,
          memCacheHeight: cacheSize.height,
          placeholder: (context, _) =>
              _ImageShimmer(backgroundColor: backgroundColor),
          errorWidget: (context, _, _) =>
              _ErrorImage(icon: fallbackIcon, backgroundColor: backgroundColor),
        );
      },
    );

    if (width == null && height == null) {
      return child;
    }

    return SizedBox(width: width, height: height, child: child);
  }

  ({int? width, int? height}) _cacheSize(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    final widthPx = _toCachePixels(
      _logicalSize(explicitSize: width, constrainedSize: constraints.maxWidth),
      pixelRatio,
      maxCacheWidth,
    );
    final heightPx = _toCachePixels(
      _logicalSize(
        explicitSize: height,
        constrainedSize: constraints.maxHeight,
      ),
      pixelRatio,
      maxCacheHeight,
    );

    // ResizeImage (memCacheWidth/Height) defaults to ResizeImagePolicy.exact.
    // Both dimensions decode like BoxFit.fill and stretch the bitmap before
    // [fit] is applied, so cover/contain cannot restore the aspect ratio.
    if (widthPx != null && heightPx != null) {
      if (widthPx >= heightPx) {
        return (width: widthPx, height: null);
      }
      return (width: null, height: heightPx);
    }

    return (width: widthPx, height: heightPx);
  }

  double? _logicalSize({
    required double? explicitSize,
    required double constrainedSize,
  }) {
    if (explicitSize != null && explicitSize.isFinite && explicitSize > 0) {
      return explicitSize;
    }
    if (constrainedSize.isFinite && constrainedSize > 0) {
      return constrainedSize;
    }
    return null;
  }

  int? _toCachePixels(double? logicalSize, double pixelRatio, int? maxPixels) {
    if (logicalSize == null) return maxPixels;

    final pixels = (logicalSize * pixelRatio).round();
    if (maxPixels == null) return pixels;

    return pixels.clamp(1, maxPixels).toInt();
  }
}

class _ImageShimmer extends StatelessWidget {
  final Color? backgroundColor;

  const _ImageShimmer({this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = backgroundColor ?? colorScheme.surfaceContainerHighest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: colorScheme.surface.withValues(alpha: 0.65),
      child: Container(color: baseColor),
    );
  }
}

class _ErrorImage extends StatelessWidget {
  final IconData icon;
  final Color? backgroundColor;

  const _ErrorImage({required this.icon, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: backgroundColor ?? colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
        size: 100,
      ),
    );
  }
}
