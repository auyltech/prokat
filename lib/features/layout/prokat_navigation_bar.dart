import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

// Simple helper class to keep the code dry
class _NavItem {
  final IconData icon;
  final String base;
  final String path;
  final String Function(AppLocalizations) label;

  _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.base,
  });
}

final ownerNavItems = [
  // _NavItem(
  //   icon: Icons.home_filled,
  //   label: l.navHome,
  //   path: AppRoutes.ownerDashboard,
  // ),
  _NavItem(
    icon: LucideIcons.user2,
    label: (l) => 'Profile',
    path: AppRoutes.ownerProfile,
    base: AppRoutes.ownerProfile,
  ),

  // _NavItem(
  //   icon: Icons.notifications_rounded,
  //   label: (l) => 'Alerts',
  //   path: AppRoutes.ownerNotifications,
  // ),
  _NavItem(
    icon: LucideIcons.send,
    label: (l) => 'Requests',
    path: AppRoutes.ownerRequests,
    base: AppRoutes.ownerRequests,
  ),
  _NavItem(
    icon: LucideIcons.truck,
    label: (l) => l.navMyFleet,
    path: AppRoutes.ownerEquiment,
    base: AppRoutes.ownerEquiment,
  ),
  _NavItem(
    icon: LucideIcons.scrollText,
    label: (l) => l.navOrders,
    path: AppRoutes.ownerBookings,
    base: AppRoutes.ownerBookings,
  ),
  _NavItem(
    icon: LucideIcons.messageCircle,
    label: (l) => l.navChats,
    path: AppRoutes.ownerChatList,
    base: AppRoutes.ownerChatList,
  ),
];

final clientNavItems = [
  // _NavItem(icon: Icons.home_rounded, label: l.navHome, path: AppRoutes.dashboard),
  _NavItem(
    icon: LucideIcons.user2,
    label: (l) => 'Profile',
    path: AppRoutes.clientProfile,
    base: AppRoutes.clientProfile,
  ),
  _NavItem(
    icon: LucideIcons.search,
    label: (l) => l.navSearch,
    path: AppRoutes.searchList,
    base: AppRoutes.search,
  ),
  _NavItem(
    icon: LucideIcons.send,
    label: (l) => l.navCreate,
    path: AppRoutes.clientRequestsCreate,
    base: AppRoutes.clientRequests,
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
    icon: LucideIcons.scrollText,
    label: (l) => l.navOrders,
    path: AppRoutes.clientOrders,
    base: AppRoutes.clientOrders,
  ),
  _NavItem(
    icon: LucideIcons.messageCircle,
    label: (l) => l.navChats,
    path: AppRoutes.clientChatList,
    base: AppRoutes.clientChatList,
  ),
];

class ProkatNavigationBar extends ConsumerStatefulWidget {
  const ProkatNavigationBar({super.key});

  @override
  ConsumerState<ProkatNavigationBar> createState() =>
      _ProkatNavigationBarState();
}

class _ProkatNavigationBarState extends ConsumerState<ProkatNavigationBar> {
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
      AppStartupRouteState.owner => AppColors.teal800,
      AppStartupRouteState.client => theme.primaryColor,
      _ => theme.primaryColor,
    };

    if (navItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final String location = GoRouterState.of(context).uri.path;

    int currentIndex = navItems.indexWhere(
      (item) => location.startsWith(item.base),
    );

    final List<String> segments = GoRouterState.of(context).uri.pathSegments;

    bool isChatDetailScreen = false;

    if (segments.length >= 2) {
      if (segments[0] == 'chat' && segments[1] == 'direct') {
        isChatDetailScreen = true;
      }

      if (segments.length >= 3 &&
          segments[0] == 'owner' &&
          segments[1] == 'chat') {
        isChatDetailScreen = true;
      }
    }

    if (isChatDetailScreen) return const SizedBox.shrink();

    // 1. Place the color-bearing Container on the absolute outside layer
    return Container(
      // This forces the background color to bleed to the phone's bottom edge
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.black12, // Light gray color
            width: 1.0, // Border thickness
          ),
        ),
      ),
      child: SafeArea(
        top:
            false, // Keeps layout restrictions focused exclusively on the bottom notch
        child: Container(
          height: 64,
          decoration: BoxDecoration(color: theme.cardColor),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // Only show the soft blue/teal pill behind the active tab
                        color: isSelected
                            ? primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: Colors.black87, size: 32),
                        child: Icon(
                          item.icon,
                          size: 28,
                          color: isSelected ? primary : const Color(0xFF707E94),
                        ),
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
