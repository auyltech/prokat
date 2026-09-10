import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

enum AppTextButtonStyle { primary, destructive }

class AppTextButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isExpanded;
  final AppTextButtonStyle style;
  final Widget? prefix;
  final Widget? postfix;

  const AppTextButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.isExpanded = true,
    this.style = AppTextButtonStyle.primary,
    this.prefix,
    this.postfix,
  });

  @override
  Widget build(BuildContext context) {
    final buttonTheme = context.colors.textButton;
    final enabled = onTap != null && !isLoading;
    final contentColor = !enabled
        ? buttonTheme.contentDisabled
        : switch (style) {
            AppTextButtonStyle.primary => buttonTheme.content,
            AppTextButtonStyle.destructive => buttonTheme.contentDestructive,
          };

    return AbsorbPointer(
      absorbing: !enabled,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: contentColor,
          minimumSize: Size(
            isExpanded ? double.infinity : 0,
            AppDimens.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16$base),
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
                  Flexible(
                    fit: isExpanded ? FlexFit.tight : FlexFit.loose,
                    child: Text(
                      title,
                      style: AppFonts.button(context)
                          .copyWith(color: contentColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ?postfix,
                ],
        ),
      ),
    );
  }
}
