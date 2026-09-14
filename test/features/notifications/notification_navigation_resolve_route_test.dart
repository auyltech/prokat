import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/notifications/utils/notification_route_resolver.dart';

AppNotification _n(
  NotificationType type, {
  Map<String, dynamic> data = const {},
  String category = 'BOOKING',
}) {
  return AppNotification(
    id: 'n1',
    type: type,
    category: category,
    title: 't',
    body: 'b',
    data: data,
  );
}

String _route(
  AppNotification notification, {
  required bool opensOwner,
  String notificationsHome = AppRoutes.clientNotifications,
}) {
  return resolveNotificationRoute(
    notification: notification,
    opensOwner: opensOwner,
    notificationsHome: notificationsHome,
  );
}

void main() {
  group('resolveNotificationRoute — chat messages', () {
    test('CHAT_MESSAGE_CREATED + chatId → client direct chat', () {
      expect(
        _route(
          _n(
            NotificationType.chatMessageCreated,
            data: const {'chatId': 'chat-1'},
            category: 'CHAT',
          ),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/chat-1',
      );
    });

    test('CHAT_MESSAGE_CREATED + numeric chatId → string path', () {
      expect(
        _route(
          _n(
            NotificationType.chatMessageCreated,
            data: const {'chatId': 42},
            category: 'CHAT',
          ),
          opensOwner: true,
          notificationsHome: AppRoutes.ownerNotifications,
        ),
        '${AppRoutes.ownerChatList}/direct/42',
      );
    });

    test('CHAT_MESSAGE_CREATED without chatId → notifications home', () {
      expect(
        _route(
          _n(NotificationType.chatMessageCreated, category: 'CHAT'),
          opensOwner: false,
        ),
        AppRoutes.clientNotifications,
      );
    });

    test('PRICE_NEGOTIATION_MESSAGE_CREATED + chatId → direct chat', () {
      expect(
        _route(
          _n(
            NotificationType.priceNegotiationMessageCreated,
            data: const {'chatId': 'neg-chat', 'negotiationId': 'n1'},
            category: 'PRICE_NEGOTIATION',
          ),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/neg-chat',
      );
    });

    test('PRICE_NEGOTIATION without chatId → notifications home', () {
      expect(
        _route(
          _n(
            NotificationType.priceNegotiationMessageCreated,
            category: 'PRICE_NEGOTIATION',
          ),
          opensOwner: true,
          notificationsHome: AppRoutes.ownerNotifications,
        ),
        AppRoutes.ownerNotifications,
      );
    });
  });

  group('resolveNotificationRoute — work status', () {
    test('BOOKING_WORK_STATUS + chatId → client direct chat', () {
      expect(
        _route(
          _n(
            NotificationType.bookingWorkStatus,
            data: const {
              'chatId': 'deal-1',
              'bookingId': 'b1',
              'workStatus': 'onMyWay',
              'audience': 'CLIENT',
            },
          ),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/deal-1',
      );
    });

    test('BOOKING_WORK_STATUS without chatId → orders', () {
      expect(
        _route(
          _n(
            NotificationType.bookingWorkStatus,
            data: const {'bookingId': 'b1', 'workStatus': 'started'},
          ),
          opensOwner: false,
        ),
        AppRoutes.clientOrders,
      );
    });

    test('legacy WORK_STARTED + chatId → direct chat', () {
      expect(
        _route(
          _n(NotificationType.workStarted, data: const {'chatId': 'deal-2'}),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/deal-2',
      );
    });

    test('CLIENT_CONFIRMATION_REQUIRED + chatId → direct chat', () {
      expect(
        _route(
          _n(
            NotificationType.clientConfirmationRequired,
            data: const {'chatId': 'deal-3'},
          ),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/deal-3',
      );
    });

    test('CLIENT_CONFIRMATION_REQUIRED without chatId → orders', () {
      expect(
        _route(
          _n(NotificationType.clientConfirmationRequired),
          opensOwner: false,
        ),
        AppRoutes.clientOrders,
      );
    });
  });

  group('resolveNotificationRoute — price negotiation legacy', () {
    test('COUNTER_OFFER_CREATED + chatId → direct chat', () {
      expect(
        _route(
          _n(
            NotificationType.counterOfferCreated,
            data: const {'chatId': 'c1'},
          ),
          opensOwner: true,
        ),
        '${AppRoutes.ownerChatList}/direct/c1',
      );
    });

    test('COUNTER_OFFER_CREATED without chatId → chat list', () {
      expect(
        _route(_n(NotificationType.counterOfferCreated), opensOwner: false),
        AppRoutes.clientChatList,
      );
    });

    test('NEGOTIATION_EXPIRED + chatId → direct chat', () {
      expect(
        _route(
          _n(NotificationType.negotiationExpired, data: const {'chatId': 'c2'}),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/c2',
      );
    });
  });

  group('resolveNotificationRoute — booking lifecycle', () {
    test('BOOKING_CONFIRMED + chatId → direct chat', () {
      expect(
        _route(
          _n(
            NotificationType.bookingConfirmed,
            data: const {'chatId': 'deal-c', 'bookingId': 'b1'},
          ),
          opensOwner: true,
        ),
        '${AppRoutes.ownerChatList}/direct/deal-c',
      );
    });

    test('BOOKING_CONFIRMED without chatId → bookings', () {
      expect(
        _route(_n(NotificationType.bookingConfirmed), opensOwner: true),
        AppRoutes.ownerBookings,
      );
    });

    test('BOOKING_CANCELLED keeps orders even with chatId', () {
      expect(
        _route(
          _n(
            NotificationType.bookingCancelled,
            data: const {'chatId': 'deal-x', 'bookingId': 'b1'},
          ),
          opensOwner: false,
        ),
        AppRoutes.clientOrders,
      );
    });

    test('BOOKING_REJECTED keeps bookings even with chatId', () {
      expect(
        _route(
          _n(
            NotificationType.bookingRejected,
            data: const {'chatId': 'deal-y', 'bookingId': 'b1'},
          ),
          opensOwner: true,
        ),
        AppRoutes.ownerBookings,
      );
    });

    test('BOOKING_COMPLETED keeps orders even with chatId', () {
      expect(
        _route(
          _n(
            NotificationType.bookingCompleted,
            data: const {'chatId': 'deal-z', 'bookingId': 'b1'},
          ),
          opensOwner: false,
        ),
        AppRoutes.clientOrders,
      );
    });

    test('CLIENT_CONFIRMED_COMPLETION keeps orders', () {
      expect(
        _route(
          _n(
            NotificationType.clientConfirmedCompletion,
            data: const {'chatId': 'deal-w'},
          ),
          opensOwner: false,
        ),
        AppRoutes.clientOrders,
      );
    });
  });

  group('resolveNotificationRoute — unrelated unchanged', () {
    test('OFFER_CREATED → client requests', () {
      expect(
        _route(
          _n(
            NotificationType.offerCreated,
            data: const {
              'chatId': 'offer-chat',
              'requestId': 'r1',
              'offerId': 'o1',
            },
            category: 'OFFER',
          ),
          opensOwner: false,
        ),
        AppRoutes.clientRequests,
      );
    });

    test('REQUEST_CREATED → owner requests', () {
      expect(
        _route(
          _n(
            NotificationType.requestCreated,
            data: const {'requestId': 'r1'},
            category: 'REQUEST',
          ),
          opensOwner: true,
        ),
        AppRoutes.ownerRequests,
      );
    });

    test('EQUIPMENT_APPROVED → owner equipment detail', () {
      expect(
        _route(
          _n(
            NotificationType.equipmentApproved,
            data: const {'equipmentId': 'eq-1'},
            category: 'EQUIPMENT',
          ),
          opensOwner: true,
        ),
        '${AppRoutes.ownerEquipment}/eq-1',
      );
    });

    test('BALANCE_TOPPED_UP → owner payment', () {
      expect(
        _route(
          _n(NotificationType.balanceToppedUp, category: 'BILLING'),
          opensOwner: true,
        ),
        AppRoutes.ownerPayment,
      );
    });

    test('REVIEW_AVAILABLE → orders', () {
      expect(
        _route(
          _n(
            NotificationType.reviewAvailable,
            data: const {'chatId': 'ignored'},
            category: 'REVIEW',
          ),
          opensOwner: false,
        ),
        AppRoutes.clientOrders,
      );
    });

    test('OWNER_APPROVED → owner profile', () {
      expect(
        _route(
          _n(NotificationType.ownerApproved, category: 'OWNER'),
          opensOwner: true,
        ),
        AppRoutes.ownerProfile,
      );
    });
  });

  group('resolveNotificationRoute — role shell paths', () {
    test('CLIENT shell + chatId → /client/chat/direct/{id}', () {
      expect(
        _route(
          _n(NotificationType.bookingWorkStatus, data: const {'chatId': 'x'}),
          opensOwner: false,
        ),
        '${AppRoutes.clientChatList}/direct/x',
      );
    });

    test('OWNER shell + chatId → /owner/chat/direct/{id}', () {
      expect(
        _route(
          _n(
            NotificationType.bookingConfirmed,
            data: const {'chatId': 'x', 'audience': 'OWNER'},
          ),
          opensOwner: true,
        ),
        '${AppRoutes.ownerChatList}/direct/x',
      );
    });
  });

  group('isTrustedNotificationAppRoute', () {
    test('accepts client and owner app paths', () {
      expect(isTrustedNotificationAppRoute('/client/chat/direct/1'), isTrue);
      expect(isTrustedNotificationAppRoute('/owner/bookings'), isTrue);
    });

    test('rejects backend-style and empty paths', () {
      expect(isTrustedNotificationAppRoute('/chat/abc'), isFalse);
      expect(isTrustedNotificationAppRoute('prokat://chat/abc'), isFalse);
      expect(isTrustedNotificationAppRoute(''), isFalse);
    });
  });
}
