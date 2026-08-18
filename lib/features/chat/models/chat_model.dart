import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/requests/models/request_model.dart';

enum ChatType { direct, support, workflow, announcement }

enum ChatStatus { active, closed, archived }

ChatType parseChatType(dynamic value) {
  if (value == null) return ChatType.direct;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in ChatType.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }
  return ChatType.direct;
}

ChatStatus parseChatStatus(dynamic value) {
  if (value == null) return ChatStatus.active;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in ChatStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }
  return ChatStatus.active;
}

class ChatModel {
  final String id;
  final ChatType type;
  final ChatStatus status;

  final UserModel? client;
  final UserModel? owner;

  final String? bookingId;
  final BookingModel? booking;
  final BookingSummaryModel? bookingSummary;

  final String? requestId;
  final RequestModel? request;
  final List<OfferModel> offers;

  final ChatMessageModel? lastMessage;
  final List<ChatMessageModel> messages;
  final int? newMessagesCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatModel({
    required this.id,
    this.type = ChatType.direct,
    this.status = ChatStatus.active,
    this.bookingId,
    this.requestId,
    this.booking,
    this.bookingSummary,
    this.request,
    this.offers = const [],
    this.client,
    this.owner,
    this.messages = const [],
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
    this.newMessagesCount,
  });

  String displayTitle(String currentUserId) {
    return _counterpart(currentUserId)?.displayName ??
        (currentUserId == client?.id ? "Owner" : "Client");
  }

  String? displayImageUrl({String? currentUserId}) {
    final counterpart = _counterpart(currentUserId);
    if (counterpart != null) {
      return _nonEmpty(counterpart.imageUrl);
    }

    return _nonEmpty(client?.imageUrl) ?? _nonEmpty(owner?.imageUrl);
  }

  UserModel? _counterpart(String? currentUserId) {
    if (currentUserId != null && currentUserId == client?.id) {
      return owner;
    }
    if (currentUserId != null && currentUserId == owner?.id) {
      return client;
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  OfferModel? getActiveOffer() {
    return offers
        .where(
          (item) =>
              item.status == OfferStatus.created ||
              item.status == OfferStatus.viewed,
        )
        .firstOrNull;
  }

  ChatModel copyWith({
    String? id,
    ChatType? type,
    ChatStatus? status,
    UserModel? client,
    UserModel? owner,
    String? bookingId,
    BookingModel? booking,
    BookingSummaryModel? bookingSummary,
    String? requestId,
    RequestModel? request,
    List<OfferModel>? offers,
    ChatMessageModel? lastMessage,
    List<ChatMessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? newMessagesCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      client: client ?? this.client,
      owner: owner ?? this.owner,
      bookingId: bookingId ?? this.bookingId,
      booking: booking ?? this.booking,
      bookingSummary: bookingSummary ?? this.bookingSummary,
      requestId: requestId ?? this.requestId,
      request: request ?? this.request,
      offers: offers ?? this.offers,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      newMessagesCount: newMessagesCount ?? this.newMessagesCount,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    try {
      return ChatModel(
        id: json['id']?.toString() ?? "",
        type: parseChatType(json['type']),
        status: parseChatStatus(json['status']),

        client: json['client'] != null
            ? UserModel.fromJson(json['client'])
            : null,
        owner: json['owner'] != null ? UserModel.fromJson(json['owner']) : null,

        bookingId: json['bookingId']?.toString() ?? "",
        booking: json['booking'] == null
            ? null
            : BookingModel.fromJson(json['booking']),

        bookingSummary: json['bookingSummary'] != null
            ? BookingSummaryModel.fromJson(json['bookingSummary'])
            : null,

        requestId: json['requestId']?.toString(),
        request: json['request'] == null
            ? null
            : RequestModel.fromJson(json['request']),

        offers: (json["offers"] as List<dynamic>? ?? [])
            .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
            .toList(),

        lastMessage: _parseMessage(json['lastMessage']),
        messages: (json["messages"] as List<dynamic>? ?? [])
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        newMessagesCount: parseNullableInt(json["newMessagesCount"]),

        createdAt: _parseDate(json["createdAt"]),
        updatedAt: _parseDate(json["updatedAt"]),
      );
    } catch (e) {
      rethrow;
    }
  }

  static ChatMessageModel? _parseMessage(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(value);
    }

    if (value is Map) {
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(value));
    }

    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
