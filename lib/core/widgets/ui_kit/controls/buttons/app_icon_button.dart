import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/colors/component_themes/app_button_tone_theme.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/widgets/ui_kit/app_icon.dart';

enum AppIconButtonVariant { plain, soft, outlined, filled, floating }

enum AppIconButtonTone {
  neutral,
  primary,
  success,
  warning,
  destructive,
  inverse,
}

enum AppIconButtonSize { regular, large }

enum AppIconButtonShape { circle, rounded }

class AppIconButton extends StatelessWidget {
  final IconData? _iconData;
  final AppIcon? _assetIcon;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? tooltip;
  final String? semanticLabel;
  final AppIconButtonVariant variant;
  final AppIconButtonTone tone;
  final AppIconButtonSize size;
  final AppIconButtonShape shape;

  const AppIconButton({
    required IconData icon,
    required this.onTap,
    this.isLoading = false,
    this.tooltip,
    this.semanticLabel,
    this.variant = AppIconButtonVariant.plain,
    this.tone = AppIconButtonTone.neutral,
    this.size = AppIconButtonSize.regular,
    this.shape = AppIconButtonShape.circle,
    super.key,
  }) : _iconData = icon,
       _assetIcon = null;

  const AppIconButton.asset({
    required AppIcon icon,
    required this.onTap,
    this.isLoading = false,
    this.tooltip,
    this.semanticLabel,
    this.variant = AppIconButtonVariant.plain,
    this.tone = AppIconButtonTone.neutral,
    this.size = AppIconButtonSize.regular,
    this.shape = AppIconButtonShape.circle,
    super.key,
  }) : _assetIcon = icon,
       _iconData = null;

  @override
  Widget build(BuildContext context) {
    final buttonTheme = context.colors.iconButton;
    final toneTheme = switch (tone) {
      AppIconButtonTone.neutral => buttonTheme.neutral,
      AppIconButtonTone.primary => buttonTheme.primary,
      AppIconButtonTone.success => buttonTheme.success,
      AppIconButtonTone.warning => buttonTheme.warning,
      AppIconButtonTone.destructive => buttonTheme.destructive,
      AppIconButtonTone.inverse => buttonTheme.inverse,
    };
    final enabled = onTap != null && !isLoading;
    final visuallyDisabled = onTap == null && !isLoading;
    final dimension = switch (size) {
      AppIconButtonSize.regular => AppDimens.iconButtonSize,
      AppIconButtonSize.large => AppDimens.iconButtonLargeSize,
    };
    final colors = _resolveColors(
      toneTheme: toneTheme,
      enabled: !visuallyDisabled,
      contentDisabled: buttonTheme.contentDisabled,
      backgroundDisabled: buttonTheme.backgroundDisabled,
      borderDisabled: buttonTheme.borderDisabled,
    );
    final borderSide = colors.border == null
        ? BorderSide.none
        : BorderSide(color: colors.border!, width: AppDimens.buttonBorderWidth);
    final buttonShape = switch (shape) {
      AppIconButtonShape.circle => CircleBorder(side: borderSide),
      AppIconButtonShape.rounded => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.r16$xl),
        side: borderSide,
      ),
    };

    Widget result = Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? tooltip,
      child: Opacity(
        opacity: visuallyDisabled ? buttonTheme.disabledOpacity : 1,
        child: Material(
          color: colors.background,
          elevation: variant == AppIconButtonVariant.floating
              ? AppDimens.s04$xs
              : 0,
          shadowColor: context.colors.barrierColor,
          shape: buttonShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: buttonShape,
            child: SizedBox.square(
              dimension: dimension,
              child: Center(
                child: isLoading
                    ? SizedBox.square(
                        dimension: AppDimens.buttonLoadingIndicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.content,
                        ),
                      )
                    : ExcludeSemantics(child: _buildIcon(colors.content)),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip case final tooltip? when tooltip.isNotEmpty) {
      result = Tooltip(message: tooltip, child: result);
    }
    return result;
  }

  Widget _buildIcon(Color color) {
    final assetIcon = _assetIcon;
    if (assetIcon != null) {
      return assetIcon.call(color: color, size: AppDimens.iconButtonIconSize);
    }
    return Icon(_iconData, color: color, size: AppDimens.iconButtonIconSize);
  }

  _AppIconButtonColors _resolveColors({
    required AppButtonToneTheme toneTheme,
    required bool enabled,
    required Color contentDisabled,
    required Color backgroundDisabled,
    required Color borderDisabled,
  }) {
    if (!enabled) {
      return _AppIconButtonColors(
        content: contentDisabled,
        background: switch (variant) {
          AppIconButtonVariant.soft ||
          AppIconButtonVariant.filled ||
          AppIconButtonVariant.floating => backgroundDisabled,
          AppIconButtonVariant.plain ||
          AppIconButtonVariant.outlined => Colors.transparent,
        },
        border: variant == AppIconButtonVariant.outlined
            ? borderDisabled
            : null,
      );
    }

    return switch (variant) {
      AppIconButtonVariant.plain => _AppIconButtonColors(
        content: toneTheme.content,
        background: Colors.transparent,
      ),
      AppIconButtonVariant.soft => _AppIconButtonColors(
        content: toneTheme.content,
        background: toneTheme.softFill,
      ),
      AppIconButtonVariant.outlined => _AppIconButtonColors(
        content: toneTheme.content,
        background: Colors.transparent,
        border: toneTheme.border,
      ),
      AppIconButtonVariant.filled ||
      AppIconButtonVariant.floating => _AppIconButtonColors(
        content: toneTheme.contentOnFill,
        background: toneTheme.fill,
      ),
    };
  }
}

final class _AppIconButtonColors {
  final Color content;
  final Color background;
  final Color? border;

  const _AppIconButtonColors({
    required this.content,
    required this.background,
    this.border,
  });
}
