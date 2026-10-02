import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

/// Tab strip plus swipeable pages.
///
/// The strip uses the app bar background and title style so it reads as the
/// next line of the app bar when it sits directly under it.
class AppTabs extends StatefulWidget {
  final List<String> titles;
  final List<Widget> children;
  final ValueChanged<int>? onChanged;
  final int initialIndex;

  AppTabs({
    super.key,
    required this.titles,
    required this.children,
    this.onChanged,
    this.initialIndex = 0,
  }) : assert(
         titles.length == children.length,
         'AppTabs titles and children must have the same length',
       ),
       assert(titles.isNotEmpty, 'AppTabs needs at least one tab'),
       assert(
         initialIndex >= 0 && initialIndex < titles.length,
         'AppTabs initialIndex is out of range',
       );

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;
  late int _settledIndex;

  @override
  void initState() {
    super.initState();
    _settledIndex = widget.initialIndex;
    _controller = TabController(
      length: widget.titles.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    )..addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant AppTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.titles.length != widget.titles.length) {
      _controller.removeListener(_onTick);
      _controller.dispose();
      _settledIndex = widget.initialIndex;
      _controller = TabController(
        length: widget.titles.length,
        vsync: this,
        initialIndex: widget.initialIndex,
      )..addListener(_onTick);
      return;
    }
    // A screen kept alive by the shell can be asked to open another tab.
    if (oldWidget.initialIndex != widget.initialIndex &&
        widget.initialIndex != _controller.index) {
      _settledIndex = widget.initialIndex;
      _controller.index = widget.initialIndex;
    }
  }

  void _onTick() {
    if (_controller.indexIsChanging) return;
    if (_controller.index == _settledIndex) return;
    _settledIndex = _controller.index;
    widget.onChanged?.call(_settledIndex);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = context.colors.appBar;
    final tabStyle = AppFonts.headingM(context);
    const stripHeight =
        AppDimens.appTabsHeight +
        AppDimens.appTabsIndicatorWeight +
        AppDimens.cardBorderWidth;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: stripHeight),
          child: TabBarView(controller: _controller, children: widget.children),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: appBar.background,
            surfaceTintColor: appBar.background,
            shadowColor: appBar.shadow,
            elevation: AppDimens.appBarElevation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  controller: _controller,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: AppDimens.appTabsIndicatorWeight,
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      width: AppDimens.appTabsIndicatorWeight,
                      color: context.colors.icons.primary,
                    ),
                  ),
                  dividerHeight: 0,
                  overlayColor: context.colors.ripple.overlay,
                  labelStyle: tabStyle,
                  unselectedLabelStyle: tabStyle,
                  labelColor: appBar.content,
                  unselectedLabelColor: context.colors.text.disabled,
                  tabs: [
                    for (final title in widget.titles)
                      Tab(text: title, height: AppDimens.appTabsHeight),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
