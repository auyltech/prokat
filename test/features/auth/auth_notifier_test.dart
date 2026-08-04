import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) respond;

  _StubAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

Dio _stubDio(
  int statusCode,
  Map<String, dynamic> body, {
  Map<String, List<String>> headers = const {},
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 600,
    ),
  );
  dio.httpClientAdapter = _StubAdapter(
    (_) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    ),
  );
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('successful request persists backend resend cooldown', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(202, {'code': 'OTP_ACCEPTED', 'resendAfterSeconds': 90}),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isTrue);
    expect(state.otpPhone, '+77001234567');
    expect(state.otpCooldownPhone, '+77001234567');
    expect(
      state.otpRetryAt!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(88, 90),
    );
  });

  test('429 remains before OTP state and uses Retry-After', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(
            429,
            {'code': 'RATE_LIMITED', 'message': 'Please try again later'},
            headers: {
              'retry-after': ['45'],
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isFalse);
    expect(state.otpPhone, isNull);
    expect(state.errorCode, 'RATE_LIMITED');
    expect(state.otpCooldownPhone, '+77001234567');
    expect(
      state.otpRetryAt!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(43, 45),
    );
  });

  test('error body retryAfterSeconds updates the cooldown state', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(429, {
            'code': 'RATE_LIMITED',
            'message': 'Please try again later',
            'retryAfterSeconds': 75,
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isFalse);
    expect(state.otpPhone, isNull);
    expect(state.otpCooldownPhone, '+77001234567');
    expect(
      state.otpRetryAt!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(73, 75),
    );
  });

  test('409 does not create an OTP session', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(409, {'code': 'OTP_ALREADY_ACTIVE', 'message': 'Conflict'}),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isFalse);
    expect(state.otpPhone, isNull);
    expect(state.otpRequestedAt, isNull);
    expect(state.errorCode, 'OTP_ALREADY_ACTIVE');
  });
}
