import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/services/foreground_notification_presenter.dart';

AppNotification notice(String id, {bool read = false}) =>
    AppNotification.fromJson({
      'id': id,
      'type': 'BOOKING_CREATED',
      'category': 'BOOKING',
      'title': 'Fallback',
      'data': {
        'i18n': {
          'ru': {
            'title': 'Новые условия заказа',
            'body': 'Проверьте адрес и время',
          },
        },
      },
      if (read) 'readAt': '2026-10-30T00:00:00Z',
    });

void main() {
  testWidgets('socket/FCM share one localized banner; tap navigates once', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(navigatorKey: key, home: const Scaffold()),
    );
    final presenter = ForegroundNotificationPresenter(
      overlay: () => key.currentState?.overlay,
      locale: () => 'ru',
      onTap: (n) => opened.add(n.id),
      accepts: (_) => true,
      isRead: (_) => false,
    );
    addTearDown(presenter.reset);
    expect(presenter.present(notice('same-event')), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Новые условия заказа'), findsOneWidget);
    expect(presenter.present(notice('same-event')), isTrue);
    await tester.pump();
    expect(find.text('Новые условия заказа'), findsOneWidget);
    await tester.tap(find.text('Новые условия заказа'));
    await tester.pumpAndSettle();
    expect(opened, ['same-event']);
    expect(find.text('Новые условия заказа'), findsNothing);
  });

  testWidgets(
    'read, other scope, and background events do not expose a banner',
    (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: key, home: const Scaffold()),
      );
      var allowed = true;
      final presenter = ForegroundNotificationPresenter(
        overlay: () => key.currentState?.overlay,
        locale: () => 'ru',
        onTap: (_) {},
        accepts: (_) => allowed,
        isRead: (id) => id == 'local-read',
      );
      addTearDown(presenter.reset);
      presenter.present(notice('read', read: true));
      presenter.present(notice('local-read'));
      allowed = false;
      presenter.present(notice('other-company'));
      await tester.pump();
      expect(find.text('Новые условия заказа'), findsNothing);
      allowed = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(presenter.present(notice('background')), isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(presenter.present(notice('foreground')), isTrue);
      await tester.pumpAndSettle();
      presenter.reset();
      await tester.pumpAndSettle();
      expect(find.text('Новые условия заказа'), findsNothing);
    },
  );
}
