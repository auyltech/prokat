import 'dart:async';

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

  test('flags unauthorized handshake messages for Crashlytics', () {
    const error = SocketConnectException(
      message: 'Not authorized',
      hasToken: true,
      tokenLength: 32,
      sessionExpiredOnClient: false,
      socketUrl: 'https://example.com',
      userId: 'user-1',
    );

    expect(error.isUnauthorized, isTrue);
    expect(error.shouldReportToCrashlytics, isTrue);
    expect(error.isExpectedDisconnect, isFalse);
    expect(error.crashlyticsKeys['socket_unauthorized'], 'true');
    expect(error.crashlyticsKeys['socket_user_id'], 'user-1');
    expect(error.toString(), 'SocketConnectException: Not authorized');
  });

  test('treats timeout and cancel as expected, not Crashlytics', () {
    final timeout = SocketConnectException(
      message: 'Socket connection timed out',
      cause: TimeoutException('Socket connection timed out'),
      hasToken: true,
      tokenLength: 16,
      sessionExpiredOnClient: false,
      socketUrl: 'https://example.com',
    );
    const cancelled = SocketConnectException(
      message: 'Socket connection cancelled',
      hasToken: true,
      tokenLength: 0,
      sessionExpiredOnClient: false,
      socketUrl: 'https://example.com',
    );

    expect(timeout.isTimeout, isTrue);
    expect(timeout.isExpectedDisconnect, isTrue);
    expect(timeout.shouldReportToCrashlytics, isFalse);

    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.isExpectedDisconnect, isTrue);
    expect(cancelled.shouldReportToCrashlytics, isFalse);
  });

  test('messageFrom keeps TimeoutException text', () {
    expect(
      SocketConnectException.messageFrom(
        TimeoutException('Socket connection timed out'),
      ),
      'Socket connection timed out',
    );
  });
}
