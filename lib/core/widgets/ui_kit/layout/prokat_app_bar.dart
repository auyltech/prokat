import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/app_icons.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_icon_button.dart';

class ProkatAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double preferredHeight =
      AppDimens.appBarHeight + AppDimens.appBarDividerHeight;

  final Widget title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final int titleMaxLines;

  /// Drops the shadow and paints the bottom hairline in the bar color so a
  /// following AppTabs strip reads as the next line of this bar.
  final bool blendWithTabs;

  const ProkatAppBar({
    required this.title,
    this.onBack,
    this.actions = const [],
    this.titleMaxLines = 1,
    this.blendWithTabs = false,
    super.key,
  }) : assert(titleMaxLines > 0);

  @override
  Size get preferredSize => const Size.fromHeight(preferredHeight);

  @override
  Widget build(BuildContext context) {
    final hasBack = onBack != null;
    final appBarTheme = context.colors.appBar;
    final backButtonTooltip = MaterialLocalizations.of(context)
        .backButtonTooltip;

    final elevation = blendWithTabs ? 0.0 : AppDimens.appBarElevation;

    return AppBar(
      toolbarHeight: AppDimens.appBarHeight,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      backgroundColor: appBarTheme.background,
      foregroundColor: appBarTheme.content,
      shadowColor: appBarTheme.shadow,
      surfaceTintColor: appBarTheme.background,
      automaticallyImplyLeading: false,
      titleSpacing: hasBack
          ? AppDimens.appBarTitleGap
          : AppDimens.appBarTitleSpacing,
      centerTitle: false,
      leadingWidth: AppDimens.appBarLeadingWidth,
      leading: onBack == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s04$xs,
                ),
                child: AppIconButton.asset(
                  icon: AppIcons.appBarChevronLeft,
                  onTap: onBack,
                  tooltip: backButtonTooltip,
                  semanticLabel: backButtonTooltip,
                  variant: AppIconButtonVariant.plain,
                  tone: AppIconButtonTone.neutral,
                ),
              ),
            ),
      title: DefaultTextStyle.merge(
        style: AppFonts.headingL(context).copyWith(color: appBarTheme.content),
        maxLines: titleMaxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        child: title,
      ),
      actions: actions.isEmpty
          ? null
          : [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppDimens.s04$xs,
                children: actions,
              ),
            ],
      actionsPadding: actions.isEmpty
          ? null
          : const EdgeInsets.only(right: AppDimens.s16$base),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(AppDimens.appBarDividerHeight),
        child: SizedBox(
          height: AppDimens.appBarDividerHeight,
          child: ColoredBox(
            color: blendWithTabs ? appBarTheme.background : appBarTheme.divider,
          ),
        ),
      ),
    );
  }
}
