import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

// Simple helper class to keep the code dry
class _NavItem {
  final IconData icon;
  final String path;
  final String Function(AppLocalizations) label;

  _NavItem({required this.icon, required this.label, required this.path});
}

final ownerNavItems = [
  // _NavItem(
  //   icon: Icons.home_filled,
  //   label: l.navHome,
  //   path: AppRoutes.ownerDashboard,
  // ),
  _NavItem(
    icon: Icons.person_rounded,
    label: (l) => 'Profile',
    path: AppRoutes.ownerProfile,
  ),

  // _NavItem(
  //   icon: Icons.notifications_rounded,
  //   label: (l) => 'Alerts',
  //   path: AppRoutes.ownerNotifications,
  // ),
  _NavItem(
    icon: Icons.description_outlined,
    label: (l) => 'Requests',
    path: AppRoutes.ownerRequests,
  ),
  _NavItem(
    icon: Icons.local_shipping_rounded,
    label: (l) => l.navMyFleet,
    path: AppRoutes.ownerEquiment,
  ),
  _NavItem(
    icon: Icons.list_alt_rounded,
    label: (l) => l.navOrders,
    path: AppRoutes.ownerBookings,
  ),
  _NavItem(
    icon: Icons.chat_bubble_rounded,
    label: (l) => l.navChats,
    path: AppRoutes.ownerChat,
  ),
];

final clientNavItems = [
  // _NavItem(icon: Icons.home_rounded, label: l.navHome, path: AppRoutes.dashboard),
  _NavItem(
    icon: Icons.person_rounded,
    label: (l) => 'Profile',
    path: AppRoutes.profile,
  ),
  _NavItem(
    icon: Icons.search_rounded,
    label: (l) => l.navSearch,
    path: AppRoutes.searchList,
  ),
  _NavItem(
    icon: Icons.add,
    label: (l) => l.navCreate,
    path: AppRoutes.clientRequestsCreate,
  ),
  // _NavItem(
  //   icon: Icons.description_outlined,
  //   label: (l) => 'Requests',
  //   path: AppRoutes.clientRequests,
  // ),
  // _NavItem(
  //   icon: Icons.notifications_rounded,
  //   label: (l) => 'Alerts',
  //   path: AppRoutes.notifications,
  // ),
  _NavItem(
    icon: Icons.list_alt_rounded,
    label: (l) => l.navOrders,
    path: AppRoutes.clientOrders,
  ),
  _NavItem(
    icon: Icons.chat_bubble_rounded,
    label: (l) => l.navChats,
    path: AppRoutes.chat,
  ),
];

class ProkatNavigationBar extends ConsumerStatefulWidget {
  const ProkatNavigationBar({super.key});

  @override
  ConsumerState<ProkatNavigationBar> createState() =>
      _ProkatNavigationBarState();
}

class _ProkatNavigationBarState extends ConsumerState<ProkatNavigationBar> {
  Widget _buildIcon(_NavItem item) {
    final icon = Icon(item.icon, size: 28);

    final isNotifications =
        item.path == AppRoutes.notifications ||
        item.path == AppRoutes.ownerNotifications;

    if (!isNotifications) {
      return icon;
    }

    return NotificationBadge();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final startupState = ref.watch(appStartupProvider).routeState;

    if (authState.session == null) {
      return const SizedBox.shrink();
    }

    final navItems = switch (startupState) {
      AppStartupRouteState.owner => ownerNavItems,
      AppStartupRouteState.client => clientNavItems,
      _ => const <_NavItem>[],
    };

    final Color primary = switch (startupState) {
      AppStartupRouteState.owner => AppColors.teal700,
      AppStartupRouteState.client => theme.primaryColor,
      _ => theme.primaryColor,
    };

    if (navItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final String location = GoRouterState.of(context).uri.path;
    int currentIndex = navItems.indexWhere(
      (item) => location.startsWith(item.path),
    );

    final List<String> segments = GoRouterState.of(context).uri.pathSegments;
    bool isChatDetailScreen = false;
    if (segments.length >= 2) {
      if (segments[0] == 'chat' && segments[1] != 'list') {
        isChatDetailScreen = true;
      }

      if (segments.length >= 3 &&
          segments[0] == 'owner' &&
          segments[1] == 'chat') {
        isChatDetailScreen = true;
      }
    }

    if (isChatDetailScreen) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24,
          0,
          24,
          0,
        ), // Gives the floating lift from the bottom and sides
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: primary, // Background color of the pill
            borderRadius: BorderRadius.circular(
              32,
            ), // Makes it a wide pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == (currentIndex < 0 ? 0 : currentIndex);

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(item.path),
                  child: Center(
                    child: Opacity(
                      // Uses theme.colorScheme.onPrimary, slightly dimmed if unselected
                      opacity: isSelected ? 1.0 : 0.5,
                      child: IconTheme(
                        data: IconThemeData(
                          color: theme.colorScheme.onPrimary,
                          size: 32,
                        ),
                        child: _buildIcon(
                          item,
                        ), // Icons only, labels completely removed
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
