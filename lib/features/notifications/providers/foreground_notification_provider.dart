import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/services/foreground_notification_presenter.dart';

final foregroundNotificationProvider =
    Provider<ForegroundNotificationPresenter>((ref) {
      final presenter = ForegroundNotificationPresenter(
        overlay: () => ref
            .read(routerProvider)
            .routerDelegate
            .navigatorKey
            .currentState
            ?.overlay,
        locale: () => ref.read(localeProvider).languageCode,
        onTap: (notification) => unawaited(
          ref
              .read(notificationNavigationServiceProvider)
              .navigate(notification),
        ),
        accepts: (notification) =>
            ref.read(notificationApiServiceProvider).accepts(notification),
        isRead: (id) => ref
            .read(notificationProvider)
            .items
            .any((item) => item.id == id && item.isRead),
      );
      ref.onDispose(presenter.reset);
      return presenter;
    });
