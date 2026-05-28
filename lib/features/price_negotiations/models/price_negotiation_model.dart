import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';

enum PriceNegotiationResponse { accept, reject }

class PriceNegotiation {
  final String id;
  final String? bookingId;
  final String? offerId;

  final String? senderId;
  final String? receiverId;

  final int price;
  final String? priceRate;
  final String? comment;

  final PriceNegotiationStatus status;

  final DateTime? createdAt;
  final DateTime? respondedAt;
  final DateTime? cancelledAt;

  const PriceNegotiation({
    required this.id,
    required this.price,
    required this.status,
    this.bookingId,
    this.offerId,
    this.senderId,
    this.receiverId,
    this.priceRate,
    this.comment,
    this.createdAt,
    this.respondedAt,
    this.cancelledAt,
  });

  bool get isPending => status == PriceNegotiationStatus.pending;

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  factory PriceNegotiation.fromJson(Map<String, dynamic> json) {
    int parsePrice(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PriceNegotiation(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
      offerId: json['offerId']?.toString(),
      senderId:
          json['senderId']?.toString() ??
          json['createdById']?.toString() ??
          json['fromUserId']?.toString(),
      receiverId:
          json['receiverId']?.toString() ?? json['toUserId']?.toString(),
      price: parsePrice(json['price']),
      priceRate: json['priceRate']?.toString(),
      comment: json['comment']?.toString(),
      status: parsePriceNegotiationStatus(json['status']?.toString()),
      createdAt: _tryParseDate(json['createdAt']),
      respondedAt: _tryParseDate(json['respondedAt']),
      cancelledAt: _tryParseDate(json['cancelledAt']),
    );
  }
}
