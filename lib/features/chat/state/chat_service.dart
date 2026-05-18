import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';

class ChatService {
  static const String _resolveChatIdPath = '/chats/chat-id';

  final ApiClient apiClient;

  ChatService(this.apiClient);

  Dio get _dio => apiClient.dio;

  // Get Chats
  // Fetch list of chat threads for owner/user
  Future<List<ChatModel>> getChatThreads(String? mode) async {
    try {
      final res = await _dio.get(mode == "owner" ? '/chats/owner' : '/chats');

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      if (data is! List) {
        return const [];
      }

      return data
          .whereType<dynamic>()
          .map(
            (item) => ChatModel.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<List<ChatMessageModel>> getMessages(String chatId) async {
    try {
      final res = await _dio.get('/chats/$chatId/messages');
      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      print(data);
      if (data is! List) {
        return const [];
      }

      return data
          .whereType<dynamic>()
          .map(
            (item) => ChatMessageModel.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final res = await _dio.get('/chats/$chatId');

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      if (data == null) return null;

      final json = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      return ChatModel.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  // TODO: DELETE: chatId is sent as part of booking and request
  // receive a bookingId or requestId and find the corresponding chatId
  Future<String?> getChatId({String? bookingId, String? requestId}) async {
    try {
      final res = await _dio.get(
        _resolveChatIdPath,
        queryParameters: {
          if ((bookingId ?? '').isNotEmpty) 'bookingId': bookingId,
          if ((requestId ?? '').isNotEmpty) 'requestId': requestId,
        },
      );

      final body = res.data;
      if (body is String && body.isNotEmpty) {
        return body;
      }

      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is String && data.isNotEmpty) {
          return data;
        }

        if (data is Map<String, dynamic>) {
          return data['id']?.toString() ?? data['chatId']?.toString();
        }

        return body['id']?.toString() ?? body['chatId']?.toString();
      }

      return null;
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
