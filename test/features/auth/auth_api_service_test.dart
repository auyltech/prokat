import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'message': 'Login successful',
        'sessionToken': 'session-token',
        'expires': '2099-01-01T00:00:00.000Z',
        'user': {
          'id': 'user-1',
          'phoneNumber': '+77011234567',
          'role': 'CLIENT',
        },
        'isNewUser': true,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;
  late AuthApiService api;

  setUp(() {
    adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    api = AuthApiService(dio);
  });

  test('verifyOtp includes exact attribution object when present', () async {
    final attribution = <String, Object?>{
      'shareId': 'AbCdEfGhIjKlMnOpQr_-12',
      'equipmentId': 'eq-1',
      'openVia': 'INSTALL_REFERRER',
      'firstShareBootstrapRun': true,
      'firstTouchAt': '2026-10-06T12:00:00.000Z',
    };

    final result = await api.verifyOtp(
      '+77011234567',
      '000000',
      attribution: attribution,
    );

    expect(result.success, isTrue);
    expect(adapter.requests.single.data, {
      'phoneNumber': '+77011234567',
      'otp': '000000',
      'attribution': attribution,
    });
  });

  test('verifyOtp omits attribution key when absent', () async {
    final result = await api.verifyOtp('+77011234567', '000000');

    expect(result.success, isTrue);
    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body, {'phoneNumber': '+77011234567', 'otp': '000000'});
    expect(body.containsKey('attribution'), isFalse);
  });
}
