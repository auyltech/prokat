import 'package:dio/dio.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'api_response.dart';

String extractBackendMessage(
  dynamic data, {
  String fallback = "Something went wrong",
}) {
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

String extractDioExceptionMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return "Connection timeout";

    case DioExceptionType.connectionError:
      return "Network error";

    case DioExceptionType.cancel:
      return "Request cancelled";

    case DioExceptionType.badCertificate:
      return "Security certificate error";

    case DioExceptionType.badResponse:
      return extractBackendMessage(e.response?.data);

    case DioExceptionType.unknown:
      return "Request failed";
  }
}

ApiResponse<T> handleApiResponse<T>({
  required Response response,
  required T Function(dynamic data) parser,
  String fallbackMessage = "Request failed",
}) {
  final statusCode = response.statusCode ?? 0;
  final responseData = response.data;

  final isSuccess = statusCode >= 200 && statusCode < 300;

  if (!isSuccess) {
    return ApiResponse.failure(
      message: extractBackendMessage(responseData, fallback: fallbackMessage),
      error: responseData,
      statusCode: statusCode,
    );
  }

  try {
    final rawData = responseData is Map && responseData.containsKey("data")
        ? responseData["data"]
        : responseData;

    final parsedData = parser(rawData);

    return ApiResponse.success(
      parsedData,
      message: extractBackendMessage(responseData, fallback: "Success"),
      statusCode: statusCode,
    );
  } catch (e) {
    return ApiResponse.failure(
      message: "Format error occurred. Please update the application.",
      error: e, // Retained under-the-hood for dev logging metrics
      statusCode: statusCode,
    );
  }
}

ApiResponse<void> handleEmptyApiResponse({
  required Response response,
  String fallbackMessage = "Request completed",
}) {
  final statusCode = response.statusCode ?? 0;
  final responseData = response.data;

  final isSuccess = statusCode >= 200 && statusCode < 300;

  if (!isSuccess) {
    return ApiResponse.failure(
      message: extractBackendMessage(responseData, fallback: fallbackMessage),
      error: responseData["error"],
      statusCode: statusCode,
    );
  }

  return ApiResponse.success(
    null,
    message: extractBackendMessage(responseData, fallback: fallbackMessage),
    statusCode: statusCode,
  );
}

ApiResponse<T> handleDioException<T>(
  DioException error, {
  String fallbackMessage = "Request failed",
}) {
  final exception = ApiException.fromDio(error);

  return ApiResponse.failure(
    message: exception.message.isNotEmpty ? exception.message : fallbackMessage,
    error: exception.data ?? error,
    statusCode: exception.statusCode,
  );
}

ApiResponse<T> handleUnknownException<T>(
  Object error, {
  String fallbackMessage = "Unexpected error",
}) {
  return ApiResponse.failure(message: fallbackMessage, error: error);
}
