import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';

class NotificationApiService {
  static const String _registerTokenPath = '/notifications/device-token';
  static const String _deactivateTokenPath =
      '/notifications/device-token/deactivate';
  static const String _notificationsPath = '/notifications';
  static const String _unreadCountPath = '/notifications/unread-count';
  static const String _readAllPath = '/notifications/read-all';

  final Dio dio;

  NotificationApiService(this.dio);

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await dio.post(
        _registerTokenPath,
        data: {
          'token': token,
          'platform': platform,
          if (metadata != null) ...metadata,
        },
      );
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<void> deactivateDeviceToken({required String token}) async {
    try {
      await dio.patch(
        _deactivateTokenPath,
        data: {
          'token': token,
        },
      );
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await dio.get(
        _notificationsPath,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      if (data is! List) {
        return const [];
      }

      return data
          .whereType<dynamic>()
          .map(
            (item) => AppNotification.fromJson(
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

  Future<int> getUnreadCount() async {
    try {
      final res = await dio.get(_unreadCountPath);
      final body = res.data;

      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is int) return data;
        if (data is String) return int.tryParse(data) ?? 0;
        if (data is Map<String, dynamic>) {
          final count = data['count'] ?? data['unreadCount'];
          if (count is int) return count;
          if (count is String) return int.tryParse(count) ?? 0;
        }
      }

      if (body is int) return body;
      if (body is String) return int.tryParse(body) ?? 0;

      return 0;
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await dio.patch('/notifications/$id/read');
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await dio.patch(_readAllPath);
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await dio.delete('/notifications/$id');
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
