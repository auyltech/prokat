import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/requests/request_create_error_message.dart';
import 'package:prokat/features/user_safety/user_safety_error_message.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  test('CONTENT_NOT_ALLOWED maps to the localized content message', () {
    final expected = {
      'ru': 'Текст содержит недопустимое содержимое. Измените его и попробуйте снова.',
      'en': 'The text contains content that is not allowed. Please edit it and try again.',
      'kk':
          'Мәтінде жол берілмейтін мазмұн бар. Оны өзгертіп, қайтадан көріңіз.',
    };

    for (final entry in expected.entries) {
      final l10n = lookupAppLocalizations(Locale(entry.key));
      expect(
        requestCreateErrorMessage(
          l10n: l10n,
          errorCode: contentNotAllowedErrorCode,
          fallback: 'The text contains content that is not allowed',
        ),
        entry.value,
      );
      expect(
        userSafetyErrorMessage(l10n, contentNotAllowedErrorCode),
        entry.value,
      );
    }
  });

  test(
    'other request errors keep the server message or the generic fallback',
    () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(
        requestCreateErrorMessage(
          l10n: l10n,
          errorCode: 'CONFLICT:REQUESTS:ACTIVE_LIMIT',
          fallback: 'Maximum number of active requests',
        ),
        'Maximum number of active requests',
      );
      expect(
        requestCreateErrorMessage(l10n: l10n, errorCode: null, fallback: '  '),
        l10n.somethingWentWrongTryAgain,
      );
    },
  );
}
