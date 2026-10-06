/// Server refused a message ack with a stable code (e.g. `USER_BLOCKED`).
class ChatSendRejected implements Exception {
  const ChatSendRejected(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ChatSendRejected($code): $message';
}
