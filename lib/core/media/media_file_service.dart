import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

class MediaHttpFileService implements FileService {
  MediaHttpFileService({
    required this.secureStorage,
    required this.requestMetadata,
    required this.namespace,
    required this.resolveNamespace,
    FileService? inner,
  }) : _inner = inner ?? HttpFileService();

  final AuthSecureStorage secureStorage;
  final ClientRequestMetadataService requestMetadata;
  final String namespace;
  final Future<String> Function() resolveNamespace;
  final FileService _inner;

  @override
  int concurrentFetches = 10;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final startedNamespace = await resolveNamespace();
    if (startedNamespace != namespace) {
      throw StateError('media cache namespace changed');
    }

    final session = await secureStorage.readSession();
    final requestHeaders = <String, String>{
      ...?headers,
      ...await requestMetadata.headers(),
    };

    final token = session?.sessionToken?.trim();
    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await _inner.get(url, headers: requestHeaders);

    final finishedNamespace = await resolveNamespace();
    if (finishedNamespace != namespace) {
      throw StateError('media cache namespace changed');
    }

    return response;
  }
}

String mediaCacheNamespace(AuthSession? session) {
  final token = session?.sessionToken?.trim();
  final userId = session?.user?.id?.trim();
  if (token == null || token.isEmpty) {
    return 'guest';
  }
  if (userId == null || userId.isEmpty) {
    return 'user:unknown';
  }
  return 'user:$userId';
}
