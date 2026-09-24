import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class NotificationBadge extends ConsumerStatefulWidget {
  final Color? color;
  const NotificationBadge({super.key, this.color});

  @override
  ConsumerState<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationProvider.select((state) => state.unreadCount), (
      previous,
      next,
    ) {
      if (previous != null &&
          next > previous &&
          !MediaQuery.disableAnimationsOf(context)) {
        _arrival.forward(from: 0);
      }
    });
    final count = ref.watch(notificationProvider).unreadCount;
    final startupState = ref.watch(appStartupProvider).routeState;

    final notificationsRoute = startupState == AppStartupRouteState.owner
        ? AppRoutes.ownerNotifications
        : AppRoutes.clientNotifications;

    final theme = Theme.of(context);
    final text = count > 99 ? '99+' : count.toString();

    final badgeContent = Stack(
      clipBehavior: Clip.none,
      children: [
        AppIconButton(
          icon: LucideIcons.bell,
          onTap: () => context.push(notificationsRoute),
          tone: widget.color == null
              ? AppIconButtonTone.neutral
              : AppIconButtonTone.inverse,
          variant: widget.color == null
              ? AppIconButtonVariant.plain
              : AppIconButtonVariant.soft,
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
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
    return AnimatedBuilder(
      animation: _arrival,
      child: badgeContent,
      builder: (context, child) => Transform.rotate(
        angle:
            math.sin(_arrival.value * math.pi * 6) *
            0.14 *
            (1 - _arrival.value),
        child: child,
      ),
    );
  }
}
