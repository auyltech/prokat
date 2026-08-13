import 'package:dio/dio.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

class ApiInterceptor extends Interceptor {
  final AuthSecureStorage secureStorage;
  final ClientRequestMetadataService requestMetadata;
  final void Function() onUnauthorized;

  DateTime? _lastUnauthorizedAt;

  ApiInterceptor(
    this.secureStorage, {
    required this.requestMetadata,
    required this.onUnauthorized,
  });

  /// Attach auth token
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final session = await secureStorage.readSession();

      if (session != null &&
          session.sessionToken != null &&
          session.sessionToken!.trim().isNotEmpty &&
          !session.isExpired) {
        final token = session.sessionToken!.trim();
        options.headers["Authorization"] = "Bearer $token";
      }

      options.headers.putIfAbsent("Content-Type", () => "application/json");
      options.headers.putIfAbsent("Accept", () => "application/json");

      final identityHeaders = await requestMetadata.headers();
      for (final entry in identityHeaders.entries) {
        options.headers.putIfAbsent(entry.key, () => entry.value);
      }

      handler.next(options);
    } catch (_) {
      handler.next(options);
    }
  }

  /// Handle successful responses
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 401) {
      _signalUnauthorized();
    }

    handler.next(response);
  }

  /// Global error handler
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    /// Session expired
    if (statusCode == 401) {
      _signalUnauthorized();
    }

    handler.next(err);
    // handler.reject(
    //   DioException(
    //     requestOptions: err.requestOptions,
    //     response: err.response,
    //     type: err.type,
    //     error: message,
    //   ),
    // );
  }

  void _signalUnauthorized() {
    final now = DateTime.now();
    final last = _lastUnauthorizedAt;
    if (last == null || now.difference(last) > const Duration(seconds: 1)) {
      _lastUnauthorizedAt = now;
      onUnauthorized();
    }
  }
}
