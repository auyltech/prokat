import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';

void main() {
  test('parses a full workflow:update payload', () {
    final update = WorkflowUpdate.tryParse({
      'v': 1,
      'eventId': 'evt-1',
      'emittedAt': '2026-08-20T12:00:00.000Z',
      'reason': 'BOOKING_STATUS_CHANGED',
      'actorId': 'user-1',
      'chatId': 'chat-1',
      'booking': {
        'id': 'booking-1',
        'status': 'CANCELLED',
        'workStatus': 'cancelled',
        'price': 2000,
        'priceRate': 'PER_TRIP',
        'updatedAt': '2026-08-20T12:00:00.000Z',
      },
      'request': {
        'id': 'request-1',
        'status': 'CANCELLED',
        'updatedAt': '2026-08-20T12:00:00.000Z',
      },
      'offers': [
        {
          'id': 'offer-1',
          'status': 'CLOSED',
          'updatedAt': '2026-08-20T12:00:00.000Z',
        },
      ],
      'negotiations': [
        {
          'id': 'neg-1',
          'status': 'CLOSED',
          'price': 1800,
          'priceRate': 'PER_HOUR',
          'updatedAt': '2026-08-20T12:00:00.000Z',
        },
      ],
      'chat': {
        'id': 'chat-1',
        'status': 'CLOSED',
        'updatedAt': '2026-08-20T12:00:00.000Z',
      },
    });

    expect(update, isNotNull);
    expect(update!.eventId, 'evt-1');
    expect(update.chatId, 'chat-1');
    expect(update.booking?.status, BookingStatus.cancelled);
    expect(update.request?.id, 'request-1');
    expect(update.offers?.single.id, 'offer-1');
    expect(update.negotiations?.single.status.name, 'closed');
    expect(update.chat?.status, ChatStatus.closed);
  });

  test('rejects payloads without eventId or v=1', () {
    expect(
      WorkflowUpdate.tryParse({
        'v': 1,
        'reason': 'BOOKING_STATUS_CHANGED',
        'actorId': 'user-1',
      }),
      isNull,
    );
    expect(
      WorkflowUpdate.tryParse({
        'v': 2,
        'eventId': 'evt-1',
        'reason': 'BOOKING_STATUS_CHANGED',
        'actorId': 'user-1',
      }),
      isNull,
    );
  });

  test('keeps payload when optional entities are missing', () {
    final update = WorkflowUpdate.tryParse({
      'v': 1,
      'eventId': 'evt-2',
      'reason': 'REVIEW_CREATED',
      'actorId': 'user-2',
      'chatId': null,
    });

    expect(update, isNotNull);
    expect(update!.chatId, isNull);
    expect(update.booking, isNull);
    expect(update.review, isNull);
  });
}
