import 'package:prokat/features/notifications/models/notification_type.dart';

class AppNotification {
  final String id;
  final NotificationType type;
  final String category;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? route;
  final String? deepLink;
  final String? priority;
  final DateTime? readAt;
  final DateTime? seenAt;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.data,
    this.route,
    this.deepLink,
    this.priority,
    this.readAt,
    this.seenAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;
  bool get isUnread => !isRead;

  String? _dataString(String key) {
    final value = data[key];
    final stringified = value?.toString().trim();
    return (stringified ?? '').isEmpty ? null : stringified;
  }

  String? get bookingId => _dataString('bookingId');
  String? get chatId => _dataString('chatId');
  String? get equipmentId => _dataString('equipmentId');
  String? get requestId => _dataString('requestId');
  String? get offerId => _dataString('offerId');
  String? get reviewId => _dataString('reviewId');

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  static Map<String, dynamic> _parseData(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      type: NotificationTypeParser.parse(json['type']),
      category: (json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      data: _parseData(json['data']),
      route: json['route']?.toString(),
      deepLink: json['deepLink']?.toString(),
      priority: json['priority']?.toString(),
      readAt: _tryParseDate(json['readAt']),
      seenAt: _tryParseDate(json['seenAt']),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.backendName,
      'category': category,
      'title': title,
      'body': body,
      'data': data,
      'route': route,
      'deepLink': deepLink,
      'priority': priority,
      'readAt': readAt?.toIso8601String(),
      'seenAt': seenAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? category,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? route,
    String? deepLink,
    String? priority,
    DateTime? readAt,
    DateTime? seenAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      route: route ?? this.route,
      deepLink: deepLink ?? this.deepLink,
      priority: priority ?? this.priority,
      readAt: readAt ?? this.readAt,
      seenAt: seenAt ?? this.seenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
