import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/booking_create_error_message.dart';
import 'package:prokat/features/offers/offer_error_message.dart';
import 'package:prokat/features/user_safety/user_safety_error_message.dart';
import 'package:prokat/l10n/app_localizations_en.dart';
import 'package:prokat/l10n/app_localizations_kk.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

void main() {
  test('USER_BLOCKED maps to the neutral interaction text in every locale', () {
    for (final l10n in [
      AppLocalizationsRu(),
      AppLocalizationsEn(),
      AppLocalizationsKk(),
    ]) {
      expect(
        userSafetyErrorMessage(l10n, userBlockedErrorCode),
        l10n.interactionUnavailableBody,
      );
      expect(
        bookingCreateErrorMessage(
          l10n: l10n,
          errorCode: userBlockedErrorCode,
          fallback: 'Interaction with this user is unavailable',
        ),
        l10n.interactionUnavailableBody,
      );
      expect(
        offerCreateErrorMessage(
          l10n: l10n,
          errorCode: userBlockedErrorCode,
          fallback: 'Interaction with this user is unavailable',
        ),
        l10n.interactionUnavailableBody,
      );
    }
  });

  test('the blocked text never says who blocked whom', () {
    final en = AppLocalizationsEn();
    expect(
      en.interactionUnavailableBody.toLowerCase(),
      isNot(contains('blocked you')),
    );
  });

  test('unknown safety codes fall back to the generic retry text', () {
    final l10n = AppLocalizationsEn();
    expect(
      userSafetyErrorMessage(l10n, 'VALIDATION_ERROR'),
      l10n.somethingWentWrongTryAgain,
    );
    expect(userSafetyErrorMessage(l10n, null), l10n.somethingWentWrongTryAgain);
  });

  test('booking mapper keeps the existing active-limit mapping', () {
    final l10n = AppLocalizationsEn();
    expect(
      bookingCreateErrorMessage(l10n: l10n, errorCode: bookingActiveLimitCode),
      l10n.bookingActiveLimitReached,
    );
  });
}
