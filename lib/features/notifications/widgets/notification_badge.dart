import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 1. Import GoRouter
import 'package:prokat/core/router/app_routes.dart'; // 2. Update with your actual AppRoutes path
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';

class NotificationBadge extends ConsumerStatefulWidget {
  const NotificationBadge({super.key});

  @override
  ConsumerState<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge> {
  @override
  Widget build(BuildContext context) {
    final count = ref.watch(notificationProvider).unreadCount;
    final theme = Theme.of(context);
    final startupState = ref.watch(appStartupProvider).routeState;

    final notificationsRoute = startupState == AppStartupRouteState.owner
        ? AppRoutes.ownerNotifications
        : AppRoutes.notifications;

    // Define the core badge UI structure
    Widget badgeContent;

    if (count <= 0) {
      badgeContent = const Icon(
        Icons.notifications_rounded,
        size: 28,
        color: Colors.white,
      );
    } else {
      final text = count > 99 ? '99+' : count.toString();
      badgeContent = Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_rounded,
            size: 28,
            color: Colors.white,
          ),
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 3. Wrap with InkWell/GestureDetector to catch taps globally
    return InkWell(
      onTap: () => context.pushNamed(notificationsRoute),
      customBorder: const CircleBorder(), // Keeps the ripple effect circular
      child: Padding(
        padding: const EdgeInsets.all(
          8.0,
        ), // Padding ensures a good hit target size
        child: badgeContent,
      ),
    );
  }
}
