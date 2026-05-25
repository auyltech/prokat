class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String? service;

  // sender not sent from backend
  final String? senderName;
  final String? senderAvatarUrl;
  final String? clientTempId;

  final String content;

  final bool isPending;
  final bool isFailed;

  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.senderName,
    this.senderAvatarUrl,
    this.type = 'TEXT',
    this.service,
    this.clientTempId,
    this.isPending = false,
    this.isFailed = false,
    this.createdAt,
  });

  ChatMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? message,
    String? type,
    String? service,
    String? clientTempId,
    bool? isPending,
    bool? isFailed,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: message ?? content,
      type: type ?? this.type,
      service: service ?? this.service,
      clientTempId: clientTempId ?? this.clientTempId,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderMap = sender is Map<String, dynamic>
        ? sender
        : sender is Map
        ? Map<String, dynamic>.from(sender)
        : null;

    return ChatMessageModel(
      id: json['id']?.toString() ?? json['messageId']?.toString() ?? '',
      chatId:
          json['chatId']?.toString() ??
          json['conversationId']?.toString() ??
          json['roomId']?.toString() ??
          '',
      senderId:
          json['senderId']?.toString() ??
          senderMap?['id']?.toString() ??
          senderMap?['userId']?.toString() ??
          '',
      senderName:
          json['senderName']?.toString() ??
          senderMap?['displayName']?.toString() ??
          senderMap?['username']?.toString(),
      senderAvatarUrl:
          json['senderAvatarUrl']?.toString() ??
          senderMap?['profileImageUrl']?.toString() ??
          senderMap?['avatarUrl']?.toString(),
      content:
          json['message']?.toString() ??
          json['content']?.toString() ??
          json['text']?.toString() ??
          '',
      type: json['type']?.toString() ?? 'TEXT',
      service: json['service']?.toString() ?? '',
      clientTempId: json['clientTempId']?.toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'type': type,
      'clientTempId': clientTempId,
      'isFailed': isFailed,
      'createdAt': createdAt?.toIso8601String(),
    };
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
