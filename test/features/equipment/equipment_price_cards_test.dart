import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_card.dart';
import 'package:prokat/l10n/app_localizations.dart';

CatalogBundle _catalogWithTariffs() {
  return const CatalogBundle(
    version: 'card-test',
    cities: [],
    categories: [],
    units: [],
    tariffUnits: [
      CatalogTariffUnit(
        id: 'tu-hour',
        code: 'PER_HOUR',
        names: LocalizedNames(ru: 'за час', en: 'per hour', kk: 'сағатына'),
        sortIndex: 0,
        isActive: true,
      ),
      CatalogTariffUnit(
        id: 'tu-month',
        code: 'PER_MONTH',
        names: LocalizedNames(ru: 'за месяц', en: 'per month', kk: 'айына'),
        sortIndex: 1,
        isActive: true,
      ),
      CatalogTariffUnit(
        id: 'tu-tonne',
        code: 'PER_TONNE',
        names: LocalizedNames(ru: 'за тонну', en: 'per tonne', kk: 'тоннаға'),
        sortIndex: 2,
        isActive: true,
      ),
    ],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );
}

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

Equipment _equipment({required String priceRate}) {
  return Equipment(
    id: 'eq-1',
    name: 'Экскаватор',
    model: 'CAT',
    status: EquipmentStatus.available,
    isVisible: true,
    city: 'atyrau',
    owner: const UserModel(rating: 5, orderCount: 3),
    prices: [
      PriceEntry(id: 'p1', price: 15000, priceRate: parseRateOption(priceRate)),
    ],
  );
}

Widget _wrap({
  required Locale locale,
  required List<Override> overrides,
  required Widget child,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// Guest card renders price in [RichText]; [find.textContaining] misses spans.
String _guestPricePlain(WidgetTester tester) {
  final texts = tester
      .widgetList<RichText>(find.byType(RichText))
      .map((widget) => widget.text.toPlainText())
      .where((text) => text.contains('₸') || text.contains('poa'))
      .toList();
  expect(texts, isNotEmpty, reason: 'expected price RichText on guest card');
  return texts.first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestEquipmentCard tariff labels', () {
    testWidgets('shows ru/en/kk full labels without slash', (tester) async {
      final catalog = _FixedCatalogNotifier(_catalogWithTariffs());
      final equipment = _equipment(priceRate: 'PER_HOUR');

      Future<void> pumpLocale(Locale locale) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            overrides: [catalogProvider.overrideWith(() => catalog)],
            child: GuestEquipmentCard(item: equipment),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpLocale(const Locale('ru'));
      expect(_guestPricePlain(tester), '15 000 ₸ за час');
      expect(_guestPricePlain(tester).contains('/'), isFalse);

      await pumpLocale(const Locale('en'));
      expect(_guestPricePlain(tester), '15 000 ₸ per hour');
      expect(_guestPricePlain(tester).contains('/'), isFalse);

      await pumpLocale(const Locale('kk'));
      expect(_guestPricePlain(tester), '15 000 ₸ сағатына');
      expect(catalog.refreshCalls, 0);
    });

    testWidgets('shows PER_MONTH and PER_TONNE from catalog', (tester) async {
      final catalog = _FixedCatalogNotifier(_catalogWithTariffs());

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ru'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: GuestEquipmentCard(item: _equipment(priceRate: 'PER_MONTH')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_guestPricePlain(tester), '15 000 ₸ за месяц');
      expect(_guestPricePlain(tester).contains('PER_TRIP'), isFalse);
      expect(_guestPricePlain(tester).contains('/'), isFalse);

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: GuestEquipmentCard(item: _equipment(priceRate: 'PER_TONNE')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_guestPricePlain(tester), '15 000 ₸ per tonne');
      expect(_guestPricePlain(tester).contains('PER_TRIP'), isFalse);
    });

    testWidgets('legacy catalog without tariffUnits uses ARB fallback', (
      tester,
    ) async {
      final catalog = _FixedCatalogNotifier(
        const CatalogBundle(
          version: 'legacy',
          cities: [],
          categories: [],
          units: [],
          tariffUnits: null,
          specs: [],
          specOptions: [],
          categorySpecs: [],
        ),
      );

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ru'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: GuestEquipmentCard(item: _equipment(priceRate: 'PER_DAY')),
        ),
      );
      await tester.pumpAndSettle();

      expect(_guestPricePlain(tester), '15 000 ₸ за день');
      expect(_guestPricePlain(tester).contains('/'), isFalse);
    });

    testWidgets('restored disk catalog labels work offline without refresh', (
      tester,
    ) async {
      // Simulate CatalogBundle restored from disk JSON (all three names intact).
      final restored = CatalogBundle.fromJson(_catalogWithTariffs().toJson());
      final catalog = _FixedCatalogNotifier(restored);

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('kk'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: GuestEquipmentCard(item: _equipment(priceRate: 'PER_HOUR')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_guestPricePlain(tester), '15 000 ₸ сағатына');

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: GuestEquipmentCard(item: _equipment(priceRate: 'PER_HOUR')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_guestPricePlain(tester), '15 000 ₸ per hour');
      expect(catalog.refreshCalls, 0);
    });
  });

  group('OwnerEquipmentCard tariff labels', () {
    testWidgets('formats full localized price line without slash', (
      tester,
    ) async {
      final catalog = _FixedCatalogNotifier(_catalogWithTariffs());

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ru'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: OwnerEquipmentCard(
            equipment: _equipment(priceRate: 'PER_HOUR'),
            showShare: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('15 000 ₸ за час'), findsWidgets);
      expect(find.textContaining('/ час'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          overrides: [catalogProvider.overrideWith(() => catalog)],
          child: OwnerEquipmentCard(
            equipment: _equipment(priceRate: 'PER_MONTH'),
            showShare: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('15 000 ₸ per month'), findsWidgets);
      expect(catalog.refreshCalls, 0);
    });
  });
}
