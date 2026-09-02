/// Handshake / connect failure for the app Socket.IO client.
class SocketConnectException implements Exception {
  final String message;
  final Object? cause;
  final bool hasToken;
  final int tokenLength;
  final bool sessionExpiredOnClient;
  final String socketUrl;
  final String? userId;

  const SocketConnectException({
    required this.message,
    required this.hasToken,
    required this.tokenLength,
    required this.sessionExpiredOnClient,
    required this.socketUrl,
    this.cause,
    this.userId,
  });

  bool get isUnauthorized {
    final lower = message.toLowerCase();
    return lower.contains('not authorized') || lower.contains('unauthorized');
  }

  Map<String, String> get crashlyticsKeys => {
    'socket_url': socketUrl,
    'socket_has_token': hasToken.toString(),
    'socket_token_length': tokenLength.toString(),
    'socket_session_expired_client': sessionExpiredOnClient.toString(),
    'socket_user_id': (userId ?? '').trim().isEmpty ? 'none' : userId!.trim(),
    'socket_unauthorized': isUnauthorized.toString(),
    'socket_error': message,
  };

  /// Socket.IO delivers `Error("Not authorized")` as a map, a string, or
  /// Dart's `{message: Not authorized}` from `toString()`.
  static String messageFrom(Object? error) {
    if (error == null) return 'unknown';
    if (error is SocketConnectException) return error.message;

    if (error is String) {
      final trimmed = error.trim();
      return trimmed.isEmpty ? 'unknown' : _unwrapMapMessage(trimmed);
    }

    if (error is Map) {
      final message = error['message'] ?? error['data'] ?? error['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return _unwrapMapMessage(error.toString());
  }

  static String _unwrapMapMessage(String text) {
    final match = RegExp(r"message:\s*([^,}]+)").firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return text;
  }

  @override
  String toString() => 'SocketConnectException: $message';
}
