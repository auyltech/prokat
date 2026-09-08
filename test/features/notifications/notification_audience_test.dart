import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/notifications/utils/notification_audience.dart';

void main() {
  group('NotificationTypeParser', () {
    test('parses BOOKING_WORK_STATUS', () {
      expect(
        NotificationTypeParser.parse('BOOKING_WORK_STATUS'),
        NotificationType.bookingWorkStatus,
      );
    });
  });

  group('notificationOpensOwnerShell', () {
    test('audience CLIENT wins over owner mode', () {
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.bookingConfirmed,
          data: const {'audience': 'CLIENT'},
          isOwnerMode: true,
        ),
        isFalse,
      );
    });

    test('audience OWNER wins over client mode', () {
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.bookingConfirmed,
          data: const {'audience': 'OWNER'},
          isOwnerMode: false,
        ),
        isTrue,
      );
    });

    test('bookingConfirmed without audience follows current mode', () {
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.bookingConfirmed,
          data: const {},
          isOwnerMode: false,
        ),
        isFalse,
      );
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.bookingConfirmed,
          data: const {},
          isOwnerMode: true,
        ),
        isTrue,
      );
    });

    test('work progress opens client shell even in owner mode', () {
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.workOnTheWay,
          data: const {},
          isOwnerMode: true,
        ),
        isFalse,
      );
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.bookingWorkStatus,
          data: const {'workStatus': 'onMyWay'},
          isOwnerMode: true,
        ),
        isFalse,
      );
    });

    test('direct BOOKING_CREATED opens owner shell from client mode', () {
      expect(
        notificationOpensOwnerShell(
          type: NotificationType.bookingCreated,
          data: const {},
          isOwnerMode: false,
        ),
        isTrue,
      );
    });
  });
}
