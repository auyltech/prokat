class ApiResponse<T> {
  final bool success;
  final T? data;

  /// Safe UI message.
  final String message;

  /// Raw technical/debug error.
  final String? error;

  /// Optional HTTP status code.
  final int? statusCode;

  /// Stable backend error/success code for client-side behavior.
  final String? errorCode;

  /// Absolute local time when the request may be attempted again.
  final DateTime? retryAt;

  /// Total matching rows when the backend sends `count` (list endpoints).
  final int? count;

  const ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.error,
    this.statusCode,
    this.errorCode,
    this.retryAt,
    this.count,
  });

  factory ApiResponse.success(
    T data, {
    String message = "Success",
    int? statusCode,
    String? errorCode,
    DateTime? retryAt,
    int? count,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      error: null,
      statusCode: statusCode,
      errorCode: errorCode,
      retryAt: retryAt,
      count: count,
    );
  }

  factory ApiResponse.failure({
    required String message,
    String? error,
    int? statusCode,
    String? errorCode,
    DateTime? retryAt,
  }) {
    return ApiResponse<T>(
      success: false,
      data: null,
      message: message,
      error: error,
      statusCode: statusCode,
      errorCode: errorCode,
      retryAt: retryAt,
    );
  }
}
