import 'package:prokat/features/notifications/services/notification_local_storage.dart';
import 'package:prokat/features/notifications/services/notification_navigation_service.dart';
import 'package:riverpod/riverpod.dart';

final notificationLocalStorageProvider = Provider<NotificationLocalStorage>((
  ref,
) {
  return NotificationLocalStorage();
});

final notificationNavigationServiceProvider =
    Provider<NotificationNavigationService>((ref) {
      final storage = ref.watch(notificationLocalStorageProvider);
      return NotificationNavigationService(ref, storage);
    });
