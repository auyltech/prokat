import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_notifier.dart';
import 'package:prokat/features/notifications/services/notification_state.dart';

final notificationCompanyScopeProvider = StateProvider<String?>((ref) => null);

enum NotificationSource { fcm, socket, local }

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationApiService(
    dio,
    scope: () =>
        ref.read(notificationCompanyScopeProvider) ??
        (ref.read(appStartupProvider).routeState == AppStartupRouteState.owner
            ? 'OWNER'
            : 'CLIENT'),
  );
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final api = ref.watch(notificationApiServiceProvider);
      final notifier = NotificationNotifier(api);
      void refreshScope() {
        if (ref.read(authProvider).session == null) {
          notifier.clearOnLogout();
        } else {
          notifier.changeScope();
        }
      }

      ref.listen(notificationCompanyScopeProvider, (_, _) => refreshScope());
      ref.listen(
        appStartupProvider.select((s) => s.routeState),
        (_, _) => refreshScope(),
      );
      return notifier;
    });
