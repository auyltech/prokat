import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/services/installation_identity_service.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/equipment_share/equipment_share_resolver.dart';

const _token = 'AbCdEfGhIjKlMnOpQr_-12';

class _AuthStorage extends AuthSecureStorage {
  _AuthStorage(this.authenticated);
  final bool authenticated;
  @override
  Future<AuthSession?> readSession() async =>
      authenticated ? const AuthSession(sessionToken: 'test-only-token') : null;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final Future<ResponseBody> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late EquipmentShareResolver resolver;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
    resolver = EquipmentShareResolver(dio);
  });
  tearDown(() => dio.close(force: true));

  for (final authenticated in [false, true]) {
    test(
      'real mobile interceptor preserves App Check/install headers (${authenticated ? 'authenticated' : 'guest'})',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final adapter = _Adapter(
          (_) async => _json({
            'success': true,
            'data': {'shareId': _token, 'equipmentId': 'eq-1'},
          }),
        );
        dio.httpClientAdapter = adapter;
        dio.interceptors.add(
          ApiInterceptor(
            _AuthStorage(authenticated),
            requestMetadata: ClientRequestMetadataService(
              installationIdentity: InstallationIdentityService(
                isSupportedPlatform: () => true,
              ),
              loadPackageInfo: () async => PackageInfo(
                appName: 'Test',
                packageName: 'test.prokat',
                version: '1.0.0',
                buildNumber: '1',
              ),
              loadAppCheckToken: () async => 'test-only-app-check',
              platformName: () => 'android',
            ),
            onUnauthorized: () => fail('unexpected unauthorized signal'),
          ),
        );
        expect(
          (await resolver.resolve(_token)).status,
          ShareResolutionStatus.resolved,
        );
        final headers = adapter.requests.single.headers;
        expect(
          headers['Authorization'],
          authenticated ? 'Bearer test-only-token' : isNull,
        );
        expect(headers['X-Firebase-AppCheck'], 'test-only-app-check');
        expect(headers['X-Client-Platform'], 'android');
        expect(
          headers['X-Installation-ID'],
          matches(RegExp(r'^[a-f0-9-]{36}$')),
        );
        expect(headers['X-App-Version'], '1.0.0');
      },
    );
  }

  testWidgets('overall timeout bounds a stalled request without real waits', (
    tester,
  ) async {
    final response = Completer<ResponseBody>();
    final adapter = _Adapter((_) => response.future);
    dio.httpClientAdapter = adapter;
    final request = resolver.resolve(_token);
    for (var i = 0; i < 10 && adapter.requests.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(adapter.requests, hasLength(1));
    await tester.pump(const Duration(seconds: 11));
    expect((await request).status, ShareResolutionStatus.temporary);
    response.complete(_json(null));
    await tester.pump();
  });

  test('uses existing mobile Dio and validates the matching mapping', () async {
    final adapter = _Adapter(
      (_) async => _json({
        'success': true,
        'data': {'shareId': _token, 'equipmentId': 'eq-1'},
      }),
    );
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll({
            'Authorization': 'test-only-token',
            'X-Firebase-AppCheck': 'test-only-app-check',
            'X-Installation-Id': 'test-only-installation',
          });
          handler.next(options);
        },
      ),
    );
    final result = await resolver.resolve(_token);
    expect(result.status, ShareResolutionStatus.resolved);
    expect(result.equipmentId, 'eq-1');
    final request = adapter.requests.single;
    expect(request.path, '/equipment-shares/resolve/$_token');
    expect(request.method, 'GET');
    expect(request.headers['Authorization'], 'test-only-token');
    expect(request.headers['X-Firebase-AppCheck'], 'test-only-app-check');
    expect(request.headers['X-Installation-Id'], 'test-only-installation');
    expect(request.followRedirects, isFalse);
    expect(request.receiveTimeout, const Duration(seconds: 8));
    expect(request.sendTimeout, const Duration(seconds: 8));
  });

  test('invalid token never makes a request', () async {
    final adapter = _Adapter((_) async => _json(null));
    dio.httpClientAdapter = adapter;
    expect(
      (await resolver.resolve('../invalid')).status,
      ShareResolutionStatus.invalid,
    );
    expect(adapter.requests, isEmpty);
  });

  for (final status in [404, 429, 500, 503, 401, 403, 302]) {
    test(
      'HTTP $status is safely classified without exposing response',
      () async {
        dio.httpClientAdapter = _Adapter(
          (_) async => _json({'error': 'private server details'}, status),
        );
        final result = await resolver.resolve(_token);
        expect(
          result.status,
          status == 404
              ? ShareResolutionStatus.unavailable
              : ShareResolutionStatus.temporary,
        );
        expect(result.equipmentId, isNull);
      },
    );
  }

  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  ]) {
    test('$type is retryable, without raw exceptions', () async {
      dio.httpClientAdapter = _Adapter((options) async {
        throw DioException(
          requestOptions: options,
          type: type,
          message: 'private transport details',
        );
      });
      expect(
        (await resolver.resolve(_token)).status,
        ShareResolutionStatus.temporary,
      );
    });
  }

  final malformed = <Object?>[
    null,
    [],
    {'success': false},
    {'success': true, 'data': null},
    {
      'success': true,
      'data': {'shareId': 'other', 'equipmentId': 'eq-1'},
    },
    {
      'success': true,
      'data': {'shareId': _token, 'equipmentId': 3},
    },
    {
      'success': true,
      'data': {'shareId': _token, 'equipmentId': '../private'},
    },
    {
      'success': true,
      'data': {'shareId': _token, 'equipmentId': ''},
    },
  ];
  for (var i = 0; i < malformed.length; i++) {
    test('malformed payload $i does not become routing data', () async {
      dio.httpClientAdapter = _Adapter((_) async => _json(malformed[i]));
      final result = await resolver.resolve(_token);
      expect(result.status, ShareResolutionStatus.temporary);
      expect(result.equipmentId, isNull);
    });
  }
}
