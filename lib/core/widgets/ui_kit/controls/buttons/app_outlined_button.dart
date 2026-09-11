import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

class AppOutlinedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isExpanded;
  final Widget? prefix;
  final Widget? postfix;

  const AppOutlinedButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.isExpanded = true,
    this.prefix,
    this.postfix,
  });

  @override
  Widget build(BuildContext context) {
    final buttonTheme = context.colors.outlinedButton;
    final enabled = onTap != null && !isLoading;
    final contentColor = enabled
        ? buttonTheme.content
        : buttonTheme.contentDisabled;
    final borderColor = enabled
        ? buttonTheme.border
        : buttonTheme.borderDisabled;
    final borderRadius = BorderRadius.circular(AppDimens.r20$xxl);

    return Opacity(
      opacity: onTap == null ? buttonTheme.disabledOpacity : 1,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: contentColor,
            backgroundColor: buttonTheme.background,
            disabledForegroundColor: contentColor,
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16$base),
            fixedSize: const Size.fromHeight(AppDimens.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            visualDensity: const VisualDensity(
              horizontal: VisualDensity.minimumDensity,
              vertical: VisualDensity.minimumDensity,
            ),
          ),
          onPressed: enabled ? onTap : null,
          child: Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppDimens.s08$sm,
            children: isLoading
                ? [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: contentColor,
                      ),
                    ),
                  ]
                : [
                    ?prefix,
                    if (isExpanded)
                      Flexible(
                        child: Text(
                          title,
                          style: AppFonts.button(context)
                              .copyWith(color: contentColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Text(
                        title,
                        style: AppFonts.button(context)
                            .copyWith(color: contentColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ?postfix,
                  ],
          ),
        ),
      ),
    );
  }
}
