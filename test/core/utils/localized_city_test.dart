import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/l10n/app_localizations_en.dart';
import 'package:prokat/l10n/app_localizations_kk.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

void main() {
  final l10nEn = AppLocalizationsEn();
  final l10nRu = AppLocalizationsRu();
  final l10nKk = AppLocalizationsKk();

  test('looks up city names case-insensitively', () {
    expect(localizedCityName('Atyrau', l10nRu), 'Атырау');
    expect(localizedCityName('atyrau', l10nRu), 'Атырау');
    expect(localizedCityName(' ATYRAU ', l10nRu), 'Атырау');
    expect(localizedCityName('Almaty', l10nKk), 'Алматы');
    expect(localizedCityName('astana', l10nEn), 'Astana');
  });

  test('keeps unknown city keys unchanged', () {
    expect(localizedCityName('Aktau', l10nRu), 'Aktau');
    expect(localizedCityName('', l10nRu), '');
    expect(localizedCityName(null, l10nRu), '');
  });

  test('canonicalCity matches known keys ignoring case', () {
    expect(canonicalCity('almaty', cities), 'Almaty');
    expect(canonicalCity('Ust-Kamenogorsk', citiesExpanded), 'Ust-Kamenogorsk');
    expect(canonicalCity('unknown', cities), isNull);
  });

  test('formatStreetCity localizes only the city part', () {
    expect(
      formatStreetCity(
        l10n: l10nRu,
        street: 'ул. Розыбакиева 247, кв. 18',
        city: 'Almaty',
      ),
      'ул. Розыбакиева 247, кв. 18, Алматы',
    );
  });
}
