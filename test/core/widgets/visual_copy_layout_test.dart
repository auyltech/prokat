import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/features/bookings/widgets/equipment_listing_content.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _Catalog extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async =>
      CatalogBundle.fromJson({'version': 'test'});
}

void main() {
  for (final locale in ['ru', 'kk', 'en']) {
    testWidgets(
      'price and schedule choices each occupy half at 320px ($locale)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProkatFlowPage(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ChoicePair(
                            leftLabel: l10n.requestWaitOwnerPrice,
                            rightLabel: l10n.requestSetBudget,
                            leftSelected: true,
                            rightSelected: false,
                            onLeft: () {},
                            onRight: () {},
                          ),
                          const SizedBox(height: 12),
                          ChoicePair(
                            leftLabel: l10n.dateAndTime,
                            rightLabel: l10n.asSoonAsPossible,
                            leftSelected: false,
                            rightSelected: true,
                            onLeft: () {},
                            onRight: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final buttons = find.byType(InkWell);
        expect(buttons, findsNWidgets(4));
        for (final first in [0, 2]) {
          expect(
            tester.getSize(buttons.at(first)),
            tester.getSize(buttons.at(first + 1)),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final duplicate in [true, false]) {
    testWidgets(
      'listing keeps ${duplicate ? "one copy of equal" : "both distinct"} owner texts',
      (tester) async {
        const description = 'Description of the rental';
        final equipment = Equipment(
          id: 'equipment',
          name: 'Crane',
          model: 'Model',
          status: EquipmentStatus.available,
          isVisible: true,
          prices: [],
          ownerComment: description,
          rentCondition: duplicate
              ? '  Description of the rental  '
              : 'Separate rental terms',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [catalogProvider.overrideWith(_Catalog.new)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ProkatFlowPage(
                builder: (_) => Scaffold(
                  body: EquipmentListingContent(
                    equipment: equipment,
                    selectedPrice: null,
                    onPriceChanged: (_) {},
                    onBack: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(duplicate ? description : 'Separate rental terms'),
          200,
        );
        expect(find.text(description), findsOneWidget);
        if (!duplicate) {
          expect(find.text('Separate rental terms'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
