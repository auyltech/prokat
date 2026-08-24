import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/offers/offer_error_message.dart';
import 'package:prokat/l10n/app_localizations_en.dart';
import 'package:prokat/l10n/app_localizations_kk.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

void main() {
  test('maps NOT_FOUND:OFFERS:CREATE to the app locale', () {
    expect(
      offerCreateErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: offerCreateRequestNotFoundCode,
      ),
      'Заявка не найдена или уже удалена',
    );
    expect(
      offerCreateErrorMessage(
        l10n: AppLocalizationsEn(),
        errorCode: offerCreateRequestNotFoundCode,
      ),
      'Request not found or already deleted',
    );
    expect(
      offerCreateErrorMessage(
        l10n: AppLocalizationsKk(),
        errorCode: offerCreateRequestNotFoundCode,
      ),
      'Өтінім табылмады немесе жойылған',
    );
  });

  test('falls back to the API message for unknown codes', () {
    expect(
      offerCreateErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: 'CONFLICT:OFFERS:CREATE',
        fallback: 'Not allowed to create offer for your own request',
      ),
      'Not allowed to create offer for your own request',
    );
  });
}
