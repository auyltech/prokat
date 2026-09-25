import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/app_images.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

abstract final class EquipmentShareCardMetrics {
  static const double width = 1080;
  static const double height = 1350;
  static const double photoHeight = 760;
  static const double padding = 64;
  static const double logoSize = 88;
  static const double nameSize = 64;
  static const double bodySize = 36;
  static const double priceSize = 48;
  static const double ctaSize = 40;
}

class EquipmentShareCard extends StatelessWidget {
  final String name;
  final String? description;
  final String priceLine;
  final String cta;
  final ImageProvider<Object>? cover;

  const EquipmentShareCard({
    super.key,
    required this.name,
    required this.description,
    required this.priceLine,
    required this.cta,
    required this.cover,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final descriptionText = description;

    return DefaultTextStyle(
      style: _capturedTextStyle(AppFonts.body16(context)),
      child: Material(
        color: colors.background.main,
        child: SizedBox(
          width: EquipmentShareCardMetrics.width,
          height: EquipmentShareCardMetrics.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: EquipmentShareCardMetrics.photoHeight,
                child: _Cover(cover: cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    EquipmentShareCardMetrics.padding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppImages.appLogo(
                        size: EquipmentShareCardMetrics.logoSize,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _capturedTextStyle(
                          AppFonts.headingL(context).copyWith(
                            fontSize: EquipmentShareCardMetrics.nameSize,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (descriptionText != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          descriptionText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: _capturedTextStyle(
                            AppFonts.body16(context).copyWith(
                              fontSize: EquipmentShareCardMetrics.bodySize,
                              color: colors.text.secondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        priceLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _capturedTextStyle(
                          AppFonts.price(context).copyWith(
                            fontSize: EquipmentShareCardMetrics.priceSize,
                            color: colors.text.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.elevatedButton.background,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 22,
                          ),
                          child: Text(
                            cta,
                            style: _capturedTextStyle(
                              AppFonts.button(context).copyWith(
                                fontSize: EquipmentShareCardMetrics.ctaSize,
                                color: colors.elevatedButton.content,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay capture sits outside [Material], so plain [Text] inherits Flutter's
/// missing-style fallback (yellow underline). `inherit: false` drops it.
TextStyle _capturedTextStyle(TextStyle style) {
  return style.copyWith(inherit: false, decoration: TextDecoration.none);
}

class _Cover extends StatelessWidget {
  final ImageProvider<Object>? cover;

  const _Cover({required this.cover});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image = cover;
    if (image == null) {
      return _placeholder(colors.background.secondaryCard, colors.icons.main);
    }

    return Image(
      image: image,
      fit: BoxFit.cover,
      width: EquipmentShareCardMetrics.width,
      height: EquipmentShareCardMetrics.photoHeight,
      errorBuilder: (_, _, _) =>
          _placeholder(colors.background.secondaryCard, colors.icons.main),
    );
  }

  Widget _placeholder(Color background, Color iconColor) {
    return ColoredBox(
      color: background,
      child: Center(
        child: Icon(
          Icons.precision_manufacturing_outlined,
          size: 160,
          color: iconColor,
        ),
      ),
    );
  }
}
