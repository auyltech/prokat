class ApiResponse<T> {
  final bool success;
  final T? data;

  /// Safe UI message.
  final String message;

  /// Raw technical/debug error.
  final Object? error;

  /// Optional HTTP status code.
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(
    T data, {
    String message = "Success",
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      error: null,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure({
    required String message,
    Object? error,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      data: null,
      message: message,
      error: error,
      statusCode: statusCode,
    );
  }
}
