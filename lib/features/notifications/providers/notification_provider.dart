import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/api_provider.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_notifier.dart';
import 'package:prokat/features/notifications/services/notification_state.dart';

enum NotificationSource { fcm, socket, local }

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationApiService(dio);
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final api = ref.watch(notificationApiServiceProvider);
      return NotificationNotifier(api);
    });
