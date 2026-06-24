enum ErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  validation,
  conflict,
  notFound,
  server,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message; // User message
  final String code; // Error code
  final dynamic originalError;

  const AppError({
    required this.type,
    required this.message,
    required this.code,
    this.originalError,
  });
}
