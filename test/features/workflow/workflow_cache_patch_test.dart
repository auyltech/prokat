import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';
import 'package:prokat/features/workflow/utils/event_id_lru.dart';
import 'package:prokat/features/workflow/utils/workflow_cache_patch.dart';
import 'package:prokat/features/workflow/utils/workflow_updated_at.dart';

WorkflowUpdate _update({
  required String eventId,
  String? chatId,
  WorkflowBookingDelta? booking,
}) {
  return WorkflowUpdate(
    v: 1,
    eventId: eventId,
    emittedAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
    reason: 'BOOKING_STATUS_CHANGED',
    actorId: 'user-1',
    chatId: chatId,
    booking: booking,
  );
}

WorkflowBookingDelta _bookingDelta({
  required BookingStatus status,
  required DateTime updatedAt,
}) {
  return WorkflowBookingDelta(
    id: 'booking-1',
    status: status,
    workStatus: parseWorkStatus('pending'),
    price: 2000,
    priceRate: parseRateOption('PER_TRIP'),
    updatedAt: updatedAt,
  );
}

void main() {
  test(
    'patches current chat booking and removes cancelled chats from active',
    () {
      final chat = ChatModel(
        id: 'chat-1',
        booking: BookingModel(
          id: 'booking-1',
          status: BookingStatus.created,
          price: 2000,
          priceRate: parseRateOption('PER_TRIP'),
          updatedAt: DateTime.parse('2026-08-20T11:00:00.000Z'),
        ),
      );

      final update = _update(
        eventId: 'evt-1',
        chatId: 'chat-1',
        booking: _bookingDelta(
          status: BookingStatus.cancelled,
          updatedAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
        ),
      );

      final patched = applyWorkflowDeltaToChat(chat, update);
      expect(patched.booking?.status, BookingStatus.cancelled);

      final result = applyWorkflowUpdateToChatItems(
        items: [chat],
        count: 1,
        filter: ChatListFilter.active,
        update: update,
      );

      expect(result.status, WorkflowChatApplyStatus.removed);
      expect(result.items, isEmpty);
      expect(result.count, 0);
    },
  );

  test('ignores stale booking updates by updatedAt', () {
    final existing = DateTime.parse('2026-08-20T13:00:00.000Z');
    final incoming = DateTime.parse('2026-08-20T12:00:00.000Z');
    expect(isIncomingWorkflowStale(existing, incoming), isTrue);

    final current = QueryState<BookingModel>(
      items: [
        BookingModel(
          id: 'booking-1',
          status: BookingStatus.confirmed,
          price: 2000,
          priceRate: parseRateOption('PER_TRIP'),
          updatedAt: existing,
        ),
      ],
      itemsPerPage: 10,
      count: 1,
    );

    final result = applyBookingDeltaToQuery(
      current: current,
      delta: _bookingDelta(
        status: BookingStatus.cancelled,
        updatedAt: incoming,
      ),
      kind: BookingQueryPatchKind.active,
    );

    expect(result.status, BookingQueryApplyStatus.skippedStale);
    expect(result.state, isNull);
  });

  test('event id LRU remembers once and drops the oldest', () {
    final lru = EventIdLru(maxSize: 2);
    expect(lru.remember('a'), isTrue);
    expect(lru.remember('a'), isFalse);
    expect(lru.remember('b'), isTrue);
    expect(lru.remember('c'), isTrue);
    expect(lru.contains('a'), isFalse);
    expect(lru.contains('c'), isTrue);
  });

  test('removes cancelled requests from the owner active list', () {
    final current = QueryState<RequestModel>(
      items: [
        RequestModel(
          id: 'request-1',
          status: RequestStatus.created,
          capacity: '2',
          offeredPrice: 1000,
          location: LocationModel(
            service: 'ADDRESS',
            street: 'st',
            city: 'city',
            country: 'kz',
            longitude: 0,
            latitude: 0,
          ),
          updatedAt: DateTime.parse('2026-08-20T11:00:00.000Z'),
        ),
      ],
      itemsPerPage: 10,
      count: 1,
    );

    final result = applyRequestDeltaToQuery(
      current: current,
      delta: WorkflowRequestDelta(
        id: 'request-1',
        status: RequestStatus.cancelled,
        updatedAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
      ),
      kind: RequestQueryPatchKind.active,
    );

    expect(result.status, RequestQueryApplyStatus.removed);
    expect(result.state?.items, isEmpty);
    expect(result.state?.count, 0);
  });

  test('detects a new offer that is not already on the open chat', () {
    final chat = ChatModel(id: 'chat-1');
    final update = WorkflowUpdate(
      v: 1,
      eventId: 'evt-offer',
      emittedAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
      reason: 'OFFER_CREATED',
      actorId: 'owner-1',
      chatId: 'chat-1',
      offers: [
        WorkflowOfferDelta(
          id: 'offer-1',
          status: OfferStatus.created,
          updatedAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
        ),
      ],
    );

    expect(workflowUpdateIntroducesUnknownOffer(chat, update), isTrue);

    final withOffer = ChatModel(
      id: 'chat-1',
      offers: [
        OfferModel(
          id: 'offer-1',
          status: OfferStatus.created,
          requestId: 'request-1',
          chatId: 'chat-1',
          equipmentId: 'equipment-1',
          price: 1000,
        ),
      ],
    );

    expect(workflowUpdateIntroducesUnknownOffer(withOffer, update), isFalse);
  });
}
