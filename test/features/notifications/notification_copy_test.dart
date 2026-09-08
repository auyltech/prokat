import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';

AppNotification _ownerApproved({Map<String, dynamic>? data}) {
  return AppNotification(
    id: 'n1',
    type: NotificationType.ownerApproved,
    category: 'OWNER',
    title: 'Owner registration approved',
    body: 'Your owner registration has been approved.',
    data: data ?? const {},
  );
}

void main() {
  test('OWNER_APPROVED without i18n uses app locale copy', () {
    final notification = _ownerApproved();

    expect(notification.localizedTitle('ru'), 'Регистрация владельца одобрена');
    expect(
      notification.localizedBody('ru'),
      'Ваша регистрация в качестве владельца одобрена.',
    );
    expect(notification.localizedTitle('kk'), 'Ие ретінде тіркелу мақұлданды');
    expect(notification.localizedTitle('en'), 'Owner registration approved');
  });

  test('stored i18n wins over type fallback', () {
    final notification = _ownerApproved(
      data: {
        'i18n': {
          'ru': {'title': 'Кастомный заголовок', 'body': 'Кастомный текст'},
        },
      },
    );

    expect(notification.localizedTitle('ru'), 'Кастомный заголовок');
    expect(notification.localizedBody('ru'), 'Кастомный текст');
  });
}
