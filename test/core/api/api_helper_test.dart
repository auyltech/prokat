import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_helper.dart';

void main() {
  group('parseRetryAfter', () {
    final now = DateTime.utc(2026, 8, 3, 10);

    test('parses delta seconds', () {
      expect(
        parseRetryAfter('45', now: now),
        now.add(const Duration(seconds: 45)),
      );
    });

    test('parses an HTTP date', () {
      final parsed = parseRetryAfter('Mon, 03 Aug 2026 10:01:00 GMT', now: now);

      expect(parsed?.toUtc(), DateTime.utc(2026, 8, 3, 10, 1));
    });

    test('clamps a past date to now', () {
      expect(parseRetryAfter('Mon, 03 Aug 2026 09:59:00 GMT', now: now), now);
    });

    test('returns null for missing or malformed values', () {
      expect(parseRetryAfter(null, now: now), isNull);
      expect(parseRetryAfter('not-a-date', now: now), isNull);
    });
  });

  test('extractRetryAt prefers Retry-After over response body', () {
    final now = DateTime.utc(2026, 8, 3, 10);
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/otp'),
      data: {'resendAfterSeconds': 60},
      headers: Headers.fromMap({
        'retry-after': ['30'],
      }),
    );

    expect(
      extractRetryAt(response, now: now),
      now.add(const Duration(seconds: 30)),
    );
  });

  test('extractRetryAt prefers error retry seconds over Retry-After', () {
    final now = DateTime.utc(2026, 8, 3, 10);
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/otp'),
      data: {'retryAfterSeconds': 45},
      headers: Headers.fromMap({
        'retry-after': ['3600'],
      }),
    );

    expect(
      extractRetryAt(response, now: now),
      now.add(const Duration(seconds: 45)),
    );
  });

  test('handleDioException retains error code and retry cooldown', () {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/otp'),
      statusCode: 429,
      data: {
        'code': 'RATE_LIMITED',
        'message': 'Please try again later',
        'retryAfterSeconds': 75,
      },
    );
    final error = DioException.badResponse(
      statusCode: 429,
      requestOptions: response.requestOptions,
      response: response,
    );

    final before = DateTime.now();
    final result = handleDioException<void>(error);

    expect(result.errorCode, 'RATE_LIMITED');
    expect(
      result.retryAt!.difference(before).inSeconds,
      inInclusiveRange(74, 75),
    );
  });

  test('handleEmptyApiResponse extracts code and resend cooldown', () {
    final before = DateTime.now();
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/otp'),
      statusCode: 202,
      data: {'code': 'OTP_ACCEPTED', 'resendAfterSeconds': 60},
    );

    final result = handleEmptyApiResponse(response: response);

    expect(result.success, isTrue);
    expect(result.errorCode, 'OTP_ACCEPTED');
    expect(
      result.retryAt!.difference(before).inSeconds,
      inInclusiveRange(59, 60),
    );
  });

  test('extractBackendCode reads fail() error codes', () {
    expect(
      extractBackendCode({
        'success': false,
        'error': 'NOT_FOUND:OFFERS:CREATE',
        'message': 'Request not found',
      }),
      'NOT_FOUND:OFFERS:CREATE',
    );
  });

  test('extractBackendCode reads nested AppError code', () {
    expect(
      extractBackendCode({
        'success': false,
        'error': {
          'code': 'CONFLICT:OWNER:STATUS:BALANCE',
          'message': 'Cannot go online with zero balance',
        },
      }),
      'CONFLICT:OWNER:STATUS:BALANCE',
    );
  });

  test('extractBackendCode prefers code over error', () {
    expect(
      extractBackendCode({
        'code': 'RATE_LIMITED',
        'error': 'NOT_FOUND:OFFERS:CREATE',
      }),
      'RATE_LIMITED',
    );
  });

  test('handleEmptyApiResponse extracts fail() envelope error code', () {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/offers'),
      statusCode: 404,
      data: {
        'success': false,
        'count': 0,
        'error': 'NOT_FOUND:OFFERS:CREATE',
        'message': 'Request not found',
      },
    );

    final result = handleEmptyApiResponse(response: response);

    expect(result.success, isFalse);
    expect(result.errorCode, 'NOT_FOUND:OFFERS:CREATE');
    expect(result.message, 'Request not found');
  });
}
