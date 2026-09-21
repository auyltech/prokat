import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/colors/component_themes/app_button_tone_theme.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

enum AppLabelButtonVariant { filled, outlined, soft, text }

enum AppLabelButtonTone { neutral, primary, success, destructive, inverse }

class AppLabelButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? prefix;
  final Widget? postfix;
  final AppLabelButtonVariant variant;
  final AppLabelButtonTone tone;

  const AppLabelButton({
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.prefix,
    this.postfix,
    this.variant = AppLabelButtonVariant.filled,
    this.tone = AppLabelButtonTone.primary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buttonTheme = context.colors.labelButton;
    final toneTheme = switch (tone) {
      AppLabelButtonTone.neutral => buttonTheme.neutral,
      AppLabelButtonTone.primary => buttonTheme.primary,
      AppLabelButtonTone.success => buttonTheme.success,
      AppLabelButtonTone.destructive => buttonTheme.destructive,
      AppLabelButtonTone.inverse => buttonTheme.inverse,
    };
    final enabled = onTap != null && !isLoading;
    final visuallyDisabled = onTap == null && !isLoading;
    final colors = _resolveColors(
      toneTheme: toneTheme,
      enabled: !visuallyDisabled,
      contentDisabled: buttonTheme.contentDisabled,
      backgroundDisabled: buttonTheme.backgroundDisabled,
      borderDisabled: buttonTheme.borderDisabled,
    );
    const borderRadius = BorderRadius.all(Radius.circular(AppDimens.r999$full));

    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: Opacity(
        opacity: visuallyDisabled ? buttonTheme.disabledOpacity : 1,
        child: Material(
          color: colors.background,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: colors.border == null
                ? BorderSide.none
                : BorderSide(
                    color: colors.border!,
                    width: AppDimens.buttonBorderWidth,
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: borderRadius,
            child: SizedBox(
              height: AppDimens.compactButtonHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s12$md,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: colors.content,
                    size: AppDimens.s20$lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: AppDimens.s08$sm,
                    children: [
                      if (isLoading)
                        SizedBox.square(
                          dimension: AppDimens.buttonLoadingIndicatorSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.content,
                          ),
                        )
                      else
                        ?prefix,
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppFonts.button(context)
                              .copyWith(color: colors.content),
                        ),
                      ),
                      if (!isLoading) ?postfix,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AppLabelButtonColors _resolveColors({
    required AppButtonToneTheme toneTheme,
    required bool enabled,
    required Color contentDisabled,
    required Color backgroundDisabled,
    required Color borderDisabled,
  }) {
    if (!enabled) {
      return _AppLabelButtonColors(
        content: contentDisabled,
        background: switch (variant) {
          AppLabelButtonVariant.filled ||
          AppLabelButtonVariant.soft => backgroundDisabled,
          AppLabelButtonVariant.outlined ||
          AppLabelButtonVariant.text => Colors.transparent,
        },
        border: variant == AppLabelButtonVariant.outlined
            ? borderDisabled
            : null,
      );
    }

    return switch (variant) {
      AppLabelButtonVariant.filled => _AppLabelButtonColors(
        content: toneTheme.contentOnFill,
        background: toneTheme.fill,
      ),
      AppLabelButtonVariant.outlined => _AppLabelButtonColors(
        content: toneTheme.content,
        background: Colors.transparent,
        border: toneTheme.border,
      ),
      AppLabelButtonVariant.soft => _AppLabelButtonColors(
        content: toneTheme.content,
        background: toneTheme.softFill,
      ),
      AppLabelButtonVariant.text => _AppLabelButtonColors(
        content: toneTheme.content,
        background: Colors.transparent,
      ),
    };
  }
}

final class _AppLabelButtonColors {
  final Color content;
  final Color background;
  final Color? border;

  const _AppLabelButtonColors({
    required this.content,
    required this.background,
    this.border,
  });
}
