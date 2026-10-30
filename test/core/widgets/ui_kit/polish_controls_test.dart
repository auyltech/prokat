import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  for (final locale in ['ru', 'kk', 'en']) {
    testWidgets('catalog group halves stay equal and tappable in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      CatalogGroup? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProkatFlowScope(
            palette: ProkatFlowPalette.light,
            child: Scaffold(
              body: CatalogGroupTabs(
                groups: CatalogGroup.values,
                selected: CatalogGroup.machinery,
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final taps = find.byType(InkWell);
      expect(taps, findsNWidgets(2));
      expect(
        tester.getSize(taps.at(0)).width,
        tester.getSize(taps.at(1)).width,
      );
      await tester.tap(taps.at(1));
      expect(selected, CatalogGroup.equipment);
      expect(tester.takeException(), isNull);
    });
  }
  for (final entry in {
    'empty_bookings.png': LucideIcons.calendarDays,
    'empty_chats.png': LucideIcons.messagesSquare,
  }.entries) {
    testWidgets(
      '${entry.key} uses a clean vector without the old label artwork',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: EmptyStateTile(title: 'No items', imageName: entry.key),
            ),
          ),
        );
        expect(find.byType(Image), findsNothing);
        expect(find.byIcon(entry.value), findsOneWidget);
        expect(find.text('No items'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
