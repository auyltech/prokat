import 'package:dio/dio.dart';

String friendlyChatError(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. The server may be warming up — please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No connection. Check your network and try again.';
    }

    final responseMessage = error.response?.data;

    if (responseMessage is Map && responseMessage['message'] is String) {
      return responseMessage['message'] as String;
    }

    if (responseMessage is String && responseMessage.trim().isNotEmpty) {
      return responseMessage;
    }

    return 'Network error. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}