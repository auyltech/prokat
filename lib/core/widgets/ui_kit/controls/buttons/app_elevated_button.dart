import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

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
    final flow = ProkatFlowScope.maybeOf(context);
    final buttonTheme = colors.elevatedButton;
    final enabled = onTap != null && !isLoading;
    final contentColor = buttonTheme.content;
    final background = switch (style) {
      AppElevatedButtonStyle.primary =>
        flow?.filledPrimary ?? buttonTheme.background,
      AppElevatedButtonStyle.destructive => buttonTheme.destructiveBackground,
    };
    final borderRadius = BorderRadius.circular(
      flow == null ? AppDimens.r12$lg : AppDimens.r16$xl,
    );

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
              child: Container(
                height: flow == null ? AppDimens.buttonHeight : null,
                constraints: flow == null
                    ? null
                    : const BoxConstraints(minHeight: AppDimens.buttonHeight),
                width: isExpanded ? double.infinity : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.s16$base,
                    vertical: flow == null ? 0 : 12,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: contentColor,
                      size: AppDimens.s20$lg,
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
                              if (isExpanded || flow != null)
                                Flexible(
                                  child: Text(
                                    title,
                                    style: AppFonts.button(context)
                                        .copyWith(color: contentColor),
                                    maxLines: flow == null ? 1 : null,
                                    overflow: flow == null
                                        ? TextOverflow.ellipsis
                                        : TextOverflow.visible,
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
      ),
    );
  }
}
