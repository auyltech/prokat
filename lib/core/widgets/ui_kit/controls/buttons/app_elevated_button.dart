import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

enum AppElevatedButtonStyle { primary, destructive }

class AppElevatedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isExpanded;
  final AppElevatedButtonStyle style;
  final Widget? prefix;
  final Widget? postfix;

  const AppElevatedButton({
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.isExpanded = true,
    this.style = AppElevatedButtonStyle.primary,
    this.prefix,
    this.postfix,
    super.key,
  });

  const AppElevatedButton.destructive({
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.isExpanded = true,
    this.prefix,
    this.postfix,
    super.key,
  }) : style = AppElevatedButtonStyle.destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buttonTheme = colors.elevatedButton;
    final enabled = onTap != null && !isLoading;
    final contentColor = buttonTheme.content;
    final background = switch (style) {
      AppElevatedButtonStyle.primary => buttonTheme.background,
      AppElevatedButtonStyle.destructive => buttonTheme.destructiveBackground,
    };
    final borderRadius = BorderRadius.circular(AppDimens.r10$base);

    return Opacity(
      opacity: onTap == null ? buttonTheme.disabledOpacity : 1,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: borderRadius,
              child: SizedBox(
                height: AppDimens.buttonHeight,
                width: isExpanded ? double.infinity : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.s16$base,
                  ),
                  child: Row(
                    mainAxisSize: isExpanded
                        ? MainAxisSize.max
                        : MainAxisSize.min,
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
            ),
          ),
        ),
      ),
    );
  }
}
