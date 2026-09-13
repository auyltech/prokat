import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/offers/offer_error_message.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
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

  test('maps CONFLICT:OFFERS:CREATE:BALANCE to the app locale', () {
    expect(
      offerCreateErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: offerCreateZeroBalanceCode,
      ),
      'Нельзя откликаться на заявки при нулевом балансе',
    );
  });

  test('maps CONFLICT:OFFERS:CREATE:OFFLINE to the app locale', () {
    expect(
      offerCreateErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: offerCreateOwnerOfflineCode,
      ),
      'Чтобы принимать прямые заявки клиентов или откликаться на открытые запросы, вы должны быть онлайн',
    );
  });

  test('maps booking and offer offline codes to the owner warning', () {
    final l10n = AppLocalizationsRu();
    expect(
      ownerOfflineActionErrorMessage(
        l10n: l10n,
        errorCode: bookingOwnerOfflineCode,
      ),
      l10n.ownerOfflineMustBeOnlineToAccept,
    );
    expect(
      ownerOfflineActionErrorMessage(
        l10n: l10n,
        errorCode: offerCreateOwnerOfflineCode,
      ),
      l10n.ownerOfflineMustBeOnlineToAccept,
    );
    expect(
      ownerOfflineActionErrorMessage(
        l10n: l10n,
        errorCode: 'OTHER',
        fallback: 'Не удалось подтвердить заказ',
      ),
      'Не удалось подтвердить заказ',
    );
  });
}
