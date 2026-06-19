import 'package:dio/dio.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

class ApiInterceptor extends Interceptor {
  final AuthSecureStorage secureStorage;
  final void Function() onUnauthorized;

  DateTime? _lastUnauthorizedAt;

  ApiInterceptor(this.secureStorage, {required this.onUnauthorized});

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

      handler.next(options);
    } catch (_) {
      handler.next(options);
    }
  }

  /// Handle successful responses
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  /// Global error handler
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    /// Session expired
    if (statusCode == 401) {
      // message = "Dio Error: session expired";

      await secureStorage.clearSession();

      final now = DateTime.now();
      final last = _lastUnauthorizedAt;
      if (last == null || now.difference(last) > const Duration(seconds: 1)) {
        _lastUnauthorizedAt = now;
        onUnauthorized();
      }
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
}
