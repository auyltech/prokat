import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

Widget _wrap(ProkatAppBar appBar, ThemeData theme) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(appBar: appBar, body: const SizedBox.shrink()),
  );
}

double _contrastRatio(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('preferred height includes toolbar and divider', () {
    const appBar = ProkatAppBar(title: Text('Title'));

    expect(appBar.preferredSize.height, 57);
    expect(
      appBar.preferredSize.height,
      AppDimens.appBarHeight + AppDimens.appBarDividerHeight,
    );
  });

  testWidgets('does not render a back button without a callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ProkatAppBar(title: Text('Title')), AppTheme.lightTheme),
    );

    expect(find.byType(AppIconButton), findsNothing);
  });

  testWidgets('renders a neutral plain back button and invokes callback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        ProkatAppBar(title: const Text('Title'), onBack: () => taps++),
        AppTheme.lightTheme,
      ),
    );

    final button = tester.widget<AppIconButton>(find.byType(AppIconButton));
    expect(button.tone, AppIconButtonTone.neutral);
    expect(button.variant, AppIconButtonVariant.plain);

    await tester.tap(find.byType(AppIconButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('uses the light component theme', (tester) async {
    final colors = AppTheme.lightTheme.extension<AppColorsTheme>()!;
    await tester.pumpWidget(
      _wrap(const ProkatAppBar(title: Text('Title')), AppTheme.lightTheme),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, colors.appBar.background);
    expect(appBar.foregroundColor, colors.appBar.content);
    expect(appBar.shadowColor, colors.appBar.shadow);
    expect(appBar.elevation, AppDimens.appBarElevation);
    expect(appBar.scrolledUnderElevation, AppDimens.appBarElevation);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == colors.appBar.divider,
        ),
      ),
      findsOneWidget,
    );
  });

  test('back icon has sufficient contrast in light and dark themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final colors = theme.extension<AppColorsTheme>()!;
      final ratio = _contrastRatio(
        colors.iconButton.neutral.content,
        colors.appBar.background,
      );

      expect(ratio, greaterThanOrEqualTo(3));
    }
  });

  testWidgets('long and multiline titles do not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        ProkatAppBar(
          title: const Text(
            'A very long application bar title that cannot fit on one line',
          ),
          titleMaxLines: 2,
          actions: [
            AppIconButton(icon: Icons.add, onTap: () {}),
            AppIconButton(icon: Icons.history, onTap: () {}),
          ],
        ),
        AppTheme.darkTheme,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppIconButton), findsNWidgets(2));
  });

  testWidgets('places title next to the back button', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProkatAppBar(title: const Text('Title'), onBack: () {}),
        AppTheme.lightTheme,
      ),
    );

    expect(
      tester.getTopLeft(find.text('Title')).dx,
      AppDimens.appBarLeadingWidth + AppDimens.appBarTitleGap,
    );
    expect(
      tester.getSize(find.byType(AppIconButton)),
      const Size(AppDimens.iconButtonSize, AppDimens.iconButtonSize),
    );
  });

  testWidgets('keeps title inset on root screens without a back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ProkatAppBar(title: Text('Title')), AppTheme.lightTheme),
    );

    expect(
      tester.getTopLeft(find.text('Title')).dx,
      AppDimens.appBarTitleSpacing,
    );
  });
}
