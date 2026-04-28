import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

final ownerNavItems = [
  _NavItem(
    icon: Icons.home_rounded,
    label: 'Home',
    path: AppRoutes.ownerDashboard,
  ),
  _NavItem(
    icon: Icons.local_shipping_rounded,
    label: 'My Fleet',
    path: AppRoutes.ownerEquiment,
  ),
  _NavItem(
    icon: Icons.list_alt_rounded,
    label: 'Orders',
    path: AppRoutes.ownerBookings,
  ),
  _NavItem(
    icon: Icons.chat_bubble_rounded,
    label: 'Chats',
    path: AppRoutes.ownerChat,
  ),
];

final clientNavItems = [
  _NavItem(icon: Icons.home_rounded, label: 'Home', path: AppRoutes.dashboard),
  _NavItem(
    icon: Icons.search_rounded,
    label: 'Search',
    path: AppRoutes.searchList,
  ),
  _NavItem(
    icon: Icons.add_box_rounded,
    label: 'Create',
    path: AppRoutes.clientRequestsCreate,
  ),
  // _NavItem(
  //   icon: Icons.description_outlined,
  //   label: 'Requests',
  //   path: AppRoutes.clientRequests,
  // ),
  _NavItem(
    icon: Icons.list_alt_rounded,
    label: 'Orders',
    path: AppRoutes.clientOrders,
  ),
  _NavItem(
    icon: Icons.chat_bubble_rounded,
    label: 'Chats',
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final startupState = ref.watch(appStartupProvider);

    if (authState.session == null) {
      return const SizedBox.shrink();
    }

    final navItems = switch (startupState) {
      AppStartupState.owner => ownerNavItems,
      AppStartupState.client => clientNavItems,
      _ => const <_NavItem>[],
    };

    if (navItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final String location = GoRouterState.of(context).uri.path;

    int currentIndex = navItems.indexWhere(
      (item) => location.startsWith(item.path),
    );

    if (currentIndex == -1) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        showSelectedLabels:
            true, // Labels help accessibility for different roles
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.hintColor,
        onTap: (index) {
          context.go(navItems[index].path);
        },
        items: navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon, size: 28),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// Simple helper class to keep the code dry
class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  _NavItem({required this.icon, required this.label, required this.path});
}
