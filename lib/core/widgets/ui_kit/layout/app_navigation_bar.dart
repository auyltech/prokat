import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

enum AppNavigationBarTone { primary, owner }

final class AppNavigationBarItem {
  final IconData icon;
  final String label;

  const AppNavigationBarItem({required this.icon, required this.label});
}

class AppNavigationBar extends StatelessWidget {
  final List<AppNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final AppNavigationBarTone tone;

  const AppNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onItemTap,
    this.tone = AppNavigationBarTone.primary,
    super.key,
  }) : assert(items.length > 0),
       assert(currentIndex >= 0),
       assert(currentIndex < items.length);

  @override
  Widget build(BuildContext context) {
    final navigationBarTheme = context.colors.navigationBar;
    final selectedColor = switch (tone) {
      AppNavigationBarTone.primary => navigationBarTheme.selected,
      AppNavigationBarTone.owner => navigationBarTheme.ownerSelected,
    };
    final (splashColor, highlightColor) = switch (tone) {
      AppNavigationBarTone.primary => (
        navigationBarTheme.splash,
        navigationBarTheme.highlight,
      ),
      AppNavigationBarTone.owner => (
        navigationBarTheme.ownerSplash,
        navigationBarTheme.ownerHighlight,
      ),
    };

    return Material(
      color: navigationBarTheme.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: navigationBarTheme.divider,
              width: AppDimens.navigationBarDividerHeight,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimens.navigationBarHeight,
            child: Row(
              children: [
                for (final (index, item) in items.indexed)
                  Expanded(
                    child: _NavigationBarItem(
                      item: item,
                      isSelected: index == currentIndex,
                      selectedColor: selectedColor,
                      unselectedColor: navigationBarTheme.unselected,
                      splashColor: splashColor,
                      highlightColor: highlightColor,
                      onTap: () => onItemTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBarItem extends StatelessWidget {
  final AppNavigationBarItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color splashColor;
  final Color highlightColor;
  final VoidCallback onTap;

  const _NavigationBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.splashColor,
    required this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = isSelected ? selectedColor : unselectedColor;
    final glowShadows = isSelected
        ? <Shadow>[
            Shadow(
              color: contentColor.withValues(alpha: 0.7),
              blurRadius: AppDimens.s16$base,
            ),
            Shadow(
              color: contentColor.withValues(alpha: 0.5),
              blurRadius: AppDimens.s32$xxl,
            ),
          ]
        : null;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: SizedBox.expand(
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: AppDimens.navigationBarIconSize,
                  color: contentColor,
                  shadows: glowShadows,
                ),
                const SizedBox(height: AppDimens.s04$xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.s04$xs,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: AppFonts.captionMedium(context).copyWith(
                      color: contentColor,
                      height: 1.1,
                      shadows: glowShadows,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
