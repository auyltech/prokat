import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';

void main() {
  test(
    'accepted terms hydrate the new address and schedule in the same chat',
    () async {
      final service = _ChatService();
      final oldBooking = BookingModel.fromJson({
        'id': 'booking-1',
        'status': 'CREATED',
        'price': 18000,
        'priceRate': 'PER_HOUR',
        'bookedOn': '2026-10-29T08:00:00Z',
        'bookedAt': '2026-10-29T08:00:00Z',
        'updatedAt': '2026-10-28T07:00:00Z',
        'equipment': {'id': 'equipment-1', 'name': 'Truck', 'model': 'Test'},
        'location': {
          'id': 'old-address',
          'service': 'ADDRESS',
          'street': 'Old street',
          'city': 'Atyrau',
          'country': 'Kazakhstan',
          'latitude': 47.1,
          'longitude': 51.9,
        },
      });
      service.next = service.next.copyWith(
        booking: oldBooking,
        bookingId: oldBooking.id,
      );
      final container = ProviderContainer(
        overrides: [
          authenticatedSessionScopeKeyProvider.overrideWithValue(
            const AuthenticatedSessionScopeKey.forUser('client-1'),
          ),
          chatServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final provider = currentChatProvider('chat-1');
      await container.read(provider.future);
      final revised = BookingModel.fromJson({
        'id': 'booking-1',
        'status': 'CONFIRMED',
        'price': 17000,
        'priceRate': 'PER_HOUR',
        'bookedOn': '2026-10-30T09:00:00Z',
        'bookedAt': '2026-10-30T09:00:00Z',
        'updatedAt': '2026-10-28T08:00:00Z',
        'equipment': {'id': 'equipment-1', 'name': 'Truck', 'model': 'Test'},
        'location': {
          'id': 'agreed-address',
          'service': 'ADDRESS',
          'street': 'Agreed street',
          'city': 'Atyrau',
          'country': 'Kazakhstan',
          'latitude': 47.2,
          'longitude': 51.8,
        },
      });
      service.next = service.next.copyWith(booking: revised);
      final notifier = container.read(provider.notifier);
      notifier.applyWorkflowDelta(
        WorkflowUpdate.tryParse({
          'v': 1,
          'eventId': 'terms-accepted',
          'emittedAt': '2026-10-28T08:00:00Z',
          'reason': 'BOOKING_TERMS_ACCEPTED',
          'actorId': 'owner-1',
          'chatId': 'chat-1',
          'booking': {
            'id': 'booking-1',
            'status': 'CONFIRMED',
            'workStatus': 'pending',
            'price': 17000,
            'priceRate': 'PER_HOUR',
            'updatedAt': '2026-10-28T08:00:00Z',
          },
        })!,
      );
      await notifier.refresh();
      final chat = container.read(provider).requireValue!;
      expect(service.calls, 2);
      expect(chat.id, 'chat-1');
      expect(chat.bookingId, 'booking-1');
      expect(chat.booking?.price, 17000);
      expect(chat.booking?.status, BookingStatus.confirmed);
      expect(chat.booking?.location?.id, 'agreed-address');
      expect(chat.booking?.location?.street, 'Agreed street');
      expect(chat.booking?.bookedAt, revised.bookedAt);
    },
  );

  test('new inquiry order loads its listing and schedule; later status updates stay local', () async {
    final service = _ChatService();
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(
          const AuthenticatedSessionScopeKey.forUser('client-1'),
        ),
        chatServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    final provider = currentChatProvider('chat-1');
    await container.read(provider.future);
    expect(container.read(provider).requireValue?.booking, isNull);

    final order = BookingModel.fromJson({
      'id': 'booking-1',
      'status': 'CREATED',
      'price': 18000,
      'priceRate': 'PER_HOUR',
      'bookedOn': '2026-10-14T08:00:00.000Z',
      'bookedAt': '2026-10-14T08:00:00.000Z',
      'updatedAt': '2026-10-14T07:00:00.000Z',
      'equipment': {'id': 'equipment-1', 'name': 'Truck', 'model': 'Test'},
    });
    service.next = service.next.copyWith(booking: order, bookingId: order.id);
    final notifier = container.read(provider.notifier);
    notifier.applyWorkflowDelta(_update('CREATED', '2026-10-14T07:00:00.000Z'));
    await notifier.refresh(); // Joins the automatic, coalesced detail fetch.

    final hydrated = container.read(provider).requireValue!;
    expect(service.calls, 2);
    expect(hydrated.id, 'chat-1');
    expect(hydrated.booking?.equipment?.name, 'Truck');
    expect(hydrated.booking?.bookedAt, isNotNull);

    notifier.applyWorkflowDelta(
      _update('CONFIRMED', '2026-10-14T07:01:00.000Z'),
    );
    expect(service.calls, 2);
    expect(
      container.read(provider).requireValue?.booking?.status,
      BookingStatus.confirmed,
    );
    expect(
      container.read(provider).requireValue?.booking?.equipment?.name,
      'Truck',
    );
  });
}

WorkflowUpdate _update(String status, String timestamp) =>
    WorkflowUpdate.tryParse({
      'v': 1,
      'eventId': 'event-$status',
      'emittedAt': timestamp,
      'reason': 'BOOKING_STATUS_CHANGED',
      'actorId': 'client-1',
      'chatId': 'chat-1',
      'booking': {
        'id': 'booking-1',
        'status': status,
        'workStatus': 'pending',
        'price': 18000,
        'priceRate': 'PER_HOUR',
        'updatedAt': timestamp,
      },
    })!;

class _ChatService extends ChatService {
  _ChatService() : super(_ApiClient());
  int calls = 0;
  ChatModel next = const ChatModel(
    id: 'chat-1',
    inquiryEquipmentId: 'equipment-1',
  );
  @override
  Future<ApiResponse<ChatModel>> getChatById(String chatId) async {
    calls++;
    return ApiResponse.success(next);
  }
}

class _ApiClient implements ApiClient {
  @override
  Dio dio = Dio();
}
