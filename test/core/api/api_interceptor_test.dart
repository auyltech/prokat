import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/services/installation_identity_service.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('accepted 401 response emits one unauthorized signal', () async {
    var unauthorizedSignals = 0;
    final secureStorage = _TrackingAuthSecureStorage();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    dio.httpClientAdapter = _StubAdapter(
      statusCode: 401,
      body: const {'message': 'Unauthorized'},
    );
    dio.interceptors.add(
      ApiInterceptor(
        secureStorage,
        requestMetadata: _requestMetadata(),
        onUnauthorized: () => unauthorizedSignals++,
      ),
    );

    final response = await dio.get<dynamic>('/protected');

    expect(response.statusCode, 401);
    expect(unauthorizedSignals, 1);
    expect(secureStorage.clearCalls, 0);
  });

  test('concurrent accepted 401 responses emit one signal', () async {
    var unauthorizedSignals = 0;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    dio.httpClientAdapter = _StubAdapter(
      statusCode: 401,
      body: const {'message': 'Unauthorized'},
    );
    dio.interceptors.add(
      ApiInterceptor(
        _TrackingAuthSecureStorage(),
        requestMetadata: _requestMetadata(),
        onUnauthorized: () => unauthorizedSignals++,
      ),
    );

    await Future.wait<dynamic>([
      dio.get<dynamic>('/protected/one'),
      dio.get<dynamic>('/protected/two'),
    ]);

    expect(unauthorizedSignals, 1);
  });

  test('rejected 401 error uses the same unauthorized boundary', () async {
    var unauthorizedSignals = 0;
    final secureStorage = _TrackingAuthSecureStorage();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    dio.httpClientAdapter = _StubAdapter(
      statusCode: 401,
      body: const {'message': 'Unauthorized'},
    );
    dio.interceptors.add(
      ApiInterceptor(
        secureStorage,
        requestMetadata: _requestMetadata(),
        onUnauthorized: () => unauthorizedSignals++,
      ),
    );

    await expectLater(
      dio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(unauthorizedSignals, 1);
    expect(secureStorage.clearCalls, 0);
  });

  test('anonymous 401 does not emit an unauthorized signal', () async {
    var unauthorizedSignals = 0;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    dio.httpClientAdapter = _StubAdapter(
      statusCode: 401,
      body: const {'message': 'Authentication required'},
    );
    dio.interceptors.add(
      ApiInterceptor(
        _TrackingAuthSecureStorage(session: null),
        requestMetadata: _requestMetadata(),
        onUnauthorized: () => unauthorizedSignals++,
      ),
    );

    final response = await dio.get<dynamic>('/protected-without-session');

    expect(response.statusCode, 401);
    expect(response.requestOptions.headers['Authorization'], isNull);
    expect(unauthorizedSignals, 0);
  });

  test('late 401 from user A does not invalidate user B session', () async {
    var unauthorizedSignals = 0;
    final secureStorage = _TrackingAuthSecureStorage(
      session: const AuthSession(sessionToken: 'session-a'),
    );
    final adapter = _ControlledAdapter();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      ApiInterceptor(
        secureStorage,
        requestMetadata: _requestMetadata(),
        onUnauthorized: () => unauthorizedSignals++,
      ),
    );

    final responseFuture = dio.get<dynamic>('/protected-as-user-a');
    await adapter.requestStarted.future;
    secureStorage.session = const AuthSession(sessionToken: 'session-b');
    adapter.complete(statusCode: 401, body: const {'message': 'Unauthorized'});

    final response = await responseFuture;
    expect(
      response.requestOptions.headers['Authorization'],
      'Bearer session-a',
    );
    expect(response.statusCode, 401);
    expect(unauthorizedSignals, 0);
  });
}

ClientRequestMetadataService _requestMetadata() {
  return ClientRequestMetadataService(
    installationIdentity: InstallationIdentityService(
      isSupportedPlatform: () => false,
    ),
    loadPackageInfo: () async => PackageInfo(
      appName: 'Prokat Test',
      packageName: 'kz.prokat.test',
      version: '1.0.0',
      buildNumber: '1',
    ),
    loadAppCheckToken: () async => null,
    platformName: () => 'test',
  );
}

class _StubAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> body;

  _StubAdapter({required this.statusCode, required this.body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ControlledAdapter implements HttpClientAdapter {
  final requestStarted = Completer<void>();
  final _response = Completer<ResponseBody>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (!requestStarted.isCompleted) requestStarted.complete();
    return _response.future;
  }

  void complete({required int statusCode, required Map<String, dynamic> body}) {
    _response.complete(
      ResponseBody.fromString(
        jsonEncode(body),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TrackingAuthSecureStorage extends AuthSecureStorage {
  AuthSession? session;
  int clearCalls = 0;

  _TrackingAuthSecureStorage({
    this.session = const AuthSession(sessionToken: 'session-token'),
  });

  @override
  Future<AuthSession?> readSession() async => session;

  @override
  Future<void> clearSession() async {
    clearCalls++;
  }
}
