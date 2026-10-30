import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/bookings/widgets/booking_order_fields.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/l10n/app_localizations_en.dart';
import 'package:prokat/l10n/app_localizations_kk.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

void main() {
  const catalog = CatalogBundle(
    version: 'booking-label',
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
    ],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );

  test('bookingTariffLabel uses catalog names without slash', () {
    final entry = PriceEntry(
      id: 'p1',
      price: 15000,
      priceRate: parseRateOption('PER_HOUR'),
    );

    expect(
      bookingTariffLabel(
        entry,
        AppLocalizationsRu(),
        catalog: catalog,
        languageCode: 'ru',
      ),
      '15 000 ₸ за час',
    );
    expect(
      bookingTariffLabel(
        entry,
        AppLocalizationsEn(),
        catalog: catalog,
        languageCode: 'en',
      ),
      '15 000 ₸ per hour',
    );
    expect(
      bookingTariffLabel(
        entry,
        AppLocalizationsKk(),
        catalog: catalog,
        languageCode: 'kk',
      ),
      '15 000 ₸ сағатына',
    );
  });

  test('bookingTariffLabel supports new codes from catalog', () {
    final entry = PriceEntry(
      id: 'p2',
      price: 90000,
      priceRate: parseRateOption('PER_MONTH'),
    );

    expect(
      bookingTariffLabel(
        entry,
        AppLocalizationsRu(),
        catalog: catalog,
        languageCode: 'ru',
      ),
      '90 000 ₸ за месяц',
    );
    expect(
      bookingTariffLabel(
        entry,
        AppLocalizationsRu(),
        catalog: catalog,
        languageCode: 'ru',
      ).contains('/'),
      isFalse,
    );
  });
}
