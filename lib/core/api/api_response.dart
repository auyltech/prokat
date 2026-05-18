class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final dynamic error;

  ApiResponse({required this.success, this.data, this.message, this.error});

  /// Success response
  factory ApiResponse.success(T data, {String message = "Success"}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      error: null,
    );
  }

  /// Error response
  factory ApiResponse.failure({String? message, String? error}) {
    return ApiResponse(
      success: false,
      data: null,
      message: message,
      error: error,
    );
  }
}
