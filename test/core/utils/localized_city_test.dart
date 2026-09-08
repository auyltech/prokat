import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/l10n/app_localizations_en.dart';
import 'package:prokat/l10n/app_localizations_kk.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

void main() {
  final l10nRu = AppLocalizationsRu();
  final l10nEn = AppLocalizationsEn();
  final l10nKk = AppLocalizationsKk();

  test('localizedCityName returns the stored city token', () {
    expect(localizedCityName('atyrau', l10nRu), 'atyrau');
    expect(localizedCityName('Almaty', l10nKk), 'Almaty');
    expect(localizedCityName(' astana ', l10nEn), 'astana');
  });

  test('localizedCityName keeps unknown tokens', () {
    expect(localizedCityName('Aktau', l10nRu), 'Aktau');
    expect(localizedCityName('', l10nRu), '');
    expect(localizedCityName(null, l10nRu), '');
  });

  test('canonicalCity matches known tokens case-insensitively', () {
    expect(
      canonicalCity('Ust-Kamenogorsk', ['Ust-Kamenogorsk']),
      'Ust-Kamenogorsk',
    );
    expect(canonicalCity('atyrau', ['Atyrau', 'Almaty']), 'Atyrau');
  });
}
