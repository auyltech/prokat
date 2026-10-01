import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

/// Category artwork + title + description.
///
/// [fallbackImage] is shown when the category has no [imageUrl].
class AppCategoryInfo extends StatelessWidget {
  static const int titleMaxLines = 2;
  static const int descriptionMaxLines = 4;

  final String title;
  final String description;
  final String? imageUrl;
  final AppImage fallbackImage;
  final double imageWidth;

  const AppCategoryInfo({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.fallbackImage,
    this.imageWidth = AppDimens.categoryInfoImageWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CategoryImage(
          width: imageWidth,
          imageUrl: imageUrl,
          fallbackImage: fallbackImage,
        ),
        const SizedBox(width: AppDimens.categoryInfoImageGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.headingM(context),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppDimens.categoryInfoTitleGap),
                Text(
                  description,
                  maxLines: descriptionMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.caption(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Height always follows the category aspect ratio so the loading
/// placeholder matches the loaded image and does not bump the layout.
class _CategoryImage extends StatelessWidget {
  final double width;
  final String? imageUrl;
  final AppImage fallbackImage;

  const _CategoryImage({
    required this.width,
    required this.imageUrl,
    required this.fallbackImage,
  });

  @override
  Widget build(BuildContext context) {
    final height = width / AppDimens.categoryInfoImageAspectRatio;
    final url = imageUrl;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.categoryInfoImageRadius),
        child: url != null && url.isNotEmpty
            ? OptimizedNetworkImage(
                imageUrl: url,
                width: width,
                height: height,
                fit: BoxFit.contain,
              )
            : fallbackImage(size: width, fit: BoxFit.contain),
      ),
    );
  }
}
