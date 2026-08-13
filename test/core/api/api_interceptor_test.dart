import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/services/installation_identity_service.dart';
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

class _TrackingAuthSecureStorage extends AuthSecureStorage {
  int clearCalls = 0;

  @override
  Future<void> clearSession() async {
    clearCalls++;
  }
}
