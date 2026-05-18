import 'package:dio/dio.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

class ApiInterceptor extends Interceptor {
  final AuthSecureStorage secureStorage;

  ApiInterceptor(this.secureStorage);

  /// Attach auth token
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final session = await secureStorage.readSession();

      if (session != null) {
        final token = session.sessionToken;

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
    // final data = err.response?.data;

    /// Extract backend error message
    // String message = "Dio Error: Something went wrong";

    // if (data is Map && data["message"] != null) {
    //   message = data["message"];
    // } else if (statusCode == 500) {
    //   message = "Server error";
    // } else if (err.type == DioExceptionType.connectionTimeout ||
    //     err.type == DioExceptionType.receiveTimeout) {
    //   message = "Connection timeout";
    // } else if (err.type == DioExceptionType.connectionError) {
    //   message = "Network error";
    // }

    /// Session expired
    if (statusCode == 401) {
      // message = "Dio Error: session expired";

      await secureStorage.clearSession();
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

String extractBackendMessage(DioException e) {
  final data = e.response?.data;

  if (data is Map<String, dynamic>) {
    final message = data['message'] ?? data['error'] ?? data['detail'];

    if (message is List) {
      return message.join(', ');
    }

  if (responseData is Map<String, dynamic>) {
    if (responseData["message"] is String) return responseData["message"];
    if (responseData["error"] is String) return responseData["error"];

    if (responseData["errors"] is Map) {
      final errors = responseData["errors"] as Map;
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    if (message != null) {
      return message.toString();
    }
  }

  if (responseData is String) return responseData;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return "Connection timeout";

    case DioExceptionType.connectionError:
      return "Network error";

    default:
      return "Request failed";
  }
}
