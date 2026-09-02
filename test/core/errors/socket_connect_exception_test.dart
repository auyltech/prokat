import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/errors/socket_connect_exception.dart';

void main() {
  test('unwraps Socket.IO map and Exception dump to Not authorized', () {
    expect(
      SocketConnectException.messageFrom({'message': 'Not authorized'}),
      'Not authorized',
    );
    expect(
      SocketConnectException.messageFrom(
        'Exception: {message: Not authorized}',
      ),
      'Not authorized',
    );
    expect(
      SocketConnectException.messageFrom('{message: Not authorized}'),
      'Not authorized',
    );
    expect(
      SocketConnectException.messageFrom('Not authorized'),
      'Not authorized',
    );
  });

  test('flags unauthorized handshake messages', () {
    const error = SocketConnectException(
      message: 'Not authorized',
      hasToken: true,
      tokenLength: 32,
      sessionExpiredOnClient: false,
      socketUrl: 'https://example.com',
      userId: 'user-1',
    );

    expect(error.isUnauthorized, isTrue);
    expect(error.crashlyticsKeys['socket_unauthorized'], 'true');
    expect(error.crashlyticsKeys['socket_user_id'], 'user-1');
    expect(error.toString(), 'SocketConnectException: Not authorized');
  });
}
