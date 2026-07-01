import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';

class ChatService {
  final ApiClient apiClient;

  ChatService(this.apiClient);

  Dio get _dio => apiClient.dio;

  // Get Chats
  // Fetch list of chat threads for owner/user
  Future<ApiResponse<List<ChatModel>>> getChatThreads(AppMode? mode) async {
    try {
      final response = await _dio.get(
        mode == AppMode.ownerMode ? '/chats/owner' : '/chats',
      );

      return handleApiResponse<List<ChatModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected chat list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid chat item");
            }

            return ChatModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load chats",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<List<ChatMessageModel>>> getMessages(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId/messages');

      return handleApiResponse<List<ChatMessageModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected chat list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid chat message item");
            }

            return ChatMessageModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load chat messages",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<ChatModel>> getChatById(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId');

      return handleApiResponse<ChatModel>(
        response: response,
        parser: (data) => ChatModel.fromJson(data),
        fallbackMessage: "Failed to load chat",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> sendChatMessage({
    required String chatId,
    required String content,
    required String type,
    String? clientTempId,
  }) async {
    try {
      final response = await _dio.post(
        "/chats/messages",
        data: {
          "chatId": chatId,
          "content": content,
          "type": type,
          "clientTempId": clientTempId,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Message sent",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<void>> marckChatRead(
    String chatId,
    String messageId,
  ) async {
    try {
      final response = await _dio.post(
        '/chats/$chatId/read',
        data: {'upToMessageId': messageId},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Chat updated",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }
}
