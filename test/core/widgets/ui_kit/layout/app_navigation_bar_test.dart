import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

const _items = <AppNavigationBarItem>[
  AppNavigationBarItem(icon: Icons.home_outlined, label: 'Home'),
  AppNavigationBarItem(icon: Icons.person_outline, label: 'Profile'),
];

Widget _wrap({
  required ThemeData theme,
  int currentIndex = 0,
  AppNavigationBarTone tone = AppNavigationBarTone.primary,
  ValueChanged<int>? onItemTap,
}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      bottomNavigationBar: AppNavigationBar(
        items: _items,
        currentIndex: currentIndex,
        tone: tone,
        onItemTap: onItemTap ?? (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('renders items with tokenized dimensions and colors', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(theme: AppTheme.lightTheme));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byType(InkWell), findsNWidgets(_items.length));

    final barSize = tester.getSize(find.byType(Row));
    expect(barSize.height, AppDimens.navigationBarHeight);

    final colors = AppTheme.lightTheme.extension<AppColorsTheme>()!;
    final selectedIcon = tester.widget<Icon>(find.byIcon(Icons.home_outlined));
    final unselectedIcon = tester.widget<Icon>(
      find.byIcon(Icons.person_outline),
    );
    expect(selectedIcon.color, colors.navigationBar.selected);
    expect(selectedIcon.shadows, hasLength(2));
    expect(unselectedIcon.color, colors.navigationBar.unselected);
    expect(unselectedIcon.shadows, isNull);

    final selectedLabel = tester.widget<Text>(find.text('Home'));
    final unselectedLabel = tester.widget<Text>(find.text('Profile'));
    expect(selectedLabel.style?.shadows, hasLength(2));
    expect(unselectedLabel.style?.shadows, isNull);
  });

  testWidgets('uses owner colors and calls the selected item callback', (
    tester,
  ) async {
    int? tappedIndex;
    await tester.pumpWidget(
      _wrap(
        theme: AppTheme.darkTheme,
        currentIndex: 1,
        tone: AppNavigationBarTone.owner,
        onItemTap: (index) => tappedIndex = index,
      ),
    );

    final colors = AppTheme.darkTheme.extension<AppColorsTheme>()!;
    final selectedIcon = tester.widget<Icon>(find.byIcon(Icons.person_outline));
    final selectedInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.person_outline),
        matching: find.byType(InkWell),
      ),
    );
    expect(selectedIcon.color, colors.navigationBar.ownerSelected);
    expect(selectedInkWell.splashColor, colors.navigationBar.ownerSplash);
    expect(selectedInkWell.highlightColor, colors.navigationBar.ownerHighlight);

    await tester.tap(find.text('Profile'));
    expect(tappedIndex, 1);
  });
}
