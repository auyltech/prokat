import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/requests/models/request_status.dart';

class WorkflowBookingDelta {
  final String id;
  final BookingStatus status;
  final WorkStatus workStatus;
  final int price;
  final PriceRateOption priceRate;
  final DateTime updatedAt;

  const WorkflowBookingDelta({
    required this.id,
    required this.status,
    required this.workStatus,
    required this.price,
    required this.priceRate,
    required this.updatedAt,
  });
}

class WorkflowRequestDelta {
  final String id;
  final RequestStatus status;
  final DateTime updatedAt;

  const WorkflowRequestDelta({
    required this.id,
    required this.status,
    required this.updatedAt,
  });
}

class WorkflowOfferDelta {
  final String id;
  final OfferStatus status;
  final DateTime updatedAt;

  const WorkflowOfferDelta({
    required this.id,
    required this.status,
    required this.updatedAt,
  });
}

class WorkflowNegotiationDelta {
  final String id;
  final PriceNegotiationStatus status;
  final int price;
  final PriceRateOption? priceRate;
  final DateTime updatedAt;

  const WorkflowNegotiationDelta({
    required this.id,
    required this.status,
    required this.price,
    required this.updatedAt,
    this.priceRate,
  });
}

class WorkflowReviewDelta {
  final String id;
  final String bookingId;
  final String reviewerId;

  const WorkflowReviewDelta({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
  });
}

class WorkflowChatDelta {
  final String id;
  final ChatStatus status;
  final DateTime updatedAt;

  const WorkflowChatDelta({
    required this.id,
    required this.status,
    required this.updatedAt,
  });
}

class WorkflowUpdate {
  final int v;
  final String eventId;
  final DateTime emittedAt;
  final String reason;
  final String actorId;
  final String? chatId;
  final WorkflowBookingDelta? booking;
  final WorkflowRequestDelta? request;
  final List<WorkflowOfferDelta>? offers;
  final List<WorkflowNegotiationDelta>? negotiations;
  final WorkflowReviewDelta? review;
  final WorkflowChatDelta? chat;

  const WorkflowUpdate({
    required this.v,
    required this.eventId,
    required this.emittedAt,
    required this.reason,
    required this.actorId,
    this.chatId,
    this.booking,
    this.request,
    this.offers,
    this.negotiations,
    this.review,
    this.chat,
  });

  static WorkflowUpdate? tryParse(dynamic payload) {
    final json = _asStringKeyedMap(payload);
    if (json == null) return null;

    final eventId = json['eventId']?.toString().trim() ?? '';
    if (eventId.isEmpty) return null;

    final v = parseNullableInt(json['v']) ?? 0;
    if (v != 1) return null;

    final reason = json['reason']?.toString().trim() ?? '';
    if (reason.isEmpty) return null;

    final actorId = json['actorId']?.toString().trim() ?? '';
    if (actorId.isEmpty) return null;

    final emittedAt = _parseDate(json['emittedAt']) ?? DateTime.now().toUtc();
    final chatId = json['chatId']?.toString().trim();

    return WorkflowUpdate(
      v: v,
      eventId: eventId,
      emittedAt: emittedAt,
      reason: reason,
      actorId: actorId,
      chatId: (chatId == null || chatId.isEmpty) ? null : chatId,
      booking: _parseBooking(json['booking']),
      request: _parseRequest(json['request']),
      offers: _parseOffers(json['offers']),
      negotiations: _parseNegotiations(json['negotiations']),
      review: _parseReview(json['review']),
      chat: _parseChat(json['chat']),
    );
  }

  static WorkflowBookingDelta? _parseBooking(dynamic value) {
    final json = _asStringKeyedMap(value);
    if (json == null) return null;

    final id = json['id']?.toString().trim() ?? '';
    final updatedAt = _parseDate(json['updatedAt']);
    if (id.isEmpty || updatedAt == null) return null;

    return WorkflowBookingDelta(
      id: id,
      status: parseBookingStatus(json['status']),
      workStatus: parseWorkStatus(json['workStatus']),
      price: (json['price'] as num?)?.toInt() ?? 0,
      priceRate: parseRateOption(json['priceRate']?.toString()),
      updatedAt: updatedAt,
    );
  }

  static WorkflowRequestDelta? _parseRequest(dynamic value) {
    final json = _asStringKeyedMap(value);
    if (json == null) return null;

    final id = json['id']?.toString().trim() ?? '';
    final updatedAt = _parseDate(json['updatedAt']);
    if (id.isEmpty || updatedAt == null) return null;

    return WorkflowRequestDelta(
      id: id,
      status: parseRequestStatus(json['status']),
      updatedAt: updatedAt,
    );
  }

  static List<WorkflowOfferDelta>? _parseOffers(dynamic value) {
    if (value is! List) return null;
    final items = <WorkflowOfferDelta>[];
    for (final item in value) {
      final json = _asStringKeyedMap(item);
      if (json == null) continue;
      final id = json['id']?.toString().trim() ?? '';
      final updatedAt = _parseDate(json['updatedAt']);
      if (id.isEmpty || updatedAt == null) continue;
      items.add(
        WorkflowOfferDelta(
          id: id,
          status: parseOfferStatus(json['status']),
          updatedAt: updatedAt,
        ),
      );
    }
    return items.isEmpty ? null : items;
  }

  static List<WorkflowNegotiationDelta>? _parseNegotiations(dynamic value) {
    if (value is! List) return null;
    final items = <WorkflowNegotiationDelta>[];
    for (final item in value) {
      final json = _asStringKeyedMap(item);
      if (json == null) continue;
      final id = json['id']?.toString().trim() ?? '';
      final updatedAt = _parseDate(json['updatedAt']);
      if (id.isEmpty || updatedAt == null) continue;
      items.add(
        WorkflowNegotiationDelta(
          id: id,
          status: parsePriceNegotiationStatus(json['status']?.toString()),
          price: (json['price'] as num?)?.toInt() ?? 0,
          priceRate: json['priceRate'] == null
              ? null
              : parseRateOption(json['priceRate']?.toString()),
          updatedAt: updatedAt,
        ),
      );
    }
    return items.isEmpty ? null : items;
  }

  static WorkflowReviewDelta? _parseReview(dynamic value) {
    final json = _asStringKeyedMap(value);
    if (json == null) return null;

    final id = json['id']?.toString().trim() ?? '';
    final bookingId = json['bookingId']?.toString().trim() ?? '';
    final reviewerId = json['reviewerId']?.toString().trim() ?? '';
    if (id.isEmpty || bookingId.isEmpty || reviewerId.isEmpty) return null;

    return WorkflowReviewDelta(
      id: id,
      bookingId: bookingId,
      reviewerId: reviewerId,
    );
  }

  static WorkflowChatDelta? _parseChat(dynamic value) {
    final json = _asStringKeyedMap(value);
    if (json == null) return null;

    final id = json['id']?.toString().trim() ?? '';
    final updatedAt = _parseDate(json['updatedAt']);
    if (id.isEmpty || updatedAt == null) return null;

    return WorkflowChatDelta(
      id: id,
      status: parseChatStatus(json['status']),
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toUtc();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
