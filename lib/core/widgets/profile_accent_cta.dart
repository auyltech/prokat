import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/overlay_badge_icon.dart';

/// Full-bleed profile CTA. All role-switch cards share this layout.
class ProfileAccentCta extends StatelessWidget {
  static const double horizontalPadding = 20;
  static const double verticalPadding = 24;
  static const double iconSize = 40;
  static const double inkRadius = 16;

  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color backgroundColor;
  final Color contentColor;
  final IconData trailingIcon;

  const ProfileAccentCta({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.isLoading = false,
    this.backgroundColor = AppTheme.accent,
    this.contentColor = AppTheme.white,
    this.trailingIcon = LucideIcons.chevronRight,
  });

  static Widget truck({Color color = AppTheme.white}) {
    return SizedBox.square(
      dimension: iconSize + 4,
      child: Center(
        child: Icon(LucideIcons.truck, color: color, size: iconSize * .88),
      ),
    );
  }

  static Widget truckPlus({
    Color color = AppTheme.white,
    Color badgeColor = AppTheme.accent,
  }) {
    return OverlayBadgeIcon(
      icon: LucideIcons.truck,
      badge: LucideIcons.plus,
      color: color,
      badgeColor: badgeColor,
      badgeBackground: Colors.white,
      size: iconSize,
    );
  }

  static Widget truckSearch({
    Color color = AppTheme.white,
    Color badgeColor = AppTheme.accent,
  }) {
    return OverlayBadgeIcon(
      icon: LucideIcons.truck,
      badge: LucideIcons.search,
      color: color,
      badgeColor: badgeColor,
      badgeBackground: Colors.white,
      size: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor = contentColor.withValues(alpha: 0.8);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(inkRadius),
      child: Container(
        height: 184 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: contentColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      height: 1.35,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contentColor,
                ),
              )
            else
              Icon(trailingIcon, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
