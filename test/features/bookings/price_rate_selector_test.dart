import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/bookings/widgets/price_rate_selector.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _FixedCatalogNotifier extends CatalogNotifier {
  _FixedCatalogNotifier(this.bundle);

  final CatalogBundle bundle;
  int refreshCalls = 0;

  @override
  Future<CatalogBundle> build() async => bundle;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> refreshIfStale() async {}
}

CatalogBundle _catalog() {
  return const CatalogBundle(
    version: 'selector-test',
    cities: [],
    categories: [],
    units: [],
    tariffUnits: [
      CatalogTariffUnit(
        id: '1',
        code: 'PER_HOUR',
        names: LocalizedNames(ru: 'за час', en: 'per hour', kk: 'сағатына'),
        sortIndex: 0,
        isActive: true,
      ),
      CatalogTariffUnit(
        id: '2',
        code: 'PER_MONTH',
        names: LocalizedNames(ru: 'за месяц', en: 'per month', kk: 'айына'),
        sortIndex: 1,
        isActive: true,
      ),
      CatalogTariffUnit(
        id: '3',
        code: 'PER_TONNE',
        names: LocalizedNames(ru: 'за тонну', en: 'per tonne', kk: 'тоннаға'),
        sortIndex: 2,
        isActive: false,
      ),
    ],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('builds active catalog options by sortIndex with raw codes', (
    tester,
  ) async {
    final catalog = _FixedCatalogNotifier(_catalog());
    PriceRateOption? selected;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogProvider.overrideWith(() => catalog)],
        child: MaterialApp(
          locale: const Locale('ru'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PriceRateSelector(
              initialValue: null,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('за час'), findsOneWidget);
    expect(find.text('за месяц'), findsOneWidget);
    expect(find.text('за тонну'), findsNothing);

    await tester.tap(find.text('за месяц'));
    await tester.pumpAndSettle();
    expect(selected?.value, 'PER_MONTH');
    expect(selected?.value, isNot('PER_TRIP'));
    expect(catalog.refreshCalls, 0);
  });

  testWidgets('keeps inactive historic code without remapping', (tester) async {
    final catalog = _FixedCatalogNotifier(_catalog());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogProvider.overrideWith(() => catalog)],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PriceRateSelector(
              initialValue: const PriceRateOption(
                value: 'PER_TONNE',
                label: 'PER_TONNE',
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('per tonne'), findsOneWidget);
    expect(find.text('PER_TRIP'), findsNothing);
  });
}
