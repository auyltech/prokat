import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/media/media_file_service.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/services/installation_identity_service.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

void main() {
  test(
    'mediaCacheNamespace isolates guest, known users, and unknown users',
    () {
      expect(mediaCacheNamespace(null), 'guest');
      expect(mediaCacheNamespace(const AuthSession()), 'guest');
      expect(
        mediaCacheNamespace(const AuthSession(sessionToken: 'tok')),
        'user:unknown',
      );
      expect(
        mediaCacheNamespace(
          const AuthSession(
            sessionToken: 'tok',
            user: UserModel(id: 'user-1'),
          ),
        ),
        'user:user-1',
      );
    },
  );

  test('GET attaches the current Bearer and client metadata headers', () async {
    final inner = _RecordingFileService();
    final service = MediaHttpFileService(
      secureStorage: _SessionStorage(
        const AuthSession(
          sessionToken: 'session-token',
          user: UserModel(id: 'user-1'),
        ),
      ),
      requestMetadata: _metadataService(),
      namespace: 'user:user-1',
      resolveNamespace: () async => 'user:user-1',
      inner: inner,
    );

    await service.get('https://api.example/media/user-content/a.png');

    expect(inner.calls, 1);
    expect(inner.lastHeaders?['Authorization'], 'Bearer session-token');
    expect(inner.lastHeaders?['X-Client-Platform'], 'android');
    expect(inner.lastHeaders?['X-App-Version'], '1.0.7');
    expect(inner.lastHeaders?['X-Installation-ID'], isNotEmpty);
    expect(inner.lastHeaders?['X-Firebase-AppCheck'], 'app-check-token');
  });

  test('omits Authorization when the current session has no token', () async {
    final inner = _RecordingFileService();
    final service = MediaHttpFileService(
      secureStorage: _SessionStorage(null),
      requestMetadata: _metadataService(),
      namespace: 'guest',
      resolveNamespace: () async => 'guest',
      inner: inner,
    );

    await service.get('https://api.example/media/user-content/a.png');

    expect(inner.lastHeaders?.containsKey('Authorization'), isFalse);
    expect(inner.lastHeaders?['X-Client-Platform'], 'android');
  });

  test(
    'throws and does not fetch when the namespace already changed',
    () async {
      final inner = _RecordingFileService();
      final service = MediaHttpFileService(
        secureStorage: _SessionStorage(
          const AuthSession(sessionToken: 'session-token'),
        ),
        requestMetadata: _metadataService(),
        namespace: 'user:a',
        resolveNamespace: () async => 'user:b',
        inner: inner,
      );

      await expectLater(
        service.get('https://api.example/media/user-content/a.png'),
        throwsA(isA<StateError>()),
      );
      expect(inner.calls, 0);
    },
  );

  test('throws after GET if logout happens before bytes are stored', () async {
    final inner = _RecordingFileService();
    var namespace = 'user:a';
    final service = MediaHttpFileService(
      secureStorage: _SessionStorage(
        const AuthSession(
          sessionToken: 'session-token',
          user: UserModel(id: 'a'),
        ),
      ),
      requestMetadata: _metadataService(),
      namespace: 'user:a',
      resolveNamespace: () async => namespace,
      inner: inner,
    );

    inner.onGet = () {
      namespace = 'guest';
    };

    await expectLater(
      service.get('https://api.example/media/user-content/a.png'),
      throwsA(isA<StateError>()),
    );
    expect(inner.calls, 1);
  });
}

ClientRequestMetadataService _metadataService() {
  return ClientRequestMetadataService(
    installationIdentity: InstallationIdentityService(
      store: _MemoryInstallationIdStore(),
      isSupportedPlatform: () => true,
    ),
    platformName: () => 'android',
    loadPackageInfo: () async => PackageInfo(
      appName: 'PROKAT',
      packageName: 'com.auyltech.prokat',
      version: '1.0.7',
      buildNumber: '3',
    ),
    loadAppCheckToken: () async => 'app-check-token',
  );
}

class _SessionStorage extends AuthSecureStorage {
  _SessionStorage(this.session);

  AuthSession? session;

  @override
  Future<AuthSession?> readSession() async => session;
}

class _MemoryInstallationIdStore implements InstallationIdStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _RecordingFileService implements FileService {
  int calls = 0;
  Map<String, String>? lastHeaders;
  void Function()? onGet;

  @override
  int concurrentFetches = 10;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    calls++;
    lastHeaders = headers;
    onGet?.call();
    return _EmptyFileServiceResponse();
  }
}

class _EmptyFileServiceResponse implements FileServiceResponse {
  @override
  Stream<List<int>> get content => const Stream.empty();

  @override
  int get contentLength => 0;

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.png';

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));
}
