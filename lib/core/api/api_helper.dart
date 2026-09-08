import 'package:dio/dio.dart';
import 'package:prokat/core/errors/api_exception.dart';

import 'api_response.dart';

String? extractBackendCode(dynamic data) {
  if (data is! Map) return null;

  final code = data['code'];
  if (code is String && code.trim().isNotEmpty) {
    return code.trim();
  }

  // Backend `fail()` puts the stable code in `error` (e.g. NOT_FOUND:OFFERS:CREATE).
  final error = data['error'];
  if (error is String) {
    final trimmed = error.trim();
    if (trimmed.isNotEmpty && !trimmed.contains(' ')) {
      return trimmed;
    }
  }

  // Error middleware wraps AppError as `{ error: { code, message, ... } }`.
  if (error is Map) {
    final nested = error['code'];
    if (nested is String && nested.trim().isNotEmpty) {
      return nested.trim();
    }
  }

  return null;
}

DateTime? parseRetryAfter(String? value, {DateTime? now}) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  final currentTime = now ?? DateTime.now();
  final seconds = int.tryParse(normalized);
  if (seconds != null) {
    return currentTime.add(Duration(seconds: seconds < 0 ? 0 : seconds));
  }

  final parsedIso = DateTime.tryParse(normalized);
  if (parsedIso != null) {
    final local = parsedIso.toLocal();
    return local.isBefore(currentTime) ? currentTime : local;
  }

  final match = RegExp(
    r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun), (\d{2}) '
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) '
    r'(\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
  ).firstMatch(normalized);
  if (match == null) return null;

  const months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  try {
    final parsed = DateTime.utc(
      int.parse(match.group(3)!),
      months[match.group(2)]!,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    ).toLocal();
    return parsed.isBefore(currentTime) ? currentTime : parsed;
  } catch (_) {
    return null;
  }
}

DateTime? extractRetryAt(Response response, {DateTime? now}) {
  final currentTime = now ?? DateTime.now();

  final data = response.data;
  if (data is Map) {
    // Error responses use retryAfterSeconds. Prefer it when present because it
    // describes the cooldown for the specific failed request.
    final retryAfterSeconds = _parsePositiveSeconds(data['retryAfterSeconds']);
    if (retryAfterSeconds != null) {
      return currentTime.add(Duration(seconds: retryAfterSeconds));
    }
  }

  final fromHeader = parseRetryAfter(
    response.headers.value('retry-after'),
    now: currentTime,
  );
  if (fromHeader != null) return fromHeader;

  if (data is! Map) return null;

  // Successful OTP requests use resendAfterSeconds.
  final seconds = _parsePositiveSeconds(data['resendAfterSeconds']);
  if (seconds == null) return null;

  return currentTime.add(Duration(seconds: seconds));
}

int? _extractListCount(dynamic data) {
  if (data is! Map) return null;
  final count = data['count'];
  if (count is num) return count.toInt();
  return int.tryParse(count?.toString() ?? '');
}

int? _parsePositiveSeconds(dynamic value) {
  final seconds = value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');
  return seconds != null && seconds > 0 ? seconds : null;
}

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
    case DioExceptionType.transformTimeout:
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
  final errorCode = extractBackendCode(responseData);
  final retryAt = extractRetryAt(response);

  final isSuccess = statusCode >= 200 && statusCode < 300;

  if (!isSuccess) {
    return ApiResponse.failure(
      message: extractBackendMessage(responseData, fallback: fallbackMessage),
      error: responseData is Map
          ? responseData["error"]?.toString()
          : responseData?.toString(),
      statusCode: statusCode,
      errorCode: errorCode,
      retryAt: retryAt,
    );
  }

  try {
    final parsedData = parser(response.data);

    return ApiResponse.success(
      parsedData,
      message: extractBackendMessage(responseData, fallback: "Success"),
      statusCode: statusCode,
      errorCode: errorCode,
      retryAt: retryAt,
      count: _extractListCount(responseData),
    );
  } catch (error) {
    return ApiResponse.failure(
      message: "Format error occurred. Please update the application.",
      error: error
          .toString(), // Retained under-the-hood for dev logging metrics
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
  final errorCode = extractBackendCode(responseData);
  final retryAt = extractRetryAt(response);

  final isSuccess = statusCode >= 200 && statusCode < 300;

  if (!isSuccess) {
    return ApiResponse.failure(
      message: extractBackendMessage(responseData, fallback: fallbackMessage),
      error: responseData is Map
          ? responseData["error"]?.toString()
          : responseData?.toString(),
      statusCode: statusCode,
      errorCode: errorCode,
      retryAt: retryAt,
    );
  }

  return ApiResponse.success(
    null,
    message: extractBackendMessage(responseData, fallback: fallbackMessage),
    statusCode: statusCode,
    errorCode: errorCode,
    retryAt: retryAt,
  );
}

ApiResponse<T> handleDioException<T>(
  DioException error, {
  String fallbackMessage = "Request failed",
}) {
  final exception = ApiException.fromDio(error);
  final response = error.response;

  return ApiResponse.failure(
    message: exception.message.isNotEmpty ? exception.message : fallbackMessage,
    error: (exception.data ?? error).toString(),
    statusCode: exception.statusCode,
    errorCode: response == null ? null : extractBackendCode(response.data),
    retryAt: response == null ? null : extractRetryAt(response),
  );
}

ApiResponse<T> handleUnknownException<T>(
  Object error, {
  String fallbackMessage = "Unexpected error",
}) {
  return ApiResponse.failure(message: fallbackMessage, error: error.toString());
}
