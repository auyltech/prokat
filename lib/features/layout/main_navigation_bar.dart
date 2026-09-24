import 'package:flutter/material.dart';
import 'package:prokat/features/layout/nav_badge.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

final class _MainNavigationItem {
  final IconData icon;
  final String basePath;
  final String path;
  final String Function(AppLocalizations) label;

  const _MainNavigationItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.basePath,
  });
}

final _ownerNavigationItems = <_MainNavigationItem>[
  _MainNavigationItem(
    icon: LucideIcons.user2400,
    label: (l10n) => l10n.navProfile,
    path: AppRoutes.ownerProfile,
    basePath: AppRoutes.ownerProfile,
  ),
  _MainNavigationItem(
    icon: LucideIcons.truck400,
    label: (l10n) => l10n.navEquipment,
    path: AppRoutes.ownerEquipment,
    basePath: AppRoutes.ownerEquipment,
  ),
  _MainNavigationItem(
    icon: LucideIcons.radar400,
    label: (l10n) => l10n.navRequests,
    path: AppRoutes.ownerRequests,
    basePath: AppRoutes.ownerRequests,
  ),
  _MainNavigationItem(
    icon: LucideIcons.scrollText400,
    label: (l10n) => l10n.navOrders,
    path: AppRoutes.ownerBookings,
    basePath: AppRoutes.ownerBookings,
  ),
  _MainNavigationItem(
    icon: LucideIcons.messageCircle400,
    label: (l10n) => l10n.navChats,
    path: AppRoutes.ownerChatList,
    basePath: AppRoutes.ownerChatList,
  ),
];

final _clientNavigationItems = <_MainNavigationItem>[
  _MainNavigationItem(
    icon: LucideIcons.user2400,
    label: (l10n) => l10n.navProfile,
    path: AppRoutes.clientProfile,
    basePath: AppRoutes.clientProfile,
  ),
  _MainNavigationItem(
    icon: LucideIcons.search400,
    label: (l10n) => l10n.navEquipment,
    path: AppRoutes.searchList,
    basePath: AppRoutes.search,
  ),
  _MainNavigationItem(
    icon: LucideIcons.megaphone400,
    label: (l10n) => l10n.navRequests,
    path: AppRoutes.clientRequests,
    basePath: AppRoutes.clientRequests,
  ),
  _MainNavigationItem(
    icon: LucideIcons.scrollText400,
    label: (l10n) => l10n.navOrders,
    path: AppRoutes.clientOrders,
    basePath: AppRoutes.clientOrders,
  ),
  _MainNavigationItem(
    icon: LucideIcons.messageCircle400,
    label: (l10n) => l10n.navChats,
    path: AppRoutes.clientChatList,
    basePath: AppRoutes.clientChatList,
  ),
];

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final startupState = ref.watch(appStartupProvider).routeState;

    if (authState.session == null) {
      return const SizedBox.shrink();
    }

    final navigationItems = switch (startupState) {
      AppStartupRouteState.owner => _ownerNavigationItems,
      AppStartupRouteState.client => _clientNavigationItems,
      _ => const <_MainNavigationItem>[],
    };
    if (navigationItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final routerState = GoRouterState.of(context);
    final segments = routerState.uri.pathSegments;
    final isClientChatDetail =
        segments.length >= 2 &&
        segments[0] == 'chat' &&
        segments[1] == 'direct';
    final isOwnerChatDetail =
        segments.length >= 3 && segments[0] == 'owner' && segments[1] == 'chat';
    final isChatDetailScreen = isClientChatDetail || isOwnerChatDetail;
    if (isChatDetailScreen) {
      return const SizedBox.shrink();
    }

    final currentIndex = navigationItems.indexWhere(
      (item) => routerState.uri.path.startsWith(item.basePath),
    );
    final l10n = AppLocalizations.of(context)!;
    final counts = ref.watch(navigationCountsProvider).valueOrNull;

    return AppNavigationBar(
      items: [
        for (final item in navigationItems)
          AppNavigationBarItem(
            icon: item.icon,
            label: item.label(l10n),
            iconWrapper: (icon) => NavIconBadge(
              count: item.path == AppRoutes.ownerRequests
                  ? counts?.pendingRequests ?? 0
                  : item.path == AppRoutes.ownerBookings
                  ? counts?.pendingOrders ?? 0
                  : 0,
              color: Theme.of(context).colorScheme.error,
              child: icon,
            ),
          ),
      ],
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      tone: startupState == AppStartupRouteState.owner
          ? AppNavigationBarTone.owner
          : AppNavigationBarTone.primary,
      onItemTap: (index) => context.go(navigationItems[index].path),
    );
  }
}
