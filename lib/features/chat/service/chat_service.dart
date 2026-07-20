import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';

class ChatService {
  final ApiClient apiClient;

  ChatService(this.apiClient);

  Dio get _dio => apiClient.dio;

  // Get Chats
  // Fetch list of chat threads for owner/user

  Future<ApiResponse<QueryResult<ChatModel>>> getClientChats({
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    return _getChats(
      endpoint: "/chats",
      page: page,
      itemsPerPage: itemsPerPage,
    );
  }

  Future<ApiResponse<QueryResult<ChatModel>>> getOwnerChats({
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    return _getChats(
      endpoint: "/chats/owner",
      page: page,
      itemsPerPage: itemsPerPage,
    );
  }

  Future<ApiResponse<QueryResult<ChatModel>>> _getChats({
    required String endpoint,
    required int page,
    required int itemsPerPage,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {"page": page, "itemsPerPage": itemsPerPage},
      );

      return handleApiResponse<QueryResult<ChatModel>>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic> && data.containsKey("data")) {
            throw const FormatException("Expected paginated chat response");
          }

          final itemsJson = data["data"];

          if (itemsJson is! List) {
            throw FormatException("Expected chat list");
          }

          final items = itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid chat item");
            }

            return ChatModel.fromJson(item);
          }).toList();

          return QueryResult<ChatModel>(
            items: items,
            page: (data["page"] as num?)?.toInt() ?? page,
            itemsPerPage:
                (data["itemsPerPage"] as num?)?.toInt() ?? itemsPerPage,
            count: (data["count"] as num?)?.toInt() ?? items.length,
          );
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

  Future<ApiResponse<QueryResult<ChatMessageModel>>> getMessages({
    required String chatId,
    int page = 1,
    int itemsPerPage = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/chats/$chatId/messages',
        queryParameters: {"page": page, "itemsPerPage": itemsPerPage},
      );

      return handleApiResponse<QueryResult<ChatMessageModel>>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic> && data.containsKey("data")) {
            throw const FormatException("Expected paginated messages response");
          }

          final itemsJson = data["data"];

          if (itemsJson is! List) {
            throw FormatException("Expected messages list");
          }

          final items = itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid chat message item");
            }

            return ChatMessageModel.fromJson(item);
          }).toList();

          return QueryResult<ChatMessageModel>(
            items: items,
            page: (data["page"] as num?)?.toInt() ?? page,
            itemsPerPage:
                (data["itemsPerPage"] as num?)?.toInt() ?? itemsPerPage,
            count: (data["count"] as num?)?.toInt() ?? items.length,
          );
        },
        fallbackMessage: "Failed to load messages",
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
        parser: (data) => ChatModel.fromJson(data["data"]),
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

  Future<ApiResponse<ChatModel>> getChatByType(ChatType type) async {
    try {
      final response = await _dio.get('/chats/type/${type.name.toUpperCase()}');

      return handleApiResponse<ChatModel>(
        response: response,
        parser: (data) => ChatModel.fromJson(data["data"]),
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

  Future<ApiResponse<void>> markChatRead({
    required String chatId,
    required String messageId,
  }) async {
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
