import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class ChatModel {
  final String id;

  final User? client;
  final User? owner;

  final String? bookingId;
  final BookingModel? booking;
  final BookingSummaryModel? bookingSummary;

  final String? requestId;
  final RequestModel? request;

  final ChatMessageModel? lastMessage;
  final List<ChatMessageModel> messages;
  final int? newMessagesCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatModel({
    required this.id,
    this.bookingId,
    this.requestId,
    this.booking,
    this.bookingSummary,
    this.request,
    this.client,
    this.owner,
    this.messages = const [],
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
    this.newMessagesCount,
  });

  String displayTitle(String currentUserId) {
    return (currentUserId == client?.id
            ? owner?.displayName
            : client?.displayName) ??
        "";
  }

  String? displayImageUrl({String? currentUserId}) {
    return client?.imageUrl ?? owner?.imageUrl;
  }

  ChatModel copyWith({
    String? id,
    User? client,
    User? owner,
    String? bookingId,
    BookingModel? booking,
    BookingSummaryModel? bookingSummary,
    String? requestId,
    RequestModel? request,
    ChatMessageModel? lastMessage,
    List<ChatMessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      client: client ?? this.client,
      owner: owner ?? this.owner,
      bookingId: bookingId ?? this.bookingId,
      booking: booking ?? this.booking,
      bookingSummary: bookingSummary ?? this.bookingSummary,
      requestId: requestId ?? this.requestId,
      request: request ?? this.request,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    try {
      return ChatModel(
        id: json['id']?.toString() ?? "",

        client: json['client'] != null ? User.fromJson(json['client']) : null,
        owner: json['owner'] != null ? User.fromJson(json['owner']) : null,

        bookingId: json['bookingId']?.toString() ?? "",
        booking: json['booking'] != null
            ? BookingModel.fromJson(json['booking'])
            : null,
        bookingSummary: json['bookingSummary'] != null
            ? BookingSummaryModel.fromJson(json['bookingSummary'])
            : null,

        requestId: json['requestId']?.toString(),
        request: json['request'] != null
            ? RequestModel.fromJson(json['request'])
            : null,

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
