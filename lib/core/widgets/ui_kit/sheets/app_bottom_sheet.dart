import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool useRootNavigator = false,
    required WidgetBuilder contentBuilder,
  }) {
    final colors = context.colors;

    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      barrierColor: colors.barrierColor,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheetBarrier(
        child: AppBottomSheetLayout(
          title: title,
          subtitle: subtitle,
          contentBuilder: contentBuilder,
        ),
      ),
    );
  }

  static Future<T?> showScrollable<T>(
    BuildContext context, {
    required String title,
    double minChildSize = 0.4,
    double maxChildSize = 0.85,
    double initialChildSize = 0.6,
    required WidgetBuilder headerBuilder,
    required Widget Function(BuildContext context, ScrollController controller)
    scrollableListBuilder,
    required WidgetBuilder footerBuilder,
  }) {
    final colors = context.colors;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      barrierColor: colors.barrierColor,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheetBarrier(
        child: AppScrollableBottomSheet(
          title: title,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          initialChildSize: initialChildSize,
          headerBuilder: headerBuilder,
          scrollableListBuilder: scrollableListBuilder,
          footerBuilder: footerBuilder,
        ),
      ),
    );
  }
}

class AppBottomSheetBarrier extends StatelessWidget {
  final Widget child;

  const AppBottomSheetBarrier({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: colors.barrierBlurSigma,
              sigmaY: colors.barrierBlurSigma,
            ),
            child: const SizedBox.expand(),
          ),
          GestureDetector(onTap: () {}, child: child),
        ],
      ),
    );
  }
}

class AppBottomSheetFrame extends StatelessWidget {
  final Widget child;

  const AppBottomSheetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background.elevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.sheetTopRadius),
        ),
        boxShadow: colors.dialogShadows,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Align(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.borders.main,
          borderRadius: BorderRadius.circular(AppDimens.sheetHandleRadius),
        ),
        child: const SizedBox(
          width: AppDimens.sheetHandleWidth,
          height: AppDimens.sheetHandleHeight,
        ),
      ),
    );
  }
}

class AppBottomSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppBottomSheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.sheetHandleToTitleGap,
      children: [
        const AppBottomSheetHandle(),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDimens.sheetTitleToSubtitleGap,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.headingM(context),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppFonts.caption(context),
              ),
          ],
        ),
      ],
    );
  }
}

class AppBottomSheetLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final WidgetBuilder contentBuilder;

  const AppBottomSheetLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    final bottomSafeRemainder = bottomSafeInset <= keyboardInset
        ? 0.0
        : bottomSafeInset - keyboardInset;

    return AppBottomSheetFrame(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.sheetHorizontalPadding,
          AppDimens.sheetTopPadding,
          AppDimens.sheetHorizontalPadding,
          AppDimens.sheetBottomPadding + bottomSafeRemainder + keyboardInset,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppDimens.sheetTitleToContentGap,
            children: [
              AppBottomSheetHeader(title: title, subtitle: subtitle),
              contentBuilder(context),
            ],
          ),
        ),
      ),
    );
  }
}

class AppScrollableBottomSheet extends StatelessWidget {
  final String title;
  final double minChildSize;
  final double maxChildSize;
  final double initialChildSize;
  final WidgetBuilder headerBuilder;
  final Widget Function(BuildContext context, ScrollController controller)
  scrollableListBuilder;
  final WidgetBuilder footerBuilder;

  const AppScrollableBottomSheet({
    super.key,
    required this.title,
    required this.minChildSize,
    required this.maxChildSize,
    required this.initialChildSize,
    required this.headerBuilder,
    required this.scrollableListBuilder,
    required this.footerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      initialChildSize: initialChildSize,
      snap: true,
      builder: (context, scrollController) {
        return AppBottomSheetFrame(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.sheetHorizontalPadding,
                  AppDimens.sheetTopPadding,
                  AppDimens.sheetHorizontalPadding,
                  AppDimens.sheetTitleToContentGap,
                ),
                child: AppBottomSheetHeader(title: title),
              ),
              headerBuilder(context),
              Expanded(child: scrollableListBuilder(context, scrollController)),
              footerBuilder(context),
            ],
          ),
        );
      },
    );
  }
}
