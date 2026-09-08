import 'package:dio/dio.dart';
import 'package:prokat/l10n/app_localizations.dart';

String friendlyChatError(Object error, AppLocalizations l10n) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.transformTimeout) {
      return l10n.connectionTimedOut;
    }

    if (error.type == DioExceptionType.connectionError) {
      return l10n.noConnectionCheckNetwork;
    }

    final responseMessage = error.response?.data;

    if (responseMessage is Map && responseMessage['message'] is String) {
      return responseMessage['message'] as String;
    }

    if (responseMessage is String && responseMessage.trim().isNotEmpty) {
      return responseMessage;
    }

    return l10n.networkErrorTryAgain;
  }

  return l10n.somethingWentWrongTryAgain;
}
