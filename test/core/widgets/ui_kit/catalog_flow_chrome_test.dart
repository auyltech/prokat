import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

void main() {
  testWidgets('catalog chrome retains tab state when the route scope changes', (
    tester,
  ) async {
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    int changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, active, _) => ProkatFlowScope(
            enabled: active,
            palette: ProkatFlowPalette.light,
            child: Theme(
              data: Theme.of(context),
              child: Scaffold(
                body: AppTabs(
                  titles: const ['Техника', 'Оборудование'],
                  children: const [
                    Text('machinery-page'),
                    Text('equipment-page'),
                  ],
                  onChanged: (_) => changes++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Оборудование'));
    await tester.pumpAndSettle();
    expect(find.text('equipment-page'), findsOneWidget);
    for (final active in [false, true]) {
      enabled.value = active;
      await tester.pumpAndSettle();
      expect(find.text('equipment-page'), findsOneWidget);
    }
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog navigation remains usable at 320px and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ProkatFlowScope(
            palette: ProkatFlowPalette.light,
            child: Scaffold(
              appBar: const ProkatAppBar(title: Text('Каталог')),
              bottomNavigationBar: AppNavigationBar(
                items: const [
                  AppNavigationBarItem(icon: Icons.person, label: 'Профиль'),
                  AppNavigationBarItem(icon: Icons.search, label: 'Каталог'),
                  AppNavigationBarItem(
                    icon: Icons.campaign,
                    label: 'Сұраныстар',
                  ),
                  AppNavigationBarItem(
                    icon: Icons.receipt,
                    label: 'Тапсырыстар',
                  ),
                  AppNavigationBarItem(icon: Icons.chat, label: 'Чаты'),
                ],
                currentIndex: 1,
                onItemTap: (index) => tapped = index,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.chat));
    expect(tapped, 4);
    final longLabel = find.text('Тапсырыстар');
    expect(
      find.ancestor(of: longLabel, matching: find.byType(FittedBox)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
