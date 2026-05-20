import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Raw backend/debug data.
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  bool get isAuthError => statusCode == 401;

  static String extractMessage(dynamic data, String fallback) {
    if (data == null) return fallback;

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (data is Map) {
      final message = data["message"];
      final error = data["error"];
      final detail = data["detail"];
      final errors = data["errors"];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      if (message is List && message.isNotEmpty) {
        return message.join(", ");
      }

      if (error is List && error.isNotEmpty) {
        return error.join(", ");
      }

      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }

        if (firstError != null) {
          return firstError.toString();
        }
      }
    }

    return fallback;
  }

  @override
  String toString() {
    return "ApiException: $message (statusCode: $statusCode, data: $data)";
  }

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: "Connection timeout",
          data: error,
        );

      case DioExceptionType.connectionError:
        return ApiException.network(error);

      case DioExceptionType.badCertificate:
        return ApiException(
          message: "Security certificate error",
          data: error,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: "Request cancelled",
          data: error,
        );

      case DioExceptionType.badResponse:
        break;

      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? "Unknown network error",
          data: error,
        );
    }

    switch (statusCode) {
      case 400:
        return ApiException.badRequest(data);

      case 401:
        return ApiException.unauthorized(data);

      case 403:
        return ApiException.forbidden(data);

      case 404:
        return ApiException.notFound(data);

      case 409:
        return ApiException.conflict(data);

      case 422:
        return ApiException.validation(data);

      case 500:
      case 502:
      case 503:
        return ApiException.serverError(data, statusCode: statusCode);

      default:
        return ApiException(
          message: extractMessage(data, error.message ?? "Unknown error"),
          statusCode: statusCode,
          data: data,
        );
    }
  }

  factory ApiException.badRequest(dynamic data) {
    return ApiException(
      message: extractMessage(data, "Bad request"),
      statusCode: 400,
      data: data,
    );
  }

  factory ApiException.unauthorized(dynamic data) {
    return ApiException(
      message: extractMessage(data, "Unauthorized"),
      statusCode: 401,
      data: data,
    );
  }

  factory ApiException.forbidden(dynamic data) {
    return ApiException(
      message: extractMessage(data, "Forbidden"),
      statusCode: 403,
      data: data,
    );
  }

  factory ApiException.notFound(dynamic data) {
    return ApiException(
      message: extractMessage(data, "Resource not found"),
      statusCode: 404,
      data: data,
    );
  }

  factory ApiException.conflict(dynamic data) {
    return ApiException(
      message: extractMessage(data, "Conflict"),
      statusCode: 409,
      data: data,
    );
  }

  factory ApiException.validation(dynamic data) {
    return ApiException(
      message: extractMessage(data, "Validation error"),
      statusCode: 422,
      data: data,
    );
  }

  factory ApiException.serverError(dynamic data, {int? statusCode}) {
    return ApiException(
      message: extractMessage(data, "Server error"),
      statusCode: statusCode ?? 500,
      data: data,
    );
  }

  factory ApiException.network([dynamic error]) {
    return ApiException(
      message: "Network error. Please check your connection.",
      data: error,
    );
  }
}